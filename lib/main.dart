import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/session/auth_store.dart';
import 'core/session/chat_store.dart';
import 'core/session/learning_store.dart';
import 'core/session/legal_store.dart';
import 'core/session/locale_store.dart';
import 'core/session/session_store.dart';
import 'core/session/theme_store.dart';
import 'core/supabase/supabase_env.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/auth/signup_page.dart';
import 'features/admin/admin_shell_page.dart';
import 'features/courses/course_path_page.dart';
import 'features/legal/legal_content.dart';
import 'features/legal/legal_document_page.dart';
import 'features/legal/permissions_page.dart';
import 'features/onboarding/filiere_picker_page.dart';
import 'features/onboarding/welcome_page.dart';
import 'features/shell/shell_page.dart';
import 'features/subscription/subscription_page.dart';
import 'features/teacher/teacher_shell_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialise Supabase uniquement si la config est fournie (--dart-define).
  // Sinon, repli transparent sur le mode démonstration hors-ligne existant.
  await SupabaseEnv.initialize();
  runApp(const EducoachApp());
}

/// Racine de l'application Educoach.
///
/// - Expose [SessionStore] et [AuthStore] via leurs scopes.
/// - Route initiale :
///   1. non authentifié → [WelcomePage]
///   2. authentifié sans filière → [LoginPage] (redirigera vers le picker)
///   3. authentifié + filière → coquille principale
class EducoachApp extends StatelessWidget {
  const EducoachApp({super.key});

