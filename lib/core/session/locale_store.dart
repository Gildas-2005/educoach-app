import 'package:flutter/material.dart';

/// Langues disponibles dans l'application.
///
/// Le Cameroun est officiellement bilingue (français / anglais) —
/// l'app suit cette réalité.
enum AppLanguage {
  french('fr', 'Français', '🇫🇷'),
  english('en', 'English', '🇬🇧');

  const AppLanguage(this.code, this.nativeLabel, this.flag);
  final String code;
  final String nativeLabel;
  final String flag;

  Locale get locale => Locale(code);

  static AppLanguage fromLocale(Locale l) =>
      values.firstWhere((v) => v.code == l.languageCode, orElse: () => french);
}

/// État global de la langue choisie.
///
/// Singleton [ChangeNotifier] : [LocaleScope] l'expose à tout l'arbre et
/// la racine [MaterialApp] écoute ce store pour appliquer la locale.
/// Choix volontairement sans dépendance externe (architecture offline-first
/// du projet) : les chaînes vivent dans `core/i18n/app_strings.dart`.
class LocaleStore extends ChangeNotifier {
  LocaleStore._();

  static final LocaleStore instance = LocaleStore._();

  AppLanguage _language = AppLanguage.french;

  AppLanguage get language => _language;
  Locale get locale => _language.locale;

  void setLanguage(AppLanguage lang) {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
  }

  /// Bascule FR ⇄ EN (raccourci du switcher).
  void toggle() => setLanguage(
    _language == AppLanguage.french ? AppLanguage.english : AppLanguage.french,
  );
}

/// InheritedWidget expose [LocaleStore] à tout le sous-arbre.
class LocaleScope extends InheritedWidget {
  const LocaleScope({super.key, required this.store, required super.child});

  final LocaleStore store;

  static LocaleStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope absent de la hiérarchie des widgets.');
    return scope!.store;
  }

  @override
  // Toujours true : le store est un singleton, donc `store != old.store`
  // ne capturerait jamais un changement de langue. Tout widget ayant
  // appelé LocaleScope.of / context.texts doit se reconstruire.
  bool updateShouldNotify(LocaleScope oldWidget) => true;
}
