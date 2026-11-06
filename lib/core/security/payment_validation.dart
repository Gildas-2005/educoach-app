/// Validation et masquage des données de paiement (saisie locale, démo).
///
/// ⚠️ Contexte : l'application est 100 % hors-ligne, sans backend ni
/// passerelle de paiement réelle. Ce fichier implémente les BONNES
/// PRATIQUES côté client pour un futur encaissement vrai :
///
/// * le numéro de carte complet et le CVV ne sont JAMAIS conservés —
///   seule la dérivation « •••• 4242 » entre dans l'historique ;
/// * le CVV n'est jamais écrit dans ce fichier ni affiché après saisie ;
/// * la validation Luhn et la date d'expiration évitent les faux
///   négatifs avant toute simulation de débit.
///
/// Pour un vrai paiement, l'autorisation doit être faite côté serveur
/// par un prestataire certifié PCI DSS (GSMA/UMS pour Mobile Money,
/// Stripe/CINET ou banque pour Visa) — aucune de ces données ne doit
/// transiter ni être stockée telle quelle par l'application.
class PaymentValidation {
  PaymentValidation._();

  /// Ne garde que les chiffres d'une saisie (carte, téléphone, PIN…).
  static String digitsOnly(String input) {
    final b = StringBuffer();
    for (final c in input.runes) {
      if (c >= 0x30 && c <= 0x39) b.writeCharCode(c);
    }
    return b.toString();
  }

  /// Algorithme de Luhn (ISO/IEC 7812) — contrôle de validité d'une
  /// numéro de carte. 13 à 19 chiffres acceptés (Visa 16, MC 16…).
  static bool luhnValid(String digits) {
    if (digits.length < 13 || digits.length > 19) return false;
    var sum = 0;
    var doubleIt = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      final r = digits.codeUnitAt(i);
      if (r < 0x30 || r > 0x39) return false;
      var d = r - 0x30;
      if (doubleIt) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      doubleIt = !doubleIt;
    }
    return sum % 10 == 0;
  }

  /// Formatage visuel « 4242 4242 4242 4242 » pendant la saisie.
  static String groupPan(String digits) {
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(digits[i]);
    }
    return b.toString();
  }

  /// Vrai si MM/AA dans le futur (l'an est noté sur 2 chiffres).
  static bool expiryInFuture(int month, int yearTwoDigits) {
    if (month < 1 || month > 12) return false;
    final now = DateTime.now();
    final year = 2000 + yearTwoDigits;
    if (year < now.year) return false;
    if (year == now.year && month < now.month) return false;
    return true;
  }

  /// Masquage de carte : ne conserve QUE les 4 derniers chiffres.
  /// C'est la seule forme sous laquelle le numéro survit au paiement.
  static String maskPan(String digits) {
    if (digits.length < 4) return '•••• ••••';
    return '•••• ${digits.substring(digits.length - 4)}';
  }

  /// Masquage d'un numéro mobile money : '+237 6•• •• •• 34'.
  static String maskPhone9(String digits9) {
    if (digits9.length < 4) return '+237 6•• •• •• ••';
    return '+237 ${digits9[0]}•• •• •• ${digits9.substring(digits9.length - 2)}';
  }
}
