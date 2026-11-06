# Horry — Educoach en HTML / CSS / JS

Version web autonome de l'application Educoach : **aucune dépendance, aucun build, aucun framework**.
HTML sémantique, CSS moderne (variables, `color-mix`, grid), JavaScript en modules ES natifs.

## Lancer

Le projet n'a **pas** besoin de compilation. Un simple serveur statique suffit (les modules ES ne
fonctionnent pas en `file://`) :

```bash
# depuis ce dossier
python3 -m http.server 4173
# ou
npx --yes serve -l 4173 .
```

Puis ouvrir <http://localhost:4173>.

Sur l'écran de connexion, trois boutons de démonstration créent un compte et ouvrent l'espace
correspondant : **Étudiant**, **Enseignant**, **Admin** (mot de passe posé automatiquement : `demo1234`).

## Structure

```
horry/
├── index.html              coquille : fond animé, splash, conteneurs, toasts, modale
├── css/
│   ├── tokens.css          palette et échelles (reprises de lib/core/theme/app_theme.dart)
│   ├── base.css            reset, typographie, gabarit, fond « aurore »
│   ├── components.css      boutons, cartes, champs, chips, onglets, toasts, modales…
│   ├── animations.css      keyframes + classes utilitaires (reveal, stagger, confetti…)
│   └── screens.css         mises en page par écran + responsive (barre latérale ≥ 1080px)
├── js/
│   ├── app.js              amorçage : routes, barre d'onglets, raccourcis
│   ├── router.js           routeur par hash + gardes de rôle
│   ├── store.js            état, persistance localStorage, données dérivées, auth
│   ├── data/
│   │   ├── seed.js         40 filières + 256 cours (GÉNÉRÉ depuis lib/core/data/seed.dart)
│   │   └── content.js      cours rédigés, générateur thématique, plans, légal, données école
│   ├── lib/
│   │   ├── dom.js          icônes SVG, toasts, modales, animations, formatage
│   │   └── i18n.js         t(fr, en) — même contrat que AppTexts.t du projet Flutter
│   └── screens/
│       ├── auth.js         bienvenue, connexion, inscription, permissions, filière
│       ├── learn.js        accueil, cours, détail, parcours, lecteur de leçon
│       ├── study.js        planning (export .ics) et notes
│       ├── social.js       messagerie (liste + fil)
│       ├── account.js      abonnement/paiement, profil, documents légaux
│       └── roles.js        espaces enseignant et administrateur
└── tools/parse-seed.mjs    régénère data/seed.js depuis la source Dart
```

## Ce qui est fidèlement repris du projet Flutter

| Flutter | Ici |
| --- | --- |
| Palette, dégradés, rayons, thème clair/sombre | `css/tokens.css` (`EducoachColors`) |
| `generateRoute` + `_guardRoute` | `js/router.js` (gardes par rôle, redirections) |
| `MockData` (cours, planning, notes, ressources dérivés d'un hash) | `js/store.js` (même logique déterministe) |
| `LearningSeed` (parcours, devoirs) | `js/data/content.js` (`buildPath`, `buildHomework`) |
| Cours phares (INF301, INF102, ECO101, DRP201, MED201, INF330) | `RICH_COURSES` — théorie, exemples chiffrés, exercices |
| 4 types d'exercices (QCM, vrai/faux, ordre, réponse libre) | lecteur de leçon dans `screens/learn.js` |
| Stores de session | `store.js`, persisté en `localStorage` |
| `AppTexts.t(fr, en)` | `js/lib/i18n.js` (bascule FR ⇄ EN dans le profil) |
| Abonnements 0 / 2 500 / 5 000 FCFA, MoMo, OM, Visa | `screens/account.js` (+ validation Luhn) |

## Animations

Fond « aurore » animé, apparition au défilement (IntersectionObserver), cascade (`stagger`),
transitions de vue, barres de progression animées, anneaux de progression, confettis et gain d'XP
flottant en fin de leçon, indicateur de frappe dans le chat, pulsation du nœud de parcours en cours,
frappe de shader `sheen` sur les cartes héro. Tout est désactivé automatiquement avec
`prefers-reduced-motion`.

## Limites connues (assumées)

- **Aucune API** : comptes, progression, messages et abonnements vivent dans `localStorage`.
  Le hachage des mots de passe est fait en SHA-256 via WebCrypto — suffisant pour une démo, mais
  un vrai déploiement doit hacher côté serveur (bcrypt/Argon2) comme le fait `server/`.
- Les ressources de cours et les fichiers ne sont pas réels (aucun téléchargement factice n'est simulé).
- Les sessions de planning et les notes sont **dérivées** du code de cours, comme dans le mode démo Flutter.
- Textes de contenu pédagogique en français ; seuls les libellés d'interface basculent FR/EN.

## Régénérer le catalogue

Si `lib/core/data/seed.dart` change :

```bash
node horry/tools/parse-seed.mjs
```
