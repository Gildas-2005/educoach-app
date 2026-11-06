import 'auth_store.dart';
import 'chat_store.dart';
import 'learning_store.dart';
import 'legal_store.dart';
import 'session_store.dart';
import 'subscription_store.dart';

/// Fin de session propre — point d'entrée unique de la déconnexion.
///
/// Faille corrigée : un simple `AuthStore.logout()` laissait en mémoire
/// la filière, la progression, les moyennes, les conversations et les
/// consentements du compte précédent. Le compte suivant voyait ces
/// données personnelles (fuite inter-comptes). [signOut] purge
/// intégralement l'état lié au compte.
class SessionCoordinator {
  SessionCoordinator._();

  /// Déconnecte l'utilisateur et efface toute trace de son passage
  /// en mémoire (tout est volatile par conception — offline-first).
  static void signOut() {
    AuthStore.instance.logout();
    SessionStore.instance.reset();
    LearningStore.instance.reset();
    ChatStore.instance.reset();
    LegalStore.instance.reset();
    PermissionsStore.instance.reset();
    // Les paliers et factures sont des données personnelles du compte :
    // ils partent aussi (aucun reçu avec masques de carte ne doit
    // survivre à la déconnexion).
    SubscriptionStore.instance.reset();
  }
}
