import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/data/mock_data.dart';
import '../../core/models/models.dart';
import '../../core/session/auth_store.dart';
import '../../core/session/learning_store.dart';
import '../../core/session/session_store.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/course_card.dart';
import '../courses/course_detail_page.dart';
import '../subscription/subscription_banner.dart';

/// Onglet Accueil : message de bienvenue, filière courante, prochaine
/// séance, résumé chiffré, raccourcis et devoirs à venir.
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onOpenTab});

  final void Function(int index)? onOpenTab;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  String _todayLabel() {
    const days = <String>[
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche',
    ];
    const months = <String>[
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    final n = DateTime.now();
    return '${days[n.weekday - 1]} ${n.day} ${months[n.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final learning = LearningScope.of(context);
    final auth = AuthScope.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([session, learning, auth]),
      builder: (context, _) => _build(context, session, learning, auth),
    );
  }

  Widget _build(
    BuildContext context,
    SessionStore session,
    LearningStore learning,
    AuthStore auth,
  ) {
    final filiere = session.filiere;
    final activeCourses = session.activeCourses;
    final activeCodes = activeCourses.map((c) => c.code).toSet();

    final today = DateTime.now().weekday;
    final todayBlocks = MockData.scheduleForDay(today)
        .where((b) => activeCodes.contains(b.courseCode))
        .toList();
    final nextBlock = todayBlocks.isNotEmpty ? todayBlocks.first : null;

    // Avancement RÉEL dérivé des leçons validées (0 pour un nouvel inscrit).
    final topCourses =
        (activeCourses.toList()..sort(
              (a, b) => learning
                  .levelProgress([b.code])
                  .compareTo(learning.levelProgress([a.code])),
            ))
            .take(3)
            .toList();

    final upcoming = MockData.upcomingAssignmentsFor(activeCodes)
        .take(3)
        .toList();
    final gpa = learning.levelAverage(activeCodes);
    final weeklySessions = MockData.schedule
        .where((b) => activeCodes.contains(b.courseCode))
        .length;
    final user = auth.user;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            FadeSlideIn(
              child: _Header(
                greeting: _greeting(),
                today: _todayLabel(),
                name: user?.fullName ?? 'Étudiant·e',
                initials: user?.initials ?? 'E',
                onBell: () => _showReminders(context, upcoming),
                onOpenProfile: () => onOpenTab?.call(5),
              ),
            ),
            const SizedBox(height: 16),

            // Carte héro : filière courante (verrouillée) + niveau
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: _FiliereHero(filiere: filiere, level: session.level),
            ),
            const SizedBox(height: 12),

            // Bandeau d'abonnement : upsell Premium si palier gratuit,
            // rappel de l'échéance si l'élève est déjà abonné.
            const SubscriptionBanner(),
            const SizedBox(height: 12),

            // Progression vers le niveau suivant
            if (filiere != null)
              FadeSlideIn(
                delay: const Duration(milliseconds: 110),
                child: _ProgressionCard(
                  progress: learning.levelProgress(activeCodes),
                  average: gpa,
                  validated: learning.isLevelValidated(activeCodes),
                  nextLevel: session.nextLevel,
                  onAdvance: () {
                    final ok = session.advanceToNextLevel();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          ok
                              ? 'Félicitations ! Tu passes au niveau '
                                    '${session.level} 🎉'
                              : 'Termine tout le programme avec une moyenne '
                                    '≥ 10/20 pour débloquer le niveau suivant.',
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (filiere != null) const SizedBox(height: 12),

            if (nextBlock != null)
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: _NextClassCard(
                  block: nextBlock,
                  onOpenSchedule: () => onOpenTab?.call(3),
                ),
              )
            else
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: const _FreeDayCard(),
              ),
            const SizedBox(height: 16),

            // Résumé animé — chiffres réels
            FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: _StatsGrid(
                gpa: gpa,
                coursesCount: activeCourses.length,
                assignments: upcoming.length,
                sessions: weeklySessions,
              ),
            ),

            SectionHeader(
              title: 'Tes meilleurs avancements',
              actionLabel: 'Tout voir',
              onAction: () => onOpenTab?.call(1),
            ),
            if (topCourses.isEmpty)
              const EmptyState(
                icon: Icons.menu_book_rounded,
                title: 'Aucun cours dans ce niveau',
                message: 'Sélectionne une filière pour démarrer ton parcours.',
              )
            else
              Stagger(
                initialDelay: const Duration(milliseconds: 60),
                children: [
                  for (final c in topCourses)
                    CourseCard(
                      course: c,
                      compact: true,
                      onTap: () => Navigator.of(context).push(
                        FadeSlideRoute<void>(
                          page: CourseDetailPage(courseCode: c.code),
                        ),
                      ),
                    ),
                ],
              ),

            SectionHeader(
              title: 'Devoirs à rendre',
              subtitle: upcoming.isEmpty ? 'Rien de prévu' : null,
            ),
            if (upcoming.isEmpty)
              const EmptyState(
                icon: Icons.task_alt_rounded,
                title: 'Aucun devoir en attente',
                message: 'Profites-en pour avancer sur tes révisions.',
              )
            else
              Stagger(
                initialDelay: const Duration(milliseconds: 60),
                children: [
                  for (final a in upcoming) _AssignmentTile(assignment: a),
                ],
              ),
            const SizedBox(height: 24),
            _ShortcutsRow(onOpenTab: onOpenTab),
          ],
        ),
      ),
    );
  }

  void _showReminders(BuildContext context, List<Assignment> upcoming) {
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
                'Rappels',
                style: Theme.of(ctx).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Les rappels de cours et devoirs se gèrent dans '
                'Profil → Préférences.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (upcoming.isEmpty)
                const Text('Aucun devoir à venir. Bien joué ! 👌')
              else
                for (final a in upcoming)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.assignment_outlined),
                    title: Text(a.title),
                    subtitle: Text(a.courseCode),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.today,
    required this.name,
    required this.initials,
    required this.onBell,
    required this.onOpenProfile,
  });
  final String greeting;
  final String today;
  final String name;
  final String initials;
  final VoidCallback onBell;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        PressableScale(
          onTap: onOpenProfile,
          child: InitialsAvatar(initials: initials, size: 44),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                today,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        PressableScale(
          onTap: onBell,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Filière héro
// ---------------------------------------------------------------------------
class _FiliereHero extends StatelessWidget {
  const _FiliereHero({required this.filiere, required this.level});

  final Filiere? filiere;
  final String level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (filiere == null) {
      return const SizedBox.shrink();
    }
    final f = filiere!;
    return AnimatedGradientCard(
      colors: <Color>[
        f.color,
        Color.alphaBlend(Colors.white.withValues(alpha: 0.24), f.color),
      ],
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(f.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.domain.isEmpty ? 'Filière' : f.domain,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  f.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$level · ${MockData.coursesFor(filiereId: f.id, level: level).length} cours',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 15, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  'Verrouillée',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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

// ---------------------------------------------------------------------------
// Carte de progression vers le niveau suivant
// ---------------------------------------------------------------------------
class _ProgressionCard extends StatelessWidget {
  const _ProgressionCard({
    required this.progress,
    required this.average,
    required this.validated,
    required this.nextLevel,
    required this.onAdvance,
  });

  final double progress;
  final double average;
  final bool validated;
  final String? nextLevel;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAdvance = validated && nextLevel != null;
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
              Icon(
                Icons.trending_up_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Progression du niveau',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            validated
                ? (nextLevel == null
                      ? 'Programme terminé avec une moyenne ≥ '
                            '${LearningStore.passingAverage.toStringAsFixed(0)}/20. '
                            'Tu es au dernier niveau 🎓'
                      : 'Programme terminé avec succès. Tu peux passer au '
                            'niveau suivant.')
                : 'Termine toutes les leçons et obtiens une moyenne ≥ '
                      '${LearningStore.passingAverage.toStringAsFixed(0)}/20 '
                      'pour débloquer le niveau suivant.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canAdvance ? onAdvance : null,
              icon: Icon(
                canAdvance
                    ? Icons.arrow_forward_rounded
                    : Icons.lock_outline_rounded,
                size: 18,
              ),
              label: Text(
                nextLevel == null
                    ? 'Dernier niveau'
                    : 'Passer au niveau $nextLevel',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Prochaine séance
// ---------------------------------------------------------------------------
class _NextClassCard extends StatelessWidget {
  const _NextClassCard({required this.block, required this.onOpenSchedule});
  final ScheduleBlock block;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, size: 18),
              const SizedBox(width: 6),
              Text(
                'Prochaine séance',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            block.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${block.startHour}h – ${block.endHour}h  ·  ${block.room}  ·  ${block.type}',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: onOpenSchedule,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Voir le planning'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeDayCard extends StatelessWidget {
  const _FreeDayCard();

  @override
  Widget build(BuildContext context) {
    return GradientHeroCard(
      child: Row(
        children: [
          const Icon(Icons.self_improvement_rounded, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Aucune séance aujourd'hui. Profites-en pour réviser.",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat grid with animated counters
// ---------------------------------------------------------------------------
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.gpa,
    required this.coursesCount,
    required this.assignments,
    required this.sessions,
  });

  final double gpa;
  final int coursesCount;
  final int assignments;
  final int sessions;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.05,
      children: [
        _AnimatedStat(
          label: 'Moyenne',
          value: gpa,
          decimals: 2,
          suffix: ' / 20',
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF2E7D32),
        ),
        _AnimatedStat(
          label: 'Cours actifs',
          value: coursesCount.toDouble(),
          icon: Icons.menu_book_rounded,
        ),
        _AnimatedStat(
          label: 'Devoirs à rendre',
          value: assignments.toDouble(),
          icon: Icons.assignment_outlined,
          color: const Color(0xFFF9A825),
        ),
        _AnimatedStat(
          label: 'Séances semaine',
          value: sessions.toDouble(),
          icon: Icons.calendar_month_rounded,
          color: const Color(0xFF00ACC1),
        ),
      ],
    );
  }
}

class _AnimatedStat extends StatelessWidget {
  const _AnimatedStat({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.decimals = 0,
    this.suffix = '',
  });

  final String label;
  final double value;
  final IconData icon;
  final Color? color;
  final int decimals;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
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
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: c, size: 22),
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
                const SizedBox(height: 2),
                AnimatedCounter(
                  value: value,
                  decimals: decimals,
                  suffix: suffix,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: c,
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

// ---------------------------------------------------------------------------
// Assignment tile
// ---------------------------------------------------------------------------
class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({required this.assignment});

  final Assignment assignment;

  String _formatDate(DateTime d) {
    final diff = d.difference(DateTime.now()).inDays;
    if (diff < 0) return 'en retard';
    if (diff == 0) return "aujourd'hui";
    if (diff == 1) return 'demain';
    return 'dans $diff j';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = MockData.courseByCode(assignment.courseCode);
    final due = assignment.dueDate;
    return PressableScale(
      onTap: () {
        if (course == null) return;
        Navigator.of(context).push(
          FadeSlideRoute<void>(page: CourseDetailPage(courseCode: course.code)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (course?.color ?? theme.colorScheme.primary).withValues(
                  alpha: 0.14,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.assignment_outlined,
                color: course?.color ?? theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${assignment.courseCode} · ${_formatDate(due)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            PillBadge(
              label: _formatDate(due),
              color: due.difference(DateTime.now()).inDays <= 1
                  ? const Color(0xFFC62828)
                  : const Color(0xFFF9A825),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shortcuts row
// ---------------------------------------------------------------------------
class _ShortcutsRow extends StatelessWidget {
  const _ShortcutsRow({this.onOpenTab});
  final void Function(int)? onOpenTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <(IconData, String, int)>[
      (Icons.menu_book_rounded, 'Cours', 1),
      (Icons.event_rounded, 'Planning', 3),
      (Icons.insights_rounded, 'Notes', 4),
      (Icons.person_rounded, 'Profil', 5),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          for (final (i, it) in items.indexed)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 8),
                child: PressableScale(
                  onTap: () => onOpenTab?.call(it.$3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(it.$1, color: theme.colorScheme.primary),
                        const SizedBox(height: 6),
                        Text(
                          it.$2,
                          style: theme.textTheme.labelMedium,
                          textAlign: TextAlign.center,
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
