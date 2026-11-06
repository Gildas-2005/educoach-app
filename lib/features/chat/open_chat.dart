import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/models/learning_models.dart';
import '../../core/session/chat_store.dart';
import 'chat_thread_page.dart';

/// Ouvre (ou crée) la discussion rattachée à une leçon puis navigue dessus.
///
/// Appelé depuis le lecteur de leçon et le parcours de cours : la
/// conversation hérite automatiquement du cours, de l'unité et de la leçon
/// en cours, exactement comme l'exige le référencement des discussions.
Future<void> openLessonChat(
  BuildContext context, {
  required String courseCode,
  required Unit unit,
  required Lesson lesson,
}) async {
  final convo = ChatStore.instance.openOrCreateForLesson(
    courseCode: courseCode,
    unit: unit,
    lesson: lesson,
  );
  await Navigator.of(
    context,
  ).push(FadeSlideRoute<void>(page: ChatThreadPage(conversationId: convo.id)));
}
