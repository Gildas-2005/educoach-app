import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/models/chat_models.dart';
import '../../core/session/auth_store.dart';
import '../../core/session/chat_store.dart';
import '../../core/widgets/aurora_backdrop.dart';
import '../../core/widgets/common_widgets.dart';

/// Discussion étudiante ⇄ enseignante.
///
/// Le haut de l'écran ancre la discussion à sa leçon (référencement
/// automatique). Le corps affiche les messages (texte, vocal, pièce jointe).
/// Le bas est un composer : joindre un fichier, écrire, ou envoyer un
/// message vocal simulé.
class ChatThreadPage extends StatefulWidget {
  const ChatThreadPage({super.key, required this.conversationId});
  static const routeName = '/chat/thread';

  final String conversationId;

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _expandedRef = false;

  bool get _isStudent => AuthStore.instance.user?.role != UserRole.teacher;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatScope.of(context).markRead(widget.conversationId);
      _jumpToBottom();
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _jumpToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: Motion.normal,
      curve: Motion.emphasized,
    );
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    ChatScope.of(context).send(widget.conversationId, text: text);
    _inputCtrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  void _sendVoice(int seconds) {
    ChatScope.of(context)
        .send(widget.conversationId, text: '', voiceSeconds: seconds);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  void _sendAttachment(Attachment a) {
    ChatScope.of(context).send(widget.conversationId, text: '', attachment: a);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final store = ChatScope.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final convo = store.byId(widget.conversationId);
        if (convo == null) {
          return const Scaffold(
            body: Center(child: Text('Conversation introuvable.')),
          );
        }
        final theme = Theme.of(context);
        final refColor = convo.ref.color;
        return Scaffold(
          body: Stack(
            children: [
              AuroraBackdrop(
                primary: refColor,
                accentA: const Color(0xFF7C4DFF),
                accentB: const Color(0xFF00BCD4),
                intensity: 0.55,
              ),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _ThreadHeader(
                      convo: convo,
                      expanded: _expandedRef,
                      onToggleRef: () =>
                          setState(() => _expandedRef = !_expandedRef),
                      onBack: () => Navigator.of(context).pop(),
                      peerLabel: _isStudent
                          ? convo.teacherName
                          : convo.studentName,
                      onResolve: () => _resolveSheet(convo),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        itemCount: convo.messages.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return _LessonContextCard(convo: convo);
                          }
                          final m = convo.messages[i - 1];
                          return _MessageBubble(
                            message: m,
                            isStudentView: _isStudent,
                          );
                        },
                      ),
                    ),
                    _Composer(
                      isStudent: _isStudent,
                      ctrl: _inputCtrl,
                      onSend: _send,
                      onAttach: () => _attachSheet(),
                      onVoice: () => _voiceSheet(),
                      accent: refColor,
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _resolveSheet(Conversation convo) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Statut de la discussion',
                  style: Theme.of(ctx).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                for (final s in ChatStatus.values)
                  ListTile(
                    leading: Icon(s.icon, color: s.color),
                    title: Text(s.label),
                    trailing: convo.status == s
                        ? Icon(
                            Icons.check_rounded,
                            color: Theme.of(ctx).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      ChatScope.of(context).setStatus(convo.id, s);
                      Navigator.of(ctx).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _attachSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Joindre un fichier',
                  style: Theme.of(ctx).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'PDF, Word, images et vidéos (démo locale).',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                for (final k in AttachmentKind.values)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: k.color.withValues(alpha: 0.14),
                      child: Icon(k.icon, color: k.color, size: 20),
                    ),
                    title: Text('Envoyer un ${k.label.toLowerCase()}'),
                    subtitle: Text(_sampleFileName(k)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _sendAttachment(
                        Attachment(
                          kind: k,
                          name: _sampleFileName(k),
                          sizeLabel: _sampleSize(k),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _sampleFileName(AttachmentKind k) => switch (k) {
    AttachmentKind.pdf => 'chapitre-revision.pdf',
    AttachmentKind.word => 'exercice-dirige.docx',
    AttachmentKind.image => 'photo-tableau.jpg',
    AttachmentKind.video => 'demo-capture.mp4',
  };

  String _sampleSize(AttachmentKind k) => switch (k) {
    AttachmentKind.pdf => '840 Ko',
    AttachmentKind.word => '126 Ko',
    AttachmentKind.image => '1,4 Mo',
    AttachmentKind.video => '6,8 Mo',
  };

  void _voiceSheet() {
    showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => const _VoiceRecordSheet(),
    ).then((seconds) {
      if (seconds != null && seconds > 0) _sendVoice(seconds);
    });
  }
}

// ---------------------------------------------------------------------------
// En-tête : nom du correspondant + référence leçon + statut.
// ---------------------------------------------------------------------------
class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({
    required this.convo,
    required this.expanded,
    required this.onToggleRef,
    required this.onBack,
    required this.peerLabel,
    required this.onResolve,
  });
  final Conversation convo;
  final bool expanded;
  final VoidCallback onToggleRef;
  final VoidCallback onBack;
  final String peerLabel;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ref = convo.ref;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                InitialsAvatar(
                  initials: _initials(peerLabel),
                  background: ref.color,
                  size: 40,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        peerLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        ref.courseTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PillBadge(
                  label: convo.status.label,
                  color: convo.status.color,
                  filled: convo.status != ChatStatus.pending,
                ),
                IconButton(
                  onPressed: onResolve,
                  tooltip: 'Changer le statut',
                  icon: const Icon(Icons.more_vert_rounded),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onToggleRef,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
              child: Row(
                children: [
                  Icon(Icons.link_rounded, size: 16, color: ref.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Leçon : ${ref.lessonTitle}',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ref.color,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: Motion.normal,
            curve: Motion.emphasized,
            child: expanded
                ? Container(
                    width: double.infinity,
                    color: ref.color.withValues(alpha: 0.06),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RefRow(
                          label: 'Cours',
                          value: '${ref.courseCode} · ${ref.courseTitle}',
                        ),
                        _RefRow(label: 'Unité', value: ref.unitTitle),
                        _RefRow(label: 'Leçon', value: ref.lessonTitle),
                        _RefRow(label: 'Enseignant', value: ref.teacher),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _RefRow extends StatelessWidget {
  const _RefRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte contextuelle affichée en tête du fil : on rappelle le chapitre.
// ---------------------------------------------------------------------------
class _LessonContextCard extends StatelessWidget {
  const _LessonContextCard({required this.convo});
  final Conversation convo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ref = convo.ref;
    return FadeSlideIn(
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: ref.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ref.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ref.icon ?? Icons.school_rounded,
                size: 18,
                color: ref.color,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Discussion rattachée à « ${ref.unitTitle} »',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ref.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bulle de message (texte / vocal / pièce jointe).
// ---------------------------------------------------------------------------
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isStudentView});
  final ChatMessage message;
  final bool isStudentView;

  bool get _mine => isStudentView ? message.fromStudent : !message.fromStudent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final senderColor = message.fromStudent
        ? const Color(0xFF3F51B5)
        : const Color(0xFF00897B);
    final bubbleBg = _mine ? senderColor : Colors.white.withValues(alpha: 0.94);
    final fg = _mine ? Colors.white : theme.colorScheme.onSurface;

    return Align(
      alignment: _mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: EdgeInsets.only(
          bottom: 10,
          left: _mine ? 40 : 0,
          right: _mine ? 0 : 40,
        ),
        child: Column(
          crossAxisAlignment: _mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!_mine)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 3),
                child: Text(
                  message.fromStudent ? 'Étudiant' : 'Enseignant',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: senderColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(_mine ? 18 : 6),
                  bottomRight: Radius.circular(_mine ? 6 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: senderColor.withValues(alpha: 0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _content(fg, theme),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _time(message.sentAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_mine && message.fromStudent)
                  Icon(
                    message.readByPeer
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 14,
                    color: message.readByPeer
                        ? const Color(0xFF00897B)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(Color fg, ThemeData theme) {
    switch (message.kind) {
      case MessageKind.voice:
        return _VoiceBody(seconds: message.voiceSeconds, fg: fg, mine: _mine);
      case MessageKind.attachment:
        final a = message.attachment!;
        return _AttachmentBody(attachment: a, fg: fg);
      case MessageKind.text:
        return Text(
          message.text,
          style: TextStyle(color: fg, fontSize: 15, height: 1.35),
        );
    }
  }

  String _time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _VoiceBody extends StatefulWidget {
  const _VoiceBody({
    required this.seconds,
    required this.fg,
    required this.mine,
  });
  final int seconds;
  final Color fg;
  final bool mine;

  @override
  State<_VoiceBody> createState() => _VoiceBodyState();
}

class _VoiceBodyState extends State<_VoiceBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.seconds.clamp(1, 60)),
  );
  bool _playing = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _fmt(int s) => '0:${s.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final bars = 22;
    final rng = math.Random(widget.seconds + 7);
    final heights = List<double>.generate(
      bars,
      (_) => 4 + rng.nextDouble() * 16,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              if (_playing) {
                _c.stop();
                _c.value = 0;
              } else {
                _c.forward(from: 0);
              }
              _playing = !_playing;
            });
            _c.addListener(() {
              if (_c.isCompleted && _playing) {
                setState(() => _playing = false);
              }
            });
          },
          child: AnimatedContainer(
            duration: Motion.fast,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.mine
                  ? Colors.white.withValues(alpha: 0.25)
                  : const Color(0xFF00897B).withValues(alpha: 0.14),
            ),
            child: Icon(
              _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 20,
              color: widget.fg,
            ),
          ),
        ),
        const SizedBox(width: 10),
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var i = 0; i < bars; i++)
                  Container(
                    width: 3,
                    height:
                        heights[i] *
                        (i / bars <= _c.value && _playing ? 1.25 : 1.0),
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: widget.fg.withValues(
                        alpha: i / bars <= _c.value ? 0.95 : 0.45,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 10),
        Text(
          _fmt(widget.seconds),
          style: TextStyle(
            color: widget.fg,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _AttachmentBody extends StatelessWidget {
  const _AttachmentBody({required this.attachment, required this.fg});
  final Attachment attachment;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final k = attachment.kind;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: k.color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(k.icon, color: k.color, size: 22),
        ),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                attachment.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                '${k.label} · ${attachment.sizeLabel}',
                style: TextStyle(
                  color: fg.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Composer : joindre, écrire, vocal.
// ---------------------------------------------------------------------------
class _Composer extends StatelessWidget {
  const _Composer({
    required this.isStudent,
    required this.ctrl,
    required this.onSend,
    required this.onAttach,
    required this.onVoice,
    required this.accent,
    required this.theme,
  });
  final bool isStudent;
  final TextEditingController ctrl;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onVoice;
  final Color accent;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onAttach,
                tooltip: 'Joindre un fichier',
                icon: Icon(Icons.attach_file_rounded, color: accent),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          minLines: 1,
                          maxLines: 5,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => onSend(),
                          decoration: InputDecoration(
                            hintText: isStudent
                                ? 'Écris ta question…'
                                : 'Réponds à l\'étudiant…',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onSend,
                        tooltip: 'Envoyer',
                        icon: Icon(Icons.send_rounded, color: accent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onVoice,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[accent, const Color(0xFF7C4DFF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fiche d'enregistrement vocal simulé (timer + onde vivante).
// ---------------------------------------------------------------------------
class _VoiceRecordSheet extends StatefulWidget {
  const _VoiceRecordSheet();

  @override
  State<_VoiceRecordSheet> createState() => _VoiceRecordSheetState();
}

class _VoiceRecordSheetState extends State<_VoiceRecordSheet>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  Timer? _ticker;
  int _seconds = 0;
  bool _recording = true;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds >= 60) {
        _stop();
        return;
      }
      setState(() => _seconds += 1);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _stop() {
    _ticker?.cancel();
    setState(() => _recording = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _recording ? 'Enregistrement…' : 'Message prêt',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _fmt(_seconds),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFFD81B60),
              ),
            ),
            const SizedBox(height: 18),
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                return Transform.scale(
                  scale: _recording ? 1 + _pulse.value * 0.12 : 1,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0xFFD81B60), Color(0xFF7C4DFF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD81B60).withValues(alpha: 0.4),
                          blurRadius: 26,
                          spreadRadius: _recording ? _pulse.value * 8 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      _recording ? Icons.mic_rounded : Icons.check_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(0),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Annuler'),
                ),
                if (!_recording)
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(_seconds),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Envoyer'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _stop,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Arrêter'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

String _initials(String name) {
  final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}
