import 'dotenv/config';

function required(name) {
  const value = process.env[name];
  if (!value) {
    // Ne jamais journaliser la valeur, uniquement le nom de la variable.
    throw new Error(`Variable d'environnement manquante: ${name}`);
  }
  return value;
}

export const config = {
  env: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT || 8080),
  // Render fournit DATABASE_URL (ou EXTERNAL_DB_URL) pour son Postgres managé.
  databaseUrl: process.env.DATABASE_URL || process.env.EXTERNAL_DB_URL || '',
  // Secret JWT : obligatoire hors développement (générer une valeur longue aléatoire).
  jwtSecret: process.env.JWT_SECRET || (process.env.NODE_ENV === 'production' ? required('JWT_SECRET') : 'dev_only_insecure_secret'),
  jwtAccessTtl: process.env.JWT_ACCESS_TTL || '15m',
  jwtRefreshTtl: process.env.JWT_REFRESH_TTL || '30d',
  bcryptRounds: Number(process.env.BCRYPT_ROUNDS || 12),
  // Origines autorisées (CORS) : le front Render + localhost en dev.
  corsOrigins: (process.env.CORS_ORIGINS || 'http://localhost:8080,https://educoach.onrender.com')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),
};
