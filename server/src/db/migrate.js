import fs from 'node:fs';
import path from 'node:path';
import url from 'node:url';
import { pool } from './pool.js';

const dir = path.join(path.dirname(url.fileURLToPath(import.meta.url)), 'migrations');

async function run() {
  await pool.query(
    `CREATE TABLE IF NOT EXISTS schema_migrations (
       name text PRIMARY KEY,
       applied_at timestamptz NOT NULL DEFAULT now()
     )`,
  );

  const files = fs.readdirSync(dir).filter((f) => f.endsWith('.sql')).sort();
  for (const file of files) {
    const { rowCount } = await pool.query('SELECT 1 FROM schema_migrations WHERE name = $1', [file]);
    if (rowCount > 0) {
      console.log(`skip  ${file}`);
      continue;
    }
    const sql = fs.readFileSync(path.join(dir, file), 'utf8');
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(sql);
      await client.query('INSERT INTO schema_migrations (name) VALUES ($1)', [file]);
      await client.query('COMMIT');
      console.log(`apply ${file}`);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error(`échec ${file}:`, err.message);
      throw err;
    } finally {
      client.release();
    }
  }
  await pool.end();
  console.log('migrations terminées');
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
