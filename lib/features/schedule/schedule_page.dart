import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/data/mock_data.dart';
import '../../core/models/models.dart';
import '../../core/session/session_store.dart';
import '../../core/widgets/common_widgets.dart';
import '../courses/course_path_page.dart';

/// Onglet Planning : vue hebdomadaire filtrée sur la filière/niveau courant.
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late int _selectedDay = DateTime.now().weekday;

  static const _dayShort = <String>[
    'Lun',
    'Mar',
    'Mer',
    'Jeu',
    'Ven',
    'Sam',
    'Dim',
  ];

  static const _dayFull = <String>[
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = SessionScope.of(context);
    final codes = session.activeCourseCodes;
    final blocks = MockData.scheduleForDay(_selectedDay)
        .where((b) => codes.contains(b.courseCode))
        .toList();
    final weekCount = MockData.schedule
        .where((b) => codes.contains(b.courseCode))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emploi du temps',
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
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          FadeSlideIn(
            child: _WeekSelector(
              dayShort: _dayShort,
              selectedDay: _selectedDay,
              today: DateTime.now().weekday,
              dateForSlot: _dateForSlot,
              onSelect: (d) => setState(() => _selectedDay = d),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 90),
            child: Row(
              children: [
                Expanded(
                  child: _InlineSummary(
                    label: 'Séances du jour',
                    value: blocks.length.toDouble(),
                    color: theme.colorScheme.primary,
                    icon: Icons.event_note_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InlineSummary(
                    label: 'Cette semaine',
                    value: weekCount.toDouble(),
                    color: const Color(0xFF00ACC1),
                    icon: Icons.calendar_month_rounded,
                  ),
                ),
              ],
            ),
          ),
          SectionHeader(
            title: _titleOfDay(_selectedDay),
            subtitle: blocks.isEmpty
                ? 'Aucun cours programmé'
                : '${blocks.length} séance(s)',
          ),
          if (blocks.isEmpty)
            const EmptyState(
              icon: Icons.weekend_rounded,
              title: 'Journée libre',
              message: 'Aucune séance ce jour. Bon moment pour réviser.',
            )
          else
            Stagger(
              children: [for (final b in blocks) _ScheduleTile(block: b)],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add-session-fab',
        onPressed: () {},
        tooltip: 'Ajouter une séance',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  DateTime _dateForSlot(int i) {
    final now = DateTime.now();
    final delta = (i + 1) - now.weekday;
    return DateTime(now.year, now.month, now.day + delta);
  }

  String _titleOfDay(int day) {
    final d = _dateForSlot(day - 1);
    return '${_dayFull[day - 1]} ${d.day}/${d.month}';
  }
}

class _WeekSelector extends StatelessWidget {
  const _WeekSelector({
    required this.dayShort,
    required this.selectedDay,
    required this.today,
    required this.dateForSlot,
    required this.onSelect,
  });

  final List<String> dayShort;
  final int selectedDay;
  final int today;
  final DateTime Function(int) dateForSlot;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < 7; i++)
            _DayPill(
              label: dayShort[i],
              number: dateForSlot(i).day,
              selected: selectedDay == i + 1,
              isToday: today == i + 1,
              onTap: () => onSelect(i + 1),
            ),
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.label,
    required this.number,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final String label;
  final int number;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.normal,
        curve: Motion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : isToday
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: Motion.fast,
              child: Text(
                '$number',
                key: ValueKey<int>(number),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isToday) ...[
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: Motion.normal,
                width: 6,
                height: 3,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineSummary extends StatelessWidget {
  const _InlineSummary({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                AnimatedCounter(
                  value: value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
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

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.block});

  final ScheduleBlock block;

  static Color _typeColor(String t) => switch (t) {
    'CM' => const Color(0xFF3F51B5),
    'TD' => const Color(0xFF00897B),
    'TP' => const Color(0xFFEF6C00),
    _ => const Color(0xFF7C4DFF),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = _typeColor(block.type);
    return PressableScale(
      onTap: () => _openSessionDetails(context, block, c),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: c.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 66,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${block.startHour}h',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${block.endHour}h',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        block.room,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        block.courseCode,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PillBadge(label: block.type, color: c),
          ],
        ),
      ),
    );
  }
}

/// Feuille de détail d'une séance : infos complètes + reprise du
/// parcours du cours. Remplace l'ancien tap sans effet.
void _openSessionDetails(
  BuildContext context,
  ScheduleBlock block,
  Color accent,
) {
  const days = <String>[
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];
  final course = MockData.courseByCode(block.courseCode);
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
                  PillBadge(label: block.type, color: accent, filled: true),
                  const SizedBox(width: 10),
                  Text(
                    '${block.startHour}h – ${block.endHour}h',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    days[(block.dayOfWeek - 1).clamp(0, 6)],
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                block.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (course != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${course.code} · ${course.title}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _SessionFact(
                icon: Icons.person_outline_rounded,
                label: 'Enseignant',
                value: course?.teacher ?? '—',
              ),
              _SessionFact(
                icon: Icons.meeting_room_outlined,
                label: 'Salle',
                value: block.room,
              ),
              if (course != null)
                _SessionFact(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Crédits',
                  value: '${course.credits} ECTS',
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      FadeSlideRoute<void>(
                        page: CoursePathPage(courseCode: block.courseCode),
                      ),
                    );
                  },
                  icon: const Icon(Icons.route_rounded),
                  label: const Text(
                    'Reprendre le parcours',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SessionFact extends StatelessWidget {
  const _SessionFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
