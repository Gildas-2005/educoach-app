import { Router } from 'express';
import { query } from '../db/pool.js';
import { requireAuth, requireRole } from '../middleware/auth.js';
import { notFound, badRequest } from '../middleware/error.js';
import { str, int, uuid, oneOf } from '../lib/validate.js';

const router = Router();
const LIMITS = [20, 50, 100];

router.get('/filieres', requireAuth, async (req, res, next) => {
  try {
    const { rows } = await query(
      'SELECT id, name, domain FROM filieres ORDER BY domain, name',
    );
    res.json({ filieres: rows });
  } catch (err) {
    next(err);
  }
});

// Liste paginée bornée : pas de fetch de table entière.
router.get('/courses', requireAuth, async (req, res, next) => {
  try {
    const limit = oneOf(req.query.limit ?? 20, LIMITS, 'limit');
    const offset = int(req.query.offset ?? 0, 'offset', { min: 0, max: 100000 });
    const filiereId = req.query.filiereId ? uuid(req.query.filiereId, 'filiereId') : null;
    const params = [limit, offset];
    let where = 'WHERE c.status = $3';
    params.push('published');
    if (filiereId) {
      where += ' AND c.filiere_id = $' + (params.length + 1);
      params.push(filiereId);
    }
    const { rows } = await query(
      `SELECT c.id, c.title, c.summary, c.filiere_id, c.teacher_id, f.name AS filiere
         FROM courses c
         JOIN filieres f ON f.id = c.filiere_id
         ${where}
        ORDER BY c.created_at DESC
        LIMIT $1 OFFSET $2`,
      params,
    );
    res.json({ courses: rows, limit, offset });
  } catch (err) {
    next(err);
  }
});

router.get('/courses/:id', requireAuth, async (req, res, next) => {
  try {
    const id = uuid(req.params.id, 'id');
    const { rows } = await query(
      `SELECT c.id, c.title, c.summary, c.filiere_id, c.teacher_id, f.name AS filiere
         FROM courses c JOIN filieres f ON f.id = c.filiere_id
        WHERE c.id = $1`,
      [id],
    );
    const course = rows[0];
    if (!course) throw notFound('Cours introuvable');
    const { rows: lessons } = await query(
      'SELECT id, title, position, duration_minutes FROM lessons WHERE course_id = $1 ORDER BY position',
      [id],
    );
    res.json({ course, lessons });
  } catch (err) {
    next(err);
  }
});

// Création réservée aux enseignants/admins ; le propriétaire est le token, pas le client.
router.post('/courses', requireAuth, requireRole('teacher', 'admin'), async (req, res, next) => {
  try {
    const title = str(req.body.title, 'title', { max: 160 });
    const summary = str(req.body.summary, 'summary', { max: 1000, optional: true });
    const filiereId = uuid(req.body.filiereId, 'filiereId');
    const { rows } = await query(
      `INSERT INTO courses (title, summary, filiere_id, teacher_id, status)
       VALUES ($1, $2, $3, $4, 'published')
       RETURNING id, title, summary, filiere_id, teacher_id`,
      [title, summary ?? null, filiereId, req.user.id],
    );
    res.status(201).json({ course: rows[0] });
  } catch (err) {
    next(err);
  }
});

export default router;
