import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/session/subscription_store.dart';
import 'subscription_page.dart';

/// Bandeau d'abonnement de l'accueil.
///
/// Palier gratuit → invitation Premium ; palier payant → rappel discret
/// de l'échéance avec accès à la gestion. Écoute le store en direct.
class SubscriptionBanner extends StatelessWidget {
  const SubscriptionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SubscriptionStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (store.isPaid) return _ActiveStrip(store: store);
        return _UpsellCard(onOpen: () => _open(context));
      },
    );
  }

  void _open(BuildContext context) {
    Navigator.of(context)
        .push(FadeSlideRoute<void>(page: const SubscriptionPage()));
  }
}

class _UpsellCard extends StatelessWidget {
  const _UpsellCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = context.texts;
    return PressableScale(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AnimatedGradientCard(
          colors: const <Color>[Color(0xFF7C4DFF), Color(0xFF3F51B5)],
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      texts.t('Passe à Premium', 'Upgrade to Premium'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      texts.t(
                        'Examens blancs illimités · correction prioritaire',
                        'Unlimited mock exams · priority grading',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${SubscriptionStore.formatFcfa(2500)} / '
                  '${texts.t('mois', 'mo')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveStrip extends StatelessWidget {
  const _ActiveStrip({required this.store});
  final SubscriptionStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = context.texts;
    final label = switch (store.tier) {
      SubscriptionTier.premium => 'Premium',
      SubscriptionTier.excellence => 'Excellence',
      SubscriptionTier.discovery => texts.t('Gratuit', 'Free'),
    };
    final r = store.renewsAt;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            Navigator.of(context)
                .push(FadeSlideRoute<void>(page: const SubscriptionPage())),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                Icons.verified_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  store.cancelRequested
                      ? texts.t(
                          'Abonnement $label · résiliation en cours',
                          '$label plan · cancellation pending',
                        )
                      : texts.t(
                          'Abonnement $label actif'
                              '${r == null ? '' : ' · échéance ${r.day}/${r.month}/${r.year}'}',
                          '$label plan active'
                              '${r == null ? '' : ' · renews ${r.month}/${r.day}/${r.year}'}',
                        ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                texts.t('Gérer', 'Manage'),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
