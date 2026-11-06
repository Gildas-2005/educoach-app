import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/session/auth_store.dart';
import '../../core/session/legal_store.dart';
import '../../core/session/session_store.dart';
import '../../core/widgets/aurora_backdrop.dart';
import '../legal/legal_content.dart';
import '../legal/legal_document_page.dart';
import '../onboarding/filiere_picker_page.dart';
import '../shell/shell_page.dart';
import 'login_page.dart';

/// Écran d'inscription Educoach — version épurée, façon app moderne.
///
/// Principe : un seul champ obligatoire par ligne, une seule case à cocher
/// pour le consentement légal (CGU + politique de confidentialité), et des
/// liens cliquables « Conditions générales » / « Politique de confidentialité »
/// qui ouvrent le texte complet dans [LegalDocumentPage].
///
/// Deux rôles seulement : étudiant et enseignant. Le compte administrateur
/// n'est pas auto-incrit — il est pré-provisionné par la plateforme. La
/// création d'un compte enseignant exige une discipline d'affectation et un
/// matricule, puis passe en validation administrateur avant la première
/// connexion. Les rappels notifications se réglent dans l'app
/// (Profil → Préférences), pas ici.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  static const routeName = '/signup';

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _matriculeCtrl = TextEditingController();

  UserRole _role = UserRole.student;
  String? _discipline;
  bool _obscure = true;
  bool _consent = false;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _matriculeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_consent) {
      final texts = context.texts;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            texts.t(
              'Merci d\'accepter les conditions pour créer ton compte.',
              'Please accept the terms to create your account.',
            ),
          ),
        ),
      );
      return;
    }
    final auth = AuthScope.of(context);
    LegalScope.of(context)
      ..acceptTerms(true)
      ..acceptPrivacy(true)
      ..setMarketing(false)
      ..setDataSharing(false);
    final result = await auth.signup(
      firstName: _firstCtrl.text.trim(),
      lastName: _lastCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _pwdCtrl.text,
      role: _role,
      matricule: _role == UserRole.teacher ? _matriculeCtrl.text.trim() : '',
      department: _role == UserRole.teacher ? (_discipline ?? '') : '',
    );
    if (!mounted) return;
    switch (result) {
      case AuthSignupResult.created:
        _redirectToWorkspace();
      case AuthSignupResult.pendingValidation:
        _showPendingValidationSheet();
      case AuthSignupResult.failed:
        break; // l'erreur s'affiche via le bandeau auth.error
    }
  }

  /// Le compte enseignant est créé mais verrouillé tant qu'un
  /// administrateur ne l'a pas validé.
  void _showPendingValidationSheet() {
    final theme = Theme.of(context);
    final texts = context.texts;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              size: 44,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              texts.t('Compte enseignant créé ✅', 'Teacher account created ✅'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              texts.t(
                'Pour la sécurité de la plateforme, chaque compte enseignant '
                    'est vérifié par un administrateur avant la première '
                    'connexion. Tu seras notifié·e dès sa validation.',
                'For platform security, every teacher account is verified by '
                    'an administrator before first sign-in. You\'ll be notified '
                    'as soon as it\'s approved.',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacement(
                  FadeSlideRoute<void>(page: const LoginPage()),
                );
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(texts.t('Retour à la connexion', 'Back to sign in')),
            ),
          ],
        ),
      ),
    );
  }

  void _redirectToWorkspace() {
    final target = switch (_role) {
      UserRole.teacher => const FilierePickerPage(),
      _ =>
        SessionStore.instance.hasSelection
            ? const ShellPage()
            : const FilierePickerPage(),
    };
    Navigator.of(context).pushReplacement(FadeSlideRoute<void>(page: target));
  }

  void _pickDiscipline() async {
    final sel = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _DisciplinePickerSheet(current: _discipline),
    );
    if (sel != null) setState(() => _discipline = sel);
  }

  void _openDoc(LegalDocument doc) {
    Navigator.of(context)
        .push(FadeSlideRoute<void>(page: LegalDocumentPage(document: doc)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = context.texts;
    final auth = AuthScope.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const AuroraBackdrop(
            primary: Color(0xFF7C4DFF),
            accentA: Color(0xFF3F51B5),
            accentB: Color(0xFF00BCD4),
            intensity: 0.9,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FadeSlideIn(child: AuthBrandMark()),
                      const SizedBox(height: 22),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 60),
                        child: Text(
                          texts.t('Créer ton compte', 'Create your account'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          texts.t(
                            'Trois minutes, et tu retrouves tes cours, '
                                'tes devoirs et tes enseignants.',
                            'Three minutes, and all your courses, '
                                'assignments and teachers are back.',
                          ),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 140),
                        child: _RoleSegment(
                          value: _role,
                          onChanged: (r) => setState(() => _role = r),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        texts.t(
                          'Administrateur ? ton compte est créé par la '
                              'plateforme — connecte-toi avec l\'identifiant reçu.',
                          'Administrator? Your account is provisioned by the '
                              'platform — sign in with the credentials provided.',
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 180),
                        offset: const Offset(0, 0.15),
                        child: _GlassCard(
                          child: Form(
                            key: _formKey,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _TwoSide(
                                  left: TextFormField(
                                    controller: _firstCtrl,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: texts.t(
                                        'Prénom',
                                        'First name',
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.person_outline_rounded,
                                      ),
                                    ),
                                    validator: (v) => (v ?? '').trim().isEmpty
                                        ? texts.t(
                                            'Prénom requis.',
                                            'First name required.',
                                          )
                                        : null,
                                  ),
                                  right: TextFormField(
                                    controller: _lastCtrl,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: texts.t('Nom', 'Last name'),
                                      prefixIcon: const Icon(
                                        Icons.badge_outlined,
                                      ),
                                    ),
                                    validator: (v) => (v ?? '').trim().isEmpty
                                        ? texts.t(
                                            'Nom requis.',
                                            'Last name required.',
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: texts.email,
                                    hintText: texts.t(
                                      'prenom.nom@exemple.cm',
                                      'first.last@example.cm',
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.alternate_email_rounded,
                                    ),
                                  ),
                                  validator: (v) {
                                    final s = (v ?? '').trim();
                                    if (s.isEmpty) {
                                      return texts.t(
                                        'Email requis.',
                                        'Email required.',
                                      );
                                    }
                                    if (!s.contains('@') || !s.contains('.')) {
                                      return texts.t(
                                        'Format email invalide.',
                                        'Invalid email format.',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _pwdCtrl,
                                  obscureText: _obscure,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    labelText: texts.password,
                                    helperText: texts.t(
                                      '8 caractères minimum',
                                      '8 characters minimum',
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                      ),
                                    ),
                                  ),
                                  validator: (v) {
                                    final s = v ?? '';
                                    if (s.isEmpty) {
                                      return texts.t(
                                        'Mot de passe requis.',
                                        'Password required.',
                                      );
                                    }
                                    if (s.length < 8) {
                                      return texts.t(
                                        'Trop court (min. 8).',
                                        'Too short (min. 8).',
                                      );
                                    }
                                    if (!s.contains(RegExp(r'[A-Za-zÀ-ÿ]'))) {
                                      return texts.t(
                                        'Ajoute au moins une lettre.',
                                        'Add at least one letter.',
                                      );
                                    }
                                    if (!s.contains(RegExp(r'[0-9]'))) {
                                      return texts.t(
                                        'Ajoute au moins un chiffre.',
                                        'Add at least one digit.',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 6),
                                _PasswordStrength(ctrl: _pwdCtrl),
                                if (_role == UserRole.teacher) ...[
                                  const SizedBox(height: 12),
                                  _ChoicePill(
                                    label: texts.t(
                                      'Discipline d\'affectation',
                                      'Teaching department',
                                    ),
                                    placeholder: texts.t(
                                      'Choisir ta discipline',
                                      'Choose your department',
                                    ),
                                    display: _discipline,
                                    onTap: _pickDiscipline,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _matriculeCtrl,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    textInputAction: TextInputAction.done,
                                    decoration: InputDecoration(
                                      labelText: texts.t(
                                        'Matricule enseignant',
                                        'Teacher staff ID',
                                      ),
                                      hintText: 'ENS-2024-0000',
                                      prefixIcon: const Icon(
                                        Icons.badge_outlined,
                                      ),
                                    ),
                                    validator: (v) =>
                                        _role == UserRole.teacher &&
                                            (v ?? '').trim().isEmpty
                                        ? texts.t(
                                            'Matricule requis pour un '
                                                'enseignant.',
                                            'Staff ID required for a teacher.',
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.verified_user_outlined,
                                        size: 16,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          texts.t(
                                            'Compte vérifié par un '
                                                'administrateur avant activation.',
                                            'Account verified by an '
                                                'administrator before activation.',
                                          ),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontSize: 11,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 240),
                        child: _ConsentTile(
                          checked: _consent,
                          onChanged: (v) => setState(() => _consent = v),
                          onOpenTerms: () => _openDoc(termsDocument),
                          onOpenPrivacy: () => _openDoc(privacyDocument),
                        ),
                      ),
                      if (auth.error != null && !auth.busy) ...[
                        const SizedBox(height: 12),
                        _ErrorBanner(message: texts.storeMessage(auth.error!)),
                      ],
                      const SizedBox(height: 22),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 340),
                        child: _GlowCta(
                          busy: auth.busy,
                          enabled: _consent,
                          onPressed: _submit,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 400),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              texts.t(
                                'Déjà inscrit·e ?',
                                'Already registered?',
                              ),
                              style: theme.textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  FadeSlideRoute<void>(page: const LoginPage()),
                                );
                              },
                              child: Text(
                                texts.t('Se connecter', 'Log in'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          texts.t(
                            'Données traitées au Cameroun · '
                                'protégées par la loi 2010/012 Livre V.',
                            'Data processed in Cameroon · protected under '
                                'Law 2010/012, Book V.',
                          ),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sélecteur de rôle compact — étudiant / enseignant uniquement.
// ---------------------------------------------------------------------------
class _RoleSegment extends StatelessWidget {
  const _RoleSegment({required this.value, required this.onChanged});
  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  static const _roles = <UserRole>[UserRole.student, UserRole.teacher];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = context.texts;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.75,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          for (final r in _roles)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(r),
                child: AnimatedContainer(
                  duration: Motion.normal,
                  curve: Motion.emphasized,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: r == value ? r.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        r.icon,
                        size: 18,
                        color: r == value
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          switch (r) {
                            UserRole.student => texts.t('Étudiant', 'Student'),
                            UserRole.teacher => texts.t(
                              'Enseignant',
                              'Teacher',
                            ),
                            _ => r.label,
                          },
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: r == value
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte en verre dépoli pour grouper les champs obligatoires.
// ---------------------------------------------------------------------------
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TwoSide extends StatelessWidget {
  const _TwoSide({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.onTap,
    required this.label,
    required this.placeholder,
    this.display,
  });
  final VoidCallback onTap;
  final String label;
  final String placeholder;

  /// Texte déjà sélectionné à afficher (ici, la discipline enseignant).
  final String? display;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = display;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.school_outlined),
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Text(
          (text == null || text.isEmpty) ? placeholder : text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: text == null || text.isEmpty
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Jauge de robustesse du mot de passe, discrète.
// ---------------------------------------------------------------------------
class _PasswordStrength extends StatefulWidget {
  const _PasswordStrength({required this.ctrl});
  final TextEditingController ctrl;

  @override
  State<_PasswordStrength> createState() => _PasswordStrengthState();
}

class _PasswordStrengthState extends State<_PasswordStrength> {
  double _v = 0;

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_recompute);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_recompute);
    super.dispose();
  }

  void _recompute() {
    final s = widget.ctrl.text;
    double score = 0;
    if (s.isNotEmpty) {
      if (s.length >= 8) score += 1;
      if (s.length >= 12) score += 1;
      if (RegExp(r'[A-Z]').hasMatch(s)) score += 1;
      if (RegExp(r'\d').hasMatch(s)) score += 1;
      if (RegExp(r'[^A-Za-z0-9]').hasMatch(s)) score += 1;
      score = (score / 5).clamp(0.0, 1.0);
    }
    if (score != _v) setState(() => _v = score);
  }

  Color _colorFor(double v) => switch (v) {
    < 0.34 => const Color(0xFFC62828),
    < 0.67 => const Color(0xFFEF6C00),
    < 0.85 => const Color(0xFF00897B),
    _ => const Color(0xFF2E7D32),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = context.texts;
    final c = _colorFor(_v);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: _v),
              duration: Motion.normal,
              curve: Motion.emphasized,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 4,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: c,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: Motion.fast,
          child: Text(
            _v < 0.34
                ? texts.t('Faible', 'Weak')
                : _v < 0.67
                ? texts.t('Moyen', 'Fair')
                : _v < 0.85
                ? texts.t('Bon', 'Good')
                : texts.t('Excellent', 'Excellent'),
            key: ValueKey<double>((_v * 100).roundToDouble()),
            style: theme.textTheme.labelSmall?.copyWith(
              color: c,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Case unique de consentement : un check, deux liens cliquables.
// ---------------------------------------------------------------------------
class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.checked,
    required this.onChanged,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
  });
  final bool checked;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = context.texts;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: checked
            ? theme.colorScheme.primary.withValues(alpha: 0.06)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: checked
              ? theme.colorScheme.primary.withValues(alpha: 0.55)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => onChanged(!checked),
            child: AnimatedContainer(
              duration: Motion.fast,
              curve: Motion.emphasized,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: checked
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: checked
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 2,
                ),
              ),
              child: checked
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 2,
              children: [
                Text(texts.t('J\'accepte les', 'I accept the')),
                _DocLink(
                  label: texts.t('Conditions générales', 'Terms of Service'),
                  onTap: onOpenTerms,
                ),
                Text(texts.t('et la', 'and the')),
                _DocLink(
                  label: texts.t(
                    'Politique de confidentialité',
                    'Privacy Policy',
                  ),
                  onTap: onOpenPrivacy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocLink extends StatelessWidget {
  const _DocLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
          decoration: TextDecoration.underline,
          decorationColor: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CTA avec halo pulsant — le bouton principal de soumission.
// ---------------------------------------------------------------------------
class _GlowCta extends StatefulWidget {
  const _GlowCta({
    required this.busy,
    required this.enabled,
    required this.onPressed,
  });
  final bool busy;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_GlowCta> createState() => _GlowCtaState();
}

class _GlowCtaState extends State<_GlowCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && !widget.busy;
    final texts = context.texts;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final glow = 0.28 + _c.value * 0.18;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withValues(alpha: glow),
                      blurRadius: 24 + _c.value * 10,
                      offset: Offset(0, 8 + _c.value * 4),
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: FilledButton.icon(
        onPressed: enabled ? widget.onPressed : null,
        icon: widget.busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.arrow_forward_rounded),
        label: Text(
          widget.busy
              ? texts.t('Création en cours…', 'Creating…')
              : texts.t('Créer mon compte', 'Create my account'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: const Color(0xFF7C4DFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    const c = Color(0xFFC62828);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: c),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: c, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Disciplines d'affectation proposées aux enseignants.
// ---------------------------------------------------------------------------
const teacherDisciplines = <String>[
  'Informatique',
  'Mathématiques',
  'Physique',
  'Chimie',
  'Biologie / SVT',
  'Médecine / Santé publique',
  'Sciences économiques',
  'Gestion & Commerce',
  'Droit',
  'Lettres & Langues',
  'Histoire-Géographie',
  'Philosophie',
  'Sciences de l’éducation',
  'STAPS / Sport',
  'Agronomie & Environnement',
  'Génie civil & Electricité',
];

class _DisciplinePickerSheet extends StatefulWidget {
  const _DisciplinePickerSheet({this.current});
  final String? current;

  @override
  State<_DisciplinePickerSheet> createState() => _DisciplinePickerSheetState();
}

class _DisciplinePickerSheetState extends State<_DisciplinePickerSheet> {
  String _query = '';
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;
    final list = teacherDisciplines
        .where(
          (d) =>
              _query.isEmpty || d.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _ctrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: texts.t(
                  'Rechercher une discipline…',
                  'Search a department…',
                ),
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                for (final d in list)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF00897B)
                          .withValues(alpha: 0.14),
                      child: const Icon(
                        Icons.co_present_rounded,
                        color: Color(0xFF00897B),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      d,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: d == widget.current
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2E7D32),
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(d),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet de choix de discipline (enseignant), avec recherche instantanée.
// ---------------------------------------------------------------------------
