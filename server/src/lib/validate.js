import { badRequest } from '../middleware/error.js';

// Validations minimales et bornées côté serveur. Toute entrée externe est
// considérée non fiable (longueur + type + format), jamais "de confiance".

export function str(value, field, { min = 1, max = 255, optional = false } = {}) {
  if (value == null || value === '') {
    if (optional) return undefined;
    throw badRequest(`Champ requis: ${field}`);
  }
  if (typeof value !== 'string') throw badRequest(`Type invalide: ${field}`);
  const s = value.trim();
  if (s.length < min) throw badRequest(`${field} trop court`);
  if (s.length > max) throw badRequest(`${field} trop long`);
  return s;
}

export function email(value, { optional = false } = {}) {
  const s = str(value, 'email', { max: 320, optional });
  if (s === undefined) return undefined;
  // Regex pragmatique (validation définitive = email confirmé, géré plus tard).
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s)) throw badRequest('Email invalide');
  return s.toLowerCase();
}

export function int(value, field, { min = -2147483647, max = 2147483647, optional = false } = {}) {
  if (value == null || value === '') {
    if (optional) return undefined;
    throw badRequest(`Champ requis: ${field}`);
  }
  const n = Number(value);
  if (!Number.isInteger(n) || n < min || n > max) throw badRequest(`${field} invalide`);
  return n;
}

export function uuid(value, field, { optional = false } = {}) {
  if (value == null || value === '') {
    if (optional) return undefined;
    throw badRequest(`Champ requis: ${field}`);
  }
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value)) {
    throw badRequest(`${field} invalide`);
  }
  return value;
}

export function oneOf(value, options, field, { optional = false } = {}) {
  if (value == null) {
    if (optional) return undefined;
    throw badRequest(`Champ requis: ${field}`);
  }
  if (!options.includes(value)) throw badRequest(`${field} invalide`);
  return value;
}
