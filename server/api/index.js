// Entrée serverless Vercel : la même application Express que `src/index.js`,
// exposée comme handler Node. Racine du projet Vercel = dossier `server/`,
// donc les dépendances de `server/package.json` sont installées au build.
//
// Les migrations ne tournent pas ici (comme sur Render) : `npm run migrate`
// est exécuté séparément contre la base Supabase.
import { createApp } from '../src/app.js';

const app = createApp();

export default function handler(request, response) {
  return app(request, response);
}
