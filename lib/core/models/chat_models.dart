import 'package:flutter/material.dart';

/// Canal d'un message : qui l'a envoyé.
enum ChatParty { student, teacher }

/// Nature du contenu d'un message.
enum MessageKind {
  /// Texte simple.
  text,

  /// Message vocal (mock : durée + waveform, pas de vrai fichier).
  voice,

  /// Pièce jointe (PDF, Word, image, vidéo).
  attachment,
}

/// Cycle de vie d'une discussion.
enum ChatStatus {
  /// L'étudiant a posé une question, aucun enseignant n'a répondu.
  pending('En attente', Color(0xFFEF6C00), Icons.hourglass_top_rounded),

  /// Au moins un enseignant a répondu, l'étudiant n'a pas clôturé.
  answered('Répondu', Color(0xFF3F51B5), Icons.mark_chat_read_rounded),

  /// L'étudiant (ou le prof) a marqué la discussion comme résolue.
  resolved('Résolu', Color(0xFF43A047), Icons.verified_rounded);

  const ChatStatus(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

/// Types de pièces jointes prises en charge.
enum AttachmentKind {
  pdf('PDF', Icons.picture_as_pdf_rounded, Color(0xFFD32F2F)),
  word('Word', Icons.description_rounded, Color(0xFF1565C0)),
  image('Image', Icons.image_rounded, Color(0xFF00897B)),
  video('Vidéo', Icons.movie_rounded, Color(0xFF7C4DFF));

  const AttachmentKind(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

/// Un fichier joint à un message (métadonnées seulement — démo sans backend).
@immutable
class Attachment {
  const Attachment({
    required this.kind,
    required this.name,
    this.sizeLabel = '',
  });
  final AttachmentKind kind;
  final String name;
  final String sizeLabel;
}

/// Un message au sein d'une conversation.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.party,
    required this.kind,
    required this.sentAt,
    this.text = '',
    this.attachment,
    this.voiceSeconds = 0,
    this.readByPeer = false,
  });

  final String id;
  final ChatParty party;
  final MessageKind kind;
  final DateTime sentAt;
  final String text;
  final Attachment? attachment;

  /// Durée d'un message vocal (secondes) ; 0 si non vocal.
  final int voiceSeconds;

  /// Marquer le message lu par le destinataire (pour les doubles coches).
  final bool readByPeer;

  bool get fromStudent => party == ChatParty.student;
}

/// Références pédagogiques attachées à une discussion : la leçon, l'unité
/// et le cours concerné. Injectées automatiquement quand l'étudiant lance
/// une question depuis le lecteur de leçon ou le parcours.
@immutable
class LessonRef {
  const LessonRef({
    required this.courseCode,
    required this.courseTitle,
    required this.unitTitle,
    required this.lessonTitle,
    this.teacher = '',
    this.color = const Color(0xFF3F51B5),
    this.icon,
  });
  final String courseCode;
  final String courseTitle;
  final String unitTitle;
  final String lessonTitle;
  final String teacher;
  final Color color;
  final IconData? icon;

  String get label => '$courseCode · $lessonTitle';
}

/// Une conversation complète entre un étudiant et un (ou des) enseignant(s),
/// rattachée à une leçon précise.
@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.studentName,
    required this.teacherName,
    required this.ref,
    required this.status,
    required this.messages,
    required this.createdAt,
  });

  final String id;
  final String studentName;
  final String teacherName;
  final LessonRef ref;
  final ChatStatus status;
  final List<ChatMessage> messages;
  final DateTime createdAt;

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  DateTime get lastActivity =>
      messages.isEmpty ? createdAt : messages.last.sentAt;

  int get unreadCount => messages
      .where((m) => m.party == ChatParty.teacher && !m.readByPeer)
      .length;

  Conversation copyWith({ChatStatus? status, List<ChatMessage>? messages}) =>
      Conversation(
        id: id,
        studentName: studentName,
        teacherName: teacherName,
        ref: ref,
        status: status ?? this.status,
        messages: messages ?? this.messages,
        createdAt: createdAt,
      );
}
