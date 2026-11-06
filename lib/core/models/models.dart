import 'package:flutter/material.dart';

/// Une filière (département / majeure universitaire).
///
/// L'étudiant choisit d'abord sa filière lors de l'onboarding, puis
/// l'application ne propose que les cours rattachés à cette filière.
@immutable
class Filiere {
  const Filiere({
    required this.id,
    required this.code,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.color,
    required this.degreeLevels,
    this.domain = '',
  });

  final String id;
  final String code; // ex : INF
  final String name; // ex : Informatique
  final String tagline; // phrase courte affichée sous le nom
  final IconData icon;
  final Color color;

  /// Niveaux proposés dans cette filière (L1, L2, L3, M1, M2).
  final List<String> degreeLevels;
  final String domain; // ex : Sciences & Technologies
}

/// Une matière / cours suivi par l'étudiant.
@immutable
class Course {
  const Course({
    required this.id,
    required this.code,
    required this.title,
    required this.teacher,
    required this.semester,
    required this.credits,
    required this.progress,
    required this.color,
    required this.icon,
    this.description = '',
    this.filiereId = '',
    this.level = '',
    this.weeklyHours = 0,
  });

  final String id;
  final String code; // ex : INF201
  final String title;
  final String teacher;
  final String semester;
  final int credits;

  /// Avancement 0.0 – 1.0 du programme.
  final double progress;
  final Color color;
  final IconData icon;
  final String description;

  /// Filière à laquelle ce cours est rattaché (voir [Filiere.id]).
  final String filiereId;

  /// Niveau d'études (L1, L2, L3, M1, M2).
  final String level;

  /// Volume horaire hebdomadaire (CM + TD + TP), indicatif.
  final int weeklyHours;
}

/// Une séance du planning hebdomadaire.
@immutable
class ScheduleBlock {
  const ScheduleBlock({
    required this.courseCode,
    required this.title,
    required this.dayOfWeek, // 1 = lundi ... 7 = dimanche
    required this.startHour,
    required this.endHour,
    required this.room,
    required this.type,
  });

  final String courseCode;
  final String title;
  final int dayOfWeek;
  final int startHour;
  final int endHour;
  final String room;

  /// 'CM', 'TD' ou 'TP'
  final String type;
}

/// Une ressource rattachée à un cours (PDF, vidéo, lien, etc.).
@immutable
class CourseResource {
  const CourseResource({
    required this.courseCode,
    required this.title,
    required this.kind,
    required this.updatedAt,
    this.sizeLabel = '',
  });

  final String courseCode;
  final String title;

  /// 'pdf' | 'video' | 'slide' | 'link' | 'audio'
  final String kind;
  final DateTime updatedAt;
  final String sizeLabel;
}

/// Une note / évaluation.
@immutable
class Grade {
  const Grade({
    required this.courseCode,
    required this.label,
    required this.score,
    required this.max,
    required this.date,
    this.weight = 1.0,
  });

  final String courseCode;
  final String label;
  final double score;
  final double max;
  final DateTime date;
  final double weight;

  double get ratio => max == 0 ? 0 : score / max;
  double get noteSur20 => ratio * 20;
}

/// Un devoir / tâche à faire.
@immutable
class Assignment {
  const Assignment({
    required this.courseCode,
    required this.title,
    required this.dueDate,
    required this.done,
  });

  final String courseCode;
  final String title;
  final DateTime dueDate;
  final bool done;
}
