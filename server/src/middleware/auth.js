import { verifyAccessToken } from '../lib/tokens.js';
import { query } from '../db/pool.js';
import { unauthorized, forbidden } from './error.js';

// Vérifie le Bearer token et charge l'identité DEPUIS LA BASE (le client ne
// peut pas falsifier son rôle/statut : source de vérité = serveur).
export async function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) throw unauthorized();

    let claims;
    try {
      claims = verifyAccessToken(token);
    } catch {
      throw unauthorized('Session expirée');
    }

    const { rows } = await query(
      'SELECT id, email, role, status FROM users WHERE id = $1',
      [claims.sub],
    );
    const user = rows[0];
    if (!user) throw unauthorized();
    if (user.status !== 'active') throw forbidden('Compte non actif');

    req.user = user;
    next();
  } catch (err) {
    next(err);
  }
}

// Garde par rôle (autorisation serveur).
export function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user) return next(unauthorized());
    if (!roles.includes(req.user.role)) return next(forbidden());
    next();
  };
}
