import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/models/models.dart';
import '../../core/session/session_store.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/course_card.dart';
import 'course_detail_page.dart';

/// Onglet Cours : bandeau filière + recherche + filtres par niveau
/// et statut + liste animée des cours.
class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int _filterIndex = 0;
  bool _loading = true;
  Timer? _loadingTimer;

  static const _filters = <String>[
    'Tous',
    'En cours',
    'À reprendre',
    'Terminés',
  ];

  @override
  void initState() {
    super.initState();
    // Simule un léger chargement pour montrer le shimmer.
    _loadingTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Course> _apply(Iterable<Course> src) {
    final q = _query.trim().toLowerCase();
    Iterable<Course> it = src;
    if (q.isNotEmpty) {
      it = it.where(
        (c) =>
            c.title.toLowerCase().contains(q) ||
            c.code.toLowerCase().contains(q) ||
            c.teacher.toLowerCase().contains(q),
      );
    }
    switch (_filterIndex) {
      case 1:
        it = it.where((c) => c.progress >= 0.4 && c.progress < 0.9);
      case 2:
        it = it.where((c) => c.progress < 0.4);
      case 3:
        it = it.where((c) => c.progress >= 0.9);
    }
    return it.toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = SessionScope.of(context);
    final f = session.filiere;
    final filtered = _apply(session.activeCourses);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mes cours',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            if (f != null)
              Text(
                '${f.name} · ${session.level}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filtrer',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un cours, un code, un enseignant…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final selected = i == _filterIndex;
                return AnimatedContainer(
                  duration: Motion.fast,
                  curve: Motion.emphasized,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ChoiceChip(
                    label: Text(_filters[i]),
                    selected: selected,
                    onSelected: (_) => setState(() => _filterIndex = i),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _loading
                ? const _CoursesSkeleton()
                : filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Aucun cours trouvé',
                    message: "Ajuste ta recherche ou change de niveau.",
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 50 * i),
                        offset: const Offset(0, 0.15),
                        child: CourseCard(
                          course: c,
                          onTap: () => Navigator.of(context).push(
                            FadeSlideRoute<void>(
                              page: CourseDetailPage(courseCode: c.code),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-course-fab',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                f == null
                    ? 'Choisis d\'abord une filière'
                    : 'Bientôt : ajout d\'un cours en ${f.name}',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
    );
  }
}

/// Skeleton de chargement animé (shimmer) pour la liste des cours.
class _CoursesSkeleton extends StatelessWidget {
  const _CoursesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ShimmerBox(height: 46, width: 46, borderRadius: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(height: 12, width: 60),
                      SizedBox(height: 6),
                      ShimmerBox(height: 14, width: 180),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const ShimmerBox(height: 8),
          ],
        ),
      ),
    );
  }
}
