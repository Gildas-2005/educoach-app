// Erreur applicative avec statut HTTP. Les messages destinés au client restent
// génériques ; les détails techniques ne sortent qu'en développement.
export class ApiError extends Error {
  constructor(status, message, details) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

export const badRequest = (m = 'Requête invalide', d) => new ApiError(400, m, d);
export const unauthorized = (m = 'Authentification requise') => new ApiError(401, m);
export const forbidden = (m = 'Accès refusé') => new ApiError(403, m);
export const notFound = (m = 'Ressource introuvable') => new ApiError(404, m);
export const conflict = (m = 'Conflit') => new ApiError(409, m);

// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, next) {
  const status = err.status || 500;
  // Ne jamais divulguer de stack trace / message interne en production.
  const payload = {
    error: status >= 500 ? 'Erreur interne du serveur' : err.message,
  };
  if (err.details && status < 500) payload.details = err.details;
  if (status >= 500) {
    // Journalisation serveur uniquement, sans données sensibles.
    console.error('Unhandled error:', err.message);
  }
  res.status(status).json(payload);
}
