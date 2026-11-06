import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/session/auth_store.dart';
import '../../core/session/session_store.dart';
import '../../core/widgets/aurora_backdrop.dart';
import '../admin/admin_shell_page.dart';
import '../onboarding/filiere_picker_page.dart';
import '../shell/shell_page.dart';
import '../teacher/teacher_shell_page.dart';
import 'signup_page.dart';

/// Écran de connexion Educoach — refonte visuelle.
///
/// Héro animé, carte en verre dépoli, CTA à halo pulsant, récupération de
/// mot de passe et rattachement automatique des comptes institutionnels.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static const routeName = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = AuthScope.of(context);
    final ok = await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted || !ok) return;
    _advance();
  }

  void _advance() {
    final role = AuthStore.instance.user?.role ?? UserRole.student;
    final hasSelection = SessionStore.instance.hasSelection;
    final target = switch ((role, hasSelection)) {
      (UserRole.admin, _) => const AdminShellPage(),
      (UserRole.teacher, true) => const TeacherShellPage(),
      (UserRole.teacher, false) => const FilierePickerPage(),
      (UserRole.student, true) => const ShellPage(),
      (UserRole.student, false) => const FilierePickerPage(),
    };
    Navigator.of(context).pushReplacement(FadeSlideRoute<void>(page: target));
  }

  void _forgotPassword() {
    final email = _emailCtrl.text.trim();
    final texts = context.texts;
    final title = texts.forgotPassword;
    final body = email.isEmpty
        ? texts.t(
            'Saisis ton adresse dans le champ Email, puis relance '
                'la réinitialisation : on t\'envoie un lien sécurisé '
                'valable 30 minutes.',
            'Enter your address in the Email field, then start the reset '
                'again: we will send you a secure link valid for 30 minutes.',
          )
        : texts.t(
                'On envoie un lien de réinitialisation sécurisé à ',
                'We will send a secure reset link to ',
              ) +
              email +
              texts.t(
                '. Le lien expire après 30 minutes.',
                '. The link expires after 30 minutes.',
              );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.lock_reset_rounded,
          color: Color(0xFF7C4DFF),
          size: 32,
        ),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(body, style: Theme.of(ctx).textTheme.bodyMedium)],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(texts.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    texts.t(
                      'Lien de réinitialisation envoyé (démo).',
                      'Reset link sent (demo).',
                    ),
                  ),
                ),
              );
            },
            child: Text(texts.t('Envoyer le lien', 'Send link')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = AuthScope.of(context);
    final texts = context.texts;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const AuroraBackdrop(
            primary: Color(0xFF3F51B5),
            accentA: Color(0xFF7C4DFF),
            accentB: Color(0xFF00BCD4),
            intensity: 1.0,
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FadeSlideIn(
                        child: Center(child: AuthBrandMark(size: 88)),
                      ),
                      const SizedBox(height: 22),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 90),
                        child: Text(
                          texts.t('Bon retour 👋', 'Welcome back 👋'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        child: Text(
                          texts.t(
                            'Connecte-toi pour retrouver tes cours, ton '
                                'planning, tes notes et discuter avec tes '
                                'professeurs.',
                            'Sign in to find your courses, schedule, grades '
                                'and chat with your teachers.',
                          ),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 220),
                        offset: const Offset(0, 0.15),
                        child: _LoginCard(
                          formKey: _formKey,
                          error: (!auth.busy && auth.error != null)
                              ? texts.storeMessage(auth.error!)
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _EmailField(ctrl: _emailCtrl),
                              const SizedBox(height: 12),
                              AuthPasswordField(
                                ctrl: _passwordCtrl,
                                obscure: _obscure,
                                onToggle: () =>
                                    setState(() => _obscure = !_obscure),
                                minLength: 4,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _forgotPassword,
                                  child: Text(texts.forgotPassword),
                                ),
                              ),
                              const SizedBox(height: 6),
                              _GlowCta(busy: auth.busy, onPressed: _submit),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 280),
                        child: _OrDivider(),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 320),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              texts.t(
                                'Pas encore de compte ?',
                                'No account yet?',
                              ),
                              style: theme.textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  FadeSlideRoute<void>(
                                    page: const SignupPage(),
                                  ),
                                );
                              },
                              child: Text(
                                texts.signup,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 360),
                        child: _DemoHint(
                          onPick: (c) {
                            _emailCtrl.text = c.email;
                            _passwordCtrl.text = c.password;
                          },
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
// Carte en verre dépoli contenant le formulaire.
// ---------------------------------------------------------------------------
class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.error,
    required this.child,
  });
  final GlobalKey<FormState> formKey;
  final String? error;
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
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(key: formKey, child: child),
    );
  }
}

