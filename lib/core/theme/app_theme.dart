import 'package:flutter/material.dart';

/// Palette et thème Material 3 d'Educoach.
///
/// Toutes les écrans de l'app consomment ce thème via [Theme.of] ou
/// [EducoachColors] pour rester cohérents.
class EducoachColors {
  const EducoachColors._();

  static const primary = Color(0xFF3F51B5); // indigo éducation
  static const primaryDark = Color(0xFF1A237E);
  static const secondary = Color(0xFF00BCD4);
  static const accent = Color(0xFF7C4DFF);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF9A825);
  static const danger = Color(0xFFC62828);

  /// Dégradé utilisé sur les en-têtes de section et cartes hero.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primary, accent],
  );

  /// Couleur associée à un avancement de cours (0.0 – 1.0).
  static Color forProgress(double p) {
    if (p >= 0.75) return success;
    if (p >= 0.4) return warning;
    return danger;
  }
}

/// Fabrique le thème clair/commun de l'application.
ThemeData buildEducoachTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: EducoachColors.primary,
    primary: EducoachColors.primary,
    secondary: EducoachColors.secondary,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF6F7FB),
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: scheme.onSurface,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: base.cardTheme.copyWith(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: scheme.primaryContainer,
      elevation: 8,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    dividerTheme: const DividerThemeData(space: 1, thickness: 1),
    textTheme: base.textTheme.apply(
      fontFamilyFallback: const <String>['Roboto'],
    ),
  );
}

/// Thème sombre aligné sur la palette Educoach.
ThemeData buildEducoachDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: EducoachColors.primary,
    brightness: Brightness.dark,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: base.cardTheme.copyWith(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: scheme.primaryContainer,
      height: 68,
      elevation: 8,
    ),
  );
}
