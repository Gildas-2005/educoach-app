// Tests Educoach : pitch d'accueil + coquille après authentification.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ide_qo/core/data/mock_data.dart';
import 'package:ide_qo/core/security/password_hasher.dart';
import 'package:ide_qo/core/session/auth_store.dart';
import 'package:ide_qo/core/session/learning_store.dart';
import 'package:ide_qo/core/session/session_store.dart';
import 'package:ide_qo/main.dart';

void main() {
  setUp(() {
    SessionStore.instance.reset();
    AuthStore.instance.logout();
  });

  testWidgets('l\'accueil présente la marque et les deux CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EducoachApp());
    // Laisse passer les délais d'entrée (FadeSlideIn) pour purger les timers.
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Educoach'), findsOneWidget);
    // Fait défiler jusqu'aux CTA.
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Créer mon compte'), findsOneWidget);
    expect(find.text("J'ai déjà un compte"), findsOneWidget);
    // Plus de 40 filières listées dans le seed.
    expect(MockData.filieres.length, greaterThan(30));
  });

  testWidgets('après connexion + filière, les onglets s\'affichent', (
    WidgetTester tester,
  ) async {
    // Connexion réelle avec le compte étudiant pré-enregistré.
    // runAsync pour échapper l'horloge virtuelle du testWidgets (login attend 650ms).
    final ok = await tester.runAsync(
      () => AuthStore.instance.login(
        email: 'etudiant@educoach.cm',
        password: 'Educoach2026',
      ),
    );
    expect(ok, isTrue);
    expect(AuthStore.instance.user?.role, UserRole.student);

    SessionStore.instance.selectFiliere(MockData.filieres.first);

    await tester.pumpWidget(const EducoachApp());
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Accueil'), findsWidgets);
    expect(find.text('Cours'), findsWidgets);
    expect(find.text('Messages'), findsWidgets);
    expect(find.text('Planning'), findsWidgets);
    expect(find.text('Notes'), findsWidgets);
    expect(find.text('Profil'), findsWidgets);
  });

  testWidgets('la sélection d\'une filière filtre les cours actifs', (
    WidgetTester tester,
  ) async {
    final inf = MockData.filieres.firstWhere((f) => f.code == 'INF');
    SessionStore.instance.selectFiliere(inf);
    final codes = SessionStore.instance.activeCourseCodes;
    expect(codes, isNotEmpty);
    // Les cours de INF incluent des mutualisés (MAT101, ANG101, etc.),
    // mais jamais de codes MED (Médecine).
    expect(codes.any((c) => c.startsWith('MED')), isFalse);
  });

  test('la filière est verrouillée après le premier choix', () {
    SessionStore.instance.selectFiliere(MockData.filieres.first);
    final locked = SessionStore.instance.filiere;
    SessionStore.instance.selectFiliere(
      MockData.filieres.lastWhere((f) => f.id != locked!.id),
    );
    expect(SessionStore.instance.filiere?.id, locked?.id);
  });

  test('tous les niveaux déclarés d\'une filière ont des cours', () {
    for (final f in MockData.filieres) {
      final levels = SessionStore.levelsWithCourses(f);
      for (final declared in f.degreeLevels) {
        expect(
          levels,
          contains(declared),
          reason: '${f.code} $declared devrait avoir des cours',
        );
        expect(
          MockData.coursesFor(filiereId: f.id, level: declared),
          isNotEmpty,
          reason: '${f.code} $declared liste vide',
        );
      }
    }
  });

  test('les compteurs d\'un nouvel utilisateur sont à 0', () {
    final inf = MockData.filieres.firstWhere((f) => f.code == 'INF');
    SessionStore.instance.selectFiliere(inf);
    final codes = SessionStore.instance.activeCourseCodes;
    final learning = LearningStore.instance;
    expect(learning.levelAverage(codes), 0);
    expect(learning.ectsValidated(codes.toList()), 0);
    expect(learning.learnerGrades(codes), isEmpty);
    expect(learning.isLevelValidated(codes), isFalse);
  });

  test('hachage : vectors FIPS 180-4 et vérification salt+hash', () {
    expect(
      PasswordHasher.sha256Hex(''),
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
    expect(
      PasswordHasher.sha256Hex('abc'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
    final stored = PasswordHasher.hash(
      'Educoach2026',
      PasswordHasher.generateSalt(),
    );
    expect(PasswordHasher.verify('Educoach2026', stored), isTrue);
    expect(PasswordHasher.verify('mauvais', stored), isFalse);
  });

  test('inscription : refus admin et compte enseignant en attente', () async {
    final admin = await AuthStore.instance.signup(
      firstName: 'X',
      lastName: 'Y',
      email: 'x@y.cm',
      password: 'Administrer2026',
      role: UserRole.admin,
    );
    expect(admin, AuthSignupResult.failed);

    final teacher = await AuthStore.instance.signup(
      firstName: 'A',
      lastName: 'B',
      email: 'prof2@educoach.cm',
      password: 'Enseigner2026',
      role: UserRole.teacher,
      department: 'Informatique',
      matricule: 'ENS-2026-0001',
    );
    expect(teacher, AuthSignupResult.pendingValidation);
    expect(
      AuthStore.instance.statusOf('prof2@educoach.cm'),
      AccountStatus.pending,
    );
  });
}
