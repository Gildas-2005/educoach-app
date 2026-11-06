import { createApp } from './app.js';
import { config } from './config.js';
import { pool } from './db/pool.js';

async function bootstrap() {
  // Contrôles de démarrage : la base doit être joignable, sinon on échoue vite.
  if (!config.databaseUrl) {
    console.error('DATABASE_URL absent — impossible de démarrer.');
    process.exit(1);
  }
  await pool.query('SELECT 1');

  // NB : les migrations ne tournent PAS ici (le script migrate.js ferme le pool
  // partagé). Sur Render, elles sont exécutées par preDeployCommand: npm run migrate.

  const app = createApp();
  const server = app.listen(config.port, () => {
    console.log(`Educoach API prête sur le port ${config.port} (env=${config.env}).`);
  });

  const shutdown = (signal) => {
    console.log(`${signal} reçu, arrêt en cours...`);
    server.close(async () => {
      await pool.end();
      process.exit(0);
    });
    // Filet de sécurité si des connexions restent ouvertes.
    setTimeout(() => process.exit(1), 10_000).unref();
  };
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

bootstrap().catch((err) => {
  console.error('Démarrage impossible:', err.message);
  process.exit(1);
});
