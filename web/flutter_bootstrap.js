{{flutter_js}}
{{flutter_build_config}}

// Personnalisation Educoach : on remplace le service worker déprécié de Flutter
// par notre propre worker de cache hors-ligne (web/app_worker.js, copié à la
// racine du build). Flutter enregistre l'URL fournie comme son worker géré,
// ce qui évite tout conflit avec le stub auto-désinscription.
_flutter.loader.load(
  {
    serviceWorkerSettings: {
      serviceWorkerUrl: 'app_worker.js',
      serviceWorkerVersion: '20261106',
    },
  },
);
