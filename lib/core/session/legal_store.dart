import 'package:flutter/material.dart';

/// Préférences légales de l'utilisateur : consentements et permissions.
///
/// Ces marqueurs sont requis par la loi camerounaise n° 2010/012 du
/// 21 décembre 2010 relative à la cybersécurité et à la prévention de la
/// cybercriminalité (Livre V — protection des données à caractère
/// personnel) et, le cas échéant, par le RGPD pour les étudiants européens.
class LegalStore extends ChangeNotifier {
  LegalStore._();
  static final LegalStore instance = LegalStore._();

  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _consentNotifications = false;
  bool _consentMarketing = false;
  bool _consentDataSharing = false;
  bool _isMinor = false;
  bool _parentalConsent = false;
  DateTime? _termsAcceptedAt;
  DateTime? _privacyAcceptedAt;
  final String _termsVersion = 'v1.0-2026';
  final String _privacyVersion = 'v1.0-2026';

  bool get acceptedTerms => _acceptedTerms;
  bool get acceptedPrivacy => _acceptedPrivacy;
  bool get consentNotifications => _consentNotifications;
  bool get consentMarketing => _consentMarketing;
  bool get consentDataSharing => _consentDataSharing;
  bool get isMinor => _isMinor;
  bool get parentalConsent => _parentalConsent;
  DateTime? get termsAcceptedAt => _termsAcceptedAt;
  DateTime? get privacyAcceptedAt => _privacyAcceptedAt;
  String get termsVersion => _termsVersion;
  String get privacyVersion => _privacyVersion;

  /// Consentement obligatoire aux CGU.
  void acceptTerms(bool v) {
    _acceptedTerms = v;
    _termsAcceptedAt = v ? DateTime.now() : null;
    notifyListeners();
  }

  /// Consentement obligatoire à la politique de confidentialité.
  void acceptPrivacy(bool v) {
    _acceptedPrivacy = v;
    _privacyAcceptedAt = v ? DateTime.now() : null;
    notifyListeners();
  }

  void setNotifications(bool v) {
    _consentNotifications = v;
    notifyListeners();
  }

  void setMarketing(bool v) {
    _consentMarketing = v;
    notifyListeners();
  }

  void setDataSharing(bool v) {
    _consentDataSharing = v;
    notifyListeners();
  }

  void setMinor(bool v) {
    _isMinor = v;
    if (!v) _parentalConsent = false;
    notifyListeners();
  }

  void setParentalConsent(bool v) {
    _parentalConsent = v;
    notifyListeners();
  }

  /// Vrai si l'utilisateur a rempli les deux prérequis obligatoires
  /// (et le consentement parental si mineur).
  bool get canSignup =>
      _acceptedTerms && _acceptedPrivacy && (!_isMinor || _parentalConsent);

  /// Réinitialisation lors d'un logout pour repartir sur une base propre.
  void reset() {
    _acceptedTerms = false;
    _acceptedPrivacy = false;
    _consentNotifications = false;
    _consentMarketing = false;
    _consentDataSharing = false;
    _isMinor = false;
    _parentalConsent = false;
    _termsAcceptedAt = null;
    _privacyAcceptedAt = null;
    notifyListeners();
  }
}

/// InheritedWidget expose [LegalStore] à tout le sous-arbre.
class LegalScope extends InheritedWidget {
  const LegalScope({super.key, required this.store, required super.child});

  final LegalStore store;

  static LegalStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LegalScope>();
    assert(scope != null, 'LegalScope absent de la hiérarchie des widgets.');
    return scope!.store;
  }

  @override
  bool updateShouldNotify(LegalScope oldWidget) => store != oldWidget.store;
}

/// État des permissions système demandées par Educoach.
@immutable
class AppPermission {
  const AppPermission({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.required,
    this.color,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool required;
  final Color? color;
}

/// Catalogue des permissions qu'Educoach peut demander.
const appPermissions = <AppPermission>[
  AppPermission(
    id: 'notifications',
    title: 'Notifications',
    description:
        'Rappels de cours, devoirs à rendre, résultats de quiz et messages '
        'de tes enseignants. Sans cette permission, tu peux manquer des '
        'échéances importantes.',
    icon: Icons.notifications_active_rounded,
    required: false,
    color: Color(0xFFEF6C00),
  ),
  AppPermission(
    id: 'calendar',
    title: 'Calendrier',
    description:
        'Synchroniser ton emploi du temps Educoach avec l\'agenda de ton '
        'téléphone pour ne jamais oublier une séance.',
    icon: Icons.calendar_month_rounded,
    required: false,
    color: Color(0xFF3F51B5),
  ),
  AppPermission(
    id: 'camera',
    title: 'Appareil photo',
    description:
        'Ajouter une photo de profil ou scanner un document d\'inscription. '
        'Les images ne sont pas téléversées sans ton accord explicite.',
    icon: Icons.photo_camera_rounded,
    required: false,
    color: Color(0xFF00897B),
  ),
  AppPermission(
    id: 'storage',
    title: 'Stockage local',
    description:
        'Télécharger les ressources (PDF, slides, audio) pour les consulter '
        'hors-ligne depuis ton appareil.',
    icon: Icons.folder_open_rounded,
    required: false,
    color: Color(0xFF7C4DFF),
  ),
  AppPermission(
    id: 'microphone',
    title: 'Microphone',
    description:
        'Enregistrer ta voix pour répondre à un oral ou poser une question '
        'à un enseignant dans les discussions de cours.',
    icon: Icons.mic_rounded,
    required: false,
    color: Color(0xFFD81B60),
  ),
  AppPermission(
    id: 'location',
    title: 'Localisation (approximative)',
    description:
        'Afficher le bâtiment et l\'amphi où a lieu ton prochain cours sur '
        'le campus. Utilisée uniquement pendant l\'application.',
    icon: Icons.place_rounded,
    required: false,
    color: Color(0xFFC62828),
  ),
];

/// Store des permissions accordées/refusées par l'utilisateur.
class PermissionsStore extends ChangeNotifier {
  PermissionsStore._();
  static final PermissionsStore instance = PermissionsStore._();

  final Map<String, bool> _granted = <String, bool>{};

  bool isGranted(String id) => _granted[id] ?? false;
  Map<String, bool> get all => Map<String, bool>.unmodifiable(_granted);

  void grant(String id, bool value) {
    _granted[id] = value;
    notifyListeners();
  }

  int get grantedCount => _granted.values.where((v) => v).length;

  void reset() {
    _granted.clear();
    notifyListeners();
  }
}

class PermissionsScope extends InheritedWidget {
  const PermissionsScope({
    super.key,
    required this.store,
    required super.child,
  });

  final PermissionsStore store;

  static PermissionsStore of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<PermissionsScope>();
    assert(scope != null, 'PermissionsScope absent de la hiérarchie.');
    return scope!.store;
  }

  @override
  bool updateShouldNotify(PermissionsScope oldWidget) =>
      store != oldWidget.store;
}
