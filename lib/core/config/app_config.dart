import 'package:flutter/foundation.dart';

/// Configuration serveur (API REST hébergée sur Render) injectée au build via
/// `--dart-define`.
///
///   flutter build web --release \
///     --dart-define=API_BASE_URL=https://educoach-api.onrender.com \
///     --dart-define=APP_ENV=production
///
/// Repli sûr : si [apiBaseUrl] est vide, l'application tourne en mode
/// démonstration hors-ligne (stores en mémoire) — la prod existante n'est
/// jamais cassée par une config absente.
class AppConfig {
  const AppConfig._();

  static const String _apiBaseUrlDefine = String.fromEnvironment('API_BASE_URL');
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  /// Base URL normalisée (sans slash final). Vide si non configuré.
  static String apiBaseUrl = '';

  /// Vrai quand l'app doit parler au backend distant.
  static bool get isRemote => apiBaseUrl.isNotEmpty;

  static Uri? endpoint(String path) {
    if (!isRemote) return null;
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$apiBaseUrl/$normalized');
  }

  static void load() {
    apiBaseUrl = _apiBaseUrlDefine.endsWith('/')
        ? _apiBaseUrlDefine.substring(0, _apiBaseUrlDefine.length - 1)
        : _apiBaseUrlDefine;
    debugPrint(
      isRemote
          ? 'AppConfig: backend distant activé → $apiBaseUrl ($environment).'
          : 'AppConfig: API_BASE_URL absent → mode démonstration hors-ligne.',
    );
  }
}
