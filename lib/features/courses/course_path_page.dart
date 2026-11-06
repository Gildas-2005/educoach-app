import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/data/learning_seed.dart';
import '../../core/data/mock_data.dart';
import '../../core/models/learning_models.dart';
import '../../core/session/learning_store.dart';
import '../../core/widgets/aurora_backdrop.dart';
import '../chat/open_chat.dart';
import 'lesson_player_page.dart';

/// Parcours vertical type Duolingo pour un cours.
///
/// Chaque leçon est un gros bouton rond ; une ligne pointillée relie les
/// nœuds. Les leçons verrouillées sont grisées avec un cadenas, la leçon
/// "en cours" pulse doucement, et les semestres s'empilent à la suite.
class CoursePathPage extends StatefulWidget {
  const CoursePathPage({super.key, required this.courseCode});

  final String courseCode;

  @override
  State<CoursePathPage> createState() => _CoursePathPageState();
}

class _CoursePathPageState extends State<CoursePathPage> {
  final _scrollController = ScrollController();

  /// Leçon « en cours » : la première débloquée non terminée. Sert à
  /// référencer automatiquement la discussion posée depuis le parcours.
  (Unit, Lesson)? _currentLesson(
    List<Semester> semesters,
    LearningStore store,
  ) {
    for (final s in semesters) {
      for (final u in s.units) {
        for (final l in u.lessons) {
          final unlocked = store.isLessonUnlocked(
            s,
            u,
            l,
            allSemesters: semesters,
          );
          if (unlocked && !store.isLessonCompleted(l.id)) {
            return (u, l);
          }
        }
      }
    }
    // Tout terminé → on rattache à la dernière leçon de la dernière unité.
    final lastSem = semesters.last;
    final lastUnit = lastSem.units.last;
    return (lastUnit, lastUnit.lessons.last);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = LearningScope.of(context);
    final course = MockData.courseByCode(widget.courseCode);
    final semesters = LearningSeed.semestersFor(widget.courseCode);
    final progress = store.courseProgress(
      widget.courseCode,
      allSemesters: semesters,
    );
    final totalLessons = store.courseLessonCount(
      widget.courseCode,
      allSemesters: semesters,
    );

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Scaffold(
          body: Stack(
            children: [
              const AuroraBackdrop(
                primary: Color(0xFF3F51B5),
                accentA: Color(0xFF7C4DFF),
                accentB: Color(0xFF00BCD4),
                intensity: 0.7,
              ),
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: course?.color ?? theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    title: Text(
                      course?.title ?? 'Parcours',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Demander au prof',
                        onPressed: () {
                          final cur = _currentLesson(semesters, store);
                          if (cur == null) return;
                          openLessonChat(
                            context,
                            courseCode: widget.courseCode,
                            unit: cur.$1,
                            lesson: cur.$2,
                          );
                        },
                        icon: const Icon(Icons.help_outline_rounded),
                      ),
                      _PathStatChip(
                        icon: Icons.bolt_rounded,
                        label: '${store.totalXp}',
                        tooltip: 'XP total',
                      ),
                      _PathStatChip(
                        icon: Icons.favorite_rounded,
                        label: '${store.hearts}',
                        tooltip: 'Cœurs restants',
                      ),
                      _PathStatChip(
                        icon: Icons.local_fire_department_rounded,
                        label: '${store.streak}',
                        tooltip: 'Série en jours',
                      ),
                      const SizedBox(width: 4),
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(58),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Progression · ${(progress * 100).round()} % '
                                  '($totalLessons leçons)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: progress),
                                duration: Motion.slow,
                                curve: Motion.emphasized,
                                builder: (_, v, _) => LinearProgressIndicator(
                                  value: v,
                                  minHeight: 8,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.28,
                                  ),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        for (final (i, s) in semesters.indexed)
                          FadeSlideIn(
                            delay: Duration(milliseconds: 90 * i),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _SemesterBanner(
                                  semester: s,
                                  unlocked: store.isSemesterUnlocked(
                                    s,
                                    allSemesters: semesters,
                                  ),
                                  isLast: i == semesters.length - 1,
                                ),
                                const SizedBox(height: 6),
                                _SemesterPath(
                                  semester: s,
                                  allSemesters: semesters,
                                  accent:
                                      course?.color ??
                                      theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 18),
                              ],
                            ),
                          ),
                      ]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PathStatChip extends StatelessWidget {
  const _PathStatChip({
    required this.icon,
    required this.label,
    required this.tooltip,
  });
  final IconData icon;
  final String label;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SemesterBanner extends StatelessWidget {
  const _SemesterBanner({
    required this.semester,
    required this.unlocked,
    required this.isLast,
  });
  final Semester semester;
  final bool unlocked;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: unlocked
            ? LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.9),
                  theme.colorScheme.tertiary.withValues(alpha: 0.85),
                ],
              )
            : null,
        color: unlocked ? null : theme.colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
            color: unlocked ? Colors.white : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  semester.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: unlocked
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  unlocked
                      ? '${semester.units.length} unités · '
                            '${semester.units.expand((u) => u.lessons).length} leçons'
                      : 'Termine le semestre précédent pour débloquer',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: unlocked
                        ? Colors.white.withValues(alpha: 0.9)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!isLast && unlocked)
            Icon(
              Icons.arrow_downward_rounded,
              color: Colors.white.withValues(alpha: 0.8),
            ),
        ],
      ),
    );
  }
}

