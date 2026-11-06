import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/security/payment_validation.dart';
import '../../core/session/subscription_store.dart';
import '../../core/widgets/aurora_backdrop.dart';
import '../../core/widgets/common_widgets.dart';
import 'payment_form.dart';

/// Tunnel d'abonnement Educoach : paliers → moyen de paiement →
/// saisie → traitement simulé → reçu.
///
/// Sécurité (voir [PaymentValidation]) : les données carte/mobile ne
/// vivent que dans les contrôleurs de formulaire, jamais dans le store;
/// le reçu n conserve que le masque « •••• 1234 ».
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});
  static const routeName = '/subscription';

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

enum _Step { plans, method, pay, processing, done }

class _SubscriptionPageState extends State<SubscriptionPage> {
  final _formKey = GlobalKey<FormState>();

  _Step _step = _Step.plans;
  SubscriptionTier _tier = SubscriptionTier.premium;
  BillingCycle _cycle = BillingCycle.monthly;
  PaymentMethod _method = PaymentMethod.mtnMoMo;
  int _phase = 0;
  PaymentReceipt? _receipt;
  String? _payError;

  final _phoneCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvcCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _panCtrl.dispose();
    _expiryCtrl.dispose();
    _cvcCtrl.dispose();
    _holderCtrl.dispose();
    super.dispose();
  }

  void _onPlanCta() {
    final store = SubscriptionStore.instance;
    if (_tier == SubscriptionTier.discovery) {
      // Résiliation « fin de période » plutôt qu'un faux paiement.
      store.requestCancelAtPeriodEnd();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            context.texts.t(
              'Abonnement résilié : le palier payant reste actif jusqu\'à '
                  'l\'échéance, puis retour gratuit.',
              'Subscription cancelled: the paid tier stays active until the '
                  'renewal date, then it reverts to free.',
            ),
          ),
        ),
      );
      return;
    }
    setState(() => _step = _Step.method);
  }

  Future<void> _submitPayment() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final hint = switch (_method) {
      PaymentMethod.mtnMoMo ||
      PaymentMethod.orangeMoney => PaymentValidation.maskPhone9(
        PaymentValidation.digitsOnly(_phoneCtrl.text),
      ),
      PaymentMethod.visaCard => PaymentValidation.maskPan(
        PaymentValidation.digitsOnly(_panCtrl.text),
      ),
    };
    setState(() {
      _step = _Step.processing;
      _phase = 0;
      _payError = null;
    });
    _advancePhases();
    try {
      final receipt = await SubscriptionStore.instance.pay(
        tier: _tier,
        cycle: _cycle,
        method: _method,
        accountHint: hint,
      );
      if (!mounted) return;
      setState(() {
        _receipt = receipt;
        _step = _Step.done;
      });
      // Le CVV n'a servi qu'à la (fausse) autorisation : on le purge
      // immédiatement de la mémoire du formulaire.
      _cvcCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _Step.pay;
        _payError = context.texts.t(
          'Paiement refusé par la passerelle. Réessaie ou change de moyen '
              'de paiement.',
          'Payment declined by the gateway. Try again or use another '
              'payment method.',
        );
      });
    }
  }

  /// Fait avancer le libellé de statut pendant le délai simulé.
  void _advancePhases() {
    Future<void>.delayed(const Duration(milliseconds: 550), () {
      if (mounted && _step == _Step.processing) {
        setState(() => _phase = 1);
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted && _step == _Step.processing) {
        setState(() => _phase = 2);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = SubscriptionStore.instance;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.texts.t('Abonnement', 'Subscription')),
        leading: _step == _Step.plans || _step == _Step.done
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() {
                  _step = switch (_step) {
                    _Step.method => _Step.plans,
                    _Step.pay => _Step.method,
                    _ => _Step.plans,
                  };
                }),
              ),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) => switch (_step) {
          _Step.plans => _PlansStep(
            tier: _tier,
            cycle: _cycle,
            onSelectTier: (t) => setState(() => _tier = t),
            onSelectCycle: (c) => setState(() => _cycle = c),
            onCta: _onPlanCta,
            onOpenHistory: _showHistory,
          ),
          _Step.method => _MethodStep(
            method: _method,
            onSelect: (m) => setState(() => _method = m),
            onCta: () => setState(() => _step = _Step.pay),
          ),
          _Step.pay => PayStepForm(
            formKey: _formKey,
            method: _method,
            tier: _tier,
            cycle: _cycle,
            phoneCtrl: _phoneCtrl,
            panCtrl: _panCtrl,
            expiryCtrl: _expiryCtrl,
            cvcCtrl: _cvcCtrl,
            holderCtrl: _holderCtrl,
            error: _payError,
            onCta: _submitPayment,
          ),
          _Step.processing => _ProcessingStep(
            method: _method,
            phase: _phase,
            amount: SubscriptionStore.pricingFor(_tier).priceOf(_cycle),
          ),
          _Step.done => _DoneStep(
            receipt: _receipt!,
            renewsAt: store.renewsAt,
            onFinish: () => Navigator.of(context).pop(),
          ),
        },
      ),
    );
  }

  void _showHistory() {
    final texts = context.texts;
    final receipts = SubscriptionStore.instance.receipts;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              texts.t('Historique de paiement', 'Payment history'),
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              texts.t(
                'Aucune donnée sensible conservée : seuls les 4 derniers '
                    'chiffres apparaissent sur les reçus.',
                'No sensitive data retained: only the last four digits '
                    'appear on receipts.',
              ),
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            if (receipts.isEmpty)
              Text(
                texts.t('Aucune facture pour le moment.', 'No invoices yet.'),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: receipts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ReceiptRow(receipt: receipts[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Étape 1 — choix du palier.
// ---------------------------------------------------------------------------
class _PlansStep extends StatelessWidget {
  const _PlansStep({
    required this.tier,
    required this.cycle,
    required this.onSelectTier,
    required this.onSelectCycle,
    required this.onCta,
    required this.onOpenHistory,
  });

  final SubscriptionTier tier;
  final BillingCycle cycle;
  final ValueChanged<SubscriptionTier> onSelectTier;
  final ValueChanged<BillingCycle> onSelectCycle;
  final VoidCallback onCta;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = context.texts;
    final store = SubscriptionStore.instance;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        FadeSlideIn(
          child: _CurrentPlanCard(store: store, texts: texts),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 70),
          child: Text(
            texts.t(
              'Choisis le palier qui colle à tes objectifs.',
              'Pick the plan that fits your goals.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final (i, pricing) in SubscriptionStore.plans.indexed)
          FadeSlideIn(
            delay: Duration(milliseconds: 110 + i * 70),
            child: _PlanCard(
              pricing: pricing,
              cycle: cycle,
              selected: tier == pricing.tier,
              isCurrent:
                  store.tier == pricing.tier &&
                  !(store.isPaid && store.cancelRequested),
              onTap: () => onSelectTier(pricing.tier),
            ),
          ),
        if (tier != SubscriptionTier.discovery) ...[
          const SizedBox(height: 14),
          FadeSlideIn(
            child: _CycleToggle(cycle: cycle, onSelect: onSelectCycle),
          ),
        ],
        const SizedBox(height: 16),
        FadeSlideIn(
          child: FilledButton.icon(
            onPressed: onCta,
            icon: const Icon(Icons.workspace_premium_rounded),
            label: Text(
              tier == SubscriptionTier.discovery
                  ? texts.t(
                      'Revenir au palier gratuit',
                      'Switch back to the free plan',
                    )
                  : texts.continueBtn,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        if (store.receipts.isNotEmpty) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onOpenHistory,
            icon: const Icon(Icons.receipt_long_rounded, size: 18),
            label: Text(texts.t('Voir mes reçus', 'View my receipts')),
          ),
        ],
      ],
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.store, required this.texts});
  final SubscriptionStore store;
  final AppTexts texts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (store.tier) {
      SubscriptionTier.discovery => texts.t('Découverte', 'Discovery'),
      SubscriptionTier.premium => 'Premium',
      SubscriptionTier.excellence => 'Excellence',
    };
    final sub = !store.isPaid
        ? texts.t(
            'Palier gratuit — essentiel illimité',
            'Free plan — unlimited essentials',
          )
        : store.cancelRequested
        ? texts.t(
            'Résiliation demandée · actif jusqu\'au '
                '${_d(store.renewsAt)}',
            'Cancellation requested · active until ${_d(store.renewsAt)}',
          )
        : texts.t(
            '${store.cycle == BillingCycle.monthly ? 'Mensuel' : 'Annuel'}'
                ' · renouvellement le ${_d(store.renewsAt)}',
            '${store.cycle == BillingCycle.monthly ? 'Monthly' : 'Yearly'}'
                ' · renews on ${_d(store.renewsAt)}',
          );
    return AnimatedGradientCard(
      colors: const <Color>[Color(0xFF3F51B5), Color(0xFF7C4DFF)],
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              store.isPaid
                  ? Icons.verified_rounded
                  : Icons.card_giftcard_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texts.t('Palier actuel · ', 'Current plan · ') + label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          if (store.isPaid && store.cancelRequested)
            TextButton(
              onPressed: () {
                store.restoreSubscription();
                Navigator.of(context).pop();
              },
              child: Text(texts.t('Rétablir', 'Restore')),
            ),
        ],
      ),
    );
  }

  String _d(DateTime? dt) =>
      dt == null ? '—' : '${dt.day}/${dt.month}/${dt.year}';
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.pricing,
    required this.cycle,
    required this.selected,
    required this.isCurrent,
    required this.onTap,
  });

  final PlanPricing pricing;
  final BillingCycle cycle;
  final bool selected;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = context.texts;
    final name = switch (pricing.tier) {
      SubscriptionTier.discovery => texts.t('Découverte', 'Discovery'),
      SubscriptionTier.premium => 'Premium',
      SubscriptionTier.excellence => 'Excellence',
    };
    final price = pricing.priceOf(cycle);
    final priceLabel = price == 0
        ? texts.t('Gratuit', 'Free')
        : '${SubscriptionStore.formatFcfa(price)} / '
              '${cycle == BillingCycle.monthly ? texts.t('mois', 'month') : texts.t('an', 'year')}';
    final perks = _perks(texts, pricing.tier);

    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.normal,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(switch (pricing.tier) {
                  SubscriptionTier.discovery => Icons.school_rounded,
                  SubscriptionTier.premium => Icons.star_rounded,
                  SubscriptionTier.excellence => Icons.diamond_rounded,
                }, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 8),
                  PillBadge(
                    label: texts.t('Actuel', 'Current'),
                    color: theme.colorScheme.tertiary,
                  ),
                ],
                const Spacer(),
                Text(
                  priceLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final p in perks)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(child: Text(p, style: theme.textTheme.bodySmall)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static List<String> _perks(AppTexts t, SubscriptionTier tier) =>
      switch (tier) {
        SubscriptionTier.discovery => [
          t.t(
            'Accès complet aux parcours de cours',
            'Full access to course learning paths',
          ),
          t.t('Planning et notes', 'Schedule and grades'),
          t.t('Chat avec les professeurs', 'Chat with teachers'),
        ],
        SubscriptionTier.premium => [
          t.t('Tout Découverte, plus :', 'Everything in Discovery, plus:'),
          t.t('Examens blancs illimités', 'Unlimited mock exams'),
          t.t(
            'Correction prioritaire par les profs',
            'Priority grading by teachers',
          ),
          t.t(
            'Statistiques avancées de progression',
            'Advanced progress analytics',
          ),
        ],
        SubscriptionTier.excellence => [
          t.t('Tout Premium, plus :', 'Everything in Premium, plus:'),
          t.t(
            'Coach individuel (sessions 1-to-1)',
            'Personal coach (1-to-1 sessions)',
          ),
          t.t('Sessions live en petit groupe', 'Small-group live sessions'),
          t.t(
            'Badge Excellence sur ton profil',
            'Excellence badge on your profile',
          ),
        ],
      };
}

