// Tests du parcours d'apprentissage Educoach (leçons, XP, déverrouillage).

import 'package:flutter_test/flutter_test.dart';

import 'package:ide_qo/core/data/learning_seed.dart';
import 'package:ide_qo/core/models/learning_models.dart';
import 'package:ide_qo/core/session/learning_store.dart';

void main() {
  setUp(() => LearningStore.instance.reset());

  group('LearningSeed', () {
    test('génère au moins un semestre pour n\'importe quel cours', () {
      final sems = LearningSeed.semestersFor('INF301');
      expect(sems, isNotEmpty);
      expect(sems.first.units, isNotEmpty);
      expect(sems.first.units.first.lessons, isNotEmpty);
    });

    test('INF301 contient des exercices de type qcm et vrai/faux', () {
      final sems = LearningSeed.semestersFor('INF301');
      final types = <ExerciseType>{};
      for (final s in sems) {
        for (final u in s.units) {
          for (final l in u.lessons) {
            types.addAll(l.exercises.map((e) => e.type));
          }
        }
      }
      expect(types, contains(ExerciseType.qcm));
      expect(types, contains(ExerciseType.trueFalse));
    });

    test('un cours exotique reçoit le générateur fallback', () {
      final sems = LearningSeed.semestersFor('JOR301');
      expect(sems, isNotEmpty);
      final lesson = sems.first.units.first.lessons.first;
      expect(lesson.exercises, isNotEmpty);
      expect(lesson.theory, isNotEmpty);
    });
  });

  group('LearningStore', () {
    test('déverrouille la première leçon et bloque les suivantes', () {
      final store = LearningStore.instance;
      final sems = LearningSeed.semestersFor('INF301');
      final unit = sems.first.units.first;
      final first = unit.lessons.first;
      final second = unit.lessons[1];
      expect(
        store.isLessonUnlocked(sems.first, unit, first, allSemesters: sems),
        isTrue,
      );
      expect(
        store.isLessonUnlocked(sems.first, unit, second, allSemesters: sems),
        isFalse,
      );
    });

    test('compléter une leçon ajoute XP et débloque la suivante', () {
      final store = LearningStore.instance;
      final sems = LearningSeed.semestersFor('INF301');
      final unit = sems.first.units.first;
      final first = unit.lessons.first;
      final second = unit.lessons[1];
      store.recordLesson(
        first,
        AttemptResult(
          correctCount: 3,
          total: 3,
          xpEarned: 30,
          finishedAt: DateTime.now(),
        ),
      );
      expect(store.totalXp, 30);
      expect(store.isLessonCompleted(first.id), isTrue);
      expect(
        store.isLessonUnlocked(sems.first, unit, second, allSemesters: sems),
        isTrue,
      );
    });

    test('un échec (<60 %) consomme un cœur', () {
      final store = LearningStore.instance;
      final sems = LearningSeed.semestersFor('INF301');
      final lesson = sems.first.units.first.lessons.first;
      final before = store.hearts;
      store.recordLesson(
        lesson,
        AttemptResult(
          correctCount: 1,
          total: 3,
          xpEarned: 5,
          finishedAt: DateTime.now(),
        ),
      );
      expect(store.hearts, before - 1);
    });

    test('le semestre 2 reste verrouillé tant que le 1 n\'est pas fini', () {
      final store = LearningStore.instance;
      final sems = LearningSeed.semestersFor('INF301');
      if (sems.length < 2) return;
      expect(store.isSemesterUnlocked(sems[1], allSemesters: sems), isFalse);
    });

    test('progression d\'un cours = leçons validées / total', () {
      final store = LearningStore.instance;
      final sems = LearningSeed.semestersFor('JOR301');
      final total = store.courseLessonCount('JOR301', allSemesters: sems);
      expect(total, greaterThan(0));
      expect(store.courseProgress('JOR301', allSemesters: sems), 0);
      final first = sems.first.units.first.lessons.first;
      store.recordLesson(
        first,
        AttemptResult(
          correctCount: 3,
          total: 3,
          xpEarned: 20,
          finishedAt: DateTime.now(),
        ),
      );
      expect(
        store.courseProgress('JOR301', allSemesters: sems),
        greaterThan(0),
      );
    });
  });
}
