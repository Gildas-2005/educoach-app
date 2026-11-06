import 'package:flutter/material.dart';

import '../security/password_hasher.dart';

/// Rôles Educoach : un même compte ne peut être qu'un.
///
/// [UserRole.admin] n'est jamais délivré par l'inscription : le compte
/// administrateur est pré-provisionné par la plateforme.
enum UserRole {
  student('student', 'Étudiant', Icons.school_rounded, Color(0xFF3F51B5)),
  teacher('teacher', 'Enseignant', Icons.co_present_rounded, Color(0xFF00897B)),
  admin(
    'admin',
    'Administrateur',
    Icons.admin_panel_settings_rounded,
    Color(0xFF7C4DFF),
  );

  const UserRole(this.id, this.label, this.icon, this.color);
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  static UserRole fromId(String v) => UserRole.values.firstWhere(
    (r) => r.id == v,
    orElse: () => UserRole.student,
  );
}

/// Cycle de vie d'un compte (validité côté sécurité, voir [AuthStore]).
enum AccountStatus {
  /// Compte utilisable.
  active,

  /// Compte enseignant fraîchement créé — en attente de validation par
  /// un administrateur avant de pouvoir se connecter.
  pending,

  /// Compte suspendu par l'administration.
  blocked,
}

/// Modèle minimal d'un compte Educoach.
@immutable
class AuthUser {
  const AuthUser({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone = '',
    this.matricule = '',
    this.level = '',
    this.birthDate,
    this.role = UserRole.student,
    this.department = '',
    this.about = '',
    this.accentValue = 0xFF3F51B5,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String matricule;
  final String level;
  final DateTime? birthDate;
  final UserRole role;

  /// Pour un enseignant : discipline d'affectation, choisie à l'inscription.
  final String department;

  /// Biographie courte personnalisable depuis l'onglet profil.
  final String about;

  /// Teinte d'avatar choisie par l'utilisateur (personnalisation).
  final int accentValue;

  Color get accent => Color(accentValue);

  String get fullName => '$firstName $lastName';
  String get initials {
    final a = firstName.isNotEmpty ? firstName[0] : 'E';
    final b = lastName.isNotEmpty ? lastName[0] : '';
    return b.isEmpty ? a.toUpperCase() : (a + b).toUpperCase();
  }

  AuthUser copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? matricule,
    String? level,
    DateTime? birthDate,
    UserRole? role,
    String? department,
    String? about,
    int? accentValue,
  }) {
    return AuthUser(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      matricule: matricule ?? this.matricule,
      level: level ?? this.level,
      birthDate: birthDate ?? this.birthDate,
      role: role ?? this.role,
      department: department ?? this.department,
      about: about ?? this.about,
      accentValue: accentValue ?? this.accentValue,
    );
  }
}

/// Résultat d'une inscription ([AuthStore.signup]).
enum AuthSignupResult {
  /// Étudiant : compte actif, connecté immédiatement.
  created,

  /// Enseignant : compte créé mais verrouillé tant qu'un administrateur
  /// ne l'a pas validé.
  pendingValidation,

  /// Échec — consulter [AuthStore.error].
  failed,
}

/// D'un compte de démonstration présenté sur l'écran de connexion.
@immutable
class DemoCredential {
  const DemoCredential(this.label, this.email, this.password, this.role);
  final String label;
  final String email;
  final String password;
  final UserRole role;
}

/// Enregistrement interne d'un compte : identité + secrets + état.
class _AccountRecord {
  _AccountRecord({
    required this.user,
    required this.salt,
    required this.passwordHash,
    this.status = AccountStatus.active,
  });

  AuthUser user;
  final String salt;
  String passwordHash;
  AccountStatus status;
  int failedAttempts = 0;
  DateTime? lockedUntil;
}

/// État global d'authentification — registre réel de comptes.
///
/// Sécurité appliquée :
///   • les mots de passe ne sont jamais stockés en clair : SHA-256 salé,
///     itéré ([PasswordHasher]), avec vérification en temps constant ;
///   • le rôle est une propriété du compte, jamais déduit de l'email ;
///   • les emails sont normalisés et uniques ;
///   • un compte administrateur ne peut pas être auto-incrit ;
///   • un compte enseignant doit être validé par un administrateur ;
///   • messages d'erreur génériques (pas d'énumération de comptes) ;
///   • verrouillage temporaire après 5 échecs consécutifs.
///
/// Singleton [ChangeNotifier] : l'app décide la route initiale en fonction
/// de [isAuthenticated] (combinaison avec [SessionStore.hasSelection]).
class AuthStore extends ChangeNotifier {
  AuthStore._() {
    _seedAccounts();
  }

  static final AuthStore instance = AuthStore._();

  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(seconds: 60);

  final Map<String, _AccountRecord> _records = <String, _AccountRecord>{};

  AuthUser? _user;
  bool _busy = false;
  String? _error;

  AuthUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get busy => _busy;
  String? get error => _error;

  /// Comptes du registre (pour la console administrateur).
  List<AuthUser> get accounts =>
      _records.values.map((r) => r.user).toList(growable: false);

