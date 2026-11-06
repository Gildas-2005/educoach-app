import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/session/session_store.dart';
import '../chat/chat_list_page.dart';
import '../courses/courses_page.dart';
import '../grades/grades_page.dart';
import '../home/home_page.dart';
import '../profile/profile_page.dart';
import '../schedule/schedule_page.dart';

/// Hôte des 5 onglets principaux de l'application.
///
/// Chaque bascule est animée (fade + slide doux) et l'état des pages est
/// préservé via un [IndexedStack] invisible. La coquille réagit aussi aux
/// changements de filière en rechargeant dynamiquement le contenu.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  late int _index = widget.initialTab;
  late final SessionStore _session = SessionStore.instance;

  static const _tabs = <_TabItem>[
    _TabItem(
      label: 'Accueil',
      labelEn: 'Home',
      icon: Icons.home_outlined,
      selected: Icons.home_rounded,
    ),
    _TabItem(
      label: 'Cours',
      labelEn: 'Courses',
      icon: Icons.menu_book_outlined,
      selected: Icons.menu_book_rounded,
    ),
    _TabItem(
      label: 'Messages',
      labelEn: 'Messages',
      icon: Icons.forum_outlined,
      selected: Icons.forum_rounded,
    ),
    _TabItem(
      label: 'Planning',
      labelEn: 'Schedule',
      icon: Icons.event_outlined,
      selected: Icons.event_rounded,
    ),
    _TabItem(
      label: 'Notes',
      labelEn: 'Grades',
      icon: Icons.insights_outlined,
      selected: Icons.insights_rounded,
    ),
    _TabItem(
      label: 'Profil',
      labelEn: 'Profile',
      icon: Icons.person_outline_rounded,
      selected: Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionChange);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChange);
    super.dispose();
  }

  void _onSessionChange() {
    // Force un rebuild des pages dépendant de la session (via les keys).
    setState(() {});
  }

  void _goTo(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final key = '${_session.filiere?.id ?? 'none'}-${_session.level}';
    final pages = <Widget>[
      HomePage(key: ValueKey('home-$key'), onOpenTab: _goTo),
      CoursesPage(key: ValueKey('courses-$key')),
      const ChatListPage(),
      SchedulePage(key: ValueKey('schedule-$key')),
      GradesPage(key: ValueKey('grades-$key')),
      ProfilePage(key: ValueKey('profile-$key')),
    ];

    final theme = Theme.of(context);

    return Scaffold(
      body: _AnimatedTabView(index: _index, children: pages),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _goTo,
          destinations: [
            for (final t in _tabs)
              NavigationDestination(
                icon: _AnimatedIcon(
                  icon: t.icon,
                  selected: _index == _tabs.indexOf(t),
                  selectedChild: Icon(t.selected),
                  child: Icon(t.icon),
                ),
                label: context.texts.t(t.label, t.labelEn),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bascule animée entre onglets : fondu + léger glissement latéral
/// qui respecte le sens de navigation.
class _AnimatedTabView extends StatelessWidget {
  const _AnimatedTabView({required this.index, required this.children});
  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.normal,
      switchInCurve: Motion.emphasized,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) {
        final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        final slide = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Motion.emphasized));
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey<int>(index), child: children[index]),
    );
  }
}

/// Icône d'onglet avec effet de rebond au moment où il devient actif.
class _AnimatedIcon extends StatelessWidget {
  const _AnimatedIcon({
    required this.icon,
    required this.selected,
    required this.child,
    required this.selectedChild,
  });

  final IconData icon;
  final bool selected;
  final Widget child;
  final Widget selectedChild;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.fast,
      switchInCurve: Motion.springy,
      transitionBuilder: (c, a) => ScaleTransition(
        scale: Tween<double>(begin: 0.7, end: 1).animate(a),
        child: FadeTransition(opacity: a, child: c),
      ),
      child: selected ? selectedChild : child,
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.label,
    required this.labelEn,
    required this.icon,
    required this.selected,
  });
  final String label;
  final String labelEn;
  final IconData icon;
  final IconData selected;
}