class _SemesterPath extends StatelessWidget {
  const _SemesterPath({
    required this.semester,
    required this.allSemesters,
    required this.accent,
  });
  final Semester semester;
  final List<Semester> allSemesters;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final store = LearningScope.of(context);
    final flat = <_Node>[];
    for (final u in semester.units) {
      flat.add(_Node.header(u));
      for (final l in u.lessons) {
        flat.add(_Node.lesson(u, l));
      }
    }
    // Localise la première leçon non-terminée mais débloquée : elle pulse.
    String? currentId;
    for (final n in flat) {
      if (n.lesson == null) continue;
      if (store.isLessonCompleted(n.lesson!.id)) continue;
      if (store.isLessonUnlocked(
        semester,
        n.unit!,
        n.lesson!,
        allSemesters: allSemesters,
      )) {
        currentId = n.lesson!.id;
        break;
      }
    }
    return Column(
      children: [
        for (final (i, n) in flat.indexed)
          Opacity(
            opacity:
                store.isSemesterUnlocked(semester, allSemesters: allSemesters)
                ? 1
                : 0.45,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: n.header != null
                  ? _UnitHeader(unit: n.header!)
                  : _LessonNode(
                      unit: n.unit!,
                      lesson: n.lesson!,
                      semester: semester,
                      allSemesters: allSemesters,
                      accent: accent,
                      isCurrent: n.lesson!.id == currentId,
                      isLast: i == flat.length - 1,
                    ),
            ),
          ),
      ],
    );
  }
}

class _Node {
  _Node.header(this.header) : unit = null, lesson = null;
  _Node.lesson(this.unit, this.lesson) : header = null;
  final Unit? header;
  final Unit? unit;
  final Lesson? lesson;
}

class _UnitHeader extends StatelessWidget {
  const _UnitHeader({required this.unit});
  final Unit unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: unit.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(unit.icon, size: 16, color: unit.color),
                const SizedBox(width: 6),
                Text(
                  unit.title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: unit.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              unit.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonNode extends StatelessWidget {
  const _LessonNode({
    required this.unit,
    required this.lesson,
    required this.semester,
    required this.allSemesters,
    required this.accent,
    required this.isCurrent,
    required this.isLast,
  });
  final Unit unit;
  final Lesson lesson;
  final Semester semester;
  final List<Semester> allSemesters;
  final Color accent;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = LearningScope.of(context);
    final done = store.isLessonCompleted(lesson.id);
    final unlocked =
        store.isSemesterUnlocked(semester, allSemesters: allSemesters) &&
        store.isLessonUnlocked(
          semester,
          unit,
          lesson,
          allSemesters: allSemesters,
        );
    final result = store.lessonResults[lesson.id];

    final nodeColor = done
        ? const Color(0xFF2E7D32)
        : unlocked
        ? accent
        : theme.colorScheme.outlineVariant;

    final node = Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? nodeColor
            : unlocked
            ? Colors.white
            : theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: nodeColor, width: unlocked && !done ? 3 : 2),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: nodeColor.withValues(alpha: done ? 0.35 : 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Icon(
        done
            ? Icons.star_rounded
            : unlocked
            ? (lesson.icon ?? Icons.play_arrow_rounded)
            : Icons.lock_rounded,
        color: done
            ? Colors.white
            : unlocked
            ? nodeColor
            : theme.colorScheme.onSurfaceVariant,
        size: 32,
      ),
    );

    Widget pulsing = node;
    if (isCurrent && !done) {
      pulsing = _Pulse(color: nodeColor, child: node);
    }
    if (unlocked) {
      pulsing = PressableScale(
        scale: 0.9,
        onTap: () => Navigator.of(context).push(
          FadeSlideRoute(
            page: LessonPlayerPage(
              lesson: lesson,
              semester: semester,
              unit: unit,
              allSemesters: allSemesters,
            ),
          ),
        ),
        child: pulsing,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: isLast ? const SizedBox() : _Connector(color: nodeColor),
        ),
        pulsing,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lesson.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: unlocked
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  done
                      ? '${result!.xpEarned} XP · '
                            '${(result.accuracy * 100).round()} %'
                      : unlocked
                      ? '+${lesson.xpReward} XP'
                      : 'Verrouillé',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: done
                        ? const Color(0xFF2E7D32)
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (unlocked)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        FadeSlideRoute(
                          page: LessonPlayerPage(
                            lesson: lesson,
                            semester: semester,
                            unit: unit,
                            allSemesters: allSemesters,
                          ),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(done ? 'Revoir' : 'Commencer'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Center(
        child: CustomPaint(
          size: const Size(6, 60),
          painter: _DottedLinePainter(color: color),
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  _DottedLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const dash = 6.0;
    const gap = 8.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + dash).clamp(0, size.height)),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter old) => old.color != color;
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.child, required this.color});
  final Widget child;
  final Color color;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 74 + 36 * t,
              height: 74 + 36 * t,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.5 * (1 - t)),
                  width: 3,
                ),
              ),
            ),
            Transform.scale(scale: 1 + 0.06 * t, child: child),
          ],
        );
      },
      child: widget.child,
    );
  }
}
