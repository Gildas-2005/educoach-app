import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/data/mock_data.dart';
import '../../core/models/models.dart';
import '../../core/session/auth_store.dart';
import '../../core/session/session_coordinator.dart';
import '../../core/session/session_store.dart';
import '../../core/widgets/aurora_backdrop.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/login_page.dart';
import '../chat/chat_list_page.dart';

/// Coquille de l'espace enseignant Educoach.
///
/// Quatre onglets pensés pour le quotidien d'un·e enseignant·e camerounais·e :
///   1. **Tableau de bord** : KPIs de la semaine, copies à corriger,
///      alertes de rendu.
///   2. **Mes cours** : la liste des matières suivies, avec progression
///      moyenne de la promotion et accès rapide aux parcours d'apprentissage.
///   3. **Copies à corriger** : file de devoirs rendus par les étudiants,
///      notation 0-20 avec retour écrit et diffusion immédiate.
///   4. **Étudiants** : annuaire de la promotion, avec taux de
///      complétion des leçons et moyenne glissante.
///
/// Les données sont générées de façon déterministe depuis [MockData] pour
/// rester cohérentes d'une session à l'autre sans backend.
class TeacherShellPage extends StatefulWidget {
  const TeacherShellPage({super.key, this.initialTab = 0});
  static const routeName = '/teacher';

  final int initialTab;

  @override
  State<TeacherShellPage> createState() => _TeacherShellPageState();
}

class _TeacherShellPageState extends State<TeacherShellPage> {
  late int _index = widget.initialTab;

  static const _tabs = <_TabItem>[
    _TabItem(
      'Tableau de bord',
      Icons.space_dashboard_outlined,
      Icons.space_dashboard_rounded,
    ),
    _TabItem('Mes cours', Icons.menu_book_outlined, Icons.menu_book_rounded),
    _TabItem('Copies', Icons.rate_review_outlined, Icons.rate_review_rounded),
    _TabItem('Étudiants', Icons.groups_outlined, Icons.groups_rounded),
    _TabItem('Messages', Icons.forum_outlined, Icons.forum_rounded),
  ];

