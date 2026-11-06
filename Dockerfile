# ============================================================================
# Educoach PWA — image de production pour Render (Web Service / Dockerfile)
# Build Flutter web multi-étapes, servi par nginx. Les clés Supabase sont
# injectées au build via --build-arg (optionnel : sans elles, repli hors-ligne).
# ============================================================================

# ---- Étape 1 : build Flutter web ----
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Cible d'hôte : Render sert à la racine → base-href "/".
ARG SUPABASE_URL=""
ARG SUPABASE_ANON_KEY=""
ARG APP_ENV=production

WORKDIR /app
COPY . .

RUN flutter build web --release --no-web-resources-cdn \
      --dart-define=APP_ENV=${APP_ENV} \
      --dart-define=SUPABASE_URL=${SUPABASE_URL} \
      --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}

# ---- Étape 2 : serveur statique durci ----
FROM nginx:alpine AS runtime

COPY --from=build /app/build/web /usr/share/nginx/html

# Cache : le service worker et le bootstrap ne sont jamais mis en cache
# longtemps ; les assets hashés sont immuables.
RUN printf 'server {\n\
  listen 80;\n\
  root /usr/share/nginx/html;\n\
  index index.html;\n\
  location = /app_worker.js { add_header Cache-Control "no-cache"; }\n\
  location = /flutter_bootstrap.js { add_header Cache-Control "no-cache"; }\n\
  location = /manifest.json { add_header Cache-Control "no-cache"; }\n\
  location /assets/ { add_header Cache-Control "public, max-age=31536000, immutable"; }\n\
  location / { try_files $uri $uri/ /index.html; }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80
