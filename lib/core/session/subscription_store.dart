import 'package:flutter/foundation.dart';

import '../security/payment_validation.dart';

/// Paliers d'abonnement Educoach.
enum SubscriptionTier {
  /// Gratuit : accès au socle (cours, planning, notes, chat profs).
  discovery,

  /// Payant : examens blancs illimités, correction prioritaire, stats.
  premium,

  /// Payant : tout Premium + coaching individuel et sessions en direct.
  excellence,
}

/// Périodicité de facturation des paliers payants.
enum BillingCycle { monthly, yearly }

/// Moyens de paiement proposés au Cameroun.
enum PaymentMethod { mtnMoMo, orangeMoney, visaCard }

/// Définition commerciale d'un palier : prix en FCFA.
class PlanPricing {
  const PlanPricing({
    required this.tier,
    required this.monthly,
    required this.yearly,
  });
  final SubscriptionTier tier;

  /// Prix mensuel en FCFA.
  final int monthly;

  /// Prix annuel en FCFA (2 mois offerts sur le mensuel × 12).
  final int yearly;

  int priceOf(BillingCycle cycle) =>
      cycle == BillingCycle.monthly ? monthly : yearly;

  bool get isFree => monthly == 0;
}

/// Reçu d'un paiement réussi. Ne contient JAMAIS de donnée sensible :
/// uniquement le masque « •••• 1234 » produit par [PaymentValidation].
class PaymentReceipt {
  const PaymentReceipt({
    required this.id,
    required this.date,
    required this.tier,
    required this.cycle,
    required this.method,
    required this.amountFcid,
    required this.maskedAccount,
  });

  final String id;
  final DateTime date;
  final SubscriptionTier tier;
  final BillingCycle cycle;
  final PaymentMethod method;

  /// Montant en FCFA (entier, pas de virgule en XAF).
  final int amountFcid;

  /// '+237 6•• •• •• 34' ou '•••• 4242' — jamais le numéro complet.
  final String maskedAccount;
}

/// État d'abonnement du compte connecté.
///
/// Singleton [ChangeNotifier] volatile comme tous les stores du projet :
/// [SessionCoordinator.signOut] appelle [reset] pour qu'un compte suivant
/// ne voie ni le palier ni les factures du précédent (fuite inter-comptes).
///
/// ⚠️ Le paiement est SIMULÉ (aucun backend dans cette démo) : en
/// production, le débit doit être autorisé par le prestataire (MTN MoMo
/// API, Orange Money API, acquiring Visa) puis confirmé ici par un
/// webhook signé, jamais par le client seul.
class SubscriptionStore extends ChangeNotifier {
  SubscriptionStore._();

  static final SubscriptionStore instance = SubscriptionStore._();

  /// Grille tarifaire (FCFA) — l'annuel offre 2 mois.
  static const List<PlanPricing> plans = [
    PlanPricing(tier: SubscriptionTier.discovery, monthly: 0, yearly: 0),
    PlanPricing(tier: SubscriptionTier.premium, monthly: 2500, yearly: 25000),
    PlanPricing(
      tier: SubscriptionTier.excellence,
      monthly: 5000,
      yearly: 50000,
    ),
  ];

  static PlanPricing pricingFor(SubscriptionTier tier) =>
      plans.firstWhere((p) => p.tier == tier);

  SubscriptionTier _tier = SubscriptionTier.discovery;
  BillingCycle _cycle = BillingCycle.monthly;
  DateTime? _renewsAt;
  bool _cancelRequested = false;
  final List<PaymentReceipt> _receipts = [];
  bool _processing = false;

  SubscriptionTier get tier => _tier;
  BillingCycle get cycle => _cycle;
  DateTime? get renewsAt => _renewsAt;
  bool get isPaid => _tier != SubscriptionTier.discovery;
  bool get cancelRequested => _cancelRequested;
  bool get processing => _processing;

  /// Factures dans l'ordre chronologique inverse (la plus récente d'abord).
  List<PaymentReceipt> get receipts => List.unmodifiable(_receipts);

  /// Formate un montant XAF avec séparateur de milliers : 2 500 FCFA.
  static String formatFcfa(int amount) {
    final s = amount.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return '$b FCFA';
  }

  /// Débit simulé puis activation du palier.
  ///
  /// [accountHint] doit déjà être masqué (derniers chiffres) — la
  /// construction du masque appartient à l'appelant via
  /// [PaymentValidation], ce store refuse toute donnée en clair :
  /// si le hint contient plus de 4 chiffres consécutifs, il est
  /// recalqué et l'origine est jetée.
  Future<PaymentReceipt> pay({
    required SubscriptionTier tier,
    required BillingCycle cycle,
    required PaymentMethod method,
    required String accountHint,
  }) async {
    if (tier == SubscriptionTier.discovery) {
      throw ArgumentError('Le palier Découverte ne se paie pas.');
    }
    if (_processing) {
      throw StateError('Un paiement est déjà en cours.');
    }
    _processing = true;
    notifyListeners();
    try {
      // Simulation du tunnel passerelle → opérateur → confirmation.
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      final pricing = pricingFor(tier);
      final amount = pricing.priceOf(cycle);
      final safeHint = _sanitizeHint(accountHint);
      final now = DateTime.now();
      final receipt = PaymentReceipt(
        id: 'REC-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
        date: now,
        tier: tier,
        cycle: cycle,
        method: method,
        amountFcid: amount,
        maskedAccount: safeHint,
      );
      _tier = tier;
      _cycle = cycle;
      _renewsAt = cycle == BillingCycle.monthly
          ? DateTime(now.year, now.month + 1, now.day)
          : DateTime(now.year + 1, now.month, now.day);
      _cancelRequested = false;
      _receipts.insert(0, receipt);
      return receipt;
    } finally {
      _processing = false;
      notifyListeners();
    }
  }

  /// Ne conserve au maximum que les 4 derniers chiffres du masque :
  /// garde-fou contre un appelant qui passerait le numéro complet.
  static String _sanitizeHint(String hint) {
    final digits = PaymentValidation.digitsOnly(hint);
    if (digits.length <= 4) return hint;
    return '•••• ${digits.substring(digits.length - 4)}';
  }

  /// Résiliation : le palier reste actif jusqu'à [renewsAt] puis retombe
  /// en Découverte (modèle « fin de période », le plus courtois).
  void requestCancelAtPeriodEnd() {
    if (!isPaid || _cancelRequested) return;
    _cancelRequested = true;
    notifyListeners();
  }

  void restoreSubscription() {
    if (!_cancelRequested) return;
    _cancelRequested = false;
    notifyListeners();
  }

  /// Retour gratuit immédiat (et purge des factures : volontaire ici,
  /// l'historique de paiement est une donnée personnelle du compte).
  void reset() {
    _tier = SubscriptionTier.discovery;
    _cycle = BillingCycle.monthly;
    _renewsAt = null;
    _cancelRequested = false;
    _processing = false;
    _receipts.clear();
    notifyListeners();
  }
}
