import 'package:flutter/material.dart';

import '../data/learning_seed.dart';
import '../data/mock_data.dart';
import '../models/learning_models.dart';
import '../models/models.dart';

/// Règles de progression pédagogique Educoach.
///
/// Le store conserve pour chaque apprenant :
///   • le résultat de chaque leçon (précision, XP gagné, date) ;
///   • l'XP total et par cours ;
///   • la série (streak) de jours consécutifs ;
///   • les cœurs (5 par défaut, rechargés avec le temps ou l'XP) ;
///   • l'état de verrouillage des semestres, unités et leçons.
///
/// Règle d'or : un contenu N+1 se débloque uniquement quand le contenu N
/// est terminé (toutes les leçons validées, devoirs rendus, précision >= 60 %).
class LearningStore extends ChangeNotifier {
  LearningStore._();
  static final LearningStore instance = LearningStore._();

  static const int maxHearts = 5;
  static const Duration heartRefillDelay = Duration(minutes: 10);
  static const double passingAccuracy = 0.6;

  final Map<String, AttemptResult> _lessonResults = <String, AttemptResult>{};
  final Map<String, AttemptResult> _homeworkResults = <String, AttemptResult>{};
  final Map<String, DateTime> _activityDays = <String, DateTime>{};
  int _totalXp = 0;
  int _hearts = maxHearts;
  DateTime? _lastHeartLoss;

  // ------- Getters -------
  int get totalXp => _totalXp;
  int get hearts => _hearts;
  bool get hasHearts => _hearts > 0;
  Map<String, AttemptResult> get lessonResults =>
      Map.unmodifiable(_lessonResults);
  Map<String, AttemptResult> get homeworkResults =>
      Map.unmodifiable(_homeworkResults);

  int xpForCourse(String courseCode) {
    var sum = 0;
    for (final e in _lessonResults.entries) {
      if (e.key.startsWith('$courseCode-')) sum += e.value.xpEarned;
    }
    return sum;
  }

  /// Nombre de jours consécutifs avec au moins une leçon terminée.
  int get streak {
    if (_activityDays.isEmpty) return 0;
    final days = _activityDays.values.toList()..sort((a, b) => b.compareTo(a));
    var current = _stripTime(days.first);
    // La série doit être active aujourd'hui ou hier.
    final today = _stripTime(DateTime.now());
    if (today.difference(current).inDays > 1) return 0;
    var count = 1;
    for (var i = 1; i < days.length; i++) {
      final d = _stripTime(days[i]);
      final diff = current.difference(d).inDays;
      if (diff == 1) {
        count++;
        current = d;
      } else if (diff == 0) {
        continue;
      } else {
        break;
      }
    }
    return count;
  }

  // ------- Mutations -------
  /// Enregistre la complétion d'une leçon.
  void recordLesson(Lesson lesson, AttemptResult result) {
    _lessonResults[lesson.id] = result;
    _totalXp += result.xpEarned;
    final key = _dayKey(DateTime.now());
    _activityDays[key] = DateTime.now();
    if (!result.passed) _loseHeart();
    notifyListeners();
  }

  void recordHomework(Homework hw, AttemptResult result) {
    _homeworkResults[hw.id] = result;
    _totalXp += result.xpEarned;
    notifyListeners();
  }

  void refillHearts() {
    _hearts = maxHearts;
    _lastHeartLoss = null;
    notifyListeners();
  }

  /// Réinitialise entièrement la progression (usage : tests ou logout).
  void reset() {
    _lessonResults.clear();
    _homeworkResults.clear();
    _activityDays.clear();
    _totalXp = 0;
    _hearts = maxHearts;
    _lastHeartLoss = null;
    notifyListeners();
  }

  void _loseHeart() {
    if (_hearts > 0) _hearts -= 1;
    _lastHeartLoss = DateTime.now();
  }