class _CycleToggle extends StatelessWidget {
  const _CycleToggle({required this.cycle, required this.onSelect});
  final BillingCycle cycle;
  final ValueChanged<BillingCycle> onSelect;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;
    return SegmentedButton<BillingCycle>(
      segments: [
        ButtonSegment(
          value: BillingCycle.monthly,
          label: Text(texts.t('Mensuel', 'Monthly')),
        ),
        ButtonSegment(
          value: BillingCycle.yearly,
          label: Text(texts.t('Annuel −2 mois', 'Yearly −2 months')),
        ),
      ],
      selected: {cycle},
      onSelectionChanged: (s) => onSelect(s.first),
    );
  }
}

// ---------------------------------------------------------------------------
// Étape 2 — choix du moyen de paiement.
// ---------------------------------------------------------------------------
class _MethodStep extends StatelessWidget {
  const _MethodStep({
    required this.method,
    required this.onSelect,
    required this.onCta,
  });

  final PaymentMethod method;
  final ValueChanged<PaymentMethod> onSelect;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = context.texts;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Text(
          texts.t('Comment veux-tu payer ?', 'How would you like to pay?'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          texts.t(
            'Tous les canaux sont simulés dans cette démo hors-ligne — '
                'aucun débit réel n\'est effectué.',
            'All channels are simulated in this offline demo — no real '
                'charge is made.',
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        for (final (i, m) in PaymentMethod.values.indexed)
          FadeSlideIn(
            delay: Duration(milliseconds: 80 + i * 70),
            child: _MethodTile(
              method: m,
              selected: method == m,
              onTap: () => onSelect(m),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onCta,
          icon: const Icon(Icons.credit_card_rounded),
          label: Text(
            texts.continueBtn,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  static (Color, Color, IconSource) _brand(PaymentMethod m) => switch (m) {
    PaymentMethod.mtnMoMo => (
      const Color(0xFFFBCE07),
      const Color(0xFF1A1A1A),
      const IconSource.text('MTN'),
    ),
    PaymentMethod.orangeMoney => (
      const Color(0xFFFF7900),
      Colors.white,
      const IconSource.text('Orange'),
    ),
    PaymentMethod.visaCard => (
      const Color(0xFF1A1F71),
      Colors.white,
      const IconSource.text('VISA'),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = context.texts;
    final (bg, fg, logo) = _brand(method);
    final label = switch (method) {
      PaymentMethod.mtnMoMo => 'MTN MoMo',
      PaymentMethod.orangeMoney => 'Orange Money',
      PaymentMethod.visaCard => 'Visa / Mastercard',
    };
    final hint = switch (method) {
      PaymentMethod.mtnMoMo => texts.t(
        'Confirmation via #126# sur ton téléphone',
        'Confirmation via #126# on your phone',
      ),
      PaymentMethod.orangeMoney => texts.t(
        'Confirmation via *354# sur ton téléphone',
        'Confirmation via *354# on your phone',
      ),
      PaymentMethod.visaCard => texts.t(
        '3-D Secure · numéro chiffré, jamais stocké',
        '3-D Secure · number encrypted, never stored',
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        child: PressableScale(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    logo.text,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        hint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mini-valeur pour les libellés de logo texte des moyens de paiement.
class IconSource {
  const IconSource.text(this.text);
  final String text;
}

// ---------------------------------------------------------------------------
// Étape 4 — traitement animé.
// ---------------------------------------------------------------------------
class _ProcessingStep extends StatelessWidget {
  const _ProcessingStep({
    required this.method,
    required this.phase,
    required this.amount,
  });

  final PaymentMethod method;
  final int phase;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = context.texts;
    final steps = <String>[
      texts.t(
        'Connexion sécurisée à la passerelle…',
        'Connecting securely to the gateway…',
      ),
      method == PaymentMethod.visaCard
          ? texts.t(
              'Authentification 3-D Secure…',
              '3-D Secure authentication…',
            )
          : texts.t(
              'Demande de confirmation sur ton téléphone…',
              'Awaiting confirmation on your phone…',
            ),
      texts.t(
        'Validation du débit de ${SubscriptionStore.formatFcfa(amount)}…',
        'Validating the ${SubscriptionStore.formatFcfa(amount)} charge…',
      ),
    ];
    // AuroraBackdrop fournit son propre Positioned.fill : il doit être
    // enfant DIRECT du Stack (sinon : conflit de ParentDataWidget).
    return Stack(
      children: [
        const AuroraBackdrop(
          primary: Color(0xFF3F51B5),
          accentA: Color(0xFF7C4DFF),
          accentB: Color(0xFF00BCD4),
          intensity: 0.35,
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(strokeWidth: 4),
                      ),
                      const SizedBox(height: 22),
                      for (final (i, s) in steps.indexed)
                        AnimatedOpacity(
                          duration: Motion.normal,
                          opacity: i <= phase ? 1 : 0.3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  i < phase
                                      ? Icons.check_circle_rounded
                                      : Icons.pending_rounded,
                                  size: 18,
                                  color: i < phase
                                      ? Colors.green.shade600
                                      : theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    s,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: i == phase
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Étape 5 — reçu.
// ---------------------------------------------------------------------------
class _DoneStep extends StatelessWidget {
  const _DoneStep({
    required this.receipt,
    required this.renewsAt,
    required this.onFinish,
  });

  final PaymentReceipt receipt;
  final DateTime? renewsAt;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = context.texts;
    // ConfettiBurst fournit son propre Positioned.fill : enfant direct
    // du Stack, jamais un ajout manuel de Positioned autour.
    return Stack(
      children: [
        const ConfettiBurst(),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const FadeSlideIn(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF2E7D32),
                    child: Icon(
                      Icons.check_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  texts.t('Paiement confirmé 🎉', 'Payment confirmed 🎉'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  receipt.tier == SubscriptionTier.premium
                      ? texts.t(
                          'Bienvenue dans Premium !',
                          'Welcome to Premium!',
                        )
                      : texts.t(
                          'Bienvenue dans Excellence !',
                          'Welcome to Excellence!',
                        ),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          _ReceiptRow(receipt: receipt, dense: false),
                          const Divider(height: 22),
                          _kv(
                            texts,
                            texts.t('Renouvellement', 'Renewal'),
                            renewsAt == null
                                ? '—'
                                : '${renewsAt!.day}/${renewsAt!.month}/${renewsAt!.year}',
                          ),
                          _kv(
                            texts,
                            texts.t('N° de reçu', 'Receipt no.'),
                            receipt.id,
                          ),
                          Text(
                            texts.t(
                              'Reçu conservé sans aucune donnée sensible.',
                              'Receipt stored without any sensitive data.',
                            ),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onFinish,
                  icon: const Icon(Icons.home_rounded),
                  label: Text(
                    texts.t('Retour à l\'accueil', 'Back to home'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _kv(AppTexts t, String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: const TextStyle(color: Colors.grey)),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.receipt, this.dense = true});
  final PaymentReceipt receipt;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = context.texts;
    final (bg, fg, logo) = _MethodTile._brand(receipt.method);
    final plan = switch (receipt.tier) {
      SubscriptionTier.discovery => texts.t('Découverte', 'Discovery'),
      SubscriptionTier.premium => 'Premium',
      SubscriptionTier.excellence => 'Excellence',
    };
    return Row(
      children: [
        Container(
          width: 42,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            logo.text,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 10.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$plan · ${receipt.maskedAccount}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${receipt.date.day}/${receipt.date.month}/${receipt.date.year}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          SubscriptionStore.formatFcfa(receipt.amountFcid),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
