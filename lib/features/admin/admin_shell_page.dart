import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/data/mock_data.dart';
import '../../core/session/auth_store.dart';
import '../../core/session/legal_store.dart';
import '../../core/session/session_coordinator.dart';
import '../../core/widgets/aurora_backdrop.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/login_page.dart';
import '../legal/legal_content.dart';
import '../legal/legal_document_page.dart';

/// Coquille de l'espace administrateur Educoach.
///
/// Quatre onglets :
///   1. **Pilotage** — KPIs globaux (comptes actifs, cours publiés,
///      tickets de conformité, demandes d'export RGPD en attente).
///   2. **Comptes** — annuaire des utilisateurs avec actions de
///      validation / blocage et changement de rôle.
///   3. **Validation** — file d'attente des parcours et devoirs
///      soumis par les enseignants, avec aperçu et bouton approuver/refuser.
///   4. **Conformité** — journal des traitements loi 2010/012 Livre V,
///      registres DPO, documents légaux en vigueur.
class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key, this.initialTab = 0});
  static const routeName = '/admin';

  final int initialTab;

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  late int _index = widget.initialTab;

  static const _tabs = <_TabItem>[
    _TabItem('Pilotage', Icons.insights_outlined, Icons.insights_rounded),
    _TabItem('Comptes', Icons.badge_outlined, Icons.badge_rounded),
    _TabItem('Validation', Icons.fact_check_outlined, Icons.fact_check_rounded),
    _TabItem('Conformité', Icons.gavel_outlined, Icons.gavel_rounded),
  ];

  void _goTo(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  Future<void> _logout() async {
    SessionCoordinator.signOut();
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(FadeSlideRoute<void>(page: const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthStore.instance.user;
    final adminName = user?.fullName ?? 'Administrateur';

    final pages = <Widget>[
      const _KpiTab(),
      const _AccountsTab(),
      const _ValidationTab(),
      const _ComplianceTab(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          const AuroraBackdrop(
            primary: Color(0xFF7C4DFF),
            accentA: Color(0xFF3F51B5),
            accentB: Color(0xFF00BCD4),
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
                              'Console administrateur',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              adminName,
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
      bottomNavigationBar: NavigationBar(
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
                  key: ValueKey('admin-tab-$_index-$i'),
                ),
              ),
              label: _tabs[i].label,
            ),
        ],
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
// 1. Pilotage / KPIs
// ---------------------------------------------------------------------------
class _KpiTab extends StatelessWidget {
  const _KpiTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _AdminMock.platformStats();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
      children: [
        FadeSlideIn(
          child: _AdminHero(
            title: 'Pilotage de la plateforme',
            subtitle:
                'Vue consolidée des ${stats.totalUsers} comptes Educoach, '
                '${stats.totalCourses} cours publiés et '
                '${stats.pendingValidations} validations en attente.',
          ),
        ),
        const SizedBox(height: 16),
        Stagger(
          children: [
            Row(
              children: [
                Expanded(
                  child: _AnimatedKpi(
                    label: 'Comptes actifs',
                    value: stats.totalUsers,
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF3F51B5),
                    caption: '+${stats.newUsersThisWeek} cette semaine',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AnimatedKpi(
                    label: 'Cours publiés',
                    value: stats.totalCourses,
                    icon: Icons.public_rounded,
                    color: const Color(0xFF00897B),
                    caption: '${stats.domainsCount} domaines couverts',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _AnimatedKpi(
                    label: 'Validations',
                    value: stats.pendingValidations,
                    icon: Icons.pending_actions_rounded,
                    color: const Color(0xFFF4511E),
                    caption: 'parcours + contenus',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AnimatedKpi(
                    label: 'Conformité',
                    value: stats.complianceScore,
                    suffix: ' %',
                    icon: Icons.verified_user_rounded,
                    color: const Color(0xFF43A047),
                    caption: 'score loi 2010/012',
                  ),
                ),
              ],
            ),
          ],
        ),
        SectionHeader(
          title: 'Répartition des rôles',
          subtitle: 'Qui utilise Educoach aujourd\'hui',
        ),
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: _RoleDistributionChart(
            students: stats.students,
            teachers: stats.teachers,
            admins: stats.admins,
          ),
        ),
        SectionHeader(
          title: 'Activité récente',
          subtitle: '10 derniers évènements système',
        ),
        Stagger(
          initialDelay: const Duration(milliseconds: 260),
          children: [
            for (final e in stats.activity)
              _ActivityTile(
                icon: e.icon,
                color: e.color,
                title: e.title,
                caption: e.caption,
                when: e.when,
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
                  Icon(Icons.shield_rounded, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Les données sensibles transitent uniquement par '
                      'des canaux chiffrés. Toute suppression est '
                      'journalisée conformément à la loi 2010/012 Livre V.',
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

class _AdminHero extends StatelessWidget {
  const _AdminHero({required this.title, required this.subtitle});
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
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
            ),
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

class _AnimatedKpi extends StatelessWidget {
  const _AnimatedKpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix = '',
    this.caption,
  });

  final String label;
  final int value;
  final String suffix;
  final IconData icon;
  final Color color;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
          if (caption != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                caption!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoleDistributionChart extends StatelessWidget {
  const _RoleDistributionChart({
    required this.students,
    required this.teachers,
    required this.admins,
  });
  final int students;
  final int teachers;
  final int admins;

  @override
  Widget build(BuildContext context) {
    final total = (students + teachers + admins).clamp(1, 1 << 31);
    final parts = <(String, int, Color)>[
      ('Étudiants', students, const Color(0xFF3F51B5)),
      ('Enseignants', teachers, const Color(0xFF00897B)),
      ('Administrateurs', admins, const Color(0xFF7C4DFF)),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final p in parts)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedBar(
                        ratio: p.$2 / total,
                        color: p.$3,
                        maxHeight: 100,
                        width: 34,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${p.$2}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: p.$3,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (final p in parts)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: p.$3,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(p.$1, style: const TextStyle(fontSize: 12)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.caption,
    required this.when,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String caption;
  final DateTime when;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  caption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _ago(when),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  static String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} j';
  }
}

// ---------------------------------------------------------------------------
// 2. Comptes
// ---------------------------------------------------------------------------
class _AccountsTab extends StatefulWidget {
  const _AccountsTab();

  @override
  State<_AccountsTab> createState() => _AccountsTabState();
}

class _AccountsTabState extends State<_AccountsTab> {
  UserRole? _filter;
  String _query = '';
  final Set<String> _blocked = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accounts = _AdminMock.accounts()
        .where((a) => _filter == null || a.role == _filter)
        .where(
          (a) =>
              _query.isEmpty ||
              a.name.toLowerCase().contains(_query.toLowerCase()) ||
              a.email.toLowerCase().contains(_query.toLowerCase()),
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
              hintText: 'Rechercher un compte…',
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
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: [
              for (final r in UserRole.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AnimatedChoiceChip(
                    label: r.label,
                    selected: _filter == r,
                    color: r.color,
                    onSelected: () =>
                        setState(() => _filter = (_filter == r ? null : r)),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: accounts.isEmpty
              ? const EmptyState(
                  icon: Icons.person_off_rounded,
                  title: 'Aucun compte',
                  message: 'Aucun utilisateur ne correspond à ces critères.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                  itemCount: accounts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final a = accounts[i];
                    final isBlocked = _blocked.contains(a.id);
                    return FadeSlideIn(
                      delay: Motion.stagger * i,
                      child: _AccountTile(
                        account: a,
                        blocked: isBlocked,
                        onToggleBlock: () {
                          setState(() {
                            if (isBlocked) {
                              _blocked.remove(a.id);
                            } else {
                              _blocked.add(a.id);
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isBlocked
                                    ? '${a.name} a été réactivé·e.'
                                    : '${a.name} est bloqué·e. '
                                          'L\'action est journalisée (loi 2010/012).',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.blocked,
    required this.onToggleBlock,
  });
  final _Account account;
  final bool blocked;
  final VoidCallback onToggleBlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: blocked
              ? const Color(0xFFE53935).withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          InitialsAvatar(
            initials: _initials(account.name),
            background: account.role.color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  account.email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    PillBadge(
                      label: account.role.label,
                      color: account.role.color,
                      filled: true,
                    ),
                    PillBadge(
                      label: account.filiere,
                      color: theme.colorScheme.tertiary,
                    ),
                    if (blocked)
                      const PillBadge(
                        label: 'Bloqué',
                        color: Color(0xFFE53935),
                        filled: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: blocked ? 'Réactiver' : 'Bloquer',
            onPressed: onToggleBlock,
            icon: Icon(
              blocked ? Icons.lock_open_rounded : Icons.block_rounded,
              color: blocked
                  ? const Color(0xFF43A047)
                  : const Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'U';
  final a = parts.first[0];
  final b = parts.length > 1 ? parts[1][0] : '';
  return (a + b).toUpperCase();
}

// ---------------------------------------------------------------------------
// 3. Validation
// ---------------------------------------------------------------------------
class _ValidationTab extends StatefulWidget {
  const _ValidationTab();

  @override
  State<_ValidationTab> createState() => _ValidationTabState();
}

class _ValidationTabState extends State<_ValidationTab> {
  final Map<String, _ValidationState> _states = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _AdminMock.validations();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
      children: [
        FadeSlideIn(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.rule_folder_rounded,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chaque parcours est relu par un·e administrateur '
                    'avant publication (droit d\'auteur loi 2000/11, '
                    'respect des programmes MINESUC / MINSANTE).',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < items.length; i++)
          FadeSlideIn(
            delay: Motion.stagger * i,
            child: _ValidationTile(
              item: items[i],
              state: _states[items[i].id] ?? _ValidationState.pending,
              onDecide: (s) => setState(() => _states[items[i].id] = s),
            ),
          ),
      ],
    );
  }
}

enum _ValidationState { pending, approved, rejected }

class _ValidationTile extends StatelessWidget {
  const _ValidationTile({
    required this.item,
    required this.state,
    required this.onDecide,
  });
  final _ValidationItem item;
  final _ValidationState state;
  final ValueChanged<_ValidationState> onDecide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${item.kind} · soumis par ${item.submitter}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (state != _ValidationState.pending)
                PillBadge(
                  label: state == _ValidationState.approved
                      ? 'Publié'
                      : 'Refusé',
                  color: state == _ValidationState.approved
                      ? const Color(0xFF43A047)
                      : const Color(0xFFE53935),
                  filled: true,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.summary,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state == _ValidationState.rejected
                      ? null
                      : () => onDecide(_ValidationState.rejected),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Refuser'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53935),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: state == _ValidationState.approved
                      ? null
                      : () => onDecide(_ValidationState.approved),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Approuver'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF43A047),
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

// ---------------------------------------------------------------------------
// 4. Conformité
// ---------------------------------------------------------------------------
class _ComplianceTab extends StatelessWidget {
  const _ComplianceTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final legal = LegalScope.of(context);
    final requests = _AdminMock.dataRequests();
    final logs = _AdminMock.auditLogs();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
      children: [
        FadeSlideIn(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C4DFF), Color(0xFF3F51B5)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.gavel_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'Cadre légal camerounais',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Loi 2010/012 Livre V — protection des données à '
                  'caractère personnel. L\'ART (Autorité de Régulation '
                  'des Télécommunications) agit comme autorité de '
                  'contrôle indépendante.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.4,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SectionHeader(
          title: 'Documents en vigueur',
          subtitle: 'Approbation et versionnement',
        ),
        Stagger(
          children: [
            _LegalRow(
              title: 'Conditions générales d\'utilisation',
              subtitle: 'Mise à jour : ${termsDocument.lastUpdated}',
              onTap: () => Navigator.of(context).push(
                FadeSlideRoute<void>(
                  page: LegalDocumentPage(document: termsDocument),
                ),
              ),
              icon: Icons.description_rounded,
              color: theme.colorScheme.primary,
            ),
            _LegalRow(
              title: 'Politique de confidentialité',
              subtitle: 'Mise à jour : ${privacyDocument.lastUpdated}',
              onTap: () => Navigator.of(context).push(
                FadeSlideRoute<void>(
                  page: LegalDocumentPage(document: privacyDocument),
                ),
              ),
              icon: Icons.privacy_tip_rounded,
              color: theme.colorScheme.tertiary,
            ),
          ],
        ),
        SectionHeader(
          title: 'Consentements actifs',
          subtitle: 'Agrégats sur tous les comptes',
        ),
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: _ConsentGrid(
            termsRate: legal.acceptedTerms ? 0.98 : 0.92,
            privacyRate: legal.acceptedPrivacy ? 0.99 : 0.91,
            notificationsRate: legal.consentNotifications ? 0.74 : 0.65,
            marketingRate: legal.consentMarketing ? 0.32 : 0.28,
          ),
        ),
        SectionHeader(
          title: 'Demandes d\'exercice des droits',
          subtitle:
              'Rectification, opposition, effacement (loi 2010/012 art. 33)',
        ),
        Stagger(
          initialDelay: const Duration(milliseconds: 260),
          children: [for (final r in requests) _DataRequestTile(request: r)],
        ),
        SectionHeader(
          title: 'Journal d\'audit',
          subtitle: 'Traçabilité complète des actions sensibles',
        ),
        FadeSlideIn(
          delay: const Duration(milliseconds: 320),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (final l in logs)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      l,
                      style: const TextStyle(
                        color: Color(0xFFB0BEC5),
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
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

class _LegalRow extends StatelessWidget {
  const _LegalRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.icon,
    required this.color,
  });
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
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
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
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

class _ConsentGrid extends StatelessWidget {
  const _ConsentGrid({
    required this.termsRate,
    required this.privacyRate,
    required this.notificationsRate,
    required this.marketingRate,
  });
  final double termsRate;
  final double privacyRate;
  final double notificationsRate;
  final double marketingRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <(String, double, Color)>[
      ('CGU', termsRate, theme.colorScheme.primary),
      ('Confidentialité', privacyRate, theme.colorScheme.tertiary),
      ('Notifications', notificationsRate, const Color(0xFF00897B)),
      ('Marketing', marketingRate, const Color(0xFFF4511E)),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (final it in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          it.$1,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      AnimatedCounter(
                        value: it.$2 * 100,
                        suffix: ' %',
                        style: TextStyle(
                          color: it.$3,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ProgressBar(value: it.$2, color: it.$3, height: 6),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DataRequestTile extends StatelessWidget {
  const _DataRequestTile({required this.request});
  final _DataRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: request.status.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              request.status.icon,
              color: request.status.color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${request.email} · reçu ${request.daysAgo} j '
                  '· délégué ${request.assignee}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          PillBadge(
            label: request.status.label,
            color: request.status.color,
            filled: request.status.filled,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mock data déterministe admin.
// ---------------------------------------------------------------------------
enum _ReqStatus {
  open('À traiter', Color(0xFFF4511E), Icons.forum_rounded, false),
  reviewing(
    'En cours',
    Color(0xFF00897B),
    Icons.pending_actions_rounded,
    false,
  ),
  closed('Clôturée', Color(0xFF43A047), Icons.task_alt_rounded, true);

  const _ReqStatus(this.label, this.color, this.icon, this.filled);
  final String label;
  final Color color;
  final IconData icon;
  final bool filled;
}

class _DataRequest {
  const _DataRequest({
    required this.title,
    required this.email,
    required this.daysAgo,
    required this.status,
    required this.assignee,
  });
  final String title;
  final String email;
  final int daysAgo;
  final _ReqStatus status;
  final String assignee;
}

class _ValidationItem {
  const _ValidationItem({
    required this.id,
    required this.title,
    required this.kind,
    required this.submitter,
    required this.summary,
    required this.icon,
    required this.accent,
  });
  final String id;
  final String title;
  final String kind;
  final String submitter;
  final String summary;
  final IconData icon;
  final Color accent;
}

class _Account {
  const _Account({
    required this.id,
    required this.name,
    required this.email,
    required this.filiere,
    required this.role,
  });
  final String id;
  final String name;
  final String email;
  final String filiere;
  final UserRole role;
}

class _ActivityEntry {
  const _ActivityEntry({
    required this.icon,
    required this.color,
    required this.title,
    required this.caption,
    required this.when,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String caption;
  final DateTime when;
}

class _PlatformStats {
  const _PlatformStats({
    required this.totalUsers,
    required this.totalCourses,
    required this.pendingValidations,
    required this.complianceScore,
    required this.newUsersThisWeek,
    required this.domainsCount,
    required this.students,
    required this.teachers,
    required this.admins,
    required this.activity,
  });
  final int totalUsers;
  final int totalCourses;
  final int pendingValidations;
  final int complianceScore;
  final int newUsersThisWeek;
  final int domainsCount;
  final int students;
  final int teachers;
  final int admins;
  final List<_ActivityEntry> activity;
}

class _AdminMock {
  const _AdminMock._();

  static _PlatformStats platformStats() {
    final users = MockData.filieres.length * 148 + 2310;
    final teachers = (users * 0.06).round();
    final admins = 12;
    final students = users - teachers - admins;
    final now = DateTime.now();
    return _PlatformStats(
      totalUsers: users,
      totalCourses: MockData.courses.length,
      pendingValidations: 18,
      complianceScore: 96,
      newUsersThisWeek: 342,
      domainsCount: MockData.filieresByDomain().length,
      students: students,
      teachers: teachers,
      admins: admins,
      activity: [
        _ActivityEntry(
          icon: Icons.person_add_alt_1_rounded,
          color: const Color(0xFF43A047),
          title: 'Nouvelle promotion L1 Informatique',
          caption: 'Filière Informatique · 214 comptes créés',
          when: now.subtract(const Duration(hours: 2, minutes: 12)),
        ),
        _ActivityEntry(
          icon: Icons.school_rounded,
          color: const Color(0xFF3F51B5),
          title: 'Dr. Ngo Bell a publié un nouveau parcours',
          caption: 'INF402 · Compilation · 32 leçons',
          when: now.subtract(const Duration(hours: 5, minutes: 42)),
        ),
        _ActivityEntry(
          icon: Icons.delete_forever_rounded,
          color: const Color(0xFFE53935),
          title: 'Demande d\'effacement conforme à l\'art. 33',
          caption: 'Compte abena.m@educoach.cm supprimé',
          when: now.subtract(const Duration(hours: 12)),
        ),
        _ActivityEntry(
          icon: Icons.verified_user_rounded,
          color: const Color(0xFF00897B),
          title: 'Audit trimestriel ART validé',
          caption: 'Rapport n°ART-2026-Q4 · 0 non-conformité',
          when: now.subtract(const Duration(days: 1, hours: 3)),
        ),
        _ActivityEntry(
          icon: Icons.lock_rounded,
          color: const Color(0xFF7C4DFF),
          title: 'Rotation des clés de chiffrement',
          caption: 'AES-256 · effectué automatiquement',
          when: now.subtract(const Duration(days: 2)),
        ),
      ],
    );
  }

  static List<_Account> accounts() {
    final seedNames = <(String, String, UserRole, String)>[
      (
        'Awa Ndiaye',
        'awa.ndiaye@educoach.cm',
        UserRole.student,
        'Informatique · L1',
      ),
      (
        'Mohamed Tchoumi',
        'm.tchoumi@educoach.cm',
        UserRole.student,
        'Réseaux & Télécoms · L2',
      ),
      (
        'Pr. Christine Etoa',
        'c.etoa@educoach.cm',
        UserRole.teacher,
        'Droit privé',
      ),
      ('Dr. Blaise Onana', 'b.onana@educoach.cm', UserRole.teacher, 'Médecine'),
      (
        'Nadège Fotso',
        'nadege.f@educoach.cm',
        UserRole.student,
        'Informatique · M2',
      ),
      (
        'Franck Kamdem',
        'f.kamdem@educoach.cm',
        UserRole.student,
        'Gestion des entreprises · L3',
      ),
      (
        'Aïcha Sadou',
        'a.sadou@educoach.cm',
        UserRole.teacher,
        'Gestion des entreprises',
      ),
      (
        'Bertrand Mbarga',
        'b.mbarga@educoach.cm',
        UserRole.student,
        'Réseaux & Télécoms · L1',
      ),
      (
        'Estelle Ngo Bell',
        'e.ngo@educoach.cm',
        UserRole.admin,
        'Direction pédagogique',
      ),
      (
        'Rodrigue Ayissi',
        'r.ayissi@educoach.cm',
        UserRole.student,
        'Lettres modernes · L2',
      ),
      (
        'Chantal Larissa',
        'c.larissa@educoach.cm',
        UserRole.teacher,
        'Médecine',
      ),
      (
        'Keller Olinga',
        'k.olinga@educoach.cm',
        UserRole.student,
        'Informatique · L3',
      ),
    ];
    return [
      for (var i = 0; i < seedNames.length; i++)
        _Account(
          id: 'u$i',
          name: seedNames[i].$1,
          email: seedNames[i].$2,
          role: seedNames[i].$3,
          filiere: seedNames[i].$4,
        ),
    ];
  }

  static List<_ValidationItem> validations() {
    final courses = MockData.courses.take(6).toList();
    final summaries = <String>[
      'Nouveau parcours de 12 leçons sur les structures de données avancées, '
          'avec QCM, exercices d\'ordonnancement et 2 devoirs notés.',
      'Révision du chapitre sur les obligations contractuelles en droit '
          'OHADA : mise à jour des références aux articles 35 à 78.',
      'Ajout de 3 études de cas camerounaises sur la microfinance et la '
          'fiscalité locale (CGI 2024 révisé).',
      'Refonte complète du module anatomie : 6 nouvelles animations 3D '
          'et 18 QCM conformes au référentiel MINSANTE.',
      'Ajout d\'un laboratoire virtuel réseau (topologie, DHCP, DNS) '
          'pour la filière IUT Réseaux & Télécoms.',
      'Module sur la constitution camerounaise de 1996 révisée, '
          'avec comparaisons avec les chartes africaines des droits.',
    ];
    final icons = <IconData>[
      Icons.memory_rounded,
      Icons.balance_rounded,
      Icons.account_balance_rounded,
      Icons.medical_services_rounded,
      Icons.lan_rounded,
      Icons.gavel_rounded,
    ];
    final colors = <Color>[
      const Color(0xFF3F51B5),
      const Color(0xFF5D4037),
      const Color(0xFFD81B60),
      const Color(0xFFC62828),
      const Color(0xFF00897B),
      const Color(0xFF7C4DFF),
    ];
    final out = <_ValidationItem>[];
    for (var i = 0; i < courses.length; i++) {
      out.add(
        _ValidationItem(
          id: 'val-$i',
          title: '${courses[i].title} — révision',
          kind: 'Parcours · ${courses[i].code}',
          submitter: courses[i].teacher,
          summary: summaries[i % summaries.length],
          icon: icons[i % icons.length],
          accent: colors[i % colors.length],
        ),
      );
    }
    return out;
  }

  static List<_DataRequest> dataRequests() {
    return const [
      _DataRequest(
        title: 'Demande de rectification',
        email: 'awa.ndiaye@educoach.cm',
        daysAgo: 2,
        status: _ReqStatus.open,
        assignee: 'DPO — Me Ngo',
      ),
      _DataRequest(
        title: 'Export de mes données (portabilité)',
        email: 'm.tchoumi@educoach.cm',
        daysAgo: 4,
        status: _ReqStatus.reviewing,
        assignee: 'DPO — Me Ngo',
      ),
      _DataRequest(
        title: 'Opposition au traitement marketing',
        email: 'n.fotso@educoach.cm',
        daysAgo: 8,
        status: _ReqStatus.closed,
        assignee: 'Service conformité',
      ),
      _DataRequest(
        title: 'Effacement après radiation',
        email: 'r.ayissi@educoach.cm',
        daysAgo: 15,
        status: _ReqStatus.closed,
        assignee: 'DPO — Me Ngo',
      ),
    ];
  }

  static List<String> auditLogs() {
    final now = DateTime.now();
    String ts(Duration off) {
      final t = now.subtract(off);
      String two(int n) => n.toString().padLeft(2, '0');
      return '${t.year}-${two(t.month)}-${two(t.day)} '
          '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
    }

    return [
      '[${ts(const Duration(minutes: 3))}] LOGIN  admin@educoach.cm  ip=10.20.4.11',
      '[${ts(const Duration(minutes: 12))}] VALIDATION  parcours=INF402  by=Estelle Ngo',
      '[${ts(const Duration(hours: 1))}] EXPORT      requester=m.tchoumi@educoach.cm  status=pending',
      '[${ts(const Duration(hours: 2, minutes: 15))}] BLOCK      account=abena.m@educoach.cm  reason=spam',
      '[${ts(const Duration(hours: 5))}] RETENTION  purge=logs>90j  deleted=1283',
      '[${ts(const Duration(hours: 8))}] POLICY     terms=v2.4 publié (loi 2010/012 conforme)',
      '[${ts(const Duration(days: 1))}] LOGIN  prof.c.etoa@educoach.cm  ip=10.20.6.44',
      '[${ts(const Duration(days: 1, hours: 4))}] AUDIT      ART-T et trimestriel : OK',
    ];
  }
}
