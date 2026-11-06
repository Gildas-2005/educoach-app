// Tests des garde-fous de sécurité ajoutés à Educoach :
// purge inter-comptes à la déconnexion, garde d'autorisation des
// routes privilégiées, verrouillage anti-force-brute.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ide_qo/core/data/mock_data.dart';
import 'package:ide_qo/core/session/auth_store.dart';
import 'package:ide_qo/core/session/learning_store.dart';
import 'package:ide_qo/core/session/session_coordinator.dart';
import 'package:ide_qo/core/session/session_store.dart';
import 'package:ide_qo/core/session/subscription_store.dart';
import 'package:ide_qo/features/admin/admin_shell_page.dart';
import 'package:ide_qo/features/auth/login_page.dart';
import 'package:ide_qo/main.dart';

void main() {
  setUp(() => SessionCoordinator.signOut());

  group('Déconnexion', () {
    test('signOut purge le palier et les factures avec le reste', () async {
      await AuthStore.instance.login(
        email: 'etudiant@educoach.cm',
        password: 'Educoach2026',
      );
      SessionStore.instance.selectFiliere(MockData.filieres.first);
      await SubscriptionStore.instance.pay(
        tier: SubscriptionTier.premium,
        cycle: BillingCycle.monthly,
        method: PaymentMethod.mtnMoMo,
        accountHint: '+237 6•• •• •• 45',
      );
      expect(SubscriptionStore.instance.isPaid, isTrue);

      SessionCoordinator.signOut();

      expect(AuthStore.instance.isAuthenticated, isFalse);
      expect(SessionStore.instance.filiere, isNull);
      expect(LearningStore.instance.ectsValidated(const {'MAT101'}), 0);
      expect(SubscriptionStore.instance.tier, SubscriptionTier.discovery);
      expect(SubscriptionStore.instance.receipts, isEmpty);
    });

    test('un compte B connecté après un compte A ne voit rien de A', () async {
      await AuthStore.instance.login(
        email: 'etudiant@educoach.cm',
        password: 'Educoach2026',
      );
      await SubscriptionStore.instance.pay(
        tier: SubscriptionTier.excellence,
        cycle: BillingCycle.monthly,
        method: PaymentMethod.visaCard,
        accountHint: '•••• 4242',
      );
      SessionCoordinator.signOut();

      final ok = await AuthStore.instance.login(
        email: 'prof@educoach.cm',
        password: 'Enseigner2026',
      );
      expect(ok, isTrue);
      expect(SubscriptionStore.instance.tier, SubscriptionTier.discovery);
      expect(SubscriptionStore.instance.receipts, isEmpty);
      expect(SubscriptionStore.instance.renewsAt, isNull);
    });
  });

  group('Garde de route (deep-link web)', () {
    testWidgets('/admin sans session ouvre la connexion, jamais la console', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const EducoachApp());
      await tester.pump(const Duration(milliseconds: 900));

      final ctx = tester.element(find.text('Educoach').first);
      Navigator.of(ctx).pushNamed('/admin');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(AdminShellPage), findsNothing);
    });

    testWidgets('/subscription sans session redirige vers l\'accueil public', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const EducoachApp());
      await tester.pump(const Duration(milliseconds: 900));

      final ctx = tester.element(find.text('Educoach').first);
      Navigator.of(ctx).pushNamed('/subscription');
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Educoach'), findsWidgets);
    });
  });

  group('Anti-force-brute', () {
    test('5 mauvais mots de passe verrouillent le compte', () async {
      await AuthStore.instance.signup(
        firstName: 'Lock',
        lastName: 'Test',
        email: 'lock@test.cm',
        password: 'Aa12345678',
        role: UserRole.student,
      );
      for (var i = 0; i < AuthStore.maxFailedAttempts; i++) {
        final bad = await AuthStore.instance.login(
          email: 'lock@test.cm',
          password: 'MauvaisPassé$i',
        );
        expect(bad, isFalse);
      }
      // Même le BON mot de passe est désormais refusé pendant la fenêtre.
      final good = await AuthStore.instance.login(
        email: 'lock@test.cm',
        password: 'Aa12345678',
      );
      expect(good, isFalse);
      expect(AuthStore.instance.error, contains('Trop de tentatives'));
    });

    test('changement de mot de passe : nouveau identique refusé', () async {
      await AuthStore.instance.login(
        email: 'etudiant@educoach.cm',
        password: 'Educoach2026',
      );
      final ok = await AuthStore.instance.changePassword(
        currentPassword: 'Educoach2026',
        newPassword: 'Educoach2026',
      );
      expect(ok, isFalse);
      expect(AuthStore.instance.error, contains('différer'));
    });
  });
}
