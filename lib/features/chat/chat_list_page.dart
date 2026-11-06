import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/models/chat_models.dart';
import '../../core/session/auth_store.dart';
import '../../core/session/chat_store.dart';
import '../../core/widgets/aurora_backdrop.dart';
import '../../core/widgets/common_widgets.dart';
import 'chat_thread_page.dart';

/// Liste des discussions côté étudiant et enseignant.
///
/// - Étudiant : « Mes discussions » — ses questions, avec statut et
///   nouveau messages des professeurs (badge de notification).
/// - Enseignant : « Boîte de réception » — les questions reçues, filtrées
///   par statut pour traiter en priorité l'« en attente ».
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  ChatStatus? _filter;
  String _query = '';

  bool get _isTeacher => AuthStore.instance.user?.role == UserRole.teacher;

  void _open(Conversation c) {
    Navigator.of(context)
        .push(FadeSlideRoute<void>(page: ChatThreadPage(conversationId: c.id)));
  }

  @override
  Widget build(BuildContext context) {
    final store = ChatScope.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final all = store.conversations;
        final filtered = all.where((c) {
          final okStatus = _filter == null || c.status == _filter;
          final q = _query.toLowerCase();
          final okQuery =
              q.isEmpty ||
              (_isTeacher ? c.studentName : c.teacherName)
                  .toLowerCase()
                  .contains(q) ||
              c.ref.courseTitle.toLowerCase().contains(q) ||
              c.ref.lessonTitle.toLowerCase().contains(q);
          return okStatus && okQuery;
        }).toList();

        return SafeArea(
          bottom: false,
          child: Stack(
            children: [
              AuroraBackdrop(
                primary: _isTeacher
                    ? const Color(0xFF00897B)
                    : const Color(0xFF7C4DFF),
                accentA: const Color(0xFF3F51B5),
                accentB: const Color(0xFF00BCD4),
                intensity: 0.5,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isTeacher
                                ? 'Boîte de réception'
                                : 'Mes discussions',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (store.totalUnread > 0)
                          PillBadge(
                            label: '${store.totalUnread} nouveau',
                            color: const Color(0xFFD81B60),
                            filled: true,
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: _isTeacher
                            ? 'Rechercher un étudiant, un cours…'
                            : 'Rechercher un professeur, une leçon…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.82),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Tous',
                          selected: _filter == null,
                          color: theme.colorScheme.primary,
                          onTap: () => setState(() => _filter = null),
                        ),
                        for (final s in ChatStatus.values)
                          _FilterChip(
                            label: s.label,
                            selected: _filter == s,
                            color: s.color,
                            onTap: () => setState(() => _filter = s),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: filtered.isEmpty
                        ? _EmptyChats(isTeacher: _isTeacher)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final c = filtered[i];
                              return FadeSlideIn(
                                delay: Duration(milliseconds: 50 * i),
                                child: _ConversationTile(
                                  convo: c,
                                  isTeacher: _isTeacher,
                                  onTap: () => _open(c),
                                ),
                              );
                            },
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.emphasized,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.convo,
    required this.isTeacher,
    required this.onTap,
  });
  final Conversation convo;
  final bool isTeacher;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final peer = isTeacher ? convo.studentName : convo.teacherName;
    final last = convo.lastMessage;
    final preview = _previewOf(last);
    final unread = convo.unreadCount;
    final ref = convo.ref;

    return PressableScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: unread > 0
                ? ref.color.withValues(alpha: 0.5)
                : theme.colorScheme.outlineVariant,
            width: unread > 0 ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ref.color.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                InitialsAvatar(
                  initials: _initials(peer),
                  background: ref.color,
                  size: 48,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      convo.status.icon,
                      size: 14,
                      color: convo.status.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          peer,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        _relTime(convo.lastActivity),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.link_rounded, size: 12, color: ref.color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${ref.courseCode} · ${ref.lessonTitle}',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: ref.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ref.color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _previewOf(ChatMessage? m) {
    if (m == null) return 'Nouvelle discussion';
    final who = m.fromStudent ? 'Toi : ' : '';
    switch (m.kind) {
      case MessageKind.voice:
        return '$who🎤 Message vocal (${m.voiceSeconds}s)';
      case MessageKind.attachment:
        final a = m.attachment;
        return '$who📎 ${a?.name ?? 'Pièce jointe'}';
      case MessageKind.text:
        return '$who${m.text}';
    }
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats({required this.isTeacher});
  final bool isTeacher;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: isTeacher
            ? Icons.forum_rounded
            : Icons.chat_bubble_outline_rounded,
        title: isTeacher
            ? 'Aucune question en attente'
            : 'Pas encore de discussion',
        message: isTeacher
            ? 'Les questions de tes étudiants apparaîtront ici, rattachées '
                  'à leur leçon en cours.'
            : 'Depuis une leçon, appuie sur « Demander au prof » pour '
                  'ouvrir une discussion liée au chapitre.',
      ),
    );
  }
}

String _relTime(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'à l\'instant';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min';
  if (diff.inHours < 24) return '${diff.inHours} h';
  if (diff.inDays < 7) return '${diff.inDays} j';
  return '${d.day}/${d.month}';
}

String _initials(String name) {
  final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}