  /// Cœurs manquants + temps restant pour le prochain rechargement.
  Duration get nextHeartIn {
    if (_hearts >= maxHearts || _lastHeartLoss == null) {
      return Duration.zero;
    }
    final elapsed = DateTime.now().difference(_lastHeartLoss!);
    final remaining = heartRefillDelay - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // ------- Règles de déverrouillage -------

  bool isLessonCompleted(String lessonId) =>
      _lessonResults[lessonId]?.passed ?? false;

  bool isUnitCompleted(Unit unit) =>
      unit.lessons.every((l) => isLessonCompleted(l.id));

  bool isSemesterCompleted(Semester sem) => sem.units.every(isUnitCompleted);

  /// Une leçon est débloquée si :
  ///   • c'est la toute première de la première unité (semestre débloqué) ;
  ///   • OU la leçon précédente du même parcours est terminée.
  /// Le semestre doit lui-même être débloqué (le précédent est terminé).
  bool isLessonUnlocked(
    Semester semester,
    Unit unit,
    Lesson lesson, {
    required List<Semester> allSemesters,
  }) {
    if (!isSemesterUnlocked(semester, allSemesters: allSemesters)) {
      return false;
    }
    if (isLessonCompleted(lesson.id)) return true;
    final flat = <String>[];
    for (final s in _orderedSemesters(
      semester.courseCode,
      allSemesters: allSemesters,
    )) {
      for (final u in s.units) {
        for (final l in u.lessons) {
          flat.add(l.id);
        }
      }
    }
    final idx = flat.indexOf(lesson.id);
    if (idx <= 0) return idx == 0;
    return isLessonCompleted(flat[idx - 1]);
  }

  bool isSemesterUnlocked(
    Semester semester, {
    required List<Semester> allSemesters,
  }) {
    final siblings = _orderedSemesters(
      semester.courseCode,
      allSemesters: allSemesters,
    );
    final idx = siblings.indexWhere((s) => s.id == semester.id);
    if (idx <= 0) return idx == 0;
    return isSemesterCompleted(siblings[idx - 1]);
  }

  List<Semester> _orderedSemesters(
    String courseCode, {
    required List<Semester> allSemesters,
  }) {
    final list = allSemesters.where((s) => s.courseCode == courseCode).toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return list;
  }

  /// Progression globale d'un cours : 0..1 sur l'ensemble des leçons.
  double courseProgress(
    String courseCode, {
    required List<Semester> allSemesters,
  }) {
    final lessons = <Lesson>[];
    for (final s in allSemesters.where((x) => x.courseCode == courseCode)) {
      for (final u in s.units) {
        lessons.addAll(u.lessons);
      }
    }
    if (lessons.isEmpty) return 0;
    final done = lessons.where((l) => isLessonCompleted(l.id)).length;
    return done / lessons.length;
  }

  int courseLessonCount(
    String courseCode, {
    required List<Semester> allSemesters,
  }) {
    var n = 0;
    for (final s in allSemesters.where((x) => x.courseCode == courseCode)) {
      for (final u in s.units) {
        n += u.lessons.length;
      }
    }
    return n;
  }

  static DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);
  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------------
  // Notes dérivées de la progression réelle de l'apprenant.
  //
  // Règle : une note n'existe que si l'apprenant a réellement terminé des
  // leçons. Un nouvel utilisateur a donc 0 partout — les compteurs montent
  // à mesure qu'il progresse. Rien n'est simulé ni aléatoire.
  // ---------------------------------------------------------------------------

  /// Toutes les leçons d'un cours, dans l'ordre du parcours.
  static List<Lesson> lessonsOf(String courseCode) {
    final out = <Lesson>[];
    for (final s in LearningSeed.semestersFor(courseCode)) {
      for (final u in s.units) {
        out.addAll(u.lessons);
      }
    }
    return out;
  }

