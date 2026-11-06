import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/chat_models.dart';
import '../models/learning_models.dart';
import 'auth_store.dart';

/// Store des discussions étudiant ⇄ enseignant.
///
/// Singleton [ChangeNotifier] consommé via [ChatScope]. Aucune donnée n'est
/// envoyée à un serveur : tout est simulé localement, de façon déterministe,
/// avec une petite réponse automatique de l'enseignant pour rendre la
/// démonstration vivante.
///
/// Chaque discussion est [LessonRef]-ée : elle porte la leçon, l'unité et le
/// cours depuis lesquels elle a été ouverte.
class ChatStore extends ChangeNotifier {
  ChatStore._();
  static final ChatStore instance = ChatStore._();

  final List<Conversation> _conversations = <Conversation>[];
  bool _seeded = false;
  int _counter = 0;

  /// Discussions triées par activité la plus récente d'abord.
  List<Conversation> get conversations {
    if (!_seeded) _seed();
    final list = List<Conversation>.from(_conversations)
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    return list;
  }

  Conversation? byId(String id) {
    if (!_seeded) _seed();
    for (final c in _conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  int get totalUnread {
    if (!_seeded) _seed();
    return _conversations.fold(0, (s, c) => s + c.unreadCount);
  }

  int get pendingCount {
    if (!_seeded) _seed();
    return _conversations.where((c) => c.status == ChatStatus.pending).length;
  }

  /// Retourne une conversation existante pour [lesson] ou en crée une.
  Conversation openOrCreateForLesson({
    required String courseCode,
    required Unit unit,
    required Lesson lesson,
  }) {
    if (!_seeded) _seed();
    final key = 'ref-${lesson.id}';
    final existing = _conversations.where((c) => c.id.startsWith(key)).toList();
    if (existing.isNotEmpty) return existing.first;

    final course = MockData.courseByCode(courseCode);
    final user = AuthStore.instance.user;
    final ref = LessonRef(
      courseCode: courseCode,
      courseTitle: course?.title ?? lesson.courseCode,
      unitTitle: unit.title,
      lessonTitle: lesson.title,
      teacher: course?.teacher ?? 'Enseignant Educoach',
      color: course?.color ?? unit.color,
      icon: lesson.icon ?? unit.icon,
    );
    final now = DateTime.now();
    final convo = Conversation(
      id: '$key-${_counter++}',
      studentName: user?.fullName ?? 'Toi',
      teacherName: ref.teacher,
      ref: ref,
      status: ChatStatus.pending,
      createdAt: now,
      messages: [
        ChatMessage(
          id: '$key-m0',
          party: ChatParty.student,
          kind: MessageKind.text,
          sentAt: now,
          text:
              'Bonjour, j\'une question sur la leçon '
              '« ${lesson.title} ».',
        ),
      ],
    );
    _conversations.add(convo);
    notifyListeners();
    return convo;
  }

  /// Envoie un message dans [conversationId] depuis le rôle actif.
  /// Simule ensuite une réponse enseignant si l'étudiant vient d'écrire.
  void send(
    String conversationId, {
    required String text,
    Attachment? attachment,
    int voiceSeconds = 0,
  }) {
    final convo = byId(conversationId);
    if (convo == null) return;
    final isStudentView = AuthStore.instance.user?.role != UserRole.teacher;
    final party = isStudentView ? ChatParty.student : ChatParty.teacher;
    final now = DateTime.now();
    final kind = attachment != null
        ? MessageKind.attachment
        : voiceSeconds > 0
        ? MessageKind.voice
        : MessageKind.text;
    final msg = ChatMessage(
      id: '$conversationId-m${convo.messages.length + _counter++}',
      party: party,
      kind: kind,
      sentAt: now,
      text: text,
      attachment: attachment,
      voiceSeconds: voiceSeconds,
      readByPeer: !isStudentView,
    );
    var status = convo.status;
    if (isStudentView && status == ChatStatus.resolved) {
      status = ChatStatus.pending;
    }
    _replace(
      convo.copyWith(status: status, messages: [...convo.messages, msg]),
    );

    // Réponse automatique de l'enseignant (démo) si l'étudiant écrit
    // un message texte dans une discussion non résolue.
    if (isStudentView && kind == MessageKind.text) {
      _scheduleTeacherReply(convo.id, text);
    }
  }

  void _scheduleTeacherReply(String convoId, String question) {
    Future.delayed(const Duration(milliseconds: 1600), () {
      final c = byId(convoId);
      if (c == null || c.status == ChatStatus.resolved) return;
      final now = DateTime.now();
      final reply = ChatMessage(
        id: '$convoId-r${now.microsecondsSinceEpoch}',
        party: ChatParty.teacher,
        kind: MessageKind.text,
        sentAt: now,
        readByPeer: false,
        text: _teacherAnswerFor(question, c.ref),
      );
      _replace(
        c.copyWith(
          status: ChatStatus.answered,
          messages: [...c.messages, reply],
        ),
      );
    });
  }

  String _teacherAnswerFor(String question, LessonRef ref) {
    final q = question.toLowerCase();
    if (q.contains('exemple') || q.contains('concret')) {
      return 'Bien vu. Prends ${ref.lessonTitle} : applique la méthode '
          'étape par étape sur un cas du cours, puis vérifie le résultat. '
          'Je te joins un exemple détaillé dès que tu veux.';
    }
    if (q.contains('pourquoi') || q.contains('quoi sert')) {
      return 'Question pertinente. « ${ref.lessonTitle} » sert à résoudre '
          'un type précis de problème dans ${ref.courseTitle}. Retiens '
          'd\'abord l\'intuition, puis formalise : c\'est comme ça qu\'on '
          'le notera au partiel.';
    }
    return 'Merci pour ta question sur « ${ref.lessonTitle} ». On va '
        'détailler ça ensemble : reformule ce que tu as compris, et je '
        'corrige point par point. Tu peux aussi joindre ton brouillon.';
  }

  /// Marque tous les messages enseignant comme lus.
  void markRead(String conversationId) {
    final convo = byId(conversationId);
    if (convo == null || convo.unreadCount == 0) return;
    final msgs = convo.messages
        .map(
          (m) => m.party == ChatParty.teacher
              ? ChatMessage(
                  id: m.id,
                  party: m.party,
                  kind: m.kind,
                  sentAt: m.sentAt,
                  text: m.text,
                  attachment: m.attachment,
                  voiceSeconds: m.voiceSeconds,
                  readByPeer: true,
                )
              : m,
        )
        .toList();
    _replace(convo.copyWith(messages: msgs));
  }

  void setStatus(String conversationId, ChatStatus status) {
    final convo = byId(conversationId);
    if (convo == null) return;
    _replace(convo.copyWith(status: status));
  }

  void _replace(Conversation convo) {
    final idx = _conversations.indexWhere((c) => c.id == convo.id);
    if (idx >= 0) {
      _conversations[idx] = convo;
    } else {
      _conversations.add(convo);
    }
    notifyListeners();
  }

  void reset() {
    _conversations.clear();
    _seeded = false;
    _counter = 0;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Jeu de données initial déterministe (démo).
  // ------------------------------------------------------------------
  void _seed() {
    _seeded = true;
    final courses = MockData.courses.take(4).toList();
    final samples = <_SeedSpec>[
      _SeedSpec(
        student: 'Aline Mbarga',
        question:
            'Professeur, je ne comprends pas comment appliquer la '
            'récursion sur l\'exemple du cours.',
        answer:
            'La récursion, c\'est se fier à la propriété : suppose que '
            'le sous-problème plus petit est résolu, alors assemble. '
            'Reprends mon exemple pas à pas.',
        status: ChatStatus.answered,
        ago: 3,
        voice: false,
      ),
      _SeedSpec(
        student: 'Rodrigue Nkoulou',
        question:
            'Pevez-vous envoyer le PDF du chapitre ? mon cahier est '
            'illisible.',
        answer: '',
        status: ChatStatus.pending,
        ago: 1,
        voice: true,
      ),
      _SeedSpec(
        student: 'Grace Fotso',
        question: 'Merci pour l\'explication, c\'est clair maintenant !',
        answer:
            'Parfait, je passe la discussion en résolue. Bon courage '
            'pour le partiel.',
        status: ChatStatus.resolved,
        ago: 26,
        voice: false,
      ),
      _SeedSpec(
        student: 'Ibrahim Bello',
        question:
            'L\'exercice sur les structures de contrôle est trop '
            'difficile, avez-vous un indice ?',
        answer:
            'Indice : décompose la condition en trois cas mutuellement '
            'exclusifs, comme dans la leçon.',
        status: ChatStatus.answered,
        ago: 8,
        voice: false,
      ),
    ];
    for (var i = 0; i < samples.length && i < courses.length; i++) {
      final course = courses[i];
      final s = samples[i];
      final now = DateTime.now();
      final t0 = now.subtract(Duration(hours: s.ago));
      final ref = LessonRef(
        courseCode: course.code,
        courseTitle: course.title,
        unitTitle: 'Unité I · Fondements',
        lessonTitle: _lessonGuess(course.title),
        teacher: course.teacher,
        color: course.color,
        icon: course.icon,
      );
      final msgs = <ChatMessage>[
        ChatMessage(
          id: 'seed-$i-m0',
          party: ChatParty.student,
          kind: s.voice ? MessageKind.voice : MessageKind.text,
          sentAt: t0,
          text: s.voice ? '' : s.question,
          voiceSeconds: s.voice ? 14 : 0,
          readByPeer: s.status != ChatStatus.pending,
        ),
      ];
      if (s.answer.isNotEmpty) {
        msgs.add(
          ChatMessage(
            id: 'seed-$i-m1',
            party: ChatParty.teacher,
            kind: MessageKind.text,
            sentAt: t0.add(const Duration(minutes: 42)),
            text: s.answer,
            readByPeer: s.status == ChatStatus.resolved,
          ),
        );
      } else {
        msgs.add(
          ChatMessage(
            id: 'seed-$i-a0',
            party: ChatParty.student,
            kind: MessageKind.attachment,
            sentAt: t0.add(const Duration(minutes: 3)),
            text: '',
            attachment: Attachment(
              kind: AttachmentKind.pdf,
              name: 'chapitre-${course.code}.pdf',
              sizeLabel: '1,2 Mo',
            ),
            readByPeer: false,
          ),
        );
      }
      _conversations.add(
        Conversation(
          id: 'seed-$i',
          studentName: s.student,
          teacherName: course.teacher,
          ref: ref,
          status: s.status,
          createdAt: t0,
          messages: msgs,
        ),
      );
    }
    notifyListeners();
  }

  String _lessonGuess(String courseTitle) {
    final t = courseTitle.toLowerCase();
    if (t.contains('algor')) return 'Récursion et invariants';
    if (t.contains('droit')) return 'Formation du contrat';
    if (t.contains('éco')) return 'Offre, demande et équilibre';
    if (t.contains('médec') || t.contains('physio')) {
      return 'Cycle cardiaque';
    }
    return ' Concepts fondamentaux';
  }
}

class _SeedSpec {
  const _SeedSpec({
    required this.student,
    required this.question,
    required this.answer,
    required this.status,
    required this.ago,
    required this.voice,
  });
  final String student;
  final String question;
  final String answer;
  final ChatStatus status;
  final int ago;
  final bool voice;
}

/// InheritedWidget expose [ChatStore] à tout le sous-arbre.
class ChatScope extends InheritedWidget {
  const ChatScope({super.key, required this.store, required super.child});

  final ChatStore store;

  static ChatStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ChatScope>();
    assert(scope != null, 'ChatScope absent de la hiérarchie.');
    return scope!.store;
  }

  @override
  bool updateShouldNotify(ChatScope oldWidget) => store != oldWidget.store;
}
