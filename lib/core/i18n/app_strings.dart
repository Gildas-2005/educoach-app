import 'package:flutter/widgets.dart';

import '../session/locale_store.dart';

/// Catalogue bilingue FR ⇄ EN de l'interface Educoach.
///
/// Architecture volontairement sans dépendance (offline-first, zéro
/// package tiers) : chaque chaîne vit dans le widget qui l'affiche,
/// via [t] :
///
/// ```dart
/// Text(context.texts.t('Bon retour', 'Welcome back'))
/// ```
///
/// Le français reste la langue de référence ; l'anglais est la variante
/// [_en]. Les getters de ce fichier sont réservés aux expressions
/// réellement répétées (navigation, boutons communs).
class AppTexts {
  const AppTexts(this.language);

  final AppLanguage language;

  static AppTexts of(BuildContext context) =>
      AppTexts(LocaleScope.of(context).language);

  bool get _en => language == AppLanguage.english;

  /// Traduit un couple FR/EN à la volée.
  String t(String fr, String en) => _en ? en : fr;

  // -------------------------------------------------------------------
  //  Messages du AuthStore (français émis par le store, traduit ici)
  // -------------------------------------------------------------------
  static const _storeMessages = <String, String>{
    'Email ou mot de passe incorrect.': 'Wrong email or password.',
    'Votre compte enseignant est en attente de validation par un '
            'administrateur.':
        'Your teacher account is awaiting admin validation.',
    "Ce compte a été suspendu par l'administration.":
        'This account was suspended by the administration.',
    'Les comptes administrateurs sont créés par la plateforme. '
            'Connectez-vous avec l\'identifiant fourni.':
        'Admin accounts are provisioned by the platform. Sign in with '
        'the credentials provided.',
    'Nom et prénom sont obligatoires.': 'First and last name are required.',
    'Adresse email invalide.': 'Invalid email address.',
    'Un compte existe déjà avec cette adresse email.':
        'An account already exists with this email.',
    'Le mot de passe doit contenir au moins 8 caractères.':
        'Password must contain at least 8 characters.',
    'Le mot de passe doit contenir au moins une lettre.':
        'Password must contain at least one letter.',
    'Le mot de passe doit contenir au moins un chiffre.':
        'Password must contain at least one digit.',
    'Ce mot de passe est trop courant, choisissez-en un autre.':
        'This password is too common, pick another one.',
    "Veuillez préciser votre discipline d'affectation.":
        'Please specify your teaching department.',
    'Le matricule enseignant est obligatoire.':
        'The teacher staff ID is required.',
    'Session expirée, reconnectez-vous.':
        'Session expired, please sign in again.',
    'Mot de passe actuel incorrect.': 'Current password is incorrect.',
    "Le nouveau mot de passe doit différer de l'actuel.":
        'New password must differ from the current one.',
  };

  /// Traduit un message renvoyé par [AuthStore.error]. Le store émet
  /// des chaînes françaises (source de vérité) ; la correspondance est
  /// exacte, avec un cas spécial pour le verrouillage dynamique («
  /// Réessayez dans N s. »). À défaut de traduction connue, le message
  /// original est renvoyé tel quel — jamais vide.
  String storeMessage(String fr) {
    if (!_en) return fr;
    final direct = _storeMessages[fr];
    if (direct != null) return direct;
    final lock = RegExp(r'^Trop de tentatives\. Réessayez dans (\d+) s\.$')
        .firstMatch(fr);
    if (lock != null) {
      return 'Too many attempts. Try again in ${lock.group(1)} s.';
    }
    return fr;
  }

  // -------------------------------------------------------------------
  //  Navigation (barre d'onglets + raccourcis)
  // -------------------------------------------------------------------
  String get navHome => t('Accueil', 'Home');
  String get navCourses => t('Cours', 'Courses');
  String get navMessages => t('Messages', 'Messages');
  String get navPlanning => t('Planning', 'Schedule');
  String get navGrades => t('Notes', 'Grades');
  String get navProfile => t('Profil', 'Profile');

  // -------------------------------------------------------------------
  //  Actions communes
  // -------------------------------------------------------------------
  String get continueBtn => t('Continuer', 'Continue');
  String get validate => t('Valider', 'Confirm');
  String get cancel => t('Annuler', 'Cancel');
  String get close => t('Fermer', 'Close');
  String get logout => t('Se déconnecter', 'Sign out');
  String get login => t('Se connecter', 'Log in');
  String get signup => t("S'inscrire", 'Sign up');

  // -------------------------------------------------------------------
  //  Authentification
  // -------------------------------------------------------------------
  String get email => t('Adresse email', 'Email address');
  String get password => t('Mot de passe', 'Password');
  String get forgotPassword => t('Mot de passe oublié ?', 'Forgot password?');
  String get badCredentials =>
      t('Email ou mot de passe incorrect.', 'Wrong email or password.');
  String get demoHint => t('Comptes de démonstration', 'Demo accounts');

  // -------------------------------------------------------------------
  //  Profil · réglages
  // -------------------------------------------------------------------
  String get settings => t('Réglages', 'Settings');
  String get languageTitle => t('Langue', 'Language');
  String get appearance => t('Apparence', 'Appearance');
  String get account => t('Compte', 'Account');
  String get security => t('Sécurité', 'Security');
}

/// Raccourci d'accès : `context.texts.t(...)`.
extension AppTextsX on BuildContext {
  AppTexts get texts => AppTexts.of(this);
  AppLanguage get appLanguage => LocaleScope.of(this).language;
}
