import 'package:flutter/material.dart';

/// Types d'exercices pris en charge par le moteur pédagogique Educoach.
enum ExerciseType {
  /// Question à choix multiples (une ou plusieurs bonnes réponses).
  qcm,

  /// Vrai ou Faux.
  trueFalse,

  /// Réponse texte libre (comparaison normalisée).
  textInput,

  /// Remettre des éléments dans l'ordre (algorithmique, phrases, etc.).
  ordering,

  /// Compléter un code / une formule (blank).
  fillBlank,
}

/// Une option pour les exercices de type QCM/VF.
@immutable
class ExerciseOption {
  const ExerciseOption({
    required this.id,
    required this.text,
    this.correct = false,
  });
  final String id;
  final String text;
  final bool correct;
}

/// Énoncé pédagogique interactif posé au sein d'une leçon.
@immutable
class Exercise {
  const Exercise({
    required this.id,
    required this.type,
    required this.prompt,
    required this.explanation,
    this.hint,
    this.options = const <ExerciseOption>[],
    this.expectedAnswer,
    this.orderItems = const <String>[],
    this.blankTemplate,
    this.acceptedAnswers = const <String>[],
    this.xp = 10,
  });

  final String id;
  final ExerciseType type;
  final String prompt;
  final String? hint;

  /// Explication affichée après la réponse ("correction").
  final String explanation;
  final List<ExerciseOption> options;

  /// Réponse attendue pour VF/textInput.
  final String? expectedAnswer;

  /// Éléments à ordonner pour [ExerciseType.ordering].
  final List<String> orderItems;

  /// Gabarit avec ___ pour [ExerciseType.fillBlank].
  final String? blankTemplate;

  /// Liste de réponses acceptées (variante pour textInput / fillBlank).
  final List<String> acceptedAnswers;

  final int xp;
}

/// Exemple concret présenté dans une leçon (code, raisonnement, cas).
@immutable
class Example {
  const Example({
    required this.title,
    required this.body,
    this.code,
    this.footnote,
  });
  final String title;
  final String body;
  final String? code;
  final String? footnote;
}

/// Une leçon : théorie + exemples + exercices.
@immutable
class Lesson {
  const Lesson({
    required this.id,
    required this.courseCode,
    required this.unitId,
    required this.title,
    required this.subtitle,
    required this.theory,
    required this.examples,
    required this.exercises,
    this.xpReward = 20,
    this.icon,
  });

  final String id;
  final String courseCode;
  final String unitId;
  final String title;
  final String subtitle;

  /// Paragraphes de cours proprement rédigés.
  final List<String> theory;
  final List<Example> examples;
  final List<Exercise> exercises;
  final int xpReward;
  final IconData? icon;
}

/// Une unité = chapitre thématique contenant plusieurs leçons.
@immutable
class Unit {
  const Unit({
    required this.id,
    required this.semesterId,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.lessons,
  });

  final String id;
  final String semesterId;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final List<Lesson> lessons;
}

/// Semestre : regroupement d'unités. Débloqué quand le précédent est
/// terminé à 100 %.
@immutable
class Semester {
  const Semester({
    required this.id,
    required this.courseCode,
    required this.index,
    required this.label,
    required this.units,
  });

  final String id;
  final String courseCode;
  final int index; // 1, 2, 3…
  final String label; // "Semestre 1"
  final List<Unit> units;
}

/// Devoir maison à rendre : exercices notés en une fois.
@immutable
class Homework {
  const Homework({
    required this.id,
    required this.courseCode,
    required this.title,
    required this.instruction,
    required this.dueDate,
    required this.exercises,
    this.points = 20,
  });

  final String id;
  final String courseCode;
  final String title;
  final String instruction;
  final DateTime dueDate;
  final List<Exercise> exercises;
  final int points;
}

/// Résultat d'une leçon ou d'un devoir.
@immutable
class AttemptResult {
  const AttemptResult({
    required this.correctCount,
    required this.total,
    required this.xpEarned,
    required this.finishedAt,
  });

  final int correctCount;
  final int total;
  final int xpEarned;
  final DateTime finishedAt;

  double get accuracy => total == 0 ? 0 : correctCount / total;
  bool get passed => accuracy >= 0.6;
}
