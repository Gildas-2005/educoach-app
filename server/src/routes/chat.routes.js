import { Router } from 'express';
import { query, tx } from '../db/pool.js';
import { requireAuth } from '../middleware/auth.js';
import { notFound, forbidden } from '../middleware/error.js';
import { uuid, str, int, oneOf } from '../lib/validate.js';

const router = Router();

async function assertMember(roomId, userId) {
  const { rows } = await query(
    'SELECT 1 FROM chat_members WHERE room_id = $1 AND user_id = $2',
    [roomId, userId],
  );
  if (rows.length === 0) throw forbidden('Non membre de cette salle');
}

router.get('/rooms', requireAuth, async (req, res, next) => {
  try {
    const { rows } = await query(
      `SELECT r.id, r.name, r.kind, r.created_at
         FROM chat_rooms r JOIN chat_members m ON m.room_id = r.id
        WHERE m.user_id = $1 ORDER BY r.created_at DESC`,
      [req.user.id],
    );
    res.json({ rooms: rows });
  } catch (err) {
    next(err);
  }
});

router.post('/rooms', requireAuth, async (req, res, next) => {
  try {
    const name = str(req.body.name, 'name', { max: 120 });
    const kind = oneOf(req.body.kind ?? 'group', ['group', 'direct'], 'kind');
    const room = await tx(async (client) => {
      const { rows } = await client.query(
        'INSERT INTO chat_rooms (name, kind, created_by) VALUES ($1, $2, $3) RETURNING id, name, kind',
        [name, kind, req.user.id],
      );
      await client.query(
        'INSERT INTO chat_members (room_id, user_id) VALUES ($1, $2)',
        [rows[0].id, req.user.id],
      );
      return rows[0];
    });
    res.status(201).json({ room });
  } catch (err) {
    next(err);
  }
});

router.get('/rooms/:id/messages', requireAuth, async (req, res, next) => {
  try {
    const roomId = uuid(req.params.id, 'id');
    await assertMember(roomId, req.user.id);
    const limit = oneOf(req.query.limit ?? 50, [20, 50, 100], 'limit');
    const before = req.query.before ? new Date(String(req.query.before)) : null;
    if (before && Number.isNaN(before.getTime())) throw notFound('Curseur invalide');
    const { rows } = await query(
      `SELECT m.id, m.body, m.created_at, u.full_name AS author
         FROM chat_messages m JOIN users u ON u.id = m.sender_id
        WHERE m.room_id = $1 AND ($2::timestamptz IS NULL OR m.created_at < $2)
        ORDER BY m.created_at DESC LIMIT $3`,
      [roomId, before, limit],
    );
    res.json({ messages: rows.reverse() });
  } catch (err) {
    if (err.status) return next(err);
    next(err);
  }
});

router.post('/rooms/:id/messages', requireAuth, async (req, res, next) => {
  try {
    const roomId = uuid(req.params.id, 'id');
    const body = str(req.body.body, 'body', { max: 4000 });
    await assertMember(roomId, req.user.id);
    const { rows } = await query(
      `INSERT INTO chat_messages (room_id, sender_id, body)
       VALUES ($1, $2, $3) RETURNING id, room_id, body, created_at`,
      [roomId, req.user.id, body],
    );
    res.status(201).json({ message: rows[0] });
  } catch (err) {
    if (err.status) return next(err);
    next(err);
  }
});

// Ajoute un membre par email (contrôle d'existence serveur, anti-injection).
router.post('/rooms/:id/members', requireAuth, async (req, res, next) => {
  try {
    const roomId = uuid(req.params.id, 'id');
    await assertMember(roomId, req.user.id);
    const targetEmail = str(req.body.email, 'email', { max: 320 }).toLowerCase();
    const target = await query('SELECT id FROM users WHERE email = $1', [targetEmail]);
    if (target.rowCount === 0) throw notFound('Utilisateur introuvable');
    await query(
      'INSERT INTO chat_members (room_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [roomId, target.rows[0].id],
    );
    res.status(201).json({ ok: true });
  } catch (err) {
    if (err.status) return next(err);
    next(err);
  }
});

export default router;
