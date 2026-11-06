import { Router } from 'express';
import { query, tx } from '../db/pool.js';
import { requireAuth, requireRole } from '../middleware/auth.js';
import { notFound, forbidden, conflict } from '../middleware/error.js';
import { str, int, uuid, oneOf } from '../lib/validate.js';

const router = Router();

// ---- Inscriptions (étudiant) ----
router.post('/enrollments', requireAuth, requireRole('student'), async (req, res, next) => {
  try {
    const courseId = uuid(req.body.courseId, 'courseId');
    const { rows } = await query(
      `INSERT INTO enrollments (course_id, student_id) VALUES ($1, $2)
       ON CONFLICT (course_id, student_id) DO UPDATE SET enrolled_at = enrollments.enrolled_at
       RETURNING id, course_id, student_id, enrolled_at`,
      [courseId, req.user.id],
    );
    res.status(201).json({ enrollment: rows[0] });
  } catch (err) {
    if (err.code === '23503') return next(notFound('Cours introuvable'));
    next(err);
  }
});

router.get('/enrollments', requireAuth, requireRole('student'), async (req, res, next) => {
  try {
    const { rows } = await query(
      `SELECT e.id, e.course_id, c.title, e.enrolled_at
         FROM enrollments e JOIN courses c ON c.id = e.course_id
        WHERE e.student_id = $1 ORDER BY e.enrolled_at DESC`,
      [req.user.id],
    );
    res.json({ enrollments: rows });
  } catch (err) {
    next(err);
  }
});

// ---- Progression par leçon (étudiant) ----
router.put('/lessons/:id/progress', requireAuth, requireRole('student'), async (req, res, next) => {
  try {
    const lessonId = uuid(req.params.id, 'id');
    const completed = oneOf(req.body.completed ?? false, [true, false], 'completed');
    const percent = int(req.body.percent ?? 0, 'percent', { min: 0, max: 100 });

    // Vérifie que l'étudiant est bien inscrit au cours de la leçon (anti-IDOR).
    const guard = await query(
      `SELECT 1 FROM lessons l
         JOIN courses c ON c.id = l.course_id
         JOIN enrollments e ON e.course_id = c.id
        WHERE l.id = $1 AND e.student_id = $2`,
      [lessonId, req.user.id],
    );
    if (guard.rowCount === 0) throw forbidden('Non inscrit à ce cours');

    const { rows } = await query(
      `INSERT INTO lesson_progress (lesson_id, student_id, percent, completed, updated_at)
       VALUES ($1, $2, $3, $4, now())
       ON CONFLICT (lesson_id, student_id)
       DO UPDATE SET percent = EXCLUDED.percent, completed = EXCLUDED.completed, updated_at = now()
       RETURNING lesson_id, student_id, percent, completed`,
      [lessonId, req.user.id, percent, completed],
    );
    res.json({ progress: rows[0] });
  } catch (err) {
    next(err);
  }
});

// ---- Notes (enseignant écrit, étudiant lit les siennes) ----
router.post('/grades', requireAuth, requireRole('teacher', 'admin'), async (req, res, next) => {
  try {
    const studentId = uuid(req.body.studentId, 'studentId');
    const courseId = uuid(req.body.courseId, 'courseId');
    const score = int(req.body.score, 'score', { min: 0, max: 100 });
    const comment = str(req.body.comment, 'comment', { max: 500, optional: true });
    const { rows } = await query(
      `INSERT INTO grades (student_id, course_id, teacher_id, score, comment)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, student_id, course_id, score, comment, created_at`,
      [studentId, courseId, req.user.id, score, comment ?? null],
    );
    res.status(201).json({ grade: rows[0] });
  } catch (err) {
    next(err);
  }
});

router.get('/grades', requireAuth, async (req, res, next) => {
  try {
    // Étudiant : ses notes. Enseignant/admin : celles de ses cours.
    const result = req.user.role === 'student'
      ? await query(
          `SELECT g.id, g.course_id, c.title, g.score, g.comment, g.created_at
             FROM grades g JOIN courses c ON c.id = g.course_id
            WHERE g.student_id = $1 ORDER BY g.created_at DESC`,
          [req.user.id],
        )
      : await query(
          `SELECT g.id, g.course_id, c.title, u.full_name AS student, g.score, g.comment, g.created_at
             FROM grades g JOIN courses c ON c.id = g.course_id JOIN users u ON u.id = g.student_id
            WHERE g.teacher_id = $1 ORDER BY g.created_at DESC`,
          [req.user.id],
        );
    res.json({ grades: result.rows });
  } catch (err) {
    next(err);
  }
});

// ---- Remises de devoirs (étudiant soumet) ----
router.post('/submissions', requireAuth, requireRole('student'), async (req, res, next) => {
  try {
    const assignmentId = uuid(req.body.assignmentId, 'assignmentId');
    const content = str(req.body.content, 'content', { max: 20000 });
    const created = await tx(async (client) => {
      const a = await client.query('SELECT id, course_id FROM assignments WHERE id = $1', [assignmentId]);
      if (a.rowCount === 0) throw notFound('Devoir introuvable');
      const courseId = a.rows[0].course_id;
      const guard = await client.query(
        'SELECT 1 FROM enrollments WHERE course_id = $1 AND student_id = $2',
        [courseId, req.user.id],
      );
      if (guard.rowCount === 0) throw forbidden('Non inscrit à ce cours');
      const { rows } = await client.query(
        `INSERT INTO submissions (assignment_id, student_id, content)
         VALUES ($1, $2, $3) RETURNING id, assignment_id, student_id, content, submitted_at`,
        [assignmentId, req.user.id, content],
      );
      return rows[0];
    });
    res.status(201).json({ submission: created });
  } catch (err) {
    if (err.status) return next(err);
    next(err);
  }
});

export default router;
