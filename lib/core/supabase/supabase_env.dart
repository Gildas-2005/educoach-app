import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration Supabase injectée à la compilation via `--dart-define`.
///
/// Utilisation (build web prod) :
///   flutter build web --release \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// La clé **anon** est publique par design (protégée par les policies RLS côté
/// serveur). La **service_role** ne doit JAMAIS arriver dans le bundle client :
/// elle reste côté serveur / variables d'environnement de la CI pour les
/// migrations et le seed.
///
/// Repli sûr : si l'URL ou la clé manquent, [isEnabled] vaut false et
/// [initialize] est un no-op — l'application conserve son mode démonstration
/// hors-ligne. Ainsi la prod actuelle n'est jamais cassée par une config absente.
class SupabaseEnv {
  const SupabaseEnv._();

  static const String url = String.fromEnvironment('SUPABASE_URL');

  // Clé publique client : l'ancien `anonKey` (JWT) et le nouveau
  // `publishableKey` (sb_publishable_...) sont interchangeables côté client.
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static String get clientKey =>
      _publishableKey.isNotEmpty ? _publishableKey : _anonKey;

  /// L'environnement de build courant (utile pour les logs/diagnostics).
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isEnabled =>
      url.isNotEmpty && clientKey.isNotEmpty && Uri.tryParse(url)?.hasScheme == true;

  static SupabaseClient get client => Supabase.instance.client;

  /// Initialise Supabase une seule fois, uniquement si la config est présente.
  static Future<void> initialize() async {
    if (!isEnabled) {
      debugPrint(
        'SupabaseEnv: non configuré (SUPABASE_URL/ANON_KEY absents) → '
        'mode hors-ligne de démonstration.',
      );
      return;
    }
    await Supabase.initialize(
      url: url,
      publishableKey: clientKey,
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        // Privilégier l'URL sur le flux natif (deep link) côté web.
        authFlowType: AuthFlowType.pkce,
      ),
    );
    debugPrint('SupabaseEnv: initialisé (env=$environment).');
  }
}
