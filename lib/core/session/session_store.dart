import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import 'learning_store.dart';

/// État applicatif global : filière et niveau choisis par l'étudiant.
///
/// Règles métier :
///   • la filière est choisie **une seule fois** puis verrouillée —
///     il n'existe aucune API pour la changer après coup ;
///   • seul un niveau réellement doté de cours est sélectionnable ;
///   • on ne passe au niveau suivant qu'après avoir terminé tout le
///     programme courant avec une moyenne ≥ [LearningStore.passingAverage].
///
/// Singleton [ChangeNotifier] consommé via [ListenableBuilder] ou
/// [SessionScope]. Toutes les pages filtrent leurs données à partir de
/// [filiere] et [level].
class SessionStore extends ChangeNotifier {
  SessionStore._();
  static final SessionStore instance = SessionStore._();

  Filiere? _filiere;
  String _level = '';

  Filiere? get filiere => _filiere;
  String get level => _level;
  bool get hasSelection => _filiere != null;

  /// Une fois la filière choisie, elle est définitive.
  bool get isFiliereLocked => _filiere != null;

  /// Codes des cours actuellement visibles (filière + niveau).
  Set<String> get activeCourseCodes => MockData.coursesFor(
    filiereId: _filiere?.id,
    level: _level,
  ).map((c) => c.code).toSet();

  List<Course> get activeCourses =>
      MockData.coursesFor(filiereId: _filiere?.id, level: _level);

  /// Tous les cours de la filière, quel que soit le niveau.
  List<Course> get allFiliereCourses =>
      MockData.coursesFor(filiereId: _filiere?.id);

  /// Niveaux réellement disponibles (dérivés des cours existants).
  List<String> availableLevels() {
    final f = _filiere;
    if (f == null) return const <String>[];
    return levelsWithCourses(f);
  }

  /// Niveaux d'une filière qui possèdent au moins un cours au catalogue.
  static List<String> levelsWithCourses(Filiere f) {
    final set = <String>{};
    for (final c in MockData.courses) {
      if (c.filiereId == f.id && c.level.isNotEmpty) {
        set.add(c.level);
      }
    }
    // Préserve l'ordre défini dans la filière si disponible.
    final result = f.degreeLevels.where(set.contains).toList();
    for (final l in set) {
      if (!result.contains(l)) result.add(l);
    }
    return result;
  }

  /// Sélection initiale de la filière — verrouillée ensuite.
  /// Le niveau par défaut est le **premier** niveau doté de cours.
  void selectFiliere(Filiere f, {String? level}) {
    if (_filiere != null && _filiere!.id == f.id) {
      // Même filière déjà verrouillée : on ne fait rien.
      return;
    }
    if (_filiere != null) return; // filière définitive
    final levels = levelsWithCourses(f);
    _filiere = f;
    _level = (level != null && levels.contains(level))
        ? level
        : (levels.isEmpty ? '' : levels.first);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Progression dans le cursus LMD
  // ---------------------------------------------------------------------------

  /// Niveau suivant du cursus, ou null si le niveau courant est le dernier.
  String? get nextLevel {
    final levels = availableLevels();
    final i = levels.indexOf(_level);
    if (i < 0 || i >= levels.length - 1) return null;
    return levels[i + 1];
  }

  /// Progression 0..1 du programme du niveau courant.
  double get levelProgress =>
      LearningStore.instance.levelProgress(activeCourseCodes);

  /// Moyenne pondérée (crédits) du niveau courant, sur 20.
  double get levelAverage =>
      LearningStore.instance.levelAverage(activeCourseCodes);

  /// Le niveau courant est-il validé (programme fini + moyenne ≥ 10) ?
  bool get isCurrentLevelValidated =>
      LearningStore.instance.isLevelValidated(activeCourseCodes);

  /// Peut-on passer au niveau suivant ?
  bool get canAdvanceToNextLevel =>
      nextLevel != null && isCurrentLevelValidated;

  /// Passe au niveau suivant — refusé si le programme n'est pas validé.
  /// Retourne true si la progression a été acceptée.
  bool advanceToNextLevel() {
    final next = nextLevel;
    if (next == null || !isCurrentLevelValidated) return false;
    _level = next;
    notifyListeners();
    return true;
  }

  void reset() {
    _filiere = null;
    _level = '';
    notifyListeners();
  }
}

/// InheritedWidget expose [SessionStore] à tout le sous-arbre.
class SessionScope extends InheritedWidget {
  const SessionScope({super.key, required this.store, required super.child});

  final SessionStore store;

  static SessionStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope absent de la hiérarchie des widgets.');
    return scope!.store;
  }

  @override
  bool updateShouldNotify(SessionScope oldWidget) => store != oldWidget.store;
}