  /// Moyenne sur 20 des leçons réellement terminées d'un cours,
  /// ou null si l'apprenant n'a encore validé aucune leçon.
  double? courseNote(String courseCode) {
    final lessons = lessonsOf(courseCode);
    var sum = 0.0;
    var count = 0;
    for (final l in lessons) {
      final result = _lessonResults[l.id];
      if (result == null || !result.passed) continue;
      sum += result.accuracy * 20;
      count++;
    }
    return count == 0 ? null : sum / count;
  }

  /// Un cours est « terminé » quand toutes ses leçons sont validées.
  bool isCourseCompleted(String courseCode) {
    final lessons = lessonsOf(courseCode);
    if (lessons.isEmpty) return false;
    return lessons.every((l) => isLessonCompleted(l.id));
  }

  /// Progression 0..1 d'un niveau : part des leçons validées sur
  /// l'ensemble des cours du niveau.
  double levelProgress(Iterable<String> courseCodes) {
    var total = 0;
    var done = 0;
    for (final code in courseCodes) {
      final lessons = lessonsOf(code);
      total += lessons.length;
      done += lessons.where((l) => isLessonCompleted(l.id)).length;
    }
    return total == 0 ? 0 : done / total;
  }

  /// Moyenne du niveau sur 20, pondérée par les crédits ECTS des cours
  /// ayant une note réelle. 0 tant que rien n'est évalué.
  double levelAverage(Iterable<String> courseCodes) {
    var weighted = 0.0;
    var credits = 0.0;
    for (final code in courseCodes) {
      final note = courseNote(code);
      if (note == null) continue;
      final course = MockData.courseByCode(code);
      final w = (course?.credits ?? 1).toDouble();
      weighted += note * w;
      credits += w;
    }
    return credits == 0 ? 0 : weighted / credits;
  }

  /// Crédits ECTS validés : somme des crédits des cours entièrement
  /// terminés (toutes leçons validées).
  int ectsValidated(Iterable<String> courseCodes) {
    var sum = 0;
    for (final code in courseCodes) {
      if (!isCourseCompleted(code)) continue;
      sum += MockData.courseByCode(code)?.credits ?? 0;
    }
    return sum;
  }

  /// Moyenne de passage exigée par l'administration (LMD : 10/20).
  static const double passingAverage = 10;

  /// Le niveau est validé — et donc le suivant débloquable — quand tout
  /// le programme est terminé et que la moyenne pondérée est ≥ 10/20.
  bool isLevelValidated(Iterable<String> courseCodes) {
    if (courseCodes.isEmpty) return false;
    final allDone = courseCodes.every(isCourseCompleted);
    return allDone && levelAverage(courseCodes) >= passingAverage;
  }

  /// Relevé réel de l'apprenant : une ligne par cours évalué.
  List<Grade> learnerGrades(Iterable<String> courseCodes) {
    final out = <Grade>[];
    for (final code in courseCodes) {
      out.addAll(learnerGradesFor(code));
    }
    return out;
  }

  /// Relevé d'un cours : moyenne des leçons validées, datée de la
  /// dernière activité sur ce cours.
  List<Grade> learnerGradesFor(String courseCode) {
    final note = courseNote(courseCode);
    if (note == null) return const <Grade>[];
    var last = DateTime(2000);
    for (final l in lessonsOf(courseCode)) {
      final r = _lessonResults[l.id];
      if (r != null && r.finishedAt.isAfter(last)) last = r.finishedAt;
    }
    final course = MockData.courseByCode(courseCode);
    return [
      Grade(
        courseCode: courseCode,
        label: 'Parcours d\'apprentissage',
        score: note,
        max: 20,
        date: last,
        weight: (course?.credits ?? 1).toDouble(),
      ),
    ];
  }
}

/// InheritedWidget expose [LearningStore] à tout le sous-arbre.
class LearningScope extends InheritedWidget {
  const LearningScope({super.key, required this.store, required super.child});

  final LearningStore store;

  static LearningStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LearningScope>();
    assert(scope != null, 'LearningScope absent de la hiérarchie.');
    return scope!.store;
  }

  @override
  bool updateShouldNotify(LearningScope oldWidget) => store != oldWidget.store;
}
