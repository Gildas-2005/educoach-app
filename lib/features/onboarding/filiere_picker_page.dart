import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/data/mock_data.dart';
import '../../core/models/models.dart';
import '../../core/session/auth_store.dart';
import '../../core/session/session_store.dart';
import '../../core/widgets/aurora_backdrop.dart';
import '../../core/widgets/common_widgets.dart';
import '../shell/shell_page.dart';
import '../teacher/teacher_shell_page.dart';

/// Écran dédié au choix d'une filière (après authentification).
///
/// - [replaceWithShell] = true : après sélection, remplace la pile par la
///   coquille principale (utilisé juste après login/signup).
/// - false : retour simple vers l'écran précédent (depuis Profil).
class FilierePickerPage extends StatefulWidget {
  const FilierePickerPage({super.key, this.replaceWithShell = true});
  static const routeName = '/pick-filiere';

  final bool replaceWithShell;

  @override
  State<FilierePickerPage> createState() => _FilierePickerPageState();
}

class _FilierePickerPageState extends State<FilierePickerPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  Filiere? _selected;
  String? _level;
  String? _domainFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matches(Filiere f) {
    if (_domainFilter != null && f.domain != _domainFilter) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return f.name.toLowerCase().contains(q) ||
        f.code.toLowerCase().contains(q) ||
        f.tagline.toLowerCase().contains(q) ||
        f.domain.toLowerCase().contains(q);
  }

  List<String> get _domains => MockData.filieresByDomain().keys.toList();

  void _pick(Filiere f) {
    final levels = SessionStore.levelsWithCourses(f);
    setState(() {
      _selected = f;
      _level = levels.isNotEmpty ? levels.first : null;
    });
  }

  void _confirm() {
    final f = _selected;
    if (f == null) return;
    SessionStore.instance.selectFiliere(f, level: _level);
    if (widget.replaceWithShell) {
      final role = AuthStore.instance.user?.role ?? UserRole.student;
      final page = role == UserRole.teacher
          ? const TeacherShellPage()
          : const ShellPage();
      Navigator.of(context).pushReplacement(FadeSlideRoute<void>(page: page));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = MockData.filieresByDomain();
    final hasAny = grouped.entries.any((e) => e.value.any(_matches));
    final role = AuthScope.of(context).user?.role ?? UserRole.student;
    final isTeacher = role == UserRole.teacher;

    return Scaffold(
      body: Stack(
        children: [
          AuroraBackdrop(
            primary: isTeacher
                ? const Color(0xFF00897B)
                : const Color(0xFF3F51B5),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  onClose: widget.replaceWithShell
                      ? null
                      : () => Navigator.of(context).pop(),
                  title: isTeacher
                      ? 'Choisis ta discipline'
                      : 'Choisis ta filière',
                  subtitle: widget.replaceWithShell
                      ? (isTeacher
                            ? 'Dernière étape avant d’ouvrir ton espace enseignant.'
                            : 'Attention : ce choix est définitif, une fois ta filière validée tu ne peux plus la changer.')
                      : (isTeacher
                            ? 'Ta discipline d’affectation.'
                            : 'Ta filière est verrouillée depuis ton choix initial.'),
                ),
                const SizedBox(height: 8),
                _SearchBar(
                  ctrl: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                ),
                const SizedBox(height: 10),
                _DomainChips(
                  domains: _domains,
                  selected: _domainFilter,
                  onSelect: (d) => setState(
                    () => _domainFilter = (_domainFilter == d ? null : d),
                  ),
                ),
                Expanded(
                  child: hasAny
                      ? ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                          children: [
                            for (final e in grouped.entries)
                              if (e.value.any(_matches)) ...[
                                SectionHeader(
                                  title: e.key,
                                  subtitle:
                                      '${e.value.where(_matches).length} filière(s)',
                                ),
                                Stagger(
                                  children: [
                                    for (final f in e.value.where(_matches))
                                      _FiliereTile(
                                        filiere: f,
                                        selected: _selected?.id == f.id,
                                        onTap: () => _pick(f),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                          ],
                        )
                      : const EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'Aucune filière',
                          message: 'Essaie un autre mot-clé ou retire le filtre de domaine.',
                        ),
                ),
              ],
            ),
          ),
          // Barre de confirmation flottante quand une filière est sélectionnée.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ConfirmBar(
              visible: _selected != null,
              filiere: _selected,
              level: _level ?? '',
              onLevelSelected: (l) => setState(() => _level = l),
              onConfirm: _confirm,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle, this.onClose});
  final String title;
  final String subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 6),
      child: Row(
        children: [
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.arrow_back_rounded),
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: FadeSlideIn(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
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
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.ctrl,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.86,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: ctrl,
                onChanged: onChanged,
                decoration: const InputDecoration(
                  hintText: 'Rechercher : droit, médecine, info…',
                  border: InputBorder.none,
                ),
              ),
            ),
            if (ctrl.text.isNotEmpty)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

class _DomainChips extends StatelessWidget {
  const _DomainChips({
    required this.domains,
    required this.selected,
    required this.onSelect,
  });

  final List<String> domains;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: domains.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = domains[i];
          final active = selected == d;
          return GestureDetector(
            onTap: () => onSelect(d),
            child: AnimatedContainer(
              duration: Motion.fast,
              curve: Motion.emphasized,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                d,
                style: TextStyle(
                  color: active
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FiliereTile extends StatelessWidget {
  const _FiliereTile({
    required this.filiere,
    required this.selected,
    required this.onTap,
  });

  final Filiere filiere;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = filiere.color;
    final courseCount = MockData.courseCountFor(filiere.id);
    final levelCount = SessionStore.levelsWithCourses(filiere).length;
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.normal,
        curve: Motion.emphasized,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? c.withValues(alpha: 0.10)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.9,
                ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? c : theme.colorScheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: c.withValues(alpha: 0.22),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: Motion.normal,
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: c.withValues(alpha: selected ? 0.24 : 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(filiere.icon, color: c),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filiere.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    filiere.tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      PillBadge(
                        label: '$levelCount niveau(x) actif(s)',
                        color: c,
                      ),
                      const SizedBox(width: 6),
                      PillBadge(label: '$courseCount cours', color: c),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedScale(
              duration: Motion.fast,
              scale: selected ? 1 : 0.7,
              child: Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? c : theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bandeau flottant de confirmation + sélecteur de niveau.
class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.visible,
    required this.filiere,
    required this.level,
    required this.onLevelSelected,
    required this.onConfirm,
  });

  final bool visible;
  final Filiere? filiere;
  final String level;
  final ValueChanged<String> onLevelSelected;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = filiere;
    final color = f?.color ?? theme.colorScheme.primary;
    return AnimatedContainer(
      duration: Motion.normal,
      curve: Motion.emphasized,
      transform: Matrix4.translationValues(0, visible ? 0 : 220, 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: visible && f != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(f.icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${f.name} · $level',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final l in SessionStore.levelsWithCourses(f))
                      _LevelChip(
                        label: l,
                        selected: level == l,
                        color: color,
                        onTap: () => onLevelSelected(l),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Choix définitif — tu progresseras niveau par niveau.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.check_rounded),
                  label: Text('Continuer · ${f.name}'),
                ),
              ],
            )
          : const SizedBox(height: 0),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
