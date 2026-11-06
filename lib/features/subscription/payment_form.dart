import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/animations/animations.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/security/payment_validation.dart';
import '../../core/session/subscription_store.dart';

/// Étape 3 — formulaire de débit selon le canal choisi.
///
/// Rappel sécurité : les numéros ne vivent que dans les
/// [TextEditingController] de cet écran ; seul un masque à 4 chiffres
/// est transmis au store. Le CVV est purgé après la tentative.
class PayStepForm extends StatelessWidget {
  const PayStepForm({
    super.key,
    required this.formKey,
    required this.method,
    required this.tier,
    required this.cycle,
    required this.phoneCtrl,
    required this.panCtrl,
    required this.expiryCtrl,
    required this.cvcCtrl,
    required this.holderCtrl,
    required this.error,
    required this.onCta,
  });

  final GlobalKey<FormState> formKey;
  final PaymentMethod method;
  final SubscriptionTier tier;
  final BillingCycle cycle;
  final TextEditingController phoneCtrl;
  final TextEditingController panCtrl;
  final TextEditingController expiryCtrl;
  final TextEditingController cvcCtrl;
  final TextEditingController holderCtrl;
  final String? error;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = context.texts;
    final amount = SubscriptionStore.pricingFor(tier).priceOf(cycle);
    final planName = switch (tier) {
      SubscriptionTier.discovery => texts.t('Découverte', 'Discovery'),
      SubscriptionTier.premium => 'Premium',
      SubscriptionTier.excellence => 'Excellence',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Récapitulatif de la commande.
            FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    _row(
                      theme,
                      texts.t('Formule', 'Plan'),
                      '$planName · '
                      '${cycle == BillingCycle.monthly ? texts.t('mensuel', 'monthly') : texts.t('annuel', 'yearly')}',
                    ),
                    _row(theme, texts.t('Moyen', 'Method'), switch (method) {
                      PaymentMethod.mtnMoMo => 'MTN MoMo',
                      PaymentMethod.orangeMoney => 'Orange Money',
                      PaymentMethod.visaCard => 'Visa / Mastercard',
                    }),
                    const Divider(height: 18),
                    _row(
                      theme,
                      texts.t('Total à payer', 'Total due'),
                      SubscriptionStore.formatFcfa(amount),
                      strong: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (method == PaymentMethod.visaCard)
              ..._cardFields(theme, texts)
            else
              ..._mobileFields(theme, texts),
            if (error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFC62828).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFC62828).withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFC62828),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: Color(0xFFB71C1C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onCta,
              icon: const Icon(Icons.lock_rounded),
              label: Text(
                '${texts.t('Payer', 'Pay')} '
                '${SubscriptionStore.formatFcfa(amount)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    texts.t(
                      'Débit simulé côté appareil (démo hors-ligne). En '
                          'production : passerelle certifiée PCI DSS côté '
                          'serveur, jamais dans l\'application.',
                      'Charge simulated on-device (offline demo). In '
                          'production: a PCI DSS certified gateway runs '
                          'server-side, never inside the app.',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, String k, String v, {bool strong = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              k,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              v,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  List<Widget> _mobileFields(ThemeData theme, AppTexts texts) {
    final isMtn = method == PaymentMethod.mtnMoMo;
    return [
      Text(
        isMtn
            ? texts.t(
                'Numéro MTN MoMo (compte Main Soum de 9 chiffres)',
                'MTN MoMo number (9-digit Main Soum account)',
              )
            : texts.t('Numéro Orange Money', 'Orange Money number'),
        style: theme.textTheme.titleSmall,
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: phoneCtrl,
        keyboardType: TextInputType.phone,
        maxLength: 9,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9),
        ],
        decoration: InputDecoration(
          prefixText: '+237 ',
          hintText: '6XX XX XX XX',
          counterText: '',
          prefixIcon: const Icon(Icons.smartphone_rounded),
        ),
        validator: (v) {
          final d = PaymentValidation.digitsOnly(v ?? '');
          if (d.length != 9 || d[0] != '6') {
            return texts.t(
              'Numéro invalide : 9 chiffres commençant par 6.',
              'Invalid number: 9 digits starting with 6.',
            );
          }
          return null;
        },
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isMtn ? const Color(0xFFFBCE07) : const Color(0xFFFF7900))
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.notifications_active_outlined,
              size: 18,
              color: isMtn ? const Color(0xFFB8950A) : const Color(0xFFE56D00),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                texts.t(
                  'Après validation, tu recevras une demande de '
                      'confirmation ${isMtn ? '(*126#01#)' : '(*354*3#)'} : '
                      'compose ton PIN opérateur sur ton téléphone pour '
                      'autoriser le débit.',
                  'After you confirm, you will get an authorization '
                      'prompt ${isMtn ? '(*126#01#)' : '(*354*3#)'} on your '
                      'phone: enter your operator PIN to approve the charge.',
                ),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _cardFields(ThemeData theme, AppTexts texts) => [
    Text(
      texts.t('Numéro de carte', 'Card number'),
      style: theme.textTheme.titleSmall,
    ),
    const SizedBox(height: 8),
    TextFormField(
      controller: panCtrl,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.creditCardNumber],
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(19),
        _PanGroupFormatter(),
      ],
      decoration: InputDecoration(
        hintText: '4242 4242 4242 4242',
        prefixIcon: const Icon(Icons.credit_card_rounded),
      ),
      validator: (v) {
        final d = PaymentValidation.digitsOnly(v ?? '');
        if (d.length < 13) {
          return texts.t('Numéro trop court.', 'Number too short.');
        }
        if (!PaymentValidation.luhnValid(d)) {
          return texts.t(
            'Numéro de carte invalide (contrôle Luhn).',
            'Invalid card number (Luhn check).',
          );
        }
        return null;
      },
    ),
    const SizedBox(height: 12),
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                texts.t('Expiration MM/AA', 'Expiry MM/YY'),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: expiryCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryFormatter(),
                ],
                decoration: const InputDecoration(hintText: '12/29'),
                validator: (v) {
                  final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(v ?? '');
                  if (m == null) {
                    return texts.t('Format MM/AA.', 'MM/YY format.');
                  }
                  final ok = PaymentValidation.expiryInFuture(
                    int.parse(m.group(1)!),
                    int.parse(m.group(2)!),
                  );
                  return ok ? null : texts.t('Carte expirée.', 'Card expired.');
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                texts.t('Cryptogramme (CVC)', 'Security code (CVC)'),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: cvcCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.creditCardSecurityCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: const InputDecoration(
                  hintText: '•••',
                  counterText: '',
                ),
                validator: (v) {
                  final d = PaymentValidation.digitsOnly(v ?? '');
                  if (d.length < 3 || d.length > 4) {
                    return texts.t('3 ou 4 chiffres.', '3 or 4 digits.');
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    ),
    const SizedBox(height: 12),
    Text(
      texts.t('Titulaire de la carte', 'Cardholder name'),
      style: theme.textTheme.titleSmall,
    ),
    const SizedBox(height: 8),
    TextFormField(
      controller: holderCtrl,
      textCapitalization: TextCapitalization.words,
      autofillHints: const [AutofillHints.creditCardName],
      decoration: InputDecoration(
        hintText: texts.t('NOM Prénom', 'Lastname Firstname'),
        prefixIcon: const Icon(Icons.person_outline_rounded),
      ),
      validator: (v) => (v ?? '').trim().length < 3
          ? texts.t('Nom requis.', 'Name required.')
          : null,
    ),
    const SizedBox(height: 10),
    Row(
      children: [
        Icon(
          Icons.visibility_off_outlined,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texts.t(
              'Le CVC ne sert qu\'à l\'autorisation puis est effacé ; il '
                  'n\'est jamais enregistré ni affiché ensuite.',
              'The CVC is only used for the authorization then wiped; '
                  'it is never stored or shown again.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  ];
}

/// Groupe la saisie PAN en paquets de 4 chiffres.
class _PanGroupFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = PaymentValidation.digitsOnly(newValue.text);
    final grouped = PaymentValidation.groupPan(digits);
    return TextEditingValue(
      text: grouped,
      selection: TextSelection.collapsed(offset: grouped.length),
    );
  }
}

/// Force le masque MM/AA pendant la saisie.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final d = PaymentValidation.digitsOnly(newValue.text);
    final out = d.length <= 2 ? d : '${d.substring(0, 2)}/${d.substring(2)}';
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}
