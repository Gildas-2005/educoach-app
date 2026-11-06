import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import { config } from './config.js';
import { errorHandler, notFound } from './middleware/error.js';
import authRoutes from './routes/auth.routes.js';
import catalogRoutes from './routes/catalog.routes.js';
import learningRoutes from './routes/learning.routes.js';
import billingRoutes from './routes/billing.routes.js';
import chatRoutes from './routes/chat.routes.js';

export function createApp() {
  const app = express();

  // Derrière le proxy Render : faire confiance à X-Forwarded-For pour le rate-limit.
  app.set('trust proxy', 1);
  app.disable('x-powered-by');

  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));

  // CORS : liste d'origines explicite (le front Render), jamais le joker *.
  app.use(
    cors({
      origin(origin, cb) {
        if (!origin || config.corsOrigins.includes(origin)) return cb(null, true);
        return cb(new Error('Origine non autorisée'));
      },
      credentials: false,
    }),
  );

  // Corps limité -> prévient l'épuisement mémoire / payloads abusifs.
  app.use(express.json({ limit: '128kb' }));

  // Santé (sans auth) pour Render.
  app.get('/api/health', (_req, res) => res.json({ status: 'ok', time: new Date().toISOString() }));

  // Rate-limit global + renforcé sur l'authentification (anti brute-force).
  const general = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 300,
    standardHeaders: true,
    legacyHeaders: false,
  });
  const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 20,
    standardHeaders: true,
    legacyHeaders: false,
    skipSuccessfulRequests: true,
  });

  app.use('/api', general);
  app.use('/api/auth', authLimiter, authRoutes);
  app.use('/api', catalogRoutes);
  app.use('/api', learningRoutes);
  app.use('/api', billingRoutes);
  app.use('/api/chat', chatRoutes);

  app.use((_req, _res, next) => next(notFound()));
  app.use(errorHandler);

  return app;
}