  /// Statut d'un compte par email (normalisé).
  AccountStatus statusOf(String email) =>
      _records[_normalizeEmail(email)]?.status ?? AccountStatus.blocked;

  /// Comptes de démonstration affichés sur l'écran de connexion.
  static const List<DemoCredential> demoCredentials = <DemoCredential>[
    DemoCredential(
      'Étudiant',
      'etudiant@educoach.cm',
      'Educoach2026',
      UserRole.student,
    ),
    DemoCredential(
      'Enseignant',
      'prof@educoach.cm',
      'Enseigner2026',
      UserRole.teacher,
    ),
    DemoCredential(
      'Administrateur',
      'admin@educoach.cm',
      'Administrer2026',
      UserRole.admin,
    ),
  ];

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Connexion
  // ---------------------------------------------------------------------------

  /// Connexion : email + mot de passe vérifiés contre le registre.
  Future<bool> login({required String email, required String password}) async {
    _begin();
    await _simulatedLatency();
    final normalized = _normalizeEmail(email);
    final record = _records[normalized];

    // Compteur d'échecs + verrouillage anti-force brute.
    if (record != null && record.lockedUntil != null) {
      final remaining = record.lockedUntil!.difference(DateTime.now());
      if (!remaining.isNegative) {
        _fail(
          'Trop de tentatives. Réessayez dans ${remaining.inSeconds + 1} s.',
        );
        return false;
      }
      record.lockedUntil = null;
      record.failedAttempts = 0;
    }

    final passwordOk =
        record != null && PasswordHasher.verify(password, record.passwordHash);
    if (record == null || !passwordOk) {
      if (record != null) {
        record.failedAttempts += 1;
        if (record.failedAttempts >= maxFailedAttempts) {
          record.lockedUntil = DateTime.now().add(lockoutDuration);
          record.failedAttempts = 0;
        }
      }
      // Message volontairement générique : ne révèle pas si l'email existe.
      _fail('Email ou mot de passe incorrect.');
      return false;
    }

    switch (record.status) {
      case AccountStatus.pending:
        _fail(
          'Votre compte enseignant est en attente de validation par un '
          'administrateur.',
        );
        return false;
      case AccountStatus.blocked:
        _fail('Ce compte a été suspendu par l\'administration.');
        return false;
      case AccountStatus.active:
        break;
    }

    record.failedAttempts = 0;
    _user = record.user;
    _end();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Inscription
  // ---------------------------------------------------------------------------

  /// Inscription étudiant / enseignant. Le rôle administrateur est refusé :
  /// ces comptes sont pré-provisionnés.
  Future<AuthSignupResult> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String phone = '',
    String matricule = '',
    String level = '',
    DateTime? birthDate,
    UserRole role = UserRole.student,
    String department = '',
  }) async {
    _begin();
    await _simulatedLatency();

    if (role == UserRole.admin) {
      _fail(
        'Les comptes administrateurs sont créés par la plateforme. '
        'Connectez-vous avec l\'identifiant fourni.',
      );
      return AuthSignupResult.failed;
    }

    final normalized = _normalizeEmail(email);
    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
      _fail('Nom et prénom sont obligatoires.');
      return AuthSignupResult.failed;
    }
    if (!_emailPattern.hasMatch(normalized)) {
      _fail('Adresse email invalide.');
      return AuthSignupResult.failed;
    }
    if (_records.containsKey(normalized)) {
      _fail('Un compte existe déjà avec cette adresse email.');
      return AuthSignupResult.failed;
    }
    final strengthError = PasswordHasher.validateStrength(password);
    if (strengthError != null) {
      _fail(strengthError);
      return AuthSignupResult.failed;
    }
    if (role == UserRole.teacher) {
      if (department.trim().isEmpty) {
        _fail('Veuillez préciser votre discipline d\'affectation.');
        return AuthSignupResult.failed;
      }
      if (matricule.trim().isEmpty) {
        _fail('Le matricule enseignant est obligatoire.');
        return AuthSignupResult.failed;
      }
    }

    final user = AuthUser(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: normalized,
      phone: phone.trim(),
      matricule: matricule.trim(),
      level: level,
      birthDate: birthDate,
      role: role,
      department: department.trim(),
    );
    final salt = PasswordHasher.generateSalt();
    final record = _AccountRecord(
      user: user,
      salt: salt,
      passwordHash: PasswordHasher.hash(password, salt),
      status: role == UserRole.teacher
          ? AccountStatus.pending
          : AccountStatus.active,
    );
    _records[normalized] = record;

    if (record.status == AccountStatus.pending) {
      _busy = false;
      notifyListeners();
      return AuthSignupResult.pendingValidation;
    }
    _user = user;
    _end();
    return AuthSignupResult.created;
  }

  // ---------------------------------------------------------------------------
  // Profil : mise à jour et mot de passe
  // ---------------------------------------------------------------------------

  /// Met à jour le profil de l'utilisateur connecté (personnalisation).
  void updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? about,
    int? accentValue,
    DateTime? birthDate,
  }) {
    final current = _user;
    if (current == null) return;
    final updated = current.copyWith(
      firstName: firstName?.trim(),
      lastName: lastName?.trim(),
      phone: phone?.trim(),
      about: about,
      accentValue: accentValue,
      birthDate: birthDate,
    );
    final record = _records[_normalizeEmail(current.email)];
    if (record != null) record.user = updated;
    _user = updated;
    notifyListeners();
  }

  /// Changement de mot de passe avec vérification de l'ancien.
  ///
  /// Même verrouillage anti-force brute que la connexion : cinq
  /// vérifications ratées d'affilée suspendent l'opération d'une minute.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _user?.email;
    final record = email == null ? null : _records[_normalizeEmail(email)];
    if (record == null) {
      _fail('Session expirée, reconnectez-vous.');
      return false;
    }
    if (record.lockedUntil != null) {
      final remaining = record.lockedUntil!.difference(DateTime.now());
      if (!remaining.isNegative) {
        _fail(
          'Trop de tentatives. Réessayez dans '
          '${remaining.inSeconds + 1} s.',
        );
        return false;
      }
      record.lockedUntil = null;
      record.failedAttempts = 0;
    }
    _begin();
    await _simulatedLatency();
    if (!PasswordHasher.verify(currentPassword, record.passwordHash)) {
      record.failedAttempts += 1;
      if (record.failedAttempts >= maxFailedAttempts) {
        record.lockedUntil = DateTime.now().add(lockoutDuration);
        record.failedAttempts = 0;
      }
      _fail('Mot de passe actuel incorrect.');
      return false;
    }
    final strengthError = PasswordHasher.validateStrength(newPassword);
    if (strengthError != null) {
      _fail(strengthError);
      return false;
    }
    if (newPassword == currentPassword) {
      _fail('Le nouveau mot de passe doit différer de l\'actuel.');
      return false;
    }
    final newSalt = PasswordHasher.generateSalt();
    record.passwordHash = PasswordHasher.hash(newPassword, newSalt);
    record.failedAttempts = 0;
    _end();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Actions administrateur
  // ---------------------------------------------------------------------------

  /// Valide un compte enseignant en attente.
  bool approveAccount(String email) {
    final record = _records[_normalizeEmail(email)];
    if (record == null || record.status != AccountStatus.pending) return false;
    record.status = AccountStatus.active;
    notifyListeners();
    return true;
  }

  /// Bloque / débloque un compte (jamais un administrateur).
  bool setBlocked(String email, {bool blocked = true}) {
    final record = _records[_normalizeEmail(email)];
    if (record == null || record.user.role == UserRole.admin) return false;
    record.status = blocked ? AccountStatus.blocked : AccountStatus.active;
    if (blocked && _user?.email == record.user.email) _user = null;
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Fin de session
  // ---------------------------------------------------------------------------

  /// Se déconnecte SANS purger les autres stores — utiliser
  /// [SessionCoordinator.signOut] (qui appelle cette méthode) pour une
  /// vraie fin de session sans fuite inter-comptes.
  void logout() {
    _user = null;
    _error = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Interne
  // ---------------------------------------------------------------------------

  void _begin() {
    _busy = true;
    _error = null;
    notifyListeners();
  }

  void _end() {
    _busy = false;
    notifyListeners();
  }

  void _fail(String message) {
    _busy = false;
    _error = message;
    notifyListeners();
  }

  static Future<void> _simulatedLatency() =>
      Future<void>.delayed(const Duration(milliseconds: 650));

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  static final RegExp _emailPattern = RegExp(
    r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$',
  );

  /// Comptes pré-provisionnés : un étudiant, un enseignant validé et
  /// l'administrateur de la plateforme.
  void _seedAccounts() {
    for (final demo in demoCredentials) {
      final salt = PasswordHasher.generateSalt();
      final base = AuthUser(
        firstName: switch (demo.role) {
          UserRole.student => 'Awa',
          UserRole.teacher => 'Bernard',
          UserRole.admin => 'Admin',
        },
        lastName: switch (demo.role) {
          UserRole.student => 'Ndiaye',
          UserRole.teacher => 'Mvongo',
          UserRole.admin => 'Educoach',
        },
        email: demo.email,
        matricule: switch (demo.role) {
          UserRole.teacher => 'ENS-2019-0341',
          _ => '',
        },
        role: demo.role,
        department: switch (demo.role) {
          UserRole.teacher => 'Informatique',
          _ => '',
        },
        about: switch (demo.role) {
          UserRole.student => 'Étudiante en informatique, passionnée d\'IA et de développement mobile.',
          UserRole.teacher =>
            'Enseignant-chercheur en informatique — algorythmique et systèmes.',
          UserRole.admin => 'Administration de la plateforme Educoach.',
        },
      );
      _records[demo.email] = _AccountRecord(
        user: base,
        salt: salt,
        passwordHash: PasswordHasher.hash(demo.password, salt),
      );
    }
  }
}

/// InheritedWidget expose [AuthStore] à tout le sous-arbre.
class AuthScope extends InheritedWidget {
  const AuthScope({super.key, required this.store, required super.child});

  final AuthStore store;

  static AuthStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope absent de la hiérarchie des widgets.');
    return scope!.store;
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) => store != oldWidget.store;
}
