import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/widgets/aurora_backdrop.dart';
import '../auth/login_page.dart';
import '../auth/signup_page.dart';

/// Page d'accueil "pitch" : présente la marque Educoach et ses atouts,
/// puis oriente vers la connexion ou l'inscription.
///
/// La sélection de filière n'est PAS faite ici : elle intervient
/// uniquement après authentification, sur [FilierePickerPage].
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  static const routeName = '/welcome';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = context.texts;
    return Scaffold(
      body: Stack(
        children: [
          const AuroraBackdrop(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
              children: [
                const FadeSlideIn(child: _Logo()),
                const SizedBox(height: 28),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    'Educoach',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 180),
                  child: Text(
                    texts.t(
                      'Le compagnon de ta réussite.\n'
                          'Toutes tes filières, tous tes cours, ton planning, '
                          'tes notes et tes ressources — au même endroit.',
                      'The companion of your success.\n'
                          'All your programs, courses, schedule, grades and '
                          'resources — in one place.',
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _FeatureRow(
                  icon: Icons.category_rounded,
                  title: texts.t(
                    'Plus de 40 filières',
                    'Over 40 academic programs',
                  ),
                  subtitle: texts.t(
                    'Sciences, droit, médecine, gestion, lettres…',
                    'Science, law, medicine, business, arts…',
                  ),
                  delay: 220,
                ),
                const SizedBox(height: 12),
                _FeatureRow(
                  icon: Icons.menu_book_rounded,
                  title: texts.t(
                    'Des centaines de cours',
                    'Hundreds of courses',
                  ),
                  subtitle: texts.t(
                    'Fiches, ressources, professeurs et ECTS.',
                    'Notes, resources, teachers and ECTS credits.',
                  ),
                  delay: 280,
                ),
                const SizedBox(height: 12),
                _FeatureRow(
                  icon: Icons.event_available_rounded,
                  title: texts.t(
                    'Planning & devoirs',
                    'Schedule & assignments',
                  ),
                  subtitle: texts.t(
                    'Ne rate plus jamais une séance ni une remise.',
                    'Never miss a class or a deadline again.',
                  ),
                  delay: 340,
                ),
                const SizedBox(height: 32),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 420),
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context)
                          .push(FadeSlideRoute<void>(page: const SignupPage()));
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      texts.t('Créer mon compte', 'Create my account'),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 480),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context)
                          .push(FadeSlideRoute<void>(page: const LoginPage()));
                    },
                    icon: const Icon(Icons.login_rounded),
                    label: Text(
                      texts.t("J'ai déjà un compte", 'I\'m already a member'),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    texts.t(
                      'En continuant, tu acceptes nos conditions d\'utilisation.',
                      'By continuing, you accept our terms of use.',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF3F51B5), Color(0xFF7C4DFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F51B5).withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Icon(Icons.school_rounded, color: Colors.white, size: 52),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.delay,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeSlideIn(
      delay: Duration(milliseconds: delay),
      offset: const Offset(0, 0.1),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
