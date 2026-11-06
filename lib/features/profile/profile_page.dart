import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/data/mock_data.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/session/auth_store.dart';
import '../../core/session/learning_store.dart';
import '../../core/session/legal_store.dart';
import '../../core/session/locale_store.dart';
import '../../core/session/session_coordinator.dart';
import '../../core/session/session_store.dart';
import '../../core/session/subscription_store.dart';
import '../../core/session/theme_store.dart';
import '../../core/widgets/common_widgets.dart';
import '../legal/legal_content.dart';
import '../legal/legal_document_page.dart';
import '../onboarding/welcome_page.dart';
import '../subscription/subscription_page.dart';

/// Onglet Profil : identité réelle, statistiques issues de la progression
/// réelle, filière verrouillée, préférences fonctionnelles et compte.
///
/// Tout est câblé : les commutateurs écrivent dans [ThemeStore] et
/// [LegalStore], les tuiles naviguent ou ouvrent des feuilles d'action,
/// et les compteurs (moyenne, ECTS, XP, série) partent de 0 pour un newly
/// inscrit et montent à mesure qu'il valide des leçons.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = AuthScope.of(context);
    final session = SessionScope.of(context);
    final learning = LearningScope.of(context);
    final legal = LegalScope.of(context);
    final appearance = ThemeScope.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([auth, session, learning, legal, appearance]),
      builder: (context, _) {
        final user = auth.user;
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Session fermée.')));
        }
        final f = session.filiere;
        final codes = session.activeCourseCodes;
        final allFiliereCodes = session.allFiliereCourses
            .map((c) => c.code)
            .toList();
        final moyenne = learning.levelAverage(codes);
        final ects = learning.ectsValidated(allFiliereCodes);
        final totalCredits = allFiliereCodes.fold<int>(
          0,
          (s, c) => s + _creditsOf(c),
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Profil',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: 'Modifier mon profil',
                onPressed: () => _openEditSheet(context, auth),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              FadeSlideIn(
                child: _IdentityCard(
                  user: user,
                  subtitle: f == null
                      ? 'Aucune filière sélectionnée'
                      : '${f.name} · ${session.level}',
                  filiereColor: f?.color,
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Row(
                  children: [
                    Expanded(
                      child: _AnimatedStatChip(
                        label: 'Moyenne du niveau',
                        value: moyenne.toStringAsFixed(2),
                        caption: '/ 20',
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AnimatedStatChip(
                        label: 'ECTS validés',
                        value: '$ects',
                        caption: 'sur $totalCredits',
                        icon: Icons.workspace_premium_rounded,
                        color: const Color(0xFF7C4DFF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 110),
                child: Row(
                  children: [
                    Expanded(
                      child: _AnimatedStatChip(
                        label: 'XP total',
                        value: '${learning.totalXp}',
                        icon: Icons.bolt_rounded,
                        color: const Color(0xFFF9A825),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AnimatedStatChip(
                        label: 'Série',
                        value: '${learning.streak}',
                        caption: 'jour(s)',
                        icon: Icons.local_fire_department_rounded,
                        color: const Color(0xFFEF6C00),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (f != null)
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: _FiliereSummaryCard(
                    progress: learning.levelProgress(codes),
                    validated: learning.isLevelValidated(codes),
                    nextLevel: session.nextLevel,
                  ),
                ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Année 2025-2026 · Semestre 2',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              const SectionHeader(title: 'Préférences'),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Mode sombre',
                      subtitle: appearance.isDark
                          ? 'Interface sombre active'
                          : 'Interface claire (suivant le système : '
                                '${appearance.mode.name})',
                      trailing: Switch(
                        value: appearance.isDark,
                        onChanged: (_) => appearance.toggleDark(),
                      ),
                    ),
                    _ProfileTile(
                      icon: Icons.translate_rounded,
                      title: 'Langue de l\'application',
                      subtitle: context.appLanguage.nativeLabel,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showLanguageSheet(context),
                    ),
                    _ProfileTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Rappels de cours et devoirs',
                      subtitle:
                          'Notifications dans l\'app · désactivable ici '
                          'à tout moment',
                      trailing: Switch(
                        value: legal.consentNotifications,
                        onChanged: (v) => legal.setNotifications(v),
                      ),
                    ),
                    _ProfileTile(
                      icon: Icons.school_outlined,
                      title: 'Parcours actuel',
                      trailing: Text(
                        f == null
                            ? 'Aucune filière'
                            : '${f.name} · ${session.level}',
                      ),
                    ),
                  ],
                ),
              ),

              const SectionHeader(title: 'Mes données'),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.folder_open_outlined,
                      title: 'Mes ressources de cours',
                      subtitle: _resourcesCaption(f?.name),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showResourcesSheet(context),
                    ),
                    _ProfileTile(
                      icon: Icons.history_rounded,
                      title: 'Historique de mes notes',
                      subtitle: learning.learnerGrades(allFiliereCodes).isEmpty
                          ? 'Aucune note pour l\'instant'
                          : '${learning.learnerGrades(allFiliereCodes).length} '
                                'cours évalué(s)',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showGradesHistorySheet(
                        context,
                        learning,
                        allFiliereCodes,
                      ),
                    ),
                    _ProfileTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Aide & tutoriels',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showHelpSheet(context),
                    ),
                  ],
                ),
              ),

              const SectionHeader(title: 'Compte'),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Informations du compte',
                      subtitle: user.email,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _openEditSheet(context, auth),
                    ),
                    _ProfileTile(
                      icon: Icons.lock_reset_rounded,
                      title: 'Changer mon mot de passe',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _openPasswordSheet(context, auth),
                    ),
                    AnimatedBuilder(
                      animation: SubscriptionStore.instance,
                      builder: (context, _) => _ProfileTile(
                        icon: Icons.workspace_premium_rounded,
                        title: context.texts.t('Abonnement', 'Subscription'),
                        subtitle: switch (SubscriptionStore.instance.tier) {
                          SubscriptionTier.discovery => context.texts.t(
                            'Palier gratuit Découverte · passer à Premium',
                            'Free Discovery plan · upgrade to Premium',
                          ),
                          SubscriptionTier.premium => context.texts.t(
                            'Premium actif',
                            'Premium active',
                          ),
                          SubscriptionTier.excellence => context.texts.t(
                            'Excellence actif',
                            'Excellence active',
                          ),
                        },
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          FadeSlideRoute<void>(page: const SubscriptionPage()),
                        ),
                      ),
                    ),
                    _ProfileTile(
                      icon: Icons.description_outlined,
                      title: 'Conditions & confidentialité',
                      subtitle: 'Loi camerounaise 2010/012 Livre V',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        FadeSlideRoute<void>(
                          page: LegalDocumentPage(document: privacyDocument),
                        ),
                      ),
                    ),
                    _ProfileTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Filière verrouillée',
                      subtitle: f == null
                          ? 'Aucune filière choisie'
                          : '${f.name} — le choix de filière est définitif, '
                                'tu progresses niveau par niveau',
                    ),
                    _ProfileTile(
                      icon: Icons.logout_rounded,
                      title: 'Se déconnecter',
                      color: const Color(0xFFC62828),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _confirmLogout(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Educoach · v1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static int _creditsOf(String code) =>
      MockData.courseByCode(code)?.credits ?? 0;

  static String _resourcesCaption(String? filiereName) => filiereName == null
      ? 'Choisis une filière pour voir tes supports'
      : 'PDF, slides et vidéos de ta filière $filiereName';

  // ---------------------------------------------------------------------------
  // Feuilles d'action fonctionnelles
  // ---------------------------------------------------------------------------

  void _openEditSheet(BuildContext context, AuthStore auth) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _EditProfileSheet(user: auth.user!),
      ),
    );
  }

  void _openPasswordSheet(BuildContext context, AuthStore auth) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _ChangePasswordSheet(auth: auth),
      ),
    );
  }

  void _showResourcesSheet(BuildContext context) {
    final session = SessionScope.of(context);
    final courses = session.activeCourses;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: courses.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun cours pour ce niveau — choisis une filière '
                  'pour démarrer.',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text(
                    'Mes ressources',
                    style: Theme.of(ctx).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  for (final c in courses)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: c.color.withValues(alpha: 0.14),
                        child: Icon(c.icon, color: c.color, size: 20),
                      ),
                      title: Text(c.title),
                      subtitle: Text(
                        '${c.code} · '
                        '${MockData.resourcesFor(c.code).length} '
                        'ressource(s)',
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  void _showGradesHistorySheet(
    BuildContext context,
    LearningStore learning,
    List<String> allCodes,
  ) {
    final grades = learning.learnerGrades(allCodes)
      ..sort((a, b) => b.date.compareTo(a.date));
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: grades.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 40,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tes notes apparaîtront ici dès que tu auras validé '
                      'tes premières leçons. Tout part de 0 et monte avec '
                      'ta progression. 💪',
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              )
            : ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text(
                    'Historique des notes',
                    style: Theme.of(ctx).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  for (final g in grades)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF2E7D32)
                            .withValues(alpha: 0.12),
                        child: Text(
                          g.noteSur20.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      title: Text('${g.courseCode} · ${g.label}'),
                      subtitle: Text('Pondération ${g.weight.toInt()} ECTS'),
                    ),
                ],
              ),
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aide & tutoriels',
                style: Theme.of(ctx).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const _HelpLine(
                icon: Icons.school_rounded,
                text: 'Choisis ta filière une fois : elle est définitive.',
              ),
              const _HelpLine(
                icon: Icons.check_circle_rounded,
                text:
                    'Valide 100 % des leçons d\'un niveau avec une moyenne '
                    '≥ 10/20 pour débloquer le niveau suivant.',
              ),
              const _HelpLine(
                icon: Icons.favorite_rounded,
                text:
                    'Tes notes, ECTS et XP partent de 0 et suivent ta '
                    'progression réelle.',
              ),
              const _HelpLine(
                icon: Icons.notifications_active_outlined,
                text: 'Active ou coupe les rappels dans Préférences.',
              ),
              const SizedBox(height: 10),
              Text(
                'Une question de compte ? contact@educoach.cm',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Feuille de choix de la langue — bascule FR ⇄ EN appliquée à tout
  /// de suite (le [LocaleScope] notifie tous les widgets dépendants).
  void _showLanguageSheet(BuildContext context) {
    final store = LocaleScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: RadioGroup<AppLanguage>(
          groupValue: store.language,
          onChanged: (v) {
            if (v != null) store.setLanguage(v);
            Navigator.of(ctx).pop();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  'Choisir la langue',
                  style: Theme.of(ctx).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              for (final l in AppLanguage.values)
                RadioListTile<AppLanguage>(
                  value: l,
                  title: Text('${l.flag}  ${l.nativeLabel}'),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Tu devras te reconnecter pour accéder à tes cours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Purge complète : plus aucune donnée de ce compte ne
              // reste en mémoire pour le compte suivant.
              SessionCoordinator.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                FadeSlideRoute<void>(page: const WelcomePage(), reverse: true),
                (route) => false,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}

/// Widgets communs du profil.

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.user,
    required this.subtitle,
    this.filiereColor,
  });

  final AuthUser user;
  final String subtitle;
  final Color? filiereColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = user.accent;
    final colors = filiereColor == null
        ? <Color>[
            accent,
            Color.alphaBlend(Colors.white.withValues(alpha: 0.24), accent),
          ]
        : <Color>[
            filiereColor!,
            Color.alphaBlend(
              Colors.white.withValues(alpha: 0.24),
              filiereColor!,
            ),
          ];
    return AnimatedGradientCard(
      colors: colors,
      child: Row(
        children: [
          Hero(
            tag: 'profile-avatar',
            child: InitialsAvatar(
              initials: user.initials,
              size: 60,
              background: Colors.white.withValues(alpha: 0.24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.role.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                if (user.about.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    user.about,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStatChip extends StatelessWidget {
  const _AnimatedStatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    if (caption != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        caption!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de filière — verrouillée, avec progression vers le niveau suivant.
class _FiliereSummaryCard extends StatelessWidget {
  const _FiliereSummaryCard({
    required this.progress,
    required this.validated,
    this.nextLevel,
  });

  final double progress;
  final bool validated;
  final String? nextLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = SessionScope.of(context);
    final f = session.filiere!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: f.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(f.icon, color: f.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filière (choix définitif)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${f.name} · ${session.level}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.lock_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: f.color.withValues(alpha: 0.10),
              color: f.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            validated
                ? (nextLevel == null
                      ? 'Programme terminé 🎓 — dernier niveau atteint.'
                      : 'Programme validé ✨ — passe au niveau $nextLevel '
                            'depuis l\'accueil.')
                : 'Programme du niveau complété à '
                      '${(progress * 100).round()} % — termine toutes les '
                      'leçons avec une moyenne ≥ 10/20 pour progresser.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(icon, color: c, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpLine extends StatelessWidget {
  const _HelpLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feuille « Modifier mon profil » — personnalisation réelle.
// ---------------------------------------------------------------------------
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user});
  final AuthUser user;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final _firstCtrl = TextEditingController(text: widget.user.firstName);
  late final _lastCtrl = TextEditingController(text: widget.user.lastName);
  late final _phoneCtrl = TextEditingController(text: widget.user.phone);
  late final _aboutCtrl = TextEditingController(text: widget.user.about);
  late int _accent = widget.user.accentValue;

  static const _swatches = <int>[
    0xFF3F51B5,
    0xFF00897B,
    0xFF7C4DFF,
    0xFFC2185B,
    0xFFEF6C00,
    0xFF2E7D32,
    0xFF0097A7,
    0xFF5D4037,
  ];

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    _aboutCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final auth = AuthScope.of(context);
    auth.updateProfile(
      firstName: _firstCtrl.text,
      lastName: _lastCtrl.text,
      phone: _phoneCtrl.text,
      about: _aboutCtrl.text,
      accentValue: _accent,
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Profil mis à jour ✅'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Modifier mon profil',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.user.email,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _firstCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Prénom'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _lastCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Nom'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  hintText: '+237 6 XX XX XX XX',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _aboutCtrl,
                maxLines: 3,
                maxLength: 160,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Quelques mots sur toi…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Couleur d\'avatar',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final swatch in _swatches)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: GestureDetector(
                        onTap: () => setState(() => _accent = swatch),
                        child: AnimatedContainer(
                          duration: Motion.fast,
                          width: _accent == swatch ? 40 : 32,
                          height: _accent == swatch ? 40 : 32,
                          decoration: BoxDecoration(
                            color: Color(swatch),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _accent == swatch
                                  ? theme.colorScheme.onSurface
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: _accent == swatch
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Enregistrer'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feuille « Changer mon mot de passe ».
// ---------------------------------------------------------------------------
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.auth});
  final AuthStore auth;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await widget.auth.changePassword(
      currentPassword: _currentCtrl.text,
      newPassword: _newCtrl.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Mot de passe changé 🔒'),
        ),
      );
    } else {
      setState(() => _error = widget.auth.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Changer mon mot de passe',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                helperText: '8 caractères min., 1 lettre et 1 chiffre',
                prefixIcon: Icon(Icons.lock_reset_rounded),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFFC62828),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: const Text('Confirmer'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
