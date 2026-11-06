import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/data/learning_seed.dart';
import '../../core/data/mock_data.dart';
import '../../core/models/learning_models.dart';
import '../../core/models/models.dart';
import '../../core/session/learning_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import 'course_path_page.dart';
import 'lesson_player_page.dart';

/// Fiche détaillée d'un cours.
///
/// - En-téro héro avec transitions (Hero) depuis la carte listée.
/// - Sous-onglets : Aperçu · Ressources · Notes · Devoirs
/// - Animations d'entrée échelonnées et retours visuels au tap.
class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({super.key, required this.courseCode});

  final String courseCode;

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final course = MockData.courseByCode(widget.courseCode);
    if (course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cours introuvable')),
        body: const EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Cours introuvable',
          message: 'Ce cours n\'existe plus ou n\'a pas pu être chargé.',
        ),
      );
    }

    final accent = course.color;
    final learning = LearningScope.of(context);
    return AnimatedBuilder(
      animation: learning,
      builder: (context, _) {
        final grades = learning.learnerGradesFor(course.code);
        final avg = grades.isEmpty
            ? null
            : grades.map((g) => g.noteSur20).reduce((a, b) => a + b) /
                  grades.length;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 220,
                backgroundColor: accent,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.share_rounded),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _AnimatedHeader(course: course, average: avg),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeSlideIn(
                        child: Row(
                          children: [
                            Expanded(
                              child: _MiniStat(
                                label: 'Avancement',
                                value: '${(course.progress * 100).round()} %',
                                color: accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniStat(
                                label: 'ECTS',
                                value: '${course.credits}',
                                color: accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniStat(
                                label: 'Volume hebdo',
                                value: '${course.weeklyHours}h',
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 90),
                        child: _SubTabBar(
                          index: _tab,
                          color: accent,
                          onChanged: (i) => setState(() => _tab = i),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: Motion.normal,
                        switchInCurve: Motion.emphasized,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.05),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey<int>(_tab),
                          child: _buildTabContent(course),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabContent(Course course) {
    switch (_tab) {
      case 0:
        return _OverviewTab(course: course);
      case 1:
        return _LearnTab(course: course);
      case 2:
        return _ResourcesTab(course: course);
      case 3:
        return _GradesTab(course: course);
      case 4:
        return _AssignmentsTab(course: course);
    }
    return const SizedBox.shrink();
  }
}

/// En-tête Sliver avec dégradé animé, titre Hero et avatar animé.
class _AnimatedHeader extends StatelessWidget {
  const _AnimatedHeader({required this.course, required this.average});
  final Course course;
  final double? average;

  @override
  Widget build(BuildContext context) {
    final accent = course.color;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent,
            Color.alphaBlend(Colors.white.withValues(alpha: 0.24), accent),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                Hero(
                  tag: HeroCourse.icon(course.code),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(course.icon, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  course.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                if (average != null)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    offset: const Offset(0, 0.2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          AnimatedCounter(
                            value: average!,
                            decimals: 2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Hero(
              tag: HeroCourse.title(course.code),
              child: Material(
                type: MaterialType.transparency,
                child: Text(
                  course.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${course.teacher}  ·  ${course.semester}'
              '${course.level.isNotEmpty ? '  ·  ${course.level}' : ''}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubTabBar extends StatelessWidget {
  const _SubTabBar({
    required this.index,
    required this.color,
    required this.onChanged,
  });
  final int index;
  final Color color;
  final ValueChanged<int> onChanged;

  static const _labels = <String>[
    'Aperçu',
    'Apprendre',
    'Ressources',
    'Notes',
    'Devoirs',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          for (final (i, label) in _labels.indexed)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: Motion.fast,
                  curve: Motion.emphasized,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index
                        ? color.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: Motion.fast,
                    style: TextStyle(
                      fontSize: 13,
                      color: i == index
                          ? color
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: i == index
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                    child: Text(label),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeSlideIn(
          child: Text(
            'Description',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: Text(
            course.description.isEmpty
                ? 'Aucune description fournie pour ce cours.'
                : course.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 120),
          child: Text(
            'Progression',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: course.progress),
            duration: Motion.slow,
            curve: Motion.emphasized,
            builder: (_, v, _) =>
                ProgressBar(value: v, color: course.color, height: 10),
          ),
        ),
        const SizedBox(height: 6),
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: Text(
            'Chapitres validés : ${course.progress > 0.7 ? "8/10" : "5/12"}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 240),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    FadeSlideRoute(
                      page: CoursePathPage(courseCode: course.code),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Reprendre'),
                  style: FilledButton.styleFrom(backgroundColor: course.color),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('Notes'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResourcesTab extends StatelessWidget {
  const _ResourcesTab({required this.course});
  final Course course;

  static IconData _iconFor(String kind) => switch (kind) {
    'pdf' => Icons.picture_as_pdf_rounded,
    'video' => Icons.play_circle_fill_rounded,
    'slide' => Icons.slideshow_rounded,
    'audio' => Icons.graphic_eq_rounded,
    _ => Icons.link_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = MockData.resourcesFor(course.code);
    if (list.isEmpty) {
      return const EmptyState(
        icon: Icons.folder_open_rounded,
        title: 'Aucune ressource',
        message: 'Les documents publiés par l\'enseignant apparaîtront ici.',
      );
    }
    return Stagger(
      children: [
        for (final r in list)
          PressableScale(
            onTap: () => _openResourceSheet(context, r, course.color),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: course.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconFor(r.kind), color: course.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            r.kind.toUpperCase(),
                            if (r.sizeLabel.isNotEmpty) r.sizeLabel,
                            _rel(r.updatedAt),
                          ].join('  ·  '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.download_rounded),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _rel(DateTime d) {
    final days = DateTime.now().difference(d).inDays;
    if (days <= 0) return 'aujourd\'hui';
    if (days == 1) return 'hier';
    if (days < 30) return 'il y a $days j';
    return '${d.day}/${d.month}';
  }
}

class _GradesTab extends StatelessWidget {
  const _GradesTab({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final learning = LearningScope.of(context);
    return ListenableBuilder(
      listenable: learning,
      builder: (context, _) {
        final list = learning.learnerGradesFor(course.code);
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.insights_rounded,
            title: 'Pas encore de note',
            message: 'Valide des leçons pour voir ta note apparaître ici.',
          );
        }
        return Stagger(
          children: [
            for (final g in list)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${g.date.day.toString().padLeft(2, '0')}/'
                            '${g.date.month.toString().padLeft(2, '0')}'
                            '  ·  coeff ${g.weight}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: g.ratio),
                            duration: Motion.slow,
                            curve: Motion.emphasized,
                            builder: (_, v, _) => ProgressBar(
                              value: v,
                              color: EducoachColors.forProgress(g.ratio),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedCounter(
                      value: g.score,
                      decimals: g.score % 1 == 0 ? 0 : 1,
                      suffix: '/${g.max.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: EducoachColors.forProgress(g.ratio),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AssignmentsTab extends StatelessWidget {
  const _AssignmentsTab({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = MockData.assignmentsFor(course.code);
    final homeworks = LearningSeed.homeworkFor(course.code);
    if (list.isEmpty && homeworks.isEmpty) {
      return const EmptyState(
        icon: Icons.task_alt_rounded,
        title: 'Aucun devoir',
        message: 'Cette matière ne comporte pas encore de travail à rendre.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (homeworks.isNotEmpty) ...[
          Text(
            'Devoirs Educoach',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Stagger(
            children: [
              for (final hw in homeworks) _HomeworkTile(hw: hw, course: course),
            ],
          ),
          const SizedBox(height: 18),
        ],
        if (list.isNotEmpty) ...[
          Text(
            'Travaux maison annoncees',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Stagger(
            children: [for (final a in list) _AssignmentTile(assignment: a)],
          ),
        ],
      ],
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({required this.assignment});
  final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = assignment;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: Motion.fast,
            child: Icon(
              a.done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              key: ValueKey<bool>(a.done),
              color: a.done
                  ? const Color(0xFF2E7D32)
                  : theme.colorScheme.outline,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: a.done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'À rendre le ${a.dueDate.day}/${a.dueDate.month}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          PillBadge(
            label: a.done ? 'Fait' : 'À faire',
            color: a.done ? const Color(0xFF2E7D32) : const Color(0xFFF9A825),
          ),
        ],
      ),
    );
  }
}

class _HomeworkTile extends StatelessWidget {
  const _HomeworkTile({required this.hw, required this.course});
  final Homework hw;
  final Course course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = LearningScope.of(context);
    final done = store.homeworkResults[hw.id];
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: done != null
                ? const Color(0xFF2E7D32).withValues(alpha: 0.4)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_rounded, color: course.color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hw.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                PillBadge(
                  label: done != null
                      ? '${(done.accuracy * hw.points).round()}/${hw.points}'
                      : '${hw.points} pts',
                  color: done != null ? const Color(0xFF2E7D32) : course.color,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              hw.instruction,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Limite : ${hw.dueDate.day}/${hw.dueDate.month}/${hw.dueDate.year}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    FadeSlideRoute(
                      page: _HomeworkRunner(hw: hw, course: course),
                    ),
                  ),
                  icon: Icon(
                    done != null
                        ? Icons.replay_rounded
                        : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(done != null ? 'Refaire' : 'Commencer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Lancer un devoir : meme moteur que la leçon, sans partie théorique.
class _HomeworkRunner extends StatelessWidget {
  const _HomeworkRunner({required this.hw, required this.course});
  final Homework hw;
  final Course course;

  @override
  Widget build(BuildContext context) {
    final lesson = Lesson(
      id: hw.id,
      courseCode: hw.courseCode,
      unitId: 'devoirs',
      title: hw.title,
      subtitle: hw.instruction,
      theory: const [],
      examples: const [],
      exercises: hw.exercises,
      xpReward: hw.points,
      icon: Icons.assignment_rounded,
    );
    final dummyUnit = Unit(
      id: 'devoirs',
      semesterId: 'devoirs',
      title: 'Devoir',
      subtitle: '',
      color: course.color,
      icon: Icons.assignment_rounded,
      lessons: [lesson],
    );
    final dummySem = Semester(
      id: 'devoirs',
      courseCode: hw.courseCode,
      index: 0,
      label: 'Devoir note',
      units: [dummyUnit],
    );
    return LessonPlayerPage(
      lesson: lesson,
      unit: dummyUnit,
      semester: dummySem,
      allSemesters: [dummySem],
    );
  }
}

/// Sous-onglet "Apprendre" : résumé du parcours et bouton d'accès.
class _LearnTab extends StatelessWidget {
  const _LearnTab({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = LearningScope.of(context);
    final semesters = LearningSeed.semestersFor(course.code);
    final totalLessons = store.courseLessonCount(
      course.code,
      allSemesters: semesters,
    );
    final progress = store.courseProgress(course.code, allSemesters: semesters);
    final xp = store.xpForCourse(course.code);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    course.color,
                    Color.alphaBlend(
                      Colors.white.withValues(alpha: 0.22),
                      course.color,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.route_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Parcours d\'apprentissage',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${semesters.length} semestre(s) · '
                                '$totalLessons leçons · +$xp XP',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.28),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(progress * 100).round()} % du parcours validé',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        FadeSlideRoute(
                          page: CoursePathPage(courseCode: course.code),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        progress == 0
                            ? 'Demarrer le parcours'
                            : 'Continuer mon parcours',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: course.color,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: Text(
              'Semestres',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Stagger(
            children: [
              for (final s in semesters)
                _SemesterPreviewTile(
                  semester: s,
                  unlocked: store.isSemesterUnlocked(
                    s,
                    allSemesters: semesters,
                  ),
                  completed: store.isSemesterCompleted(s),
                  onTap: () => Navigator.of(context).push(
                    FadeSlideRoute(
                      page: CoursePathPage(courseCode: course.code),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SemesterPreviewTile extends StatelessWidget {
  const _SemesterPreviewTile({
    required this.semester,
    required this.unlocked,
    required this.completed,
    required this.onTap,
  });
  final Semester semester;
  final bool unlocked;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessons = semester.units.expand((u) => u.lessons).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: unlocked ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: unlocked
                ? Colors.white
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: completed
                  ? const Color(0xFF2E7D32)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      (completed
                              ? const Color(0xFF2E7D32)
                              : theme.colorScheme.primary)
                          .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  completed
                      ? Icons.verified_rounded
                      : unlocked
                      ? Icons.school_rounded
                      : Icons.lock_rounded,
                  color: completed
                      ? const Color(0xFF2E7D32)
                      : unlocked
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      semester.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      unlocked
                          ? '${semester.units.length} unités · $lessons leçons'
                          : 'Semestre précédent à terminer',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (unlocked)
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Feuille « visionneuse » d'une ressource pédagogique : métadonnées,
/// téléchargement simulé avec progression réelle, puis ouverture
/// (démo hors-ligne : aucun fichier n'est réellement produit).
void _openResourceSheet(BuildContext context, CourseResource r, Color color) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 2, 22, 26),
        child: _ResourceViewer(resource: r, color: color),
      ),
    ),
  );
}

class _ResourceViewer extends StatefulWidget {
  const _ResourceViewer({required this.resource, required this.color});
  final CourseResource resource;
  final Color color;

  @override
  State<_ResourceViewer> createState() => _ResourceViewerState();
}

class _ResourceViewerState extends State<_ResourceViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed) setState(() => _downloaded = true);
      });
  bool _downloaded = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  IconData get _icon => switch (widget.resource.kind) {
    'pdf' => Icons.picture_as_pdf_rounded,
    'video' => Icons.play_circle_fill_rounded,
    'slide' => Icons.slideshow_rounded,
    'audio' => Icons.graphic_eq_rounded,
    _ => Icons.link_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.resource;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_icon, color: widget.color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    [
                      r.kind.toUpperCase(),
                      if (r.sizeLabel.isNotEmpty) r.sizeLabel,
                      '${r.updatedAt.day}/${r.updatedAt.month}/'
                          '${r.updatedAt.year}',
                    ].join('  ·  '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Faux aperçu : un cadre qui rappelle l'aperçu du document.
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withValues(alpha: 0.25)),
          ),
          child: Icon(
            _icon,
            size: 46,
            color: widget.color.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final running = _c.isAnimating;
            return Column(
              children: [
                if (running || _downloaded) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _downloaded ? 1 : _c.value,
                      minHeight: 6,
                      color: widget.color,
                      backgroundColor: widget.color.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: running
                        ? null
                        : () {
                            if (_downloaded) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    'Ouverture de la ressource (démo '
                                    'hors-ligne).',
                                  ),
                                ),
                              );
                              Navigator.of(context).pop();
                            } else {
                              _c.forward(from: 0);
                            }
                          },
                    icon: Icon(
                      _downloaded
                          ? Icons.open_in_new_rounded
                          : Icons.download_rounded,
                    ),
                    label: Text(
                      _downloaded
                          ? 'Ouvrir'
                          : running
                          ? 'Téléchargement…'
                          : 'Télécharger',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: widget.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
