// Tests du tunnel d'abonnement : tarification, validation carte,
// masquage des données sensibles, cycle de vie du palier.

import 'package:flutter_test/flutter_test.dart';

import 'package:ide_qo/core/security/payment_validation.dart';
import 'package:ide_qo/core/session/subscription_store.dart';

void main() {
  setUp(() => SubscriptionStore.instance.reset());

  group('PaymentValidation', () {
    test('Luhn accepte les PAN de test et refuse les invalides', () {
      expect(PaymentValidation.luhnValid('4242424242424242'), isTrue);
      expect(PaymentValidation.luhnValid('1234567812345670'), isTrue);
      expect(PaymentValidation.luhnValid('4242424242424241'), isFalse);
      expect(
        PaymentValidation.luhnValid(
          '4242 4242 4242 4242'.replaceAll(RegExp(r'\s'), ''),
        ),
        isTrue,
      );
      expect(PaymentValidation.luhnValid('1234'), isFalse);
    });

    test('digitsOnly ne garde que les chiffres', () {
      expect(
        PaymentValidation.digitsOnly('+237 6 81 22 33 4a5'),
        '237681223345',
      );
      expect(PaymentValidation.digitsOnly('a1b2c3'), '123');
    });

    test('les masques ne révèlent jamais le numéro complet', () {
      final masked = PaymentValidation.maskPan('4242424242424242');
      expect(masked, '•••• 4242');
      expect(masked.contains('4242424242'), isFalse);
      final phone = PaymentValidation.maskPhone9('681223345');
      expect(phone.contains('681223345'), isFalse);
      expect(phone.contains('45'), isTrue);
    });

    test('expiration : MM/AA passé refusé, futur accepté', () {
      final now = DateTime.now();
      expect(PaymentValidation.expiryInFuture(1, now.year - 2000 - 1), isFalse);
      expect(
        PaymentValidation.expiryInFuture(13, now.year - 2000 + 1),
        isFalse,
      );
      expect(PaymentValidation.expiryInFuture(12, now.year - 2000 + 1), isTrue);
    });
  });

  group('SubscriptionStore', () {
    test('paliers et prix : annuel = 10× mensuel premium (2 mois offerts)', () {
      final premium = SubscriptionStore.pricingFor(SubscriptionTier.premium);
      expect(premium.monthly, 2500);
      expect(premium.yearly, 25000);
      expect(SubscriptionStore.formatFcfa(25000), '25 000 FCFA');
    });

    test('le palier gratuit ne se paie pas', () async {
      // pay() est async : le refus arrive via la Future, pas un throw
      // synchrone — expectLater est la bonne forme.
      await expectLater(
        SubscriptionStore.instance.pay(
          tier: SubscriptionTier.discovery,
          cycle: BillingCycle.monthly,
          method: PaymentMethod.visaCard,
          accountHint: '•••• 0000',
        ),
        throwsArgumentError,
      );
    });

    test(
      'paiement Visa : activation, échéance et reçu sans donnée brute',
      () async {
        // L'appelant transmet volontairement le PAN complet ici pour
        // prouver que le store RECalc le masque et jette l'origine.
        final receipt = await SubscriptionStore.instance.pay(
          tier: SubscriptionTier.premium,
          cycle: BillingCycle.yearly,
          method: PaymentMethod.visaCard,
          accountHint: '4242424242424242',
        );
        final store = SubscriptionStore.instance;
        expect(store.tier, SubscriptionTier.premium);
        expect(store.cycle, BillingCycle.yearly);
        expect(store.isPaid, isTrue);
        expect(store.renewsAt!.year, greaterThan(DateTime.now().year - 1));
        expect(receipt.maskedAccount, '•••• 4242');
        expect(
          store.receipts.first.maskedAccount.contains('4242424242'),
          isFalse,
        );
      },
    );

    test('paiement MTN MoMo puis résiliation en fin de période', () async {
      await SubscriptionStore.instance.pay(
        tier: SubscriptionTier.excellence,
        cycle: BillingCycle.monthly,
        method: PaymentMethod.mtnMoMo,
        accountHint: PaymentValidation.maskPhone9('681223345'),
      );
      final store = SubscriptionStore.instance;
      expect(store.tier, SubscriptionTier.excellence);
      store.requestCancelAtPeriodEnd();
      expect(store.cancelRequested, isTrue);
      // La résiliation en fin de période garde le palier actif.
      expect(store.tier, SubscriptionTier.excellence);
      store.restoreSubscription();
      expect(store.cancelRequested, isFalse);
    });

    test('un paiement ne peut pas se chevaucher', () async {
      final store = SubscriptionStore.instance;
      final first = store.pay(
        tier: SubscriptionTier.premium,
        cycle: BillingCycle.monthly,
        method: PaymentMethod.orangeMoney,
        accountHint: '•••• 1111',
      );
      await expectLater(
        store.pay(
          tier: SubscriptionTier.excellence,
          cycle: BillingCycle.monthly,
          method: PaymentMethod.visaCard,
          accountHint: '•••• 2222',
        ),
        throwsStateError,
      );
      await first;
      expect(store.tier, SubscriptionTier.premium);
    });

    test('reset : plus de palier, plus aucune facture en mémoire', () async {
      await SubscriptionStore.instance.pay(
        tier: SubscriptionTier.premium,
        cycle: BillingCycle.monthly,
        method: PaymentMethod.visaCard,
        accountHint: '•••• 4242',
      );
      SubscriptionStore.instance.reset();
      final store = SubscriptionStore.instance;
      expect(store.tier, SubscriptionTier.discovery);
      expect(store.renewsAt, isNull);
      expect(store.receipts, isEmpty);
    });
  });
}
