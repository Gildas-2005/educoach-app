import jwt from 'jsonwebtoken';
import crypto from 'node:crypto';
import { config } from '../config.js';

// Access court + refresh long durée. Le refresh est stocké HACHÉ en base
// (jamais en clair) : il ne permet pas de retrouver le token d'origine.
export function signAccessToken(user) {
  return jwt.sign(
    { sub: user.id, role: user.role },
    config.jwtSecret,
    { expiresIn: config.jwtAccessTtl },
  );
}

export function verifyAccessToken(token) {
  return jwt.verify(token, config.jwtSecret);
}

export function newRefreshToken() {
  // Token opaque aléatoire (pas un JWT) : renvoyé au client, stocké haché.
  return crypto.randomBytes(48).toString('hex');
}

export function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

export function refreshExpiresAt() {
  const ms = parseTtl(config.jwtRefreshTtl);
  return new Date(Date.now() + ms);
}

// "30d" / "15m" / "12h" -> millisecondes.
function parseTtl(ttl) {
  const match = /^(\d+)([smhd])$/.exec(ttl);
  if (!match) return 30 * 24 * 60 * 60 * 1000;
  const n = Number(match[1]);
  const unit = { s: 1e3, m: 60e3, h: 3600e3, d: 86400e3 }[match[2]];
  return n * unit;
}