  static const _appName = 'Educoach';

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      store: AuthStore.instance,
      child: LegalScope(
        store: LegalStore.instance,
        child: PermissionsScope(
          store: PermissionsStore.instance,
          child: LearningScope(
            store: LearningStore.instance,
            child: ChatScope(
              store: ChatStore.instance,
              child: SessionScope(
                store: SessionStore.instance,
                child: ThemeScope(
                  store: ThemeStore.instance,
                  child: LocaleScope(
                    store: LocaleStore.instance,
                    child: ListenableBuilder(
                      listenable: Listenable.merge([
                        ThemeStore.instance,
                        LocaleStore.instance,
                      ]),
                      builder: (context, _) => MaterialApp(
                        title: _appName,
                        debugShowCheckedModeBanner: false,
                        theme: buildEducoachTheme(),
                        darkTheme: buildEducoachDarkTheme(),
                        themeMode: ThemeStore.instance.mode,
                        locale: LocaleStore.instance.locale,
                        supportedLocales: [
                          for (final l in AppLanguage.values) l.locale,
                        ],
                        localizationsDelegates: const [
                          GlobalMaterialLocalizations.delegate,
                          GlobalWidgetsLocalizations.delegate,
                          GlobalCupertinoLocalizations.delegate,
                        ],
                        initialRoute: _initialRoute(),
                        onGenerateRoute: generateRoute,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _initialRoute() {
    if (!AuthStore.instance.isAuthenticated) return WelcomeRoute.routeName;
    final role = AuthStore.instance.user?.role ?? UserRole.student;
    if (role == UserRole.admin) return AdminShellRoute.routeName;
    if (!SessionStore.instance.hasSelection) return LoginRoute.routeName;
    if (role == UserRole.teacher) return TeacherShellRoute.routeName;
    return ShellRoute.routeName;
  }
}

/// Point d'extension unique de la navigation de l'application.
///
/// Chaque route sensible est vérifiée contre le rôle du compte connecté :
/// sans cette garde, un lien tapé à la main (ex. `/#/admin` sur le web)
/// ouvrirait la console d'administration à un visiteur non autorisé.
Route<dynamic>? generateRoute(RouteSettings settings) {
  final route = AppRoute.fromName(settings.name);
  if (route == null) return null;
  final redirect = _guardRoute(route);
  if (redirect != null) {
    return MaterialPageRoute<dynamic>(
      builder: (context) => redirect,
      settings: const RouteSettings(name: '/'),
    );
  }
  return MaterialPageRoute<dynamic>(
    builder: (context) => route.build(context),
    settings: settings,
  );
}

/// Renvoie la page de redirection si [route] est inaccessible à
/// l'utilisateur actuel, sinon null (accès autorisé).
Widget? _guardRoute(AppRoute route) {
  final auth = AuthStore.instance;
  final role = auth.user?.role;
  if (route is AdminShellRoute) {
    if (auth.isAuthenticated && role == UserRole.admin) return null;
    return auth.isAuthenticated ? _homeForRole(role) : const LoginPage();
  }
  if (route is TeacherShellRoute) {
    if (auth.isAuthenticated && role == UserRole.teacher) return null;
    return auth.isAuthenticated ? _homeForRole(role) : const LoginPage();
  }
  if (route is SubscriptionRoute) {
    // Payant = réservé aux comptes authentifiés ; l'admin n'achète pas
    // de palier élève, il reste sur sa console.
    if (!auth.isAuthenticated) return const WelcomePage();
    if (role == UserRole.admin) return const AdminShellPage();
    return null;
  }
  if (route is ShellRoute ||
      route is CoursePathRoute ||
      route is FilierePickerRoute ||
      route is PermissionsRoute) {
    if (!auth.isAuthenticated) return const WelcomePage();
    if (role == UserRole.student) return null;
    return _homeForRole(role);
  }
  // Routes publiques : welcome, login, signup, mentions légales.
  return null;
}

Widget _homeForRole(UserRole? role) => switch (role) {
  UserRole.teacher => const TeacherShellPage(),
  UserRole.admin => const AdminShellPage(),
  _ => const WelcomePage(),
};

/// Contrat des routes de l'application.
abstract class AppRoute {
  const AppRoute();

  String get name;
  Widget build(BuildContext context);

  static AppRoute? fromName(String? name) {
    switch (name) {
      case ShellRoute.routeName:
        return const ShellRoute();
      case WelcomeRoute.routeName:
        return const WelcomeRoute();
      case LoginRoute.routeName:
        return const LoginRoute();
      case SignupRoute.routeName:
        return const SignupRoute();
      case FilierePickerRoute.routeName:
        return const FilierePickerRoute();
      case PermissionsRoute.routeName:
        return const PermissionsRoute();
      case TermsRoute.routeName:
        return const TermsRoute();
      case PrivacyRoute.routeName:
        return const PrivacyRoute();
      case TeacherShellRoute.routeName:
        return const TeacherShellRoute();
      case AdminShellRoute.routeName:
        return const AdminShellRoute();
      case SubscriptionRoute.routeName:
        return const SubscriptionRoute();
      default:
        if (name != null && name.startsWith('/course/')) {
          final code = name.split('/').last;
          if (code.isNotEmpty && code != 'path') {
            return CoursePathRoute(code);
          }
        }
        return null;
    }
  }
}

/// Onboarding / pitch.
class WelcomeRoute extends AppRoute {
  const WelcomeRoute();
  static const routeName = WelcomePage.routeName;

  @override
  String get name => routeName;

  @override
  Widget build(BuildContext context) => const WelcomePage();
}

/// Connexion.
class LoginRoute extends AppRoute {
  const LoginRoute();
  static const routeName = LoginPage.routeName;

  @override
  String get name => routeName;

  @override
  Widget build(BuildContext context) => const LoginPage();
}

/// Inscription.
class SignupRoute extends AppRoute {
  const SignupRoute();
  static const routeName = SignupPage.routeName;

  @override
  String get name => routeName;

  @override
  Widget build(BuildContext context) => const SignupPage();
}

/// Écran post-auth de sélection de filière.
class FilierePickerRoute extends AppRoute {
  const FilierePickerRoute();
  static const routeName = FilierePickerPage.routeName;

  @override
  String get name => routeName;

  @override
  Widget build(BuildContext context) => const FilierePickerPage();
}

/// Coquille avec barre d'onglets.
class ShellRoute extends AppRoute {
  const ShellRoute();
  static const routeName = '/';

  @override
  String get name => routeName;

  @override
  Widget build(BuildContext context) => const ShellPage();
}

/// Écran de demande de permissions après inscription.
class PermissionsRoute extends AppRoute {
  const PermissionsRoute();
  static const routeName = '/permissions';

  @override
  String get name => routeName;

  @override
  Widget build(BuildContext context) => const PermissionsPage();
}

/// Conditions générales.
class TermsRoute extends AppRoute {
  const TermsRoute();
  static const routeName = '/legal/terms';

  @override
  String get name => routeName;

  @override
  Widget build(BuildContext context) =>
      LegalDocumentPage(document: termsDocument);
}

/// Politique de confidentialité.
class PrivacyRoute extends AppRoute {
  const PrivacyRoute();
  static const routeName = '/legal/privacy';

  @override
  String get name => routeName;

  @override
  Widget build(BuildContext context) =>
      LegalDocumentPage(document: privacyDocument);
}

/// Parcours d'apprentissage type Duolingo pour un cours.
class CoursePathRoute extends AppRoute {
  const CoursePathRoute(this.courseCode);
  static const routePrefix = '/course';

  final String courseCode;

  @override
  String get name => '$routePrefix/$courseCode/path';

  @override
  Widget build(BuildContext context) => CoursePathPage(courseCode: courseCode);
}

/// Coquille enseignant.
class TeacherShellRoute extends AppRoute {
  const TeacherShellRoute();
  static const routeName = '/teacher';

  @override
  String get name => routeName;

  @override
  Widget build(BuildContext context) => const TeacherShellPage();
}

/// Coquille administrateur.
class AdminShellRoute extends AppRoute {
  const AdminShellRoute();
  static const routeName = '/admin';

  @override
  String get name => routeName;

  @override
  Widget build(BuildContext context) => const AdminShellPage();
}

/// Plans d'abonnement et tunnel de paiement.
class SubscriptionRoute extends AppRoute {
  const SubscriptionRoute();
  static const routeName = SubscriptionPage.routeName;

  @override
  String get name => routeName;

  @override
  Widget build(BuildContext context) => const SubscriptionPage();
}
