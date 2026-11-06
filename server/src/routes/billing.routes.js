import { Router } from 'express';
import { query, tx } from '../db/pool.js';
import { requireAuth } from '../middleware/auth.js';
import { notFound, badRequest } from '../middleware/error.js';
import { uuid, oneOf, str } from '../lib/validate.js';

const router = Router();
const TIERS = ['discovery', 'premium', 'excellence'];
const CYCLES = ['monthly', 'yearly'];
const METHODS = ['mtnMoMo', 'orangeMoney', 'visaCard'];

// NB : les paiements sont SIMULÉS (aucun PSP sélectionné). En production réelle,
// le débit et la confirmation doivent passer par une passerelle PCI DSS côté
// serveur, jamais dans le client. Aucun numéro de carte / CVV n'est stocké ici.

router.get('/subscriptions/current', requireAuth, async (req, res, next) => {
  try {
    const { rows } = await query(
      `SELECT id, tier, billing_cycle, status, current_period_end
         FROM subscriptions WHERE user_id = $1
        ORDER BY created_at DESC LIMIT 1`,
      [req.user.id],
    );
    res.json({ subscription: rows[0] ?? null });
  } catch (err) {
    next(err);
  }
});

router.post('/subscriptions', requireAuth, async (req, res, next) => {
  try {
    const tier = oneOf(req.body.tier, TIERS, 'tier');
    const billingCycle = oneOf(req.body.billingCycle, CYCLES, 'billingCycle');
    const { rows } = await query(
      `INSERT INTO subscriptions (user_id, tier, billing_cycle, status, current_period_end)
       VALUES ($1, $2, $3, 'active', now() + interval '1 month')
       RETURNING id, tier, billing_cycle, status, current_period_end`,
      [req.user.id, tier, billingCycle],
    );
    res.status(201).json({ subscription: rows[0] });
  } catch (err) {
    next(err);
  }
});

// Paiement simulé : enregistre une intention puis la marque réussie, avec un
// indice masqué (4 derniers caractères d'un identifiant opérateur fictif).
router.post('/payments', requireAuth, async (req, res, next) => {
  try {
    const method = oneOf(req.body.method, METHODS, 'method');
    const subscriptionId = uuid(req.body.subscriptionId, 'subscriptionId');
    const amount = Number(req.body.amount);
    if (!Number.isFinite(amount) || amount <= 0 || amount > 1_000_000) {
      throw badRequest('Montant invalide');
    }
    const maskedHint = str(req.body.maskedHint, 'maskedHint', { max: 16, optional: true });

    const payment = await tx(async (client) => {
      const sub = await client.query(
        'SELECT id FROM subscriptions WHERE id = $1 AND user_id = $2',
        [subscriptionId, req.user.id],
      );
      if (sub.rowCount === 0) throw notFound('Abonnement introuvable');
      const { rows } = await client.query(
        `INSERT INTO payments (subscription_id, user_id, method, amount, currency, status, masked_hint)
         VALUES ($1, $2, $3, $4, 'XAF', 'succeeded', $5)
         RETURNING id, method, amount, currency, status, masked_hint, created_at`,
        [subscriptionId, req.user.id, method, Math.round(amount), maskedHint ?? null],
      );
      return rows[0];
    });
    res.status(201).json({ payment });
  } catch (err) {
    if (err.status) return next(err);
    next(err);
  }
});

export default router;
