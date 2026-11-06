import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { query, tx } from '../db/pool.js';
import { config } from '../config.js';
import {
  signAccessToken,
  newRefreshToken,
  hashToken,
  refreshExpiresAt,
} from '../lib/tokens.js';
import { requireAuth } from '../middleware/auth.js';
import { badRequest, unauthorized, conflict } from '../middleware/error.js';
import { str, email } from '../lib/validate.js';

const router = Router();
const ROLES = ['student', 'teacher', 'admin'];

// N'authentifie que par identifiants ; les rôles/status sont résolus depuis la
// base. Message d'erreur identique quel que soit le motif -> pas d'énumération.
const INVALID = () => unauthorized('Email ou mot de passe incorrect');

async function issueSession(userId) {
  const refresh = newRefreshToken();
  const refreshHash = hashToken(refresh);
  const expiresAt = refreshExpiresAt();
  await query(
    'INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)',
    [userId, refreshHash, expiresAt],
  );
  return { refresh, refreshHash };
}

router.post('/register', async (req, res, next) => {
  try {
    const fullName = str(req.body.fullName, 'fullName', { max: 120 });
    const emailValue = email(req.body.email);
    const password = str(req.body.password, 'password', { min: 8, max: 200 });
    const role = str(req.body.role, 'role', { max: 20 });
    if (!ROLES.includes(role)) throw badRequest('Rôle invalide');
    // Un compte admin ne se crée jamais via inscription publique.
    if (role === 'admin') throw conflict('Création admin réservée');

    const exists = await query('SELECT 1 FROM users WHERE email = $1', [emailValue]);
    if (exists.rowCount > 0) throw conflict('Email déjà utilisé');

    const passwordHash = await bcrypt.hash(password, config.bcryptRounds);
    // Les enseignants démarrent en attente de validation ; étudiants actifs.
    const status = role === 'teacher' ? 'pending' : 'active';

    const user = await tx(async (client) => {
      const { rows } = await client.query(
        `INSERT INTO users (full_name, email, password_hash, role, status)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id, full_name, email, role, status`,
        [fullName, emailValue, passwordHash, role, status],
      );
      return rows[0];
    });

    const { refresh } = await issueSession(user.id);
    const accessToken = signAccessToken(user);
    res.status(201).json({ user, accessToken, refreshToken: refresh });
  } catch (err) {
    next(err);
  }
});

router.post('/login', async (req, res, next) => {
  try {
    const emailValue = email(req.body.email);
    const password = str(req.body.password, 'password', { max: 200 });

    const { rows } = await query(
      'SELECT id, full_name, email, password_hash, role, status FROM users WHERE email = $1',
      [emailValue],
    );
    const user = rows[0];
    if (!user) throw INVALID();

    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) throw INVALID();
    if (user.status === 'blocked') throw unauthorized('Compte bloqué');
    // 'pending' : autorisé à se connecter mais signalé côté client pour onboarding.

    const safe = {
      id: user.id,
      fullName: user.full_name,
      email: user.email,
      role: user.role,
      status: user.status,
    };
    const { refresh } = await issueSession(user.id);
    const accessToken = signAccessToken(user);
    res.json({ user: safe, accessToken, refreshToken: refresh });
  } catch (err) {
    next(err);
  }
});

// Rotation : le refresh présenté est invalidé et remplacé.
router.post('/refresh', async (req, res, next) => {
  try {
    const presented = str(req.body.refreshToken, 'refreshToken', { max: 200 });
    const tokenHash = hashToken(presented);
    const { rows } = await query(
      `SELECT rt.user_id, rt.expires_at, u.id, u.full_name, u.email, u.role, u.status
         FROM refresh_tokens rt
         JOIN users u ON u.id = rt.user_id
        WHERE rt.token_hash = $1`,
      [tokenHash],
    );
    const record = rows[0];
    if (!record || new Date(record.expires_at) < new Date()) throw unauthorized();
    if (record.status !== 'active') throw unauthorized('Compte non actif');

    await query('DELETE FROM refresh_tokens WHERE token_hash = $1', [tokenHash]);
    const { refresh } = await issueSession(record.user_id);
    const accessToken = signAccessToken(record);
    res.json({
      user: { id: record.id, fullName: record.full_name, email: record.email, role: record.role, status: record.status },
      accessToken,
      refreshToken: refresh,
    });
  } catch (err) {
    next(err);
  }
});

router.post('/logout', async (req, res, next) => {
  try {
    const presented = req.body?.refreshToken;
    if (presented) {
      await query('DELETE FROM refresh_tokens WHERE token_hash = $1', [hashToken(String(presented))]);
    }
    res.status(204).end();
  } catch (err) {
    next(err);
  }
});

router.get('/me', requireAuth, (req, res) => {
  res.json({ user: req.user });
});

export default router;