  void _goTo(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Tu devras saisir à nouveau tes identifiants Educoach.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    SessionCoordinator.signOut();
    Navigator.of(context)
        .pushReplacement(FadeSlideRoute<void>(page: const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthStore.instance.user;
    final teacherName = user != null
        ? 'Pr. ${user.lastName.isNotEmpty ? user.lastName : user.firstName}'
        : 'Enseignant·e';

    final pages = <Widget>[
      _DashboardTab(onOpenTab: _goTo),
      const _MyCoursesTab(),
      const _CorrectionsTab(),
      const _StudentsTab(),
      const ChatListPage(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          const AuroraBackdrop(
            primary: Color(0xFF00897B),
            accentA: Color(0xFF26A69A),
            accentB: Color(0xFF7C4DFF),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Espace enseignant',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bonjour, $teacherName',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Se déconnecter',
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: Motion.normal,
                    switchInCurve: Motion.emphasized,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.03, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey<int>(_index),
                      child: pages[_index],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              blurRadius: 22,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _goTo,
          destinations: [
            for (var i = 0; i < _tabs.length; i++)
              NavigationDestination(
                icon: AnimatedSwitcher(
                  duration: Motion.fast,
                  switchInCurve: Motion.springy,
                  transitionBuilder: (c, a) => ScaleTransition(
                    scale: Tween<double>(begin: 0.75, end: 1).animate(a),
                    child: FadeTransition(opacity: a, child: c),
                  ),
                  child: Icon(
                    _index == i ? _tabs[i].selected : _tabs[i].icon,
                    key: ValueKey('$_index-$i'),
                  ),
                ),
                label: _tabs[i].label,
              ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem(this.label, this.icon, this.selected);
  final String label;
  final IconData icon;
  final IconData selected;
}

// ---------------------------------------------------------------------------
// 1. Dashboard
// ---------------------------------------------------------------------------
class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.onOpenTab});
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = SessionScope.of(context);
    final filiere = session.filiere;
    final courses = filiere == null
        ? MockData.courses.take(4).toList()
        : MockData.coursesFor(filiereId: filiere.id);
    final students = _TeacherMock.studentsFor(courses);
    final pending = _TeacherMock.pendingCorrections(courses, students);
    final avgProgress = courses.isEmpty
        ? 0.0
        : courses.map((c) => c.progress).reduce((a, b) => a + b) /
              courses.length;
    final weeklyXp = students.fold<int>(0, (s, e) => s + e.xpThisWeek);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
      children: [
        FadeSlideIn(
          child: _TeacherHero(
            title: 'Bonjour ${filiere?.name ?? 'à toi'} 👋',
            subtitle:
                '${courses.length} cours actifs · ${students.length} étudiants suivis · '
                '${pending.length} copies en attente de correction.',
          ),
        ),
        const SizedBox(height: 16),
        Stagger(
          children: [
            Row(
              children: [
                Expanded(
                  child: _AnimatedKpiTile(
                    label: 'Copies à corriger',
                    value: pending.length,
                    suffix: '',
                    icon: Icons.rate_review_rounded,
                    color: const Color(0xFFF4511E),
                    onTap: () => onOpenTab(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AnimatedKpiTile(
                    label: 'Étudiants actifs',
                    value: students.length,
                    suffix: '',
                    icon: Icons.groups_rounded,
                    color: const Color(0xFF3F51B5),
                    onTap: () => onOpenTab(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _AnimatedKpiTile(
                    label: 'XP de la semaine',
                    value: weeklyXp,
                    suffix: ' XP',
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFF7C4DFF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AnimatedKpiTile(
                    label: 'Progression moyenne',
                    value: (avgProgress * 100).round(),
                    suffix: ' %',
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFF43A047),
                  ),
                ),
              ],
            ),
          ],
        ),
        SectionHeader(
          title: 'Rendu récents',
          subtitle: 'Les 4 derniers devoirs déposés',
          actionLabel: 'Tout voir',
          onAction: () => onOpenTab(2),
        ),
        Stagger(
          initialDelay: const Duration(milliseconds: 220),
          children: [
            for (final s in pending.take(4))
              _CorrectionTile(
                submission: s,
                compact: true,
                onGrade: () => onOpenTab(2),
              ),
          ],
        ),
        SectionHeader(
          title: 'Alertes',
          subtitle: 'Étudiants en difficulté (< 60 % de complétion)',
        ),
        Stagger(
          initialDelay: const Duration(milliseconds: 320),
          children: [
            for (final s in students.where((e) => e.completion < 0.6).take(3))
              _StudentWarningTile(student: s),
            if (students.every((e) => e.completion >= 0.6))
              const EmptyState(
                icon: Icons.emoji_events_rounded,
                title: 'Aucun étudiant en difficulté',
                message: 'Toute la promotion avance à un rythme satisfaisant.',
              ),
          ],
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 400),
          child: Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.tips_and_updates_rounded,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Astuce : publie un nouveau parcours d\'apprentissage '
                      'directement depuis l\'onglet « Mes cours » pour que '
                      'tes étudiants progressent en autonomie.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedKpiTile extends StatelessWidget {
  const _AnimatedKpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix = '',
    this.onTap,
  });

  final String label;
  final int value;
  final String suffix;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            AnimatedCounter(
              value: value.toDouble(),
              suffix: suffix,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Mes cours
// ---------------------------------------------------------------------------
class _MyCoursesTab extends StatefulWidget {
  const _MyCoursesTab();

  @override
  State<_MyCoursesTab> createState() => _MyCoursesTabState();
}

class _MyCoursesTabState extends State<_MyCoursesTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filiere = SessionStore.instance.filiere;
    final courses =
        (filiere == null
                ? MockData.courses
                : MockData.coursesFor(filiereId: filiere.id))
            .where(
              (c) =>
                  _query.isEmpty ||
                  c.title.toLowerCase().contains(_query.toLowerCase()) ||
                  c.code.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Rechercher un cours…',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
          ),
        ),
        Expanded(
          child: courses.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Aucun cours',
                  message:
                      'Aucun enseignement ne correspond à cette recherche.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                  itemCount: courses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final c = courses[i];
                    return FadeSlideIn(
                      delay: Motion.stagger * i,
                      child: _TeacherCourseCard(course: c),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TeacherCourseCard extends StatelessWidget {
  const _TeacherCourseCard({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressableScale(
      onTap: () {
        Navigator.of(context).pushNamed('/course/${course.code}/path');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${course.code} · ${course.level} · ${course.credits} crédits',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ProgressBar(value: course.progress, color: course.color),
                  const SizedBox(height: 6),
                  Text(
                    'Promotion : ${(course.progress * 100).round()} % des leçons validées',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Corrections
// ---------------------------------------------------------------------------
class _CorrectionsTab extends StatefulWidget {
  const _CorrectionsTab();

  @override
  State<_CorrectionsTab> createState() => _CorrectionsTabState();
}

class _CorrectionsTabState extends State<_CorrectionsTab> {
  bool _onlyPending = true;
  final Map<String, double> _grades = {};

  @override
  Widget build(BuildContext context) {
    final filiere = SessionStore.instance.filiere;
    final courses = filiere == null
        ? MockData.courses.take(4).toList()
        : MockData.coursesFor(filiereId: filiere.id);
    final students = _TeacherMock.studentsFor(courses);
    final submissions = _TeacherMock.pendingCorrections(
      courses,
      students,
    ).where((s) => !_onlyPending || s.graded == null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'File de correction',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              FilterChip(
                label: const Text('En attente'),
                selected: _onlyPending,
                onSelected: (v) => setState(() => _onlyPending = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: submissions.isEmpty
              ? const EmptyState(
                  icon: Icons.task_alt_rounded,
                  title: 'Rien à corriger',
                  message: 'Toutes les copies rendues ont été notées. Beau travail !',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  itemCount: submissions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final s = submissions[i];
                    return FadeSlideIn(
                      delay: Motion.stagger * i,
                      child: _CorrectionTile(
                        submission: s,
                        graded: _grades[s.id],
                        onGrade: () => _openGradeSheet(context, s, (g) {
                          setState(() => _grades[s.id] = g);
                        }),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _openGradeSheet(
    BuildContext context,
    _Submission s,
    ValueChanged<double> onSaved,
  ) async {
    final ctrl = TextEditingController(
      text: s.graded == null ? '' : s.graded!.toStringAsFixed(1),
    );
    final noteCtrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Noter la copie de ${s.student.fullName}',
                style: Theme.of(ctx).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${s.courseCode} · ${s.title}',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Note / 20',
                  hintText: 'Ex : 14.5',
                  prefixIcon: Icon(Icons.star_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Commentaire pour l\'étudiant',
                  hintText: 'Bon raisonnement, manque de rigueur sur…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  final g = double.tryParse(ctrl.text.trim());
                  if (g == null || g < 0 || g > 20) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Note invalide : attendu un nombre entre 0 et 20.',
                        ),
                      ),
                    );
                    return;
                  }
                  onSaved(g);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Copie de ${s.student.fullName} notée ${g.toStringAsFixed(1)}/20.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Valider la note'),
              ),
            ],
          ),
        );
      },
    );
    ctrl.dispose();
    noteCtrl.dispose();
  }
}

class _CorrectionTile extends StatelessWidget {
  const _CorrectionTile({
    required this.submission,
    this.compact = false,
    this.graded,
    required this.onGrade,
  });

  final _Submission submission;
  final bool compact;
  final double? graded;
  final VoidCallback onGrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = submission;
    final resolved = graded ?? s.graded;
    final isDone = resolved != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialsAvatar(
            initials: _initialsOf(s.student.fullName),
            background: s.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.student.fullName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.courseCode} · ${s.title}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    PillBadge(
                      label: _relative(s.submittedAt),
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 6),
                    PillBadge(
                      label: '${s.points} pts',
                      color: theme.colorScheme.primary,
                    ),
                    if (isDone) ...[
                      const SizedBox(width: 6),
                      PillBadge(
                        label: 'Note : ${resolved.toStringAsFixed(1)}/20',
                        color: const Color(0xFF43A047),
                        filled: true,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!compact)
            IconButton.filledTonal(
              onPressed: onGrade,
              icon: Icon(
                isDone ? Icons.edit_note_rounded : Icons.rate_review_rounded,
              ),
              tooltip: isDone ? 'Ajuster' : 'Corriger',
            )
          else
            TextButton(onPressed: onGrade, child: const Text('Corriger')),
        ],
      ),
    );
  }

  static String _relative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

// ---------------------------------------------------------------------------
// 4. Étudiants
// ---------------------------------------------------------------------------
class _StudentsTab extends StatelessWidget {
  const _StudentsTab();

  @override
  Widget build(BuildContext context) {
    final filiere = SessionStore.instance.filiere;
    final courses = filiere == null
        ? MockData.courses.take(4).toList()
        : MockData.coursesFor(filiereId: filiere.id);
    final students = _TeacherMock.studentsFor(courses)
      ..sort((a, b) => b.average.compareTo(a.average));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      itemCount: students.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = students[i];
        return FadeSlideIn(
          delay: Motion.stagger * i,
          child: _StudentTile(student: s, rank: i + 1),
        );
      },
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student, required this.rank});
  final _Student student;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          InitialsAvatar(
            initials: _initialsOf(student.fullName),
            background: student.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${student.programme} · ${student.level}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                ProgressBar(
                  value: student.completion,
                  color: student.completion < 0.6
                      ? const Color(0xFFF4511E)
                      : const Color(0xFF43A047),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${student.average.toStringAsFixed(1)}/20',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: student.average >= 12
                      ? const Color(0xFF43A047)
                      : const Color(0xFFF4511E),
                ),
              ),
              Text(
                '${student.xpThisWeek} XP',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentWarningTile extends StatelessWidget {
  const _StudentWarningTile({required this.student});
  final _Student student;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4511E).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF4511E).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF4511E)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Complétion : ${(student.completion * 100).round()} % · '
                  'moyenne ${student.average.toStringAsFixed(1)}/20',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('Relancer')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mock data déterministe pour l'espace enseignant.
// ---------------------------------------------------------------------------
class _TeacherHero extends StatelessWidget {
  const _TeacherHero({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GradientHeroCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.co_present_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
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

String _initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'E';
  final a = parts.first[0];
  final b = parts.length > 1 ? parts[1][0] : '';
  return (a + b).toUpperCase();
}

class _Student {
  const _Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.programme,
    required this.level,
    required this.completion,
    required this.average,
    required this.xpThisWeek,
    required this.accent,
  });
  final String id;
  final String firstName;
  final String lastName;
  final String programme;
  final String level;
  final double completion;
  final double average;
  final int xpThisWeek;
  final Color accent;
  String get fullName => '$firstName $lastName';
}

class _Submission {
  const _Submission({
    required this.id,
    required this.student,
    required this.courseCode,
    required this.title,
    required this.submittedAt,
    required this.points,
    this.graded,
    required this.accent,
  });
  final String id;
  final _Student student;
  final String courseCode;
  final String title;
  final DateTime submittedAt;
  final int points;
  final double? graded;
  final Color accent;
}

class _TeacherMock {
  const _TeacherMock._();

  static const _firstNames = <String>[
    'Awa',
    'Mohamed',
    'Christelle',
    'Blaise',
    'Nadège',
    'Franck',
    'Chantal',
    'Yves',
    'Estelle',
    'Rodrigue',
    'Sandrine',
    'Bertrand',
    'Aïcha',
    'Dorlyne',
    'Karl',
    'Mireille',
    'Serge',
    'Larissa',
    'Abel',
    'Josiane',
    'Rachelle',
    'Hervé',
    'Brice',
    'Aline',
    'Cyrille',
    'Nancy',
    'Éric',
    'Solange',
  ];
  static const _lastNames = <String>[
    'Ndiaye',
    'Mbarga',
    'Onana',
    'Tchoumi',
    'Fotso',
    'Biya',
    'Etoa',
    'Amadou',
    'Ngo Bell',
    'Kamdem',
    'Tabekou',
    'Ayissi',
    'Etoundi',
    'Njoya',
    'Abena',
    'Djoumgang',
    'Kana',
    'Melus',
    'Olinga',
    'Sadou',
    'Ateba',
    'Ngwa',
  ];
  static const _programmeNames = <String>[
    'L3 Informatique',
    'M1 Génie logiciel',
    'L2 Droit privé',
    'M2 Finance quantitative',
    'L3 Médecine',
    'DUT Réseaux',
  ];

  static int _h(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0x7fffffff;
    }
    return h;
  }

  static List<_Student> studentsFor(List<Course> courses) {
    final key = courses.map((c) => c.code).join('|');
    final seed = _h(key.isEmpty ? 'default' : key);
    final count = 12 + (seed % 8); // 12 à 19 étudiants
    final out = <_Student>[];
    for (var i = 0; i < count; i++) {
      final h = _h('student-$i-$key');
      final first = _firstNames[h % _firstNames.length];
      final last = _lastNames[(h >> 3) % _lastNames.length];
      final programme = _programmeNames[(h >> 5) % _programmeNames.length];
      final completion = ((h >> 7) % 100) / 100.0; // 0..1
      final avg = 6.0 + ((h >> 11) % 130) / 10.0; // 6.0..19.0
      final xp = 40 + ((h >> 4) % 380);
      out.add(
        _Student(
          id: 's$i',
          firstName: first,
          lastName: last,
          programme: programme,
          level: programme.split(' ').first,
          completion: completion,
          average: avg.clamp(4.0, 19.5),
          xpThisWeek: xp,
          accent: Color(0xFF000000 | ((h >> 8) & 0xFFFFFF))
              .withValues(alpha: 0.9),
        ),
      );
    }
    return out;
  }

  static List<_Submission> pendingCorrections(
    List<Course> courses,
    List<_Student> students,
  ) {
    if (courses.isEmpty || students.isEmpty) return const [];
    final out = <_Submission>[];
    var id = 0;
    for (final c in courses.take(4)) {
      final chosen = students.take(3).toList();
      for (final s in chosen) {
        final h = _h('${c.code}-${s.id}');
        final submittedDays = 1 + (h % 8);
        final graded = (h >> 4) % 3 == 0; // 1 sur 3 déjà notée
        out.add(
          _Submission(
            id: 'sub-${id++}',
            student: s,
            courseCode: c.code,
            title: 'DM ${_h(c.code) % 5 + 1} · ${c.title}',
            submittedAt: DateTime.now().subtract(Duration(days: submittedDays)),
            points: 20,
            graded: graded ? (10.0 + ((h >> 6) % 80) / 10.0) : null,
            accent: c.color,
          ),
        );
      }
    }
    out.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return out;
  }
}
