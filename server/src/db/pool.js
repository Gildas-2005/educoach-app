import pg from 'pg';
import fs from 'node:fs';
import { config } from '../config.js';

const { Pool } = pg;

// Pool unique, réutilisé. Render impose TLS vers son Postgres managé ; le
// certificat est signé par une CA racine de confiance du système, donc la
// vérification reste ACTIVE (pas de rejectUnauthorized:false -> pas de MITM).
// Pour une CA interne, fournir DATABASE_CA_PATH (chemin vers le .crt).
function sslConfig() {
  if (/sslmode=disable/.test(config.databaseUrl) && config.env !== 'production') {
    return false; // réservé à une base locale de développement uniquement
  }
  const caPath = process.env.DATABASE_CA_PATH;
  return caPath ? { require: true, ca: fs.readFileSync(caPath) } : { require: true };
}

export const pool = new Pool({
  connectionString: config.databaseUrl,
  max: Number(process.env.PG_POOL_MAX || 8),
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 10_000,
  ssl: sslConfig(),
});

pool.on('error', (err) => {
  // Connexion oisive cassée : journalise sans données sensibles.
  console.error('pg pool idle client error', err.message);
});

// Exécute une requête paramétrée (jamais de concaténation SQL -> pas d'injection).
export function query(text, params) {
  return pool.query(text, params);
}

// Transaction helper : rollback automatique en cas d'erreur.
export async function tx(fn) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}
