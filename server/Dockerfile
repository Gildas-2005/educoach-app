# ============================================================================
# Educoach API — image Node/Express pour Render (Web Service / Dockerfile)
# CONTEXTE DE BUILD = racine du repo (Render). Chemins préfixés server/.
# Start : node src/index.js. Santé : /api/health.
# ============================================================================
FROM node:20-alpine

ENV NODE_ENV=production
WORKDIR /app

# Installe uniquement les dépendances de production.
COPY server/package.json server/package-lock.json* ./
RUN npm install --omit=dev --no-audit --no-fund

# Code applicatif (src/ de l'API).
COPY server/src ./src

# Ne tourne pas en root.
USER node

EXPOSE 8080
CMD ["node", "src/index.js"]