// ---------------------------------------------------------------------------
// CTA connexion avec halo animé.
// ---------------------------------------------------------------------------
class _GlowCta extends StatefulWidget {
  const _GlowCta({required this.busy, required this.onPressed});
  final bool busy;
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
    final enabled = !widget.busy;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final glow = 0.26 + _c.value * 0.16;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF3F51B5).withValues(alpha: glow),
                      blurRadius: 22 + _c.value * 10,
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
            : const Icon(Icons.login_rounded),
        label: Text(
          widget.busy
              ? context.texts.t('Connexion…', 'Signing in…')
              : context.texts.login,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: const Color(0xFF3F51B5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            context.texts.t('ou', 'or'),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
      ],
    );
  }
}

class _DemoHint extends StatefulWidget {
  const _DemoHint({required this.onPick});
  final ValueChanged<DemoCredential> onPick;

  @override
  State<_DemoHint> createState() => _DemoHintState();
}

class _DemoHintState extends State<_DemoHint> {
  /// Les mots de passe ne s'affichent qu'à la demande : un écran de
  /// connexion peut être regardé à la dérobée (shoulder-surfing), et la
  /// présence d'un compte admin mérite un choix explicite plutôt
  /// qu'un affichage permanent.
  bool _reveal = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = context.texts;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  texts.t(
                    'Comptes de démonstration — touche un rôle pour '
                        'remplir les champs :',
                    'Demo accounts — tap a role to fill the fields:',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                tooltip: _reveal
                    ? texts.t('Masquer les mots de passe', 'Hide passwords')
                    : texts.t('Afficher les mots de passe', 'Show passwords'),
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _reveal = !_reveal),
                icon: Icon(
                  _reveal
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final c in AuthStore.demoCredentials)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => widget.onPick(c),
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    Icon(c.role.icon, size: 15, color: c.role.color),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 92,
                      child: Text(
                        switch (c.role) {
                          UserRole.student => texts.t('Étudiant', 'Student'),
                          UserRole.teacher => texts.t('Enseignant', 'Teacher'),
                          UserRole.admin => texts.t('Administrateur', 'Admin'),
                        },
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: c.role.color,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _reveal
                            ? '${c.email} · ${c.password}'
                            : '${c.email} · ••••••••',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets partagés entre login et signup.
// ---------------------------------------------------------------------------

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.size = 76});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.29),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF3F51B5), Color(0xFF7C4DFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F51B5).withValues(alpha: 0.35),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(Icons.school_rounded, color: Colors.white, size: size * 0.52),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.formKey,
    required this.busy,
    required this.error,
    required this.children,
  });

  final GlobalKey<FormState> formKey;
  final bool busy;
  final String? error;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...children,
            if (error != null && !busy) ...[
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: Motion.normal,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFC62828).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFC62828).withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFC62828),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: Color(0xFFB71C1C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.ctrl});
  final TextEditingController ctrl;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const <String>[AutofillHints.email],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: texts.t('prenom.nom@educoach.cm', 'first.last@educoach.cm'),
        prefixIcon: const Icon(Icons.alternate_email_rounded),
      ),
      validator: (v) {
        final s = (v ?? '').trim();
        if (s.isEmpty) return texts.t('Email requis.', 'Email required.');
        if (!s.contains('@') || !s.contains('.')) {
          return texts.t('Format email invalide.', 'Invalid email format.');
        }
        return null;
      },
    );
  }
}

/// Marque de marque Educoach utilisée en-tête de login/signup.
class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({super.key, this.size = 76});
  final double size;
  @override
  Widget build(BuildContext context) => _BrandMark(size: size);
}

/// Carte d'authentification partagée login/signup.
class AuthCardShell extends StatelessWidget {
  const AuthCardShell({
    super.key,
    required this.formKey,
    required this.busy,
    required this.error,
    required this.children,
  });

  final GlobalKey<FormState> formKey;
  final bool busy;
  final String? error;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      _AuthCard(formKey: formKey, busy: busy, error: error, children: children);
}

/// Divider "ou" partagé.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});
  @override
  Widget build(BuildContext context) => _OrDivider();
}

/// Champ email partagé.
class AuthEmailField extends StatelessWidget {
  const AuthEmailField({super.key, required this.ctrl});
  final TextEditingController ctrl;
  @override
  Widget build(BuildContext context) => _EmailField(ctrl: ctrl);
}

/// Champ mot de passe partagé.
class AuthPasswordField extends StatelessWidget {
  const AuthPasswordField({
    super.key,
    required this.ctrl,
    required this.obscure,
    required this.onToggle,
    this.label = 'Mot de passe',
    this.minLength = 4,
  });

  final TextEditingController ctrl;
  final bool obscure;
  final VoidCallback onToggle;
  final String label;
  final int minLength;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      autofillHints: const <String>[AutofillHints.password],
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: label == 'Mot de passe' ? texts.password : label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          ),
        ),
      ),
      validator: (v) {
        final s = v ?? '';
        if (s.isEmpty) {
          return texts.t('Mot de passe requis.', 'Password required.');
        }
        if (s.length < minLength) {
          return texts.t(
            'Trop court (min. $minLength caractères).',
            'Too short (min. $minLength characters).',
          );
        }
        return null;
      },
    );
  }
}
