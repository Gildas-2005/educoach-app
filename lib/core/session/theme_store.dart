import 'package:flutter/material.dart';

/// Préférence d'apparence (clair / sombre / système).
///
/// Singleton [ChangeNotifier] consommé par [MaterialApp.themeMode] via
/// [ThemeScope], et piloté depuis le commutateur « Mode sombre » de
/// l'onglet profil.
class ThemeStore extends ChangeNotifier {
  ThemeStore._();
  static final ThemeStore instance = ThemeStore._();

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  bool get isDark => switch (_mode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
  };

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  /// Bascule sombre / clair (part du système ou du mode courant).
  void toggleDark() {
    setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}

/// InheritedWidget expose [ThemeStore] à tout le sous-arbre.
class ThemeScope extends InheritedWidget {
  const ThemeScope({super.key, required this.store, required super.child});

  final ThemeStore store;

  static ThemeStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope absent de la hiérarchie des widgets.');
    return scope!.store;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) => store != oldWidget.store;
}
