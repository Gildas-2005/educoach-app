import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/data/mock_data.dart';
import '../../core/models/models.dart';
import '../../core/session/learning_store.dart';
import '../../core/session/session_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../courses/course_detail_page.dart';

/// Onglet Notes : moyenne héro, histogramme animé par cours et liste
/// des évaluations, le tout dérivé de la progression RÉELLE de l'apprenant
/// (compteurs à 0 pour un nouvel inscrit).
class GradesPage extends StatelessWidget {
  const GradesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final learning = LearningScope.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([session, learning]),
      builder: (context, _) => _build(context, session, learning),
    );
  }

  Widget _build(
    BuildContext context,
    SessionStore session,
    LearningStore learning,
  ) {
    final theme = Theme.of(context);
    final courses = session.activeCourses;
    final codes = courses.map((c) => c.code).toSet();

    final grades = learning.learnerGrades(codes);
    final perCourse = _averagePerCourse(grades);
    final avg = learning.levelAverage(codes);
    final sorted = grades.toList()..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mes notes',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            if (session.filiere != null)
              Text(
                '${session.filiere!.name} · ${session.level}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    'Les notes sont calculées à partir de tes leçons '
                    'validées.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          FadeSlideIn(
            child: _GpaHero(average: avg, mention: _mention(avg)),
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Répartition par cours',
            subtitle: 'Moyenne sur 20 par matière',
          ),
          FadeSlideIn(
            delay: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: perCourse.isEmpty
                  ? const EmptyState(
                      icon: Icons.insights_rounded,
                      title: 'Aucune note',
                      message: 'Valide des leçons pour alimenter ce graphique.',
                    )
                  : _BarChart(data: perCourse),
            ),
          ),
          SectionHeader(
            title: 'Dernières évaluations',
            subtitle: '${sorted.length} résultat(s)',
          ),
          if (sorted.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'Aucune évaluation',
              message: 'Tes prochains résultats apparaîtront ici.',
            )
          else
            Stagger(children: [for (final g in sorted) _GradeTile(grade: g)]),
        ],
      ),
    );
  }

  static String _mention(double avg) {
    if (avg >= 16) return 'Mention Très Bien';
    if (avg >= 14) return 'Mention Bien';
    if (avg >= 12) return 'Mention Assez Bien';
    if (avg >= 10) return 'Admis';
    return 'À renforcer';
  }

  static Map<Course, double> _averagePerCourse(List<Grade> grades) {
    final map = <Course, List<double>>{};
    for (final g in grades) {
      final c = MockData.courseByCode(g.courseCode);
      if (c == null) continue;
      map.putIfAbsent(c, () => <double>[]).add(g.noteSur20);
    }
    return map.map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
  }
}

class _GpaHero extends StatelessWidget {
  const _GpaHero({required this.average, required this.mention});
  final double average;
  final String mention;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedGradientCard(
      colors: const <Color>[Color(0xFF3F51B5), Color(0xFF7C4DFF)],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Moyenne semestrielle',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    AnimatedCounter(
                      value: average,
                      decimals: 2,
                      duration: const Duration(milliseconds: 900),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '/ 20',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  offset: const Offset(0, 0.2),
                  child: Text(
                    mention,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _MiniRing(value: (average / 20).clamp(0.0, 1.0)),
        ],
      ),
    );
  }
}

class _MiniRing extends StatelessWidget {
  const _MiniRing({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 1000),
      curve: Motion.emphasized,
      builder: (context, v, _) => SizedBox(
        width: 82,
        height: 82,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: v,
              strokeWidth: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            AnimatedCounter(
              value: v * 100,
              suffix: '%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.data});
  final Map<Course, double> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = data.entries.toList();
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final e in entries)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedCounter(
                      value: e.value,
                      decimals: 1,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: e.key.color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedBar(
                      ratio: e.value / 20,
                      color: e.key.color,
                      maxHeight: 100,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      e.key.code,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
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

class _GradeTile extends StatelessWidget {
  const _GradeTile({required this.grade});
  final Grade grade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = MockData.courseByCode(grade.courseCode);
    final color = EducoachColors.forProgress(grade.ratio);
    return PressableScale(
      onTap: () => _openGradeDetails(context, grade),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (course?.color ?? color).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                course?.icon ?? Icons.receipt_long_rounded,
                color: course?.color ?? color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${grade.courseCode}  ·  ${grade.date.day}/'
                    '${grade.date.month}  ·  coeff ${grade.weight}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: grade.ratio),
                    duration: Motion.slow,
                    curve: Motion.emphasized,
                    builder: (_, v, _) =>
                        ProgressBar(value: v, color: color, height: 6),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedCounter(
              value: grade.noteSur20,
              decimals: 2,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Feuille de détail d'une évaluation : note, coefficient, mention et
/// accès direct à la fiche du cours.
void _openGradeDetails(BuildContext context, Grade grade) {
  final course = MockData.courseByCode(grade.courseCode);
  final color = EducoachColors.forProgress(grade.ratio);
  final mention = switch (grade.noteSur20) {
    >= 16 => 'Excellent — continue comme ça.',
    >= 14 => 'Très bien.',
    >= 12 => 'Bien.',
    >= 10 => 'Passable, une marge de progression existe.',
    _ => 'Insuffisant — rattrape les exercices du parcours.',
  };
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 2, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (course != null) ...[
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: course.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(course.icon, color: course.color),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          grade.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${grade.courseCode}'
                          '${course == null ? '' : ' · ${course.title}'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    grade.noteSur20.toStringAsFixed(2),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10, left: 4),
                    child: Text('/ 20'),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Coef. ${grade.weight}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${grade.date.day}/${grade.date.month}/${grade.date.year}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: grade.ratio),
                duration: Motion.slow,
                curve: Motion.emphasized,
                builder: (_, v, _) =>
                    ProgressBar(value: v, color: color, height: 8),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded, size: 18, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mention,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (course != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        FadeSlideRoute<void>(
                          page: CourseDetailPage(courseCode: grade.courseCode),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book_rounded),
                    label: const Text(
                      'Voir la fiche du cours',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
