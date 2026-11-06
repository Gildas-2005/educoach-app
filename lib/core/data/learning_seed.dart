import 'package:flutter/material.dart';

import '../models/learning_models.dart';
import 'learning_content.dart';
import 'mock_data.dart';

/// Contenu pédagogique Educoach.
///
/// Deux modes :
///   1. Cours phares ([richCourseBuilders] dans learning_content.dart) —
///      leçons entièrement rédigées à la main, avec théorie dense, exemples
///      chiffrés et exercices variés.
///   2. Tous les autres cours — générateur thématique par domaine.
///      Chaque [_Theme] porte un bagage réel : plusieurs paragraphes de
///      théorie spécifiques, un exemple concret issu du contexte
///      camerounais et des exercices concrets. Les leçons d'une même unité
///      cyclent dans ce bagage, si bien qu'aucun contenu générique du type
///      « Introduction au concept » n'est jamais produit.
///
/// Les identifiants sont stables (`<code>-s<i>-u<j>-l<k>`) pour que la
/// progression survive à un redémarrage de l'app.
class LearningSeed {
  LearningSeed._();

  static final Map<String, List<Semester>> _cache = <String, List<Semester>>{};

  /// Semestres d'un cours (crée à la demande si nécessaire).
  static List<Semester> semestersFor(String courseCode) {
    if (_cache.containsKey(courseCode)) return _cache[courseCode]!;
    final builder = richCourseBuilders[courseCode];
    final list = builder != null
        ? builder(courseCode)
        : _generateFallback(courseCode);
    _cache[courseCode] = list;
    return list;
  }

  /// Devoirs associés à un cours.
  static List<Homework> homeworkFor(String courseCode) {
    final sems = semestersFor(courseCode);
    final out = <Homework>[];
    var idx = 1;
    for (final s in sems) {
      final lesson = s.units.first.lessons.last;
      out.add(
        Homework(
          id: '$courseCode-hw$idx',
          courseCode: courseCode,
          title: 'Devoir ${_roman(idx)} · ${lesson.title}',
          instruction:
              'Révise la leçon « ${lesson.title} » puis traite les '
              'exercices ci-dessous. Tu disposes de 7 jours ; la '
              'correction détaillée s\'affichera après la validation.',
          dueDate: DateTime.now().add(Duration(days: 4 + idx * 2)),
          points: 20,
          exercises: lesson.exercises,
        ),
      );
      idx++;
    }
    return out;
  }

  // ==================================================================
  //  Générateur de parcours par défaut (thème réaliste par domaine)
  // ==================================================================
  static List<Semester> _generateFallback(String code) {
    final course = MockData.courses.firstWhere(
      (c) => c.code == code,
      orElse: () => MockData.courses.first,
    );
    final name = course.title;
    final themes = _themesFor(name);
    final sems = <Semester>[];
    for (var s = 0; s < 3; s++) {
      final units = <Unit>[];
      for (var u = 0; u < 4; u++) {
        final theme = themes[(s * 4 + u) % themes.length];
        final lessons = <Lesson>[];
        for (var l = 0; l < 5; l++) {
          final id = '$code-s${s + 1}-u${u + 1}-l${l + 1}';
          final spec = theme.specFor(l, name, code, s * 4 + u);
          lessons.add(
            Lesson(
              id: id,
              courseCode: code,
              unitId: '$code-s${s + 1}-u${u + 1}',
              title: spec.title,
              subtitle: spec.subtitle,
              theory: spec.theory,
              examples: spec.examples,
              exercises: spec.exercises,
              xpReward: 20 + l * 5,
              icon: theme.icon,
            ),
          );
        }
        units.add(
          Unit(
            id: '$code-s${s + 1}-u${u + 1}',
            semesterId: '$code-s${s + 1}',
            title: 'Unité ${_roman(s * 4 + u + 1)} · ${theme.label}',
            subtitle: theme.blurb,
            color: theme.color,
            icon: theme.icon,
            lessons: lessons,
          ),
        );
      }
      sems.add(
        Semester(
          id: '$code-s${s + 1}',
          courseCode: code,
          index: s + 1,
          label: 'Semestre ${s + 1}',
          units: units,
        ),
      );
    }
    return sems;
  }

  // ==================================================================
  //  Thèmes réalistes par domaine
  // ==================================================================
  static List<_Theme> _themesFor(String courseTitle) {
    final t = courseTitle.toLowerCase();
    if (t.contains('algor') ||
        t.contains('programmation') ||
        t.contains('data') ||
        t.contains('dev') ||
        t.contains('flutter') ||
        t.contains('info') ||
        t.contains('logiciel') ||
        t.contains('base de')) {
      return _infoThemes;
    }
    if (t.contains('droit') ||
        t.contains('constitution') ||
        t.contains('obligation') ||
        t.contains('procédure') ||
        t.contains('pénal') ||
        t.contains('civil')) {
      return _droitThemes;
    }
    if (t.contains('éco') ||
        t.contains('marché') ||
        t.contains('fin') ||
        t.contains('gestion') ||
        t.contains('comptab') ||
        t.contains('marketing')) {
      return _ecoThemes;
    }
    if (t.contains('médecine') ||
        t.contains('anatom') ||
        t.contains('physio') ||
        t.contains('pharma') ||
        t.contains('soin') ||
        t.contains('santé')) {
      return _santeThemes;
    }
    if (t.contains('chimie') ||
        t.contains('physique') ||
        t.contains('biologie') ||
        t.contains('math') ||
        t.contains('statistique') ||
        t.contains('écologie') ||
        t.contains('agronomie') ||
        t.contains('environnement')) {
      return _scienceThemes;
    }
    if (t.contains('littérature') ||
        t.contains('langue') ||
        t.contains('histoire') ||
        t.contains('géo') ||
        t.contains('socio') ||
        t.contains('psycho') ||
        t.contains('philo') ||
        t.contains('communication') ||
        t.contains('journalisme') ||
        t.contains('angais') ||
        t.contains('pagnol')) {
      return _lettresThemes;
    }
    return _genericThemes;
  }
}

// ---------------------------------------------------------------------------
// Représente une leçon générée par un thème.
// ---------------------------------------------------------------------------
class _LessonSpec {
  const _LessonSpec({
    required this.title,
    required this.subtitle,
    required this.theory,
    required this.examples,
    required this.exercises,
  });
  final String title;
  final String subtitle;
  final List<String> theory;
  final List<Example> examples;
  final List<Exercise> exercises;
}

/// Thème disciplinaire qui sait produire trois leçons substantielles.
class _Theme {
  const _Theme({
    required this.label,
    required this.blurb,
    required this.color,
    required this.icon,
    required this.lessonTitles,
    required this.theoryBank,
    required this.example,
    required this.exercises,
  });

  final String label;
  final String blurb;
  final Color color;
  final IconData icon;

  /// Trois intitulés distincts pour les volets 1/2/3.
  final List<String> lessonTitles;

  /// Réserve de 6 à 8 paragraphes réellement pédagogiques ; chaque leçon
  /// puise trois paragraphes consécutifs dans cette banque.
  final List<String> theoryBank;

  /// Exemple concret unique au thème, réutilisé avec des variantes.
  final _ExamplePack example;

  /// Trois exercices concrets, propres au thème.
  final List<Exercise> Function(String lessonId) exercises;

  _LessonSpec specFor(int slot, String courseName, String code, int unitIdx) {
    final title = lessonTitles[slot % lessonTitles.length];
    final start = (slot * 5) % theoryBank.length;
    final theory = <String>[
      for (var i = 0; i < 5 && i < theoryBank.length; i++)
        theoryBank[(start + i) % theoryBank.length],
    ];
    final lessonId =
        '$code-s${(unitIdx ~/ 4) + 1}'
        '-u${(unitIdx % 4) + 1}-l${slot + 1}';
    final baseExamples = <Example>[];
    for (var e = 0; e < 2; e++) {
      baseExamples.addAll(example.variants(courseName, slot + e));
    }
    final baseEx = exercises(lessonId);
    // Compléter jusqu'à 5 en variantant les exercices existants.
    final fullEx = <Exercise>[...baseEx];
    var extra = 0;
    while (fullEx.length < 5 && baseEx.isNotEmpty) {
      final src = baseEx[extra % baseEx.length];
      fullEx.add(
        Exercise(
          id: '$lessonId-ex${extra + 1}',
          type: src.type,
          prompt: 'Approfondissement ${extra + 1} · ${src.prompt}',
          options: src.options,
          expectedAnswer: src.expectedAnswer,
          orderItems: src.orderItems,
          blankTemplate: src.blankTemplate,
          acceptedAnswers: src.acceptedAnswers,
          explanation: src.explanation,
          hint: src.hint,
          xp: src.xp,
        ),
      );
      extra++;
    }
    return _LessonSpec(
      title: title,
      subtitle: blurb,
      theory: theory,
      examples: baseExamples,
      exercises: fullEx,
    );
  }
}

/// Exemple concret attaché à un thème : titre + corps + code ou citation.
class _ExamplePack {
  const _ExamplePack({required this.titles, required this.bodies, this.codes});
  final List<String> titles;
  final List<String> bodies;
  final List<String?>? codes;

  List<Example> variants(String courseName, int slot) {
    final i = slot % titles.length;
    final code = codes == null ? null : codes![i % codes!.length];
    return [
      Example(
        title: titles[i],
        body: bodies[i],
        code: code,
        footnote:
            'Astuce : recopie cet exemple à la main avant de '
            'refaire l\'exercice sans regarder.',
      ),
    ];
  }
}

// ===========================================================================
//  Informatique / algorithmique — contenu réellement rédigé
// ===========================================================================
final _infoThemes = <_Theme>[
  _Theme(
    label: 'Fondements',
    blurb: 'Variables, types et raisonnement correctness',
    color: Color(0xFF3F51B5),
    icon: Icons.foundation_rounded,
    lessonTitles: [
      'Variables, types et portée',
      'Spécification d\'un algorithme',
      'Preuve d\'une invariante',
    ],
    theoryBank: [
      'Un algorithme est une suite finie d\'instructions effectives qui, '
          'appliquées à une entrée conforme, produit une sortie en un temps '
          'maisable. Cette définition cache trois exigences : la finesse '
          '(pas de boucle infinie), l\'effectivité ( chaque instruction '
          'doit pouvoir être exécutée par une machine) et la terminaison.',
      'Le typage — qu\'il soit statique (Dart, Java) ou dynamique '
          '(Python, JavaScript) — n\'est pas un luxe : il documente '
          'l\'intention et permet au compilateur ou à l\'interpréteur de '
          'rejeter tôt une operation aberrante. À l\'Université de '
          'Yaoundé I, les étudiants qui programment en Flutter '
          'découvrent que `int + String` est rejeté bien avant l\'exécution.',
      'La portée (scope) détermine où un nom est visible. Une variable '
          'déclarée dans un bloc `{ … }` disparaît à la sortie du bloc. '
          'Comprendre la portée évite la majorité des bugs de variables '
          'globales et des effets de bord imprévus dans les projets de '
          'fin de L3.',
      'Spécifier un algorithme, c\'est écrire ce qu\'il fait AVANT '
          'd\'écrire comment. Une spéculation correcte comporte : le type '
          'de l\'entrée, le type de la sortie, la propriété de correction '
          '(ce qui doit être vrai en sortie) et la borne de complexité '
          '(ce qui doit être rapide).',
      'Une invariante de boucle est une assertion vraie avant la boucle, '
          'retablie à chaque itération, et suffisante pour garantir la '
          'propriété de correction à la sortie. Prouver une invariante '
          'est l\'exercice roi de l\'algorithmique : c\'est ce qui '
          'distingue un code qui « marche » d\'un code correct.',
      'En pratique, les étudiants de L3 Informatique à Douala sont '
          'évalués sur trois critères : la correction partielle (le '
          'programme compile), la correction totale (tous les cas de '
          'test passent) et l\'optimisation (complexité annoncée et '
          'atteinte).',
      'Ne jamais confondre l\'algorithme avec le programme. Un même '
          'algorithme de tri peut s\'écrire en Dart, en Python ou en '
          'pseudo-code ; l\'algorithme est l\'idée, le programme en est '
          'une implémentation particulière.',
    ],
    example: _ExamplePack(
      titles: [
        'Invariante d\'une somme',
        'Types et inférence',
        'Pré/post-condition',
      ],
      bodies: [
        'Pour calculer la somme d\'un tableau T[0..n-1], on maintient '
            'l\'invariante « s = T[0] + … + T[i-1] ». Avant la boucle i=0 '
            'et s=0 : vrai à vide. À chaque pas on ajoute T[i] et on '
            'incrémente i : l\'invariant reste vrai. À la fin i = n, donc '
            's est bien la somme complète.',
        'En Dart, `var x = 3;` déduit `int`. `x = "trois";` provoque une '
            'erreur de compilation. Cette discipline évite des bugs '
            'comme « TypeError : undefined is not a function » qui '
            'coûtent des heures de débogage aux stagiaires.',
        'Spécification d\'une recherche binaire : précondition — le '
            'tableau T est trié croissant ; postcondition — retourne '
            'l\'indice i tel que T[i] == cible, ou -1 si absent ; '
            'complexité — O(log n) comparaisons dans le pire cas.',
      ],
      codes: [
        'somme(T):\n'
            '    s ← 0\n'
            '    pour i de 0 à longueur(T) - 1 faire\n'
            '        // invariante : s = T[0] + … + T[i-1]\n'
            '        s ← s + T[i]\n'
            '    retourne s',
        'void main() {\n'
            '  var x = 3;         // x est inféré comme int\n'
            '  x = x * 2;         // OK\n'
            '  // x = "trois";    // erreur de compilation\n'
            '}',
        'rechercheBinaire(T, cible):\n'
            '    g ← 0 ; d ← longueur(T) - 1\n'
            '    tant que g ≤ d faire\n'
            '        m ← (g + d) / 2\n'
            '        si T[m] == cible alors retourner m\n'
            '        si T[m] < cible alors g ← m + 1 sinon d ← m - 1\n'
            '    retourner -1',
      ],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt: 'Quelle condition doit satisfaire une invariante de boucle ?',
        options: const [
          ExerciseOption(
            id: 'a',
            text:
                'Être vraie avant la boucle, rétablie à chaque '
                'itération et suffisante pour conclure à la sortie',
            correct: true,
          ),
          ExerciseOption(id: 'b', text: 'Être vraie uniquement au milieu'),
          ExerciseOption(id: 'c', text: 'N\'être vérifiée qu\'à la fin'),
          ExerciseOption(id: 'd', text: 'Dépendre de la taille de l\'entrée'),
        ],
        explanation:
            'Une invariante se lit en trois temps : '
            'initialisation, conservation, terminaison. C\'est la clé '
            'des preuves de correction.',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt:
            'Un algorithme correct peut être écrit dans plusieurs '
            'langages sans changer sa spécification.',
        expectedAnswer: 'Vrai',
        explanation:
            'Vrai. La spécification est indépendante de '
            'l\'implémentation : c\'est précisément ce qui rend '
            'l\'algorithmique universelle.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.fillBlank,
        prompt:
            'Complète : une variable déclarée dans un bloc '
            'appartient à la ___ du bloc.',
        blankTemplate: 'une variable déclarée dans un bloc appartient à la ___',
        acceptedAnswers: const ['portée', 'scope'],
        expectedAnswer: 'portée',
        explanation:
            'La portée (scope) détermine l\'accessibilité '
            'd\'un nom. En Dart, une variable locale meurt à la fin '
            'du bloc.',
      ),
    ],
  ),
  _Theme(
    label: 'Structures de contrôle',
    blurb: 'Conditions, boucles et raisonnement sur le flux',
    color: Color(0xFF00897B),
    icon: Icons.account_tree_rounded,
    lessonTitles: [
      'Conditionnelles et courts-circuits',
      'Boucles : pour, tant que, faire…tant que',
      'Imbrication et sorties anticipées',
    ],
    theoryBank: [
      'Une conditionnelle `if / else if / else` traduit un choix. '
          'Le court-circuit logique (ET et OU) permet de placer en '
          'première position la garde la moins coûteuse : '
          '`if (x != null && x.length > 3)` ne plante jamais si '
          'x est null, car la seconde évaluation est court-circuitée.',
      'Trois formes de boucles : `pour` quand le nombre d\'itérations '
          'est connu à l\'avance, `tant que` quand il dépend d\'un '
          'état qui évolue, `faire…tant que` quand le corps doit '
          's\'exécuter au moins une fois. Choisir la mauvaise forme '
          'est une source fréquente de bugs en TD.',
      'Le nombre d\'itérations d\'un `pour i de 0 à n` est n+0 en '
          'bornes fermées Dart (`for (var i = 0; i < n; i++)` itère '
          'n fois). Les L3 perdent souvent un point à l\'examen sur '
          'cette arithmétique des bornes.',
      'Une imbrication de deux boucles `pour` sur n parcourt en '
          'moyenne n² cellules. C\'est la structure des algorithmes '
          'de tri élémentaires (bubble, insertion, sélection) et '
          'des recherches croisées dans une base de données.',
      'Les sorties anticipées (`break`, `return`, `continue`) '
          'améliorent la performance et la lisibilité à condition '
          'de documenter la condition de sortie : « on sort dès '
          'qu\'un élément négatif est rencontré ». Sans '
          'commentaire, ces instructions sont considérées comme '
          'une mauvaise pratique.',
      'Les structures de contrôle ne sont pas équivalentes en '
          'puissance : un `pour` borné ne peut pas tout faire, '
          'alors qu\'un `tant que` avec mémoire équivalente à une '
          'machine de Turing peut calculer toute fonction '
          'calculable.',
      'En pratique professionnelle au Cameroun, la plupart des '
          'revues de code en agence portent sur la lisibilité '
          'des structures de contrôle : préférer des fonctions '
          'courtes, des noms clairs, et remonter `return` au '
          'plus tôt plutôt que d\'imbriquer 5 niveaux de `if`.',
    ],
    example: _ExamplePack(
      titles: [
        'Court-circuit d\'une validation',
        'Boucle imbriée pour un tri bulle',
        'Sortie anticipée sur première anomalie',
      ],
      bodies: [
        'Un formulaire d\'inscription Educoach ne doit tester la '
            'longueur du mot de passe QUE si celui-ci est non vide : '
            '`if (password.isNotEmpty && password.length < 6)` '
            'évite d\'appeler `.length` sur une référence null.',
        'Le tri bulle compare chaque paire adjacente et remonte ; '
            'après k passes, les k plus grands éléments sont à '
            'leur place. Complexité O(n²) dans le pire cas, O(n) '
            'si le tableau est déjà trié grâce à un booléen '
            '« échangé ».',
        'Parcourir les relevés bancaires d\'un client et s\'arrêter '
            'dès qu\'une opération dépasse le plafond : on ne '
            'réclame pas un calcul plus coûteux que nécessaire.',
      ],
      codes: [
        'if (mdp.isNotEmpty && mdp.length >= 8) {\n'
            '  // validation correcte ; && court-circuite\n'
            '}',
        'pour i de 0 à n-2 faire\n'
            '    échange ← faux\n'
            '    pour j de 0 à n-2-i faire\n'
            '        si T[j] > T[j+1] alors\n'
            '            échanger T[j], T[j+1]\n'
            '            échange ← vrai\n'
            '    si non échange alors retourner',
        'pour chaque opération o dans relevé:\n'
            '    si o.montant > plafond alors\n'
            '        journaliser(o) ; retourner "alerte"',
      ],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt:
            'Combien de comparaisons effectue un tri bulle sur '
            'un tableau déjà trié de taille n (avec booléen '
            '« échange ») ?',
        options: const [
          ExerciseOption(id: 'a', text: 'O(n)', correct: true),
          ExerciseOption(id: 'b', text: 'O(n log n)'),
          ExerciseOption(id: 'c', text: 'O(n²)'),
          ExerciseOption(id: 'd', text: 'O(1)'),
        ],
        explanation:
            'Le booléen « échange » détecte l\'absence '
            'd\'échange à la première passe et sort : on n\'a '
            'fait que n-1 comparaisons.',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt:
            'L\'expression `if (x != null || x.length > 3)` '
            'peut lever une NullPointerException.',
        expectedAnswer: 'Vrai',
        explanation:
            'Vrai — avec OU, la seconde expression '
            's\'évalue quand la première est fausse, donc quand '
            'x == null : erreur. Il faut ET et tester null en '
            'premier.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.ordering,
        prompt:
            'Ordre d\'exécution des passes d\'un tri bulle sur '
            '[5, 3, 8, 1] :',
        orderItems: const [
          'Pass 1 : [3, 5, 1, 8]',
          'Pass 2 : [3, 1, 5, 8]',
          'Pass 3 : [1, 3, 5, 8]',
          'Aucun échange → tableau trié',
        ],
        explanation:
            'Chaque passe « fait remonter » le plus grand '
            'restant vers la droite ; trois passes suffisent sur '
            '4 éléments.',
      ),
    ],
  ),
  _Theme(
    label: 'Complexité',
    blurb: 'Notation grand O et analyse des coûts',
    color: Color(0xFFF4511E),
    icon: Icons.speed_rounded,
    lessonTitles: [
      'Notation O, Ω et Θ',
      'Coûts amortis et mémoire',
      'Choisir un algorithme selon la taille n',
    ],
    theoryBank: [
      'La notation grand O cache les constantes et les termes '
          'dominés : 3n² + 17n + 42 = O(n²). Elle décrit une borne '
          'supérieure dans le pire cas ; Ω décrit une borne '
          'inférieure (meilleur cas) et Θ les deux à la fois.',
      'Analyser un algorithme, c\'est compter le nombre d'
          '\'opérations élémentaires en fonction de la taille de '
          'l\'entrée. Les opérations comptées : affectation, '
          'comparaison, appel de fonction, accès à un tableau.',
      'La complexité amortie justifie des structures comme la '
          'liste dynamique : un push unique est parfois O(n) quand '
          'le tableau interne doit être recopié, mais sur une '
          'succession de k insertions, le coût moyen est O(1) par '
          'opération.',
      'La mémoire compte autant que le temps : un tri fusion est '
          'O(n log n) en temps mais O(n) en espace, ce qui le rend '
          'inutilisable pour trier des fichiers de plusieurs '
          'gigaoctets sur un téléphone d\'étudiant. En '
          'contrepartie, heapsort est O(1) en espace.',
      'Un algorithme exponentiel (2ⁿ) devient inutilisable dès '
          'n = 30 : une nanoseconde par opération donne 30 secondes '
          'pour 2³⁰. Sur un problème de sac-à-dos, les étudiants '
          'de M1 sont jugés sur leur capacité à reconnaître un '
          'cas exponentiel et à basculer vers une programmation '
          'dynamique polynomiale.',
      'Les classes P, NP et NP-complet ne sont pas que '
          'théoriques : tout problème d\'emploi du temps ou de '
          'routage est NP-difficile ; accepter une solution '
          'approchée est souvent plus utile que chercher '
          'l\'optimum exact pendant des heures.',
    ],
    example: _ExamplePack(
      titles: [
        'Deux algorithmes, deux destins',
        'Tableau de complexité usuelle',
        'Passage de n = 20 à n = 200',
      ],
      bodies: [
        'Sur n = 10 000 enregistrements, une recherche linéaire '
            'fait 10 000 comparaisons ; une recherche binaire, 14. '
            'Le gain est massif mais exige un tri préalable '
            'O(n log n) amorti sur des milliers de requêtes.',
        'Constante O(1), logarithmique O(log n), linéaire O(n), '
            'linéarithmique O(n log n), quadratique O(n²), '
            'exponentielle O(2ⁿ), factorielle O(n!). Pour n = 30, '
            'les trois derniers sautent de 10⁹ à l\'infini '
            'pratique.',
        'Un algorithme de complexité O(n²) sur n = 20 coûte 400 '
            'opérations ; sur n = 200 il en coûte 40 000. Un O(2ⁿ) '
            'passe de 10⁶ à 10⁶⁰ : la vie de l\'étudiant '
            'change à partir de ce seuil.',
      ],
      codes: [
        null,
        '// n=10⁵\n'
            '// O(n)     ~ 100 000 op  → instantané\n'
            '// O(n²)    ~ 10¹⁰ op     → 10 s\n'
            '// O(2ⁿ)    ~ 10³⁰ 000 op → jamais',
        'int fibonacci(int n) {\n'
            '  if (n < 2) return n;              // O(1)\n'
            '  return fib(n-1) + fib(n-2);       // O(2ⁿ) naïf\n'
            '}',
      ],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt: 'Quelle complexité domine pour n → ∞ ?',
        options: const [
          ExerciseOption(id: 'a', text: 'O(n log n)'),
          ExerciseOption(id: 'b', text: 'O(n²)'),
          ExerciseOption(id: 'c', text: 'O(2ⁿ)', correct: true),
          ExerciseOption(id: 'd', text: 'O(n)'),
        ],
        explanation:
            'La croissance exponentielle écrase toute '
            'croissance polynomiale dès que n devient grand.',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.fillBlank,
        prompt:
            'Complète : la notation qui décrit une borne '
            'inférieure s\'appelle ___',
        blankTemplate: 'borne inférieure = ___',
        expectedAnswer: 'oméga',
        acceptedAnswers: const ['omega', 'Ω', 'grand omega'],
        explanation:
            'Ω(g(n)) = {f : ∃c>0, f(n) ≥ c·g(n)}. '
            'C\'est la contrepartie mathématique de O.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.ordering,
        prompt: 'Du plus rapide au plus lent pour n = 10⁶ :',
        orderItems: const ['O(log n)', 'O(n)', 'O(n log n)', 'O(n²)', 'O(2ⁿ)'],
        explanation:
            'Ordre classique des classes de '
            'complexité : logarithmique < linéaire < '
            'linéarithmique < quadratique < exponentielle.',
      ),
    ],
  ),
  _Theme(
    label: 'Récursion',
    blurb: 'Fonctions qui s\'appellent elles-mêmes et arbres d\'appels',
    color: Color(0xFF8E24AA),
    icon: Icons.loop_rounded,
    lessonTitles: [
      'Cas de base et cas récursif',
      'Arbre d\'appels et pile mémoire',
      'Récursivité terminale et mémoïsation',
    ],
    theoryBank: [
      'Une fonction récursive se décompose toujours en deux '
          'parties : un cas de base (où la réponse est triviale) '
          'et un cas récursif (où l\'appel se fait sur une '
          'instance strictement plus petite). Sans cas de base '
          'atteignable, la pile s\'épuise et l\'app planté avec '
          'StackOverflowError.',
      'L\'arbre d\'appels visualise chaque invocation comme un '
          'nœud. Sa hauteur correspond à la profondeur de pile ; '
          'son nombre total de nœuds correspond au nombre '
          'd\'appels. Un fibonacci naïf dessine un arbre '
          'quasi-exponentiel, d\'où O(2ⁿ).',
      'La pile des appels coûte : chaque frame conserve les '
          'paramètres locaux, la variable de retour et l\'adresse '
          'de retour. En Dart sur mobile, la pile fait ~1 Mo, '
          'soit ~10⁴ frames typiques. Une récursion profonde '
          '(n = 100 000) ne passera jamais.',
      'La récursivité terminale (l\'appel récursif est la '
          'dernière opération) peut être optimisée par le '
          'compilateur en une simple boucle : la pile ne croît '
          'pas. Les langages fonctionnels (Scheme, OCaml) le '
          'garantissent ; en Dart, il faut vérifier la doc de '
          'l\'équipe VM.',
      'La mémoïsation transforme un algorithme exponentiel en '
          'polynomial en stockant les résultats déjà calculés '
          'dans une Map. Fibonacci passe de O(2ⁿ) à O(n) avec '
          'seulement quelques lignes : `final memo = <int, int>;`.',
      'Récursion ≠ tour de magie : tout algorithme récursif '
          'peut être écrit itérativement avec une pile '
          'explicite. Le choix dépend de la clarté : parcourir '
          'un arbre se fait naturellement en récursif, '
          'parcourir une liste se fait mieux en boucle.',
    ],
    example: _ExamplePack(
      titles: [
        'Somme récursive',
        'Fibonacci mémoïsé',
        'Parcours d\'un arbre binaire',
      ],
      bodies: [
        'Calculer la somme des n premiers entiers : S(n) = n + '
            'S(n-1) avec S(0) = 0. La profondeur est n ; la '
            'version itérative évite la pile.',
        'Le calcul naïf de fib(40) prend plusieurs secondes ; '
            'avec mémoïsation, il prend moins d\'une '
            'milliseconde, car chaque sous-valeur n\'est '
            'calculée qu\'une fois.',
        'Un arbre de catégories de cours (racine : « Informatique » '
            '→ enfants : « Programmation », « Bases de données » '
            '→ …) se parcourt récursivement avec une fonction '
            'qui imprime le nom puis appelle elle-même sur '
            'chaque enfant.',
      ],
      codes: [
        'int somme(int n) {\n'
            '  if (n == 0) return 0;        // cas de base\n'
            '  return n + somme(n - 1);     // cas récursif\n'
            '}',
        'final _memo = <int, int>{};\n'
            'int fib(int n) {\n'
            '  if (n < 2) return n;\n'
            '  return _memo[n] ??= fib(n-1) + fib(n-2);\n'
            '}',
        'void afficherArbre(Nœud n, int profondeur) {\n'
            '  print(\'\${"  " * profondeur}\${n.nom}\');\n'
            '  for (final c in n.enfants) {\n'
            '    afficherArbre(c, profondeur + 1);\n'
            '  }\n'
            '}',
      ],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt: 'Que se passe-t-il sans cas de base ?',
        options: const [
          ExerciseOption(
            id: 'a',
            text:
                'La fonction s\'appelle indéfiniment jusqu\'au '
                'débordement de pile',
            correct: true,
          ),
          ExerciseOption(id: 'b', text: 'Le compilateur retourne 0'),
          ExerciseOption(id: 'c', text: 'La récursion se transforme en boucle'),
          ExerciseOption(id: 'd', text: 'Rien'),
        ],
        explanation:
            'Chaque appel consomme une frame de pile ; '
            'sans cas de base, la pile s\'épuise en quelques '
            'dizaines de milliers d\'appels.',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt:
            'Toute récursion peut être transformée en '
            'itération avec une pile explicite.',
        expectedAnswer: 'Vrai',
        explanation:
            'Vrai — c\'est la base de la compilation '
            'et de la programmation fonctionnelle stricte.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.fillBlank,
        prompt:
            'Complète : stocker les résultats intermédiaires '
            'd\'une fonction récursive s\'appelle la ___.',
        blankTemplate: 'stocker les résultats intermédiaires = la ___',
        expectedAnswer: 'mémoïsation',
        acceptedAnswers: const ['mémoïsation', 'memoization', 'mémo'],
        explanation:
            'La mémoïsation transforme souvent une '
            'complexité exponentielle en linéaire.',
      ),
    ],
  ),
  _Theme(
    label: 'Tri & recherche',
    blurb: 'Classer et retrouver efficacement de grandes données',
    color: Color(0xFF00ACC1),
    icon: Icons.sort_rounded,
    lessonTitles: [
      'Tris quadratiques : bubble, insertion, sélection',
      'Tris O(n log n) : quicksort, merge sort, tas',
      'Recherche binaire et tables de hachage',
    ],
    theoryBank: [
      'Les tris quadratiques (bubble, insertion, sélection) '
          'restent utiles pour n < 50 grâce à leur faible '
          'constante et leur stabilité. Insertion sort est même '
          'le tri sous-jacent de Timsort, utilisé par Python et '
          'Java pour les petits segments.',
      'Quicksort partitionne autour d\'un pivot : éléments plus '
          'petits à gauche, plus grands à droite. Dans le cas '
          'moyen, il est O(n log n) ; dans le pire (tableau trié '
          '+ pivot = premier élément), il tombe en O(n²). La '
          'stratégie « median-of-three » évite ce pire.',
      'Merge sort est garanti O(n log n) mais O(n) en espace. '
          'Il est privilégié pour le tri de fichiers trop gros '
          'pour la mémoire — exactement le cas du MINRES qui '
          'doit trier 3 millions de relevés de notes.',
      'Heapsort combine le meilleur des deux : O(n log n) '
          'garanti et O(1) en mémoire. En contrepartie, il '
          'n\'est pas stable (préserve pas l\'ordre des '
          'éléments égaux) et son facteur constant est plus '
          'mauvais que quicksort.',
      'La recherche binaire s\'applique uniquement à des '
          'données triées. Elle divise l\'intervalle de recherche '
          'par deux à chaque étape : O(log n). Attention aux '
          'overflow classiques : `mid = (low + high) / 2` déborde '
          'dès que low + high dépasse INT_MAX ; la version sûre '
          'est `low + (high - low) / 2`.',
      'Une table de hachage offre O(1) en espérance pour '
          'l\'insertion et la recherche. Elle repose sur une '
          'fonction de hachage qui répartit uniformément les '
          'clés dans un tableau. Les collisions (deux clés avec '
          'le même hash) se règlent par chaînage ou sondage.',
    ],
    example: _ExamplePack(
      titles: [
        'Partitionnement quicksort',
        'Recherche binaire en Dart',
        'Map en tant que table de hachage',
      ],
      bodies: [
        'Sur [8, 3, 1, 5, 9, 2] avec pivot = 5, on obtient '
            '[3, 1, 2] — 5 — [8, 9]. Quicksort appliquera la '
            'même opération récursivement sur les deux moitiés.',
        'Chercher 42 dans [1, 3, 7, 15, 22, 30, 42, 51, 68, 84] '
            'nécessite 4 comparaisons : [0..9] → [5..9] → [5..7] '
            '→ index 6. Une recherche linéaire aurait pris 7 '
            'tests.',
        'En Dart, `Map<String, int>` est implémenté comme une '
            'table de hachage à chaînage : `map["awa"] = 15` '
            's\'exécute en O(1) amorti.',
      ],
      codes: [
        'quicksort(T):\n'
            '    si longueur(T) < 2 retourner T\n'
            '    pivot ← T[dernier]\n'
            '    G ← [x pour x in T[:-1] si x ≤ pivot]\n'
            '    D ← [x pour x in T[:-1] si x > pivot]\n'
            '    retourner quicksort(G) + [pivot] + quicksort(D)',
        'int binaire(List<int> T, int cible) {\n'
            '  int lo = 0, hi = T.length - 1;\n'
            '  while (lo <= hi) {\n'
            '    final mid = lo + (hi - lo) ~/ 2;\n'
            '    if (T[mid] == cible) return mid;\n'
            '    if (T[mid] < cible) { lo = mid + 1; }\n'
            '    else { hi = mid - 1; }\n'
            '  }\n'
            '  return -1;\n'
            '}',
        'final notes = <String, double>{};\n'
            'notes["awa"] = 15.2;\n'
            'notes["mbarga"] = 12.8;\n'
            'print(notes["awa"]);  // O(1) en espérance',
      ],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt:
            'Quel tri est garanti O(n log n) dans le PIRE cas '
            'ET utilise O(1) de mémoire supplémentaire ?',
        options: const [
          ExerciseOption(id: 'a', text: 'Quicksort'),
          ExerciseOption(id: 'b', text: 'Merge sort'),
          ExerciseOption(id: 'c', text: 'Heapsort', correct: true),
          ExerciseOption(id: 'd', text: 'Insertion sort'),
        ],
        explanation:
            'Heapsort offre la borne supérieure '
            'garantie et un tri en place. Merge sort est '
            'également garanti mais en O(n) mémoire.',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt:
            'La recherche binaire fonctionne sur une liste '
            'non triée.',
        expectedAnswer: 'Faux',
        explanation:
            'Faux — la recherche binaire exige un '
            'tableau trié. Sur une liste non triée, le pire '
            'cas reste linéaire.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.ordering,
        prompt: 'Ordre croissant de complexité dans le pire cas :',
        orderItems: const [
          'Recherche binaire',
          'Merge sort',
          'Quicksort (pire cas)',
          'Tri bulle',
        ],
        explanation:
            'O(log n) < O(n log n) < O(n²). Quicksort '
            'en pire cas rejoint le tri bulle.',
      ),
    ],
  ),
  _Theme(
    label: 'Bonnes pratiques',
    blurb: 'Lisibilité, tests et maintenance sur le long terme',
    color: Color(0xFF43A047),
    icon: Icons.verified_rounded,
    lessonTitles: [
      'Nommer, documenter, structurer',
      'Tests unitaires et TDD',
      'Refactoring et revues de code',
    ],
    theoryBank: [
      'Un code est lu 100 fois pour être écrit 1 fois : les noms '
          'doivent être explicites. `dureeSession` plutôt que '
          '`x`. Une fonction de plus de 30 lignes doit être '
          'découpée ; une classe de plus de 200 lignes devient '
          'un fourre-tout.',
      'Les commentaires ne remplacent pas un code clair : ils '
          'expliquent le POURQUOI (intention métier), jamais le '
          'QUOI (déjà visible). Un commentaire daté du 12 mars '
          'devient faux dès que le code évolue.',
      'Les tests unitaires vérifient chaque unité de code de '
          'façon isolée. En Flutter/Dart : `test(\'additionne\', '
          '() => expect(somme([1,2,3]), 6))`. Une bonne '
          'couverture atteint 80 % des chemins critiques.',
      'Le TDD (test-driven development) impose le cycle rouge → '
          'vert → refactor : j\'écris d\'abord un test qui '
          'échoue, puis le code minimal qui le fait passer, puis '
          'je nettoie sans casser. C\'est une discipline, pas '
          'une religion : elle paie surtout sur les modules '
          'métier complexes.',
      'Un refactor est une transformation qui améliore la '
          'structure sans changer le comportement observable. '
          'Sans tests automatisés, il est impossible de garantir '
          'cette invariance : les tests sont le filet de '
          'sécurité du refactoring.',
      'Les revues de code en entreprise camerounaise (SNI, '
          'MTN, Orange) suivent trois axes : lisibilité, '
          'sécurité (injections, secrets en dur, accès non '
          'autorisés), et performance (complexité, fuites '
          'mémoire). Chaque commentaire doit proposer une '
          'solution, pas seulement pointer un problème.',
    ],
    example: _ExamplePack(
      titles: [
        'Renommage expressif',
        'Test unitaire Flutter',
        'Refactor : extraire une fonction',
      ],
      bodies: [
        'Avant : `int c = 0; for (var u in users) if (u.a > 17) '
            'c++;`. Après : `int compteMajeurs(List<Utilisateur> '
            'utilisateurs) => utilisateurs.where((u) => '
            'u.age > 17).length;` — même opération, clarté '
            'radicalement différente.',
        'Chaque composant critique d\'Educoach (progression XP, '
            'déverrouillage de leçon, calcul de moyenne) est '
            'accompagné d\'un test dans le dossier `test/` qui '
            'fait appel à une store reset() pour l\'isolation.',
        'Extraire une méthode qui dépasse 40 lignes dans une '
            'classe : on sélectionne le bloc, on crée une '
            'méthode privée qui retourne la valeur utilisée '
            'ensuite. Aucun changement de comportement ; '
            'seule la structure s\'améliore.',
      ],
      codes: [
        '// avant\n'
            'int c = 0;\n'
            'for (var u in users) { if (u.a > 17) c++; }\n'
            '// après\n'
            'int compteMajeurs(List<Utilisateur> u) =>\n'
            '    u.where((x) => x.age > 17).length;',
        'void main() {\n'
            '  test(\'additionne les scores\', () {\n'
            '    expect(somme([1, 2, 3]), 6);\n'
            '  });\n'
            '}',
        'class LessonPlayer {\n'
            '  void _updateProgress(Lesson l, AttemptResult r) {\n'
            '    final xp = _computeXp(r);\n'
            '    _unlockNextIfNeeded(l);\n'
            '    _recordStreak();\n'
            '  }\n'
            '}',
      ],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt:
            'Quel ratio de couverture de test est généralement '
            'considéré comme un bon seuil pour le code métier '
            'critique ?',
        options: const [
          ExerciseOption(id: 'a', text: '20 %'),
          ExerciseOption(id: 'b', text: '50 %'),
          ExerciseOption(id: 'c', text: '80 %', correct: true),
          ExerciseOption(id: 'd', text: '100 % obligatoire'),
        ],
        explanation:
            '80 % est l\'ordre de grandeur usuel ; viser '
            '100 % est contre-productif car des branches '
            'défensives difficiles à tester apportent peu.',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt:
            'Un refactor doit toujours changer le '
            'comportement observable.',
        expectedAnswer: 'Faux',
        explanation:
            'Faux — par définition, un refactor '
            'préserve le comportement observable ; c\'est ce '
            'que garantissent les tests.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.textInput,
        prompt:
            'En TDD, quelles sont les trois étapes du cycle '
            '(séparées par des virgules, dans l\'ordre) ?',
        acceptedAnswers: const ['rouge, vert, refactor', 'rouge,vert,refactor'],
        expectedAnswer: 'rouge, vert, refactor',
        hint: 'On écrit d\'abord un test qui échoue.',
        explanation:
            'Rouge (test échoue) → vert (code minimal '
            'pour le faire passer) → refactor (nettoyer sans '
            'casser).',
      ),
    ],
  ),
];

// ===========================================================================
//  Droit — contenu réaliste (droit camerounais, OHADA, constitutions)
// ===========================================================================
final _droitThemes = <_Theme>[
  _Theme(
    label: 'Sources du droit',
    blurb: 'Constitution, traités, lois, règlement, jurisprudence, doctrine',
    color: Color(0xFF5D4037),
    icon: Icons.gavel_rounded,
    lessonTitles: [
      'La hiérarchie des normes',
      'Constitution camerounaise de 1996 révisée',
      'Traités OHADA et espace juridique communautaire',
    ],
    theoryBank: [
      'La pyramide de Kelsen structure l\'ordre juridique : au '
          'sommet la Constitution, puis les traités '
          'internationalement ratifiés (dont l\'Acte uniforme '
          'OHADA), puis les lois votées par le Parlement, puis '
          'les règlements (décrets, arrêtés), enfin les '
          'circulaires. Une norme inférieure ne peut contredire '
          'une norme supérieure.',
      'La Constitution camerounaise du 18 janvier 1996, révisée '
          'en 2008 (fin de la limitation du nombre de mandats) '
          'et en 2019 (grand dialogue de national, statut des '
          'régions anglophones), pose les principes fondamentaux '
          ': République, laïcité, bilinguisme français/anglais, '
          'séparation des pouvoirs et indépendance de la '
          'justice.',
      'L\'OHADA (Organisation pour l\'Harmonisation en Afrique '
          'du Droit des Affaires), créée par le traité de '
          'Port-Louis le 17 octobre 1993, regroupe 17 États '
          'africains dont le Cameroun. Ses Actes uniformes '
          '(droit commercial général, sociétés commerciales, '
          'procédures simplifiées de recouvrement, voies '
          'd\'exécution, etc.) s\'imposent directement aux '
          'justiciables.',
      'La jurisprudence désigne l\'ensemble des décisions '
          'rendues par les juridictions sur une question. Elle '
          'n\'a pas autorité de la chose jugée au-delà du '
          'litige, mais elle éclaire le droit vivant. La CCJA '
          '(Cour Commune de Justice et d\'Arbitrage) de l\'OHADA '
          'produit une jurisprudence uniforme pour ses 17 '
          'États membres.',
      'La doctrine — travaux des universitaires, articles, '
          'ouvrages — n\'est pas source formelle du droit mais '
          'guide juges et législateurs. Les thèses soutenues à '
          'l\'Université de Dschang ou de Douala participent à '
          'cette effervescence doctrinale.',
      'Les coutumes ont une place reconnue dans plusieurs '
          'matières au Cameroun : chefferie traditionnelle, '
          'successions foncières, régimes matrimoniaux. Le '
          'décret du 20 mai 1931 (encore en vigueur) définit '
          'leur domaine d\'application, sous réserve de '
          'l\'ordre public.',
    ],
    example: _ExamplePack(
      titles: [
        'Contrôle de constitutionnalité',
        'Acte uniforme applicable en L3',
        'Coutume et ordre public',
      ],
      bodies: [
        'Le Conseil constitutionnel camerounais, saisi par 20 '
            'sénateurs, censure une loi qui restreindrait la '
            'liberté de réunion au-delà de ce que permet '
            'l\'article 9 de la Constitution. La décision '
            's\'impose à toutes les autorités.',
        'Un étudiant de L3 Droit privé à l\'UCAC traite un cas '
            'de redressement judiciaire : le juge-commissaire '
            'applique l\'Acte uniforme OHADA relatif aux '
            'procédures collectives, révisé le 24 janvier 2017, '
            'sans qu\'il soit besoin de transposition nationale.',
        'Une succession coutumière dans le Nord-Cameroun peut '
            'écarter les femmes de l\'héritage du vivant ; la '
            'Cour suprême, au nom de l\'ordre public '
            'constitutionnel et de la CEDAF, invalide ces '
            'clauses contraires à l\'égalité.',
      ],
      codes: [null, null, null],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt:
            'En quel ordre hiérarchique se situent, du plus '
            'fort au plus faible, ces textes ?',
        options: const [
          ExerciseOption(
            id: 'a',
            text:
                'Constitution > traités OHADA > lois > '
                'décrets',
            correct: true,
          ),
          ExerciseOption(
            id: 'b',
            text:
                'Lois > Constitution > '
                'traités > décrets',
          ),
          ExerciseOption(
            id: 'c',
            text:
                'Décrets > lois > '
                'Constitution > traités',
          ),
          ExerciseOption(
            id: 'd',
            text:
                'Traités > Constitution '
                '> décrets > lois',
          ),
        ],
        explanation:
            'La pyramide de Kelsen place la Constitution '
            'au sommet. Viennent ensuite les engagements '
            'internationaux régulièrement ratifiés (art. 45 de '
            'la Constitution camerounaise), puis les lois, puis '
            'les actes réglementaires.',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt: 'L\'OHADA compte aujourd\'hui 17 États membres.',
        expectedAnswer: 'Vrai',
        explanation:
            'Vrai — depuis l\'adhésion de la Guinée '
            'en 2014. Le Cameroun fait partie des 14 signataires '
            'originaires de 1993.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.textInput,
        prompt:
            'Quelle cour de l\'OHADA statue sur '
            'l\'uniformisation du droit des affaires en '
            'dernier ressort ?',
        expectedAnswer: 'CCJA',
        acceptedAnswers: const [
          'CCJA',
          'Cour Commune de Justice et d\'Arbitrage',
          'la ccja',
        ],
        hint: 'Sigle en quatre lettres, siège à Abidjan.',
        explanation:
            'La Cour Commune de Justice et d\'Arbitrage '
            '(CCJA), sise à Abidjan, assure l\'uniforme '
            'interprétation du droit OHADA.',
      ),
    ],
  ),
  _Theme(
    label: 'Personnes et patrimoine',
    blurb: 'Majorité, incapacités, régimes matrimoniaux, successions',
    color: Color(0xFF37474F),
    icon: Icons.person_rounded,
    lessonTitles: [
      'Personnalité juridique et capacités',
      'Contrats et obligations',
      'Successions et libéralités',
    ],
    theoryBank: [
      'La personnalité juridique s\'acquiert à la naissance, '
          'vivante et viable (Code civil). Elle emporte la '
          'capacité d\'avoir des droits ; la capacité d\'exercer '
          'ces droits suppose la majorité, fixée à 21 ans au '
          'Cameroun par le Code civil (à distinguer des 18 ans '
          'du Code pénal pour la responsabilité).',
      'Un contrat valide suppose quatre conditions (art. 1108 '
          'Code civil) : consentement libre et éclairé, capacité '
          'de contracter, objet certain licite, cause licite. '
          'L\'erreur, le dol ou la violence vicient le '
          'consentement et ouvrent une action en nullité.',
      'Le patrimoine — concept d\'Aubry et Rau — est un tout '
          'indivisible de droits et d\'obligations évaluables en '
          'argent. Il est unique, personnel et transmissible. '
          'Il ne faut pas le confondre avec la masse de biens : '
          'les droits extra-patrimoniaux (droit à l\'honneur) '
          'en sont exclus.',
      'Les régimes matrimoniaux au Cameroun : communauté '
          'réduite aux acquêts (régime légal résiduel), '
          'séparation de biens, communauté universelle. Le '
          'contrat de mariage est facultatif mais fortement '
          'recommandé dès qu\'un conjoint exerce une activité '
          'commerciale.',
      'Les successions ab intestat suivent un ordre légal : '
          'descendants, ascendants privilégiés, collatéraux '
          'ordinaires. Le conjoint survivant recueille une '
          'partie en propriété ou en usufruct selon la présence '
          'ou l\'absence d\'héritiers réservataires.',
      'Les libéralités (donations et testaments) sont '
          'encadrées par la réserve héréditaire : la quotité '
          'disponible dépend du nombre d\'enfants. Un testament '
          'olographe doit être entièrement écrit, daté et signé '
          'de la main du testateur.',
    ],
    example: _ExamplePack(
      titles: [
        'Nullité pour dol',
        'Communauté réduite aux acquêts',
        'Testament olographe irrégulier',
      ],
      bodies: [
        'Vendeur d\'un terrain à Douala qui dissimule un '
            'contentieux foncier en cours : dol caractérisé, '
            'nullité absolue de la vente, restitution du prix '
            'plus dommages-intérêts.',
        'Un couple de fonctionnaires à Yaoundé, mariés sans '
            'contrat, acquiert un appartement après le mariage '
            '→ bien commun. Un terrain reçu en héritage par '
            'l\'épouse reste propre.',
        'Un testament olographe daté au crayon, sans signature '
            'en toutes lettres, est annulé par la juridiction '
            'de Maroua : la forme est une condition de validité '
            'et non une formalité.',
      ],
      codes: [null, null, null],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt:
            'Quelles sont les conditions de validité d\'un '
            'contrat selon l\'article 1108 du Code civil ?',
        options: const [
          ExerciseOption(
            id: 'a',
            text:
                'Consentement, capacité, objet certain et '
                'licite, cause licite',
            correct: true,
          ),
          ExerciseOption(
            id: 'b',
            text:
                'Écrit, signature, '
                'timbre fiscal',
          ),
          ExerciseOption(
            id: 'c',
            text:
                'Témoins, notaire, '
                'enregistrement',
          ),
          ExerciseOption(
            id: 'd',
            text:
                'Publicité foncière '
                'seulement',
          ),
        ],
        explanation:
            'L\'article 1108 exige quatre conditions '
            'de fond ; les conditions de forme ne sont '
            'requises que pour certains actes (solennités).',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt:
            'Le patrimoine comprend les droits '
            'extra-patrimoniaux comme le droit à l\'honneur.',
        expectedAnswer: 'Faux',
        explanation:
            'Faux — le patrimoine ne contient que des '
            'droits et obligations pécuniaires ; les droits '
            'extrapatrimoniaux en sont exclus car '
            'insaisissables et incessibles.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.textInput,
        prompt:
            'Combien de conditions de fond l\'article 1108 '
            'exige-t-elle pour la validité d\'un contrat ?',
        acceptedAnswers: const ['4', 'quatre'],
        expectedAnswer: '4',
        explanation:
            'Quatre : consentement, capacité, objet, '
            'cause.',
      ),
    ],
  ),
  _Theme(
    label: 'Procédure civile',
    blurb: 'Saisine, instance, preuve et exécution',
    color: Color(0xFF455A64),
    icon: Icons.fact_check_rounded,
    lessonTitles: [
      'Organisation judiciaire camerounaise',
      'Saisine et déroulement de l\'instance',
      'Preuve, exécution et voies de recours',
    ],
    theoryBank: [
      'L\'ordre judiciaire camerounais comprend les tribunaux '
          'de première instance, les cours d\'appel (10 au total, '
          'dont Yaoundé, Douala, Bafoussam, Maroua), et la Cour '
          'suprême — juridiction de cassation pour les questions '
          'de droit. Les tribunaux coutumiers statuent en '
          'matière personnelle dans les zones où la coutume est '
          'reconnue.',
      'La saisine se fait par assignation (acte d\'huissier) '
          'ou par requête selon les matières. L\'article 4 du '
          'CPC exige l\'indication des noms, qualité, domicile '
          'des parties, l\'objet de la demande et l\'exposé des '
          'moyens. Un défaut de formalité peut entraîner la '
          'nullité de l\'acte.',
      'Le fardeau de la preuve : « actor incumbit probatio » — '
          'celui qui allègue doit prouver. Les modes de preuve '
          'sont hiérarchiques : écrit authentique > écrit sous '
          'seing privé > témoignage > présomption > aveu > '
          'serment. En matière commerciale, la liberté de la '
          'preuve est plus large.',
      'L\'exécution forcée suppose un titre exécutoire : '
          'jugement passé en force de chose jugée, acte '
          'notarié, chèque impayé. Les mesures varient : saisie '
          'appréhension sur les meubles, saisie-attribution sur '
          'les créances, saisie immobilière pour les immeubles.',
      'Les voies de recours sont l\'opposition (contre un '
          'jugement réputé contradictoire non signifié), '
          'l\'appel (dans un mois, réexamen de l\'affaire au '
          'fond par la cour d\'appel) et le pourvoi en '
          'cassation (dans deux mois, sur des moyens de droit '
          'uniquement).',
      'La médiation et l\'arbitrage se développent au '
          'Cameroun, notamment en matière commerciale et '
          'familiale. Le centre d\'arbitrage de la CCJA et le '
          'CMA-Cameroun offrent des alternatives à la voie '
          'judiciaire classique.',
    ],
    example: _ExamplePack(
      titles: [
        'Assignation devant le TPI de Yaoundé',
        'Charge de la preuve en droit bancaire',
        'Pourvoi en cassation après appel',
      ],
      bodies: [
        'Pour un litige de 5 millions FCFA entre deux '
            'commerçants de Mokolo, l\'huissier délivre une '
            'assignation au tribunal de première instance de '
            'Yaoundé-Centre, avec indication de la date '
            'd\'audience et constitution d\'avocat obligatoire.',
        'Face à un emprunteur qui conteste un découvert, la '
            'banque productrice doit rapporter la preuve écrite du '
            'contrat de crédit et du relevé de compte signé. '
            'Sans écrit, le juge déboutera la banque.',
        'Après un arrêt confirmatif de la Cour d\'appel de '
            'Bafoussam, la partie perdante forme un pourvoi en '
            'cassation : elle ne conteste plus les faits, mais '
            'la violation de la loi (défaut de motifs, manque '
            'de base légale, violation d\'un acte uniforme '
            'OHADA).',
      ],
      codes: [null, null, null],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt:
            'Quel est le délai pour interjeter appel d\'un '
            'jugement civil au Cameroun ?',
        options: const [
          ExerciseOption(id: 'a', text: '15 jours'),
          ExerciseOption(id: 'b', text: '1 mois', correct: true),
          ExerciseOption(id: 'c', text: '3 mois'),
          ExerciseOption(id: 'd', text: '2 ans'),
        ],
        explanation:
            'Un mois à compter de la signification du '
            'jugement (CPC) ; deux mois pour le pourvoi en '
            'cassation.',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt:
            'Le pourvoi en cassation rejuge l\'affaire au '
            'fond.',
        expectedAnswer: 'Faux',
        explanation:
            'Faux — la Cour suprême ne juge que le '
            'droit ; elle casse et renvoie, mais ne rejuge '
            'jamais les faits.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.ordering,
        prompt: 'Instauration d\'une instance civile :',
        orderItems: const [
          'Constitution d\'avocat',
          'Assignation délivrée par huissier',
          'Mise au rôle au greffe',
          'Ordonnance de clôture',
          'Plaidoiries et délibéré',
        ],
        explanation:
            'On constitue avocat, on assigne, on met '
            'au rôle, on clôture les échanges, puis on plaide.',
      ),
    ],
  ),
];

// ===========================================================================
//  Économie & gestion
// ===========================================================================
final _ecoThemes = <_Theme>[
  _Theme(
    label: 'Microéconomie',
    blurb: 'Offre, demande, équilibre et élasticité',
    color: Color(0xFF1565C0),
    icon: Icons.trending_up_rounded,
    lessonTitles: [
      'Loi de l\'offre et de la demande',
      'Élasticité-prix et revenus',
      'Concurrence, monopole et oligopole',
    ],
    theoryBank: [
      'La demande : relation décroissante entre prix et quantité '
          'achetée, toutes choses égales par ailleurs. L\'offre : '
          'relation croissante entre prix et quantité produite. '
          'L\'équilibre de marché est le prix où quantité '
          'demandée = quantité offerte.',
      'L\'équilibre du marché du manioc à Bafoussam se '
          'détermine chaque jeudi : les offres agrégées des '
          'productrices et les demandes des grossistes se '
          'rencontrent sur la courbe. Un déplacement de la '
          'demande (sécheresse) déplace le prix d\'équilibre.',
      'L\'élasticité-prix de la demande mesure la sensibilité '
          'des quantités au prix : ε = (% Δ Q) / (% Δ P). '
          'Elle est élevée pour les biens de luxe (café '
          'arabica), faible pour les biens essentiels (manioc, '
          'mazout).',
      'En concurrence pure et parfaite, le producteur est '
          '« price taker » : il fixe sa quantité là où coût '
          'marginal = prix. Cette règle fonde toute la théorie '
          'de l\'entreprise néoclassique.',
      'Le monopoleur fait face à la demande du marché : il '
          'fixe sa quantité où recette marginale = coût '
          'marginal, puis relève le prix sur la courbe de '
          'demande. Il engendre une perte sèche d\'efficience.',
      'Les oligopoles (télécoms au Cameroun : MTN, Orange) '
          's\'analysent par la théorie des jeux : équilibre de '
          'Nash, dilemme du prisonnier, modèles de Stackelberg '
          'et de Cournot.',
    ],
    example: _ExamplePack(
      titles: [
        'Équilibre sur le marché du plantain',
        'Élasticité du prix du carburant',
        'Tarif monopole vs concurrentiel',
      ],
      bodies: [
        'Qd = 200 - 2P ; Qo = 50 + 3P → à l\'équilibre, '
            '200 - 2P = 50 + 3P → P* = 30 FCFA, Q* = 140 '
            'kg. Une taxe de 5 FCFA/kg déplace le prix '
            'payé par le consommateur à 33 et celui reçu par '
            'le producteur à 28.',
        'Le prix du super à la pompe passe de 750 à 825 FCFA '
            '(+10 %) : les automobilistes réduisent leur '
            'consommation de 4 % seulement. L\'élasticité-prix '
            'du carburant est de -0,4 : demande inélastique, '
            'les revenus fiscaux augmentent.',
        'Un opérateur en situation de monopole fixe P = 1200 '
            'FCFA, quantité 5 000 ; sous concurrence parfaite, '
            'P = 800 FCFA, quantité 8 000. La perte sèche '
            'représente les 3 000 unités qui ne sont plus '
            'produites alors que leur utilité sociale '
            'excédait le coût marginal.',
      ],
      codes: [
        'Qd = 200 - 2P ; Qo = 50 + 3P\n'
            'À l\'équilibre : P* = 30 FCFA, Q* = 140 kg',
        'ε = (ΔQ/Q) / (ΔP/P)\n'
            '  = (-0,04) / (0,10) = -0,4  → inélastique',
        'Concurrence : P = Cm = 800, Q = 8 000\n'
            'Monopole      : Pm = 1 200, Qm = 5 000\n'
            'Perte sèche = ½ × (Qc − Qm) × (Pm − Cm)',
      ],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt:
            'Si ε = -0,3 (inelastique), une hausse de prix '
            'de 10 % entraîne :',
        options: const [
          ExerciseOption(
            id: 'a',
            text:
                'Une baisse de 3 % des quantités et une '
                'hausse du chiffre d\'affaires',
            correct: true,
          ),
          ExerciseOption(
            id: 'b',
            text:
                'Une baisse de 30 % '
                'des quantités',
          ),
          ExerciseOption(
            id: 'c',
            text:
                'Une baisse du chiffre '
                'd\'affaires',
          ),
          ExerciseOption(id: 'd', text: 'Aucun effet'),
        ],
        explanation:
            'Une demande inélastique signifie que la '
            'hausse de prix est plus que compensée par la '
            'faible baisse des quantités : le CA augmente.',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.fillBlank,
        prompt:
            'Le producteur en concurrence parfaite maximise '
            'son profit quand ___ = prix.',
        blankTemplate: 'max profit quand ___ = prix',
        expectedAnswer: 'coût marginal',
        acceptedAnswers: const ['coût marginal', 'Cm', 'cost marginal'],
        explanation:
            'P = Cm : la règle Cardinale de '
            'l\'équilibre concurrentiel.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.trueFalse,
        prompt:
            'Un bien de Giffen présente une courbe de '
            'demande décroissante.',
        expectedAnswer: 'Faux',
        explanation:
            'Faux — un bien de Giffen présente une '
            'courbe de demande CROISSANTE : quand le prix '
            'augmente, la quantité demandée augmente aussi, '
            'car l\'effet revenu domine l\'effet de '
            'substitution.',
      ),
    ],
  ),
  _Theme(
    label: 'Macroéconomie',
    blurb: 'PIB, inflation, chômage, politique monétaire',
    color: Color(0xFF0288D1),
    icon: Icons.show_chart_rounded,
    lessonTitles: [
      'Comptabilité nationale et PIB',
      'Inflation, chômage et cycle',
      'Politiques budgétaire et monétaire',
    ],
    theoryBank: [
      'Le PIB mesure la valeur ajoutée produite sur le '
          'territoire en un an. Trois optiques concordantes : '
          'production (somme des VA), demande '
          '(C + I + G + X - M), revenu (salaires + profits + '
          'impôts nets). Au Cameroun, le PIB nominal avoisine '
          '45 000 milliards FCFA.',
      'L\'inflation se mesure par l\'indice des prix à la '
          'consommation (IPC) : une hausse de 5 % signifie '
          'qu\'un panier qui coûtait 100 FCFA en base coûte '
          '105 FCFA cette année. Les causes typiques : '
          'inflation monétaire (quantité de monnaie qui croît '
          'plus que la production), par les coûts (pétrole), '
          'et par la demande.',
      'Le chômage au sens du BIT : personne sans emploi, '
          'disponible, en recherche active. Le taux de '
          'chômage camerounais se situe autour de 3,4 % au '
          'recensement RGPH 2005 ; les enquêtes EBCMQP récentes '
          'donnent un chiffre proche, mais le sous-emploi '
          'touche 60 % de la population active.',
      'La BEAC conduit la politique monétaire de la CEMAC '
          '(Cameroun, Tchad, RCA, Congo, Gabon, Guinée '
          'équatoriale) : elle fixe le taux directeur, pilote '
          'la masse monétaire, gère les réserves de change '
          'indexées sur l\'euro via le FCFA.',
      'La politique budgétaire utilise la dépense publique et '
          'la fiscalité. Les règles keynésiennes recommandent '
          'un déficit en récession et un excédent en '
          'expansion. La CEMAC impose un déficit inférieur à '
          '3 % du PIB.',
      'La courbe de Phillips illustre un arbitrage court-termiste '
          'entre inflation et chômage : accepter un peu plus '
          'd\'inflation pour réduire le chômage. À long terme, '
          'cet arbitrage disparaît (Friedman, Phelps).',
    ],
    example: _ExamplePack(
      titles: [
        'Calcul du PIB par la demande',
        'Indice des prix et taux d\'inflation',
        'Multiplicateur keynésien',
      ],
      bodies: [
        'Si C = 30 000, I = 8 000, G = 6 000, X = 3 000, '
            'M = 4 000 (en milliards FCFA) : PIB = 30 000 + 8 '
            '000 + 6 000 + 3 000 - 4 000 = 43 000 milliards.',
        'Panier 2024 : 200 FCFA, panier 2025 : 210 FCFA. '
            'IPC base 100 en 2024 → IPC 105 en 2025. Taux '
            'd\'inflation = 5 %.',
        'Une hausse des dépenses publiques de 100 milliards '
            'avec une propension moyenne à consommer de 0,7 : '
            'multiplicateur = 1/(1-0,7) ≈ 3,33 ; impact total '
            '≈ 333 milliards de PIB.',
      ],
      codes: [
        'PIB = C + I + G + (X − M)',
        'Taux d\'inflation = (IPC_t − IPC_{t−1}) / IPC_{t−1}',
        'k = 1 / (1 − c) ; ΔY = k · ΔD',
      ],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt: 'Le PIB mesure :',
        options: const [
          ExerciseOption(
            id: 'a',
            text:
                'La valeur ajoutée produite sur le '
                'territoire',
            correct: true,
          ),
          ExerciseOption(
            id: 'b',
            text:
                'Les revenus perçus '
                'par les nationaux, où qu\'ils soient',
          ),
          ExerciseOption(id: 'c', text: 'La consommation finale'),
          ExerciseOption(id: 'd', text: 'Le stock de richesses'),
        ],
        explanation:
            'PIB = production intérieure. Le RNB lui '
            'ajoute les revenus primaires nets reçus du reste '
            'du monde.',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.fillBlank,
        prompt:
            'La banque centrale de la zone FCFA '
            'camerounaise s\'appelle ___.',
        blankTemplate: 'La banque centrale du Cameroun = ___',
        expectedAnswer: 'BEAC',
        acceptedAnswers: const [
          'BEAC',
          'Banque des États de '
              'l\'Afrique Centrale',
        ],
        explanation:
            'La BEAC (Banque des États de l\'Afrique '
            'Centrale), siège à Yaoundé.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.trueFalse,
        prompt: 'La courbe de Phillips vaut aussi à long terme.',
        expectedAnswer: 'Faux',
        explanation:
            'Faux — à long terme la courbe est '
            'verticale au taux naturel de chômage ; '
            'l\'arbitrage n\'existe qu\'à court terme.',
      ),
    ],
  ),
  _Theme(
    label: 'Finance d\'entreprise',
    blurb: 'Valeur temps, financement, investissement',
    color: Color(0xFFEF6C00),
    icon: Icons.savings_rounded,
    lessonTitles: [
      'Actualisation et VAN',
      'Coût du capital et structure financière',
      'Valorisation et fusions-acquisitions',
    ],
    theoryBank: [
      'Un euro aujourd\'hui vaut plus qu\'un euro demain : '
          'c\'est le principe de la préférence temporelle. '
          'Actualiser une somme future consiste à la diviser '
          'par (1 + i)ⁿ. La valeur actuelle nette (VAN) d\'un '
          'projet est la somme des flux actualisés moins '
          'l\'investissement initial.',
      'Le coût moyen pondéré du capital (CMPC ou WACC) est '
          '(E/(D+E)) × ke + (D/(D+E)) × kd × (1 - IS) : le '
          'taux d\'actualisation pertinent pour un projet au '
          'risque comparable à l\'entreprise.',
      'ke (coût des fonds propres) s\'estime souvent par le '
          'MEDAF : ke = rf + β × (rm − rf). Au Cameroun, '
          'l\'absence de marché financier liquide oblige à '
          'utiliser un β sectoral africain et une prime de '
          'risque souverain.',
      'Le Modigliani-Miller (1958) dit qu\'à marché parfait, '
          'la valeur de l\'entreprise ne dépend pas de sa '
          'structure de capital. En pratique, la déductibilité '
          'fiscale des intérêts d\'emprunt crée un bouclier '
          'fiscal qui pousse vers l\'endettement.',
      'Valoriser par les multiples (EV/EBITDA, PER) ou par '
          'DCF : deux approches complémentaires. Une start-up '
          'de fintech à Douala avec 0 EBITDA se valorise sur '
          'des multiples d\'utilisateurs actifs.',
      'Les fusions-acquisitions suivent un processus : '
          'stratégie → screening → due diligence → négociation '
          '→ closing → intégration. Le risque majeur est le '
          'surpaye et l\'échec d\'intégration.',
    ],
    example: _ExamplePack(
      titles: [
        'Calcul d\'une VAN',
        'WACC d\'une PME camerounaise',
        'Valorisation par les multiples',
      ],
      bodies: [
        'Projet d\'un centre de formation numérique à Douala : '
            'investissement 150 millions, flux 45 millions/an '
            'pendant 5 ans, taux 12 %. VAN = -150 + 45 × '
            'annuité(12 %, 5) = -150 + 45 × 3,605 = 12,2 '
            'millions → positif, on investit.',
        'Une PME avec fonds propres 60 M, dette 40 M, ke 15 %, '
            'kd 9 %, IS 30 % : WACC = 0,6 × 15 % + 0,4 × 9 % × '
            '0,7 = 12,2 %.',
        'Une brasserie avec EBITDA 800 M et secteur coté à '
            'EV/EBITDA = 6× → valeur d\'entreprise ≈ 4,8 '
            'milliards. On retranche la dette nette pour '
            'obtenir la valeur des capitaux propres.',
      ],
      codes: [
        'VAN = −I₀ + Σ (CFₜ / (1+i)ᵗ)',
        'WACC = E/(D+E)·ke + D/(D+E)·kd·(1 − IS)',
        'VE = EBITDA × multiple\n'
            'Capitaux propres = VE − dette nette',
      ],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt: 'Un projet est acceptable si :',
        options: const [
          ExerciseOption(id: 'a', text: 'VAN > 0', correct: true),
          ExerciseOption(id: 'b', text: 'TRI < taux d\'actualisation'),
          ExerciseOption(id: 'c', text: 'Payback > durée de vie'),
          ExerciseOption(
            id: 'd',
            text:
                'Compte de résultat '
                'positif',
          ),
        ],
        explanation:
            'VAN positive : le projet crée de la '
            'valeur après rémunération du capital au coût de '
            'l\'argent.',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt:
            'D\'après Modigliani-Miller (1958, hypothèses '
            'fortes), la valeur d\'une entreprise dépend de sa '
            'structure de capital.',
        expectedAnswer: 'Faux',
        explanation:
            'Faux — dans leur proposition I, la '
            'valeur est INDEPENDANTE de la structure du '
            'capital sous les hypothèses de marchés parfaits, '
            'sans fiscalité ni faillite.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.fillBlank,
        prompt:
            'Le taux qui rend la VAN nulle s\'appelle le '
            '___ d\'un investissement.',
        blankTemplate: 'taux où VAN = 0 → ___',
        expectedAnswer: 'TRI',
        acceptedAnswers: const [
          'TRI',
          'taux de rendement '
              'interne',
          'IRR',
        ],
        explanation:
            'TRI : taux d\'actualisation interne, '
            'comparable au coût du capital.',
      ),
    ],
  ),
];

// ===========================================================================
//  Santé / médecine
// ===========================================================================
final _santeThemes = <_Theme>[
  _Theme(
    label: 'Anatomie et physiologie',
    blurb: 'Cellule, tissus, organes, systèmes fonctionnels',
    color: Color(0xFFC62828),
    icon: Icons.favorite_rounded,
    lessonTitles: [
      'La cellule et ses organites',
      'Tissus épithéliaux, conjonctifs, musculaires, nerveux',
      'Systèmes cardiovasculaire et respiratoire',
    ],
    theoryBank: [
      'La cellule eucaryote est délimitée par une membrane '
          'plasmique phospholipidique semi-perméable. Elle '
          'contiendra le noyau (23 paires de chromosomes chez '
          'l\'humain), les mitochondries (centrales énergétiques '
          'productrices d\'ATP), le réticulum endoplasmique '
          '(synthèse protéique et lipidique) et l\'appareil de '
          'Golgi (tri et maturation).',
      'Les quatre grands types de tissus : épithélial (revêtement '
          'et sécrétion, ex. : peau, muqueuse intestinale), '
          'conjonctif (soutien, ex. : os, cartilage, sang), '
          'musculaire (contractilité : squelettique strié, '
          'lisse, cardiaque) et nerveux (neurones + cellules '
          'gliales, conduisent l\'influx).',
      'Le cœur pompe 5 litres de sang par minute au repos, '
          '7 à 35 litres à l\'effort. Les quatre cavités — '
          'oreillettes droite et gauche, ventricules droit et '
          'gauche — fonctionnent en double circuit : petite '
          'circulation (cœur ↔ poumons) et grande circulation '
          '(cœur ↔ organes).',
      'La respiration assure les échanges gazeux : O₂ entre '
          'dans le sang au niveau des alvéoles, CO₂ en sort. '
          '150 m² de surface alvéolaire au total, soit la '
          'surface d\'un terrain de tennis replié dans la '
          'poitrine.',
      'Le néphron, unité fonctionnelle du rein, compte environ '
          '1 million par rein. Il filtre le plasma (glomérule), '
          'réabsorbe eau et nutriments (tube contourné, anse de '
          'Henlé, tube collecteur) et sécrète les déchets.',
      'Au Cameroun, l\'hypertension artérielle touche plus de '
          '30 % des adultes de plus de 35 ans, selon l\'étude '
          'HyCAM (2016) : un enjeu de santé publique majeur, '
          'facteur principal d\'AVC et d\'insuffisance rénale.',
    ],
    example: _ExamplePack(
      titles: ['Diffusion membranaire', 'Cycles cardiaques', 'Glomérule rénal'],
      bodies: [
        'Un globule rouge placé dans une solution hypertonique '
            'se créne (perte d\'eau par osmose) ; en hypotonique, '
            'il gonfle et hémolyse. Explication directe du '
            'transport d\'eau à travers la membrane.',
        'Un cycle cardiaque = systole auriculaire (0,1 s) → '
            'systole ventriculaire (0,3 s) → diastole générale '
            '(0,4 s). À 75 bpm, un cycle = 0,8 s.',
        'La filtration glomérulaire produit ~180 litres de '
            'filtrat primaire par jour, dont 99 % sont '
            'réabsorbés : le volume d\'urine finale n\'est '
            'qu\'1,5 L.',
      ],
      codes: [null, null, null],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt:
            'Combien de paires de chromosomes compte la '
            'cellule humaine ?',
        options: const [
          ExerciseOption(id: 'a', text: '23', correct: true),
          ExerciseOption(id: 'b', text: '24'),
          ExerciseOption(id: 'c', text: '46'),
          ExerciseOption(id: 'd', text: '22'),
        ],
        explanation:
            '23 paires = 46 chromosomes (dont une '
            'paire sexuelle XX ou XY).',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt:
            'Le muscle cardiaque est un muscle strié '
            'volontaire.',
        expectedAnswer: 'Faux',
        explanation:
            'Faux — le myocarde est strié mais '
            'INVOLONTAIRE, ce qui le distingue du muscle '
            'squelettique.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.ordering,
        prompt:
            'Ordre des structures rénales parcourues par '
            'un filtrat :',
        orderItems: const [
          'Glomérule',
          'Tube contourné proximal',
          'Anse de Henlé',
          'Tube contourné distal',
          'Tube collecteur',
        ],
        explanation:
            'C\'est l\'ordre canonique du néphron ; '
            'chaque segment effectue des échanges spécifiques.',
      ),
    ],
  ),
  _Theme(
    label: 'Pharmacologie',
    blurb: 'ADME, mécanismes d\'action et posologie',
    color: Color(0xFFAD1457),
    icon: Icons.medication_liquid_rounded,
    lessonTitles: [
      'ADME : absorption, distribution, métabolisme, élimination',
      'Récepteurs et mécanismes d\'action',
      'Calcul de dose et posologie adaptée',
    ],
    theoryBank: [
      'L\'ADME décrit le voyage du médicament : Absorption (du '
          'lieu d\'administration au sang), Distribution (du '
          'sang aux organes), Métabolisme (transformation '
          'chimique, surtout hépatique via CYP450) et '
          'Élimination (excrétion rénale ou biliaire).',
      'La biodisponibilité F est la fraction de dose atteignant '
          'la circulation générale. En IV, F = 100 % ; par voie '
          'orale, elle varie : paracétamol ~80 %, morphine ~30 % '
          'à cause du métabolisme de premier passage hépatique.',
      'La demi-vie plasmatique t₁/₂ correspond au temps nécessaire '
          'pour que la concentration plasmatique diminue de '
          'moitié. À l\'état d\'équilibre (régime permanent), '
          'il faut 4 à 5 demi-vies pour atteindre 94-97 % de '
          'la concentration cible.',
      'Un agoniste active le récepteur ; un antagoniste le '
          'bloque sans l\'activer. Les bêtabloquants (aténolol) '
          'sont des antagonistes compétitifs des récepteurs '
          'β-adrénergiques ; la salbutamol en est un agoniste '
          'β2 utilisé dans l\'asthme.',
      'Chez l\'insuffisant rénal, on ajuste la dose selon la '
          'clairance de la créatinine (formule de Cockcroft). '
          'Chez le sujet âgé, la réduction de la masse '
          'hépatique impose de surveiller les médicaments '
          'métabolisés par CYP3A4.',
      'Le Cameroun dispose d\'une Pharmacie Nationale d\'Approvisionnement '
          '(PNA) qui garantit l\'accès aux médicaments essentiels. '
          'La lutte contre les médicaments falsifiés est un '
          'axe prioritaire du MINSANTÉ.',
    ],
    example: _ExamplePack(
      titles: [
        'Demi-vie et accumulation',
        'Ajustement de posologie',
        'Interactions médicamenteuses',
      ],
      bodies: [
        'Un antibiotique à t₁/₂ = 6 h administré toutes les '
            '8 h atteindra son plateau après 24-30 h. Une '
            'administration trop rapprochée provoque une '
            'accumulation toxique.',
        'Créatinine sérique 180 µmol/L chez un patient de '
            '70 kg, 65 ans : Cockcroft → ClCr ≈ 30 ml/min. '
            'La dose de l\'amoxicilline doit être réduite de '
            '50 % et l\'intervalle allongé.',
        'Le clopidogrel est un pro-drogue activée par CYP2C19. '
            'Le kétoconazole, inhibiteur puissant, diminue son '
            'efficacité antiagrégante : risque accru de '
            'thrombose.',
      ],
      codes: [
        'ClCr = ((140 − âge) × poids) / (72 × créat) '
            '× 0,85 si femme',
        null,
        null,
      ],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt:
            'Combien de demi-vies faut-il pour atteindre '
            'l\'équilibre plasmatique ?',
        options: const [
          ExerciseOption(id: 'a', text: '1 à 2'),
          ExerciseOption(id: 'b', text: '4 à 5', correct: true),
          ExerciseOption(id: 'c', text: '10 à 12'),
          ExerciseOption(id: 'd', text: '24 heures'),
        ],
        explanation:
            '4 à 5 demi-vies → 94-97 % de l\'état '
            'stable. C\'est la règle d\'or en pharmacocinétique.',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt:
            'La morphine a une biodisponibilité orale de '
            '100 %.',
        expectedAnswer: 'Faux',
        explanation:
            'Faux — à cause de son important '
            'métabolisme de premier passage hépatique, elle '
            'n\'atteint que ~30 % en voie orale.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.fillBlank,
        prompt:
            'Complète : les enzymes hépatiques responsables '
            'du métabolisme des médicaments sont les ___.',
        blankTemplate: 'enzymes hépatiques = ___',
        expectedAnswer: 'CYP450',
        acceptedAnswers: const ['CYP450', 'cytochrome P450', 'Cyp'],
        explanation:
            'Le système cytochrome P450 regroupe une '
            'super-famille d\'isoenzymes (CYP3A4, CYP2D6, '
            'CYP2C19, etc.).',
      ),
    ],
  ),
  _Theme(
    label: 'Santé publique',
    blurb: 'Épidémiologie, prévention, systèmes de soins',
    color: Color(0xFF455A64),
    icon: Icons.public_rounded,
    lessonTitles: [
      'Chaîne épidémiologique et mesure de fréquence',
      'Niveaux de prévention et vaccination',
      'Système de santé camerounais et couverture universelle',
    ],
    theoryBank: [
      'L\'incidence mesure le nombre de nouveaux cas dans une '
          'population donnée pendant une période. La prévalence '
          'mesure les cas existants à un instant. Exemple : '
          'au Cameroun, la prévalence du VIH est d\'environ '
          '3,0 % chez les 15-49 ans ; l\'incidence annuelle '
          'avoisine 100 000 nouvelles infections.',
      'La chaîne épidémiologique comprend six maillons : agent, '
          'réservoir, porte d\'entrée, mode de transmission, '
          'hôte sensible, porte de sortie. Casser un maillon '
          'suffit à interrompre l\'épidémie — principe de base '
          'des mesures barrières.',
      'Trois niveaux de prévention : primaire (éviter la '
          'maladie : vaccination, hygiène), secondaire '
          '(dépistage précoce) et tertiaire (réduire les '
          'complications et la réinsertion).',
      'Le Programme Élargi de Vaccination (PEV), coordonné au '
          'Cameroun par le MINSAINTÉ avec l\'OMS et l\'UNICEF, '
          'couvre BCG, DTC-HepB-Hib, PCV13, rougeole-rubéole, '
          'rotavirus et polio. La couverture vaccinale nationale '
          'dépasse 85 % pour le Penta 3.',
      'Le système de santé camerounais est pyramidal : '
          'Fondation (FOSA, district), intermédiaire '
          '(Hôpital de Division), régional (Hôpital Régional), '
          'central (HOPITAL Central Yaoundé, HOGNARO Douala). '
          'La carte sanitaire impose un ratio de 1 médecin '
          'pour 5 000 habitants.',
      'Le paludisme représente 30 % des consultations et 20 % '
          'des décès hospitaliers au Cameroun. La lutte passe '
          'par les moustiquaires imprégnées, le traitement '
          'préventif intermittent chez la femme enceinte et '
          'l\'accès au diagnostic par TDR.',
    ],
    example: _ExamplePack(
      titles: [
        'Calcul d\'incidence et prévalence',
        'Stratégie PRETTI chez la femme enceinte',
        'Couverture vaccinale et immortalité infantile',
      ],
      bodies: [
        'Sur une population de 100 000 personnes suivies 5 ans, '
            '450 nouveaux cas de diabète sont détectés. '
            'Incidence = 450/(100 000 × 5) = 0,9 ‰/an. Si '
            '1 800 personnes vivent avec le diabète à la fin '
            'de la période, prévalence = 1,8 %.',
        'Au Nord-Cameroun, les femmes enceintes reçoivent 3 '
            'doses de SP (sulfadoxine-pyriméthamine) à chaque '
            'consultation prénatale après le premier trimestre. '
            'Résultat : réduction de 40 % du paludisme '
            'congenital.',
        'Un pays dont la couverture Penta 3 passe de 60 % à '
            '90 % observe en général une baisse de 25 % de la '
            'mortalité des moins de 5 ans, d\'après les '
            'données OMS.',
      ],
      codes: [null, null, null],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt: 'La prévalence d\'une maladie correspond à :',
        options: const [
          ExerciseOption(
            id: 'a',
            text: 'Tous les cas existants à un instant donné',
            correct: true,
          ),
          ExerciseOption(
            id: 'b',
            text:
                'Les nouveaux cas sur '
                'une période',
          ),
          ExerciseOption(id: 'c', text: 'Les décès annuels'),
          ExerciseOption(
            id: 'd',
            text:
                'Le nombre de '
                'hospitalisations',
          ),
        ],
        explanation:
            'Prévalence = cas existants / population. '
            'Incidence = nouveaux cas / population-temps.',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt: 'La vaccination est une prévention secondaire.',
        expectedAnswer: 'Faux',
        explanation:
            'Faux — la vaccination est une prévention '
            'PRIMAIRE : elle empêche la survenue de la maladie.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.ordering,
        prompt:
            'Niveaux de prise en charge au Cameroun, du '
            'plus proche au plus spécialisé :',
        orderItems: const [
          'FOSA / Formation sanitaire',
          'Hôpital de District',
          'Hôpital de Division',
          'Hôpital Régional',
          'Hôpital Central / Gynéco-Obstétrique',
        ],
        explanation:
            'La pyramide sanitaire définit ces cinq '
            'niveaux d\'offre de soins.',
      ),
    ],
  ),
];

// ===========================================================================
//  Sciences fondamentales (maths, physique, chimie, bio, agro, env, stats)
// ===========================================================================
final _scienceThemes = <_Theme>[
  _Theme(
    label: 'Raisonnement scientifique',
    blurb: 'Hypothèse, expérimentation et modélisation',
    color: Color(0xFF3949AB),
    icon: Icons.science_rounded,
    lessonTitles: [
      'La démarche hypothético-déductive',
      'Modélisation mathématique d\'un phénomène',
      'Incertitude, erreurs et chiffres significatifs',
      'Expérimentation et reproductibilité',
      'Du concept à la loi scientifique',
    ],
    theoryBank: [
      'La méthode scientifique commence par une observation, suivie '
          'd\'une question, d\'une hypothèse testable, puis d\'une '
          'expérience contrôlée. Si le résultat contredit l\'hypothèse, '
          'on la révise. C\'est le cycle de Popper : falsifiabilité.',
      'Modéliser, c\'est traduire un phénomène physique, chimique ou '
          'biologique en équations. Le modèle n\'est jamais la réalité : '
          'il en est une approximation volontairement simplifiée. '
          'Un bon modèle prédit avec une erreur inférieure à la '
          'précision des mesures disponibles.',
      'Le chiffre significatif indique la précision réelle d\'une '
          'mesure. Au Cameroun, les étudiants de L1 Sciences '
          'perdent des points à l\'examen en écrivant '
          '"9,816678 m/s²" au lieu de "9,82 m/s²" quand la '
          'balance utilisée ne précise que deux décimales.',
      'La reproductibilité est le socle de la science : toute '
          'expérience doit pouvoir être refaite par un tiers, dans '
          'les mêmes conditions, avec le même résultat. La crise '
          'de reproductibilité touche aussi bien la psychologie '
          'que la biologie moléculaire.',
      'Une loi scientifique énonce une relation invariante entre '
          'grandeurs mesurables (F = ma, PV = nRT). Elle se '
          'distingue d\'une théorie : la loi décrit QUOI, la '
          'théorie explique POURQUOI. La loi de la chute libre '
          'de Galilée est incluse dans la relativité générale '
          'd\'Einstein.',
      'L\'analyse dimensionnelle vérifie qu\'une équation est '
          'cohérente : les deux membres doivent avoir la même '
          'dimension. Si on obtient kg·m/s² = kg·m/s, l\'erreur '
          'est détectée avant même de calculer numériquement.',
      'En biologie et agronomie tropicale, les essais variétaux '
          'à l\'IRAD (Institut de Recherche Agricole pour le '
          'Développement) suivent un protocole de randomisation '
          'en blocs pour contrôler l\'hétérogénéité des sols.',
      'Les statistiques inférentielles permettent de conclure sur '
          'une population à partir d\'un échantillon. Le seuil '
          'p < 0,05 signifie qu\'il y a moins de 5 % de risque '
          'que le résultat observe soit dû au hasard seul.',
      'Le changement climatique redéfinit la recherche en '
          'agronomie au Cameroun : les cycles culturaux du '
          'caféier et du cacaoyer se déplacent, et les modèles '
          'prédictifs doivent intégrer des scénarios '
          'd\'élévation de +1,5 à +4 °C d\'ici 2100.',
      'Un protocole expérimental correct spécifie le groupe '
          'contrôle, le groupe traitement, la taille '
          'd\'échantillon, la randomisation et l\'aveugle. '
          'Toute déviation invalide la conclusion causale.',
    ],
    example: _ExamplePack(
      titles: [
        'Chute libre et analyse dimensionnelle',
        'Essai variétal à l\'IRAD',
        'Loi des gaz parfaits appliquée',
      ],
      bodies: [
        'v = g × t : dimension de v = L·T⁻¹ ; dimension de '
            'g × t = L·T⁻² × T = L·T⁻¹. Cohérent. Pour un objet '
            'lâché sans vitesse initiale depuis 45 m, '
            't = √(2h/g) ≈ 3,03 s.',
        '12 variétés de maïs, 3 blocs, 4 répétitions = 144 '
            'parcelles. Le dispositif en blocs aléatoires '
            'permet de soustraire la variabilité du sol '
            'à la variabilité génétique.',
        'Dans une bouteille de 2 L à 25 °C et 1 atm : '
            'n = PV/(RT) = 1 × 2 / (0,082 × 298) = 0,082 mol, '
            'soit ≈ 5 × 10²² molécules. L\'ordre de grandeur '
            'étonne toujours en TD.',
      ],
      codes: [
        'h = 45;\n'
            'g = 9,82;\n'
            't = sqrt(2 * h / g);  // ≈ 3,03 s',
        null,
        'P = 1; V = 2;\n'
            'R = 0,082; T = 298;\n'
            'n = P * V / (R * T);  // ≈ 0,082 mol',
      ],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt:
            'La falsifiabilité (Popper) signifie qu\'une théorie '
            'scientifique doit :',
        options: const [
          ExerciseOption(
            id: 'a',
            text:
                'Être prouvée vraie une '
                'fois pour toutes',
          ),
          ExerciseOption(
            id: 'b',
            text:
                'Être réfutable par au '
                'moins une observation',
            correct: true,
          ),
          ExerciseOption(id: 'c', text: 'Reposer sur l\'autorité'),
          ExerciseOption(id: 'd', text: 'Être simple à comprendre'),
        ],
        explanation:
            'Pour Popper, une théorie n\'est '
            'scientifique que si on peut concevoir une '
            'expérience qui la contredirait.',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt:
            'Un résultat statistiquement significatif (p < 0,05) '
            'prouve la causalité.',
        expectedAnswer: 'Faux',
        explanation:
            'Faux — p < 0,05 rejette l\'hypothèse nulle '
            '(pas d\'effet), mais la causalité exige un '
            'protocole expérimental adéquat, pas seulement '
            'une corrélation.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.fillBlank,
        prompt: 'La formule des gaz parfaits s\'écrit P ___ = nRT.',
        blankTemplate: 'P ___ = nRT',
        acceptedAnswers: const ['V', 'v'],
        expectedAnswer: 'V',
        explanation:
            'PV = nRT — P pression, V volume, n nombre '
            'de moles, R constante, T température en Kelvin.',
      ),
      Exercise(
        id: '$id-e4',
        type: ExerciseType.textInput,
        prompt:
            'Combien de chiffres significatifs dans '
            '"0,00450" ? (répondre par un nombre)',
        acceptedAnswers: const ['3'],
        expectedAnswer: '3',
        explanation:
            '0,00450 → trois chiffres significatifs : '
            '4, 5, et le 0 final qui traduit la précision.',
      ),
      Exercise(
        id: '$id-e5',
        type: ExerciseType.ordering,
        prompt: 'Ordre des étapes de la méthode scientifique :',
        orderItems: const [
          'Observation',
          'Question',
          'Hypothèse',
          'Expérimentation',
          'Conclusion / Révision',
        ],
        explanation:
            'Le cycle classique de la démarche '
            'scientifique, enseigné dès le lycée.',
      ),
    ],
  ),
  _Theme(
    label: 'Structures et réactions',
    blurb: 'Atomistique, liaison et transformation de la matière',
    color: Color(0xFF8E24AA),
    icon: Icons.blur_circular_rounded,
    lessonTitles: [
      'Organisation électronique de l\'atome',
      'Liaisons covalente, ionique, métallique',
      'Stœchiométrie et équilibre chimique',
      'Thermodynamique des réactions',
      'Cinétique et catalyse',
    ],
    theoryBank: [
      'La configuration électronique d\'un atome se remplit selon '
          'les règles de Klechkowsky : 1s, 2s, 2p, 3s, 3p, 4s, 3d… '
          'Le tableau périodique de Mendeleïev organise les '
          'éléments par numéro atomique croissant et groupe de '
          'valence similaire.',
      'Une liaison covalente partage des électrons (H₂O), une '
          'liaison ionique les transfère (NaCl), une liaison '
          'métallique les délocalise (Cu). La différence '
          'd\'électro-négativité de Pauling prédit le type : '
          '< 0,4 covalente, '
          '> 1,7 ionique.',
      'La loi de Lavoisier — « rien ne se perd, rien ne se '
          'crée, tout se transforme » — impose la conservation '
          'de la masse dans tout bilan chimique. Équilibrer une '
          'équation, c\'est respecter cette loi à l\'atome près.',
      'L\'enthalpie ΔH mesure la chaleur échangée à pression '
          'constante. ΔH < 0 → exothermique ; ΔH > 0 → '
          'endothermique. La loi de Hess permet de calculer '
          'un ΔH inaccessible par expérimentation directe.',
      'Un catalyseur abaisse l\'énergie d\'activation sans être '
          'consommé. Le pot d\'échappement catalytique '
          'transforme CO + NOx en CO₂ + N₂ sans que le '
          'platine soit usé : c\'est la catalyse '
          'hétérogène appliquée.',
      'La constante d\'équilibre Kc relie les concentrations '
          'des produits et réactifs à l\'équilibre. K >> 1 : '
          'réaction quasi-totale ; K << 1 : réaction '
          'n\'atteint presque pas l\'équilibre.',
      'Le pH = -log[H₃O⁺] mesure l\'acidité. Une eau de '
          'rivière camerounaise en saison sèche peut descendre '
          'à pH 5,5 (acidification par la matière organique '
          'en décomposition), ce qui impacte la faune '
          'aquatique.',
      'En cinétique chimique, la loi de vitesse v = k[A]ⁿ[B]ᵐ '
          's\'obtient expérimentalement (jamais par lecture de '
          'l\'équation). L\'ordre partiel n\'est déterminé '
          'par la méthode des vitesses initiales.',
    ],
    example: _ExamplePack(
      titles: [
        'Équilibrage CH₄ + O₂ → CO₂ + H₂O',
        'Calcul de pH d\'un acide faible',
        'Catalyse enzymatique de l\'amylase',
      ],
      bodies: [
        'CH₄ + 2O₂ → CO₂ + 2H₂O : on vérifie C(1=1), '
            'H(4=2×2), O(4=2+2). La combustion du méthane est '
            'très exothermique (ΔH = -890 kJ/mol).',
        'Acide acétique 0,1 M avec Ka = 1,8 × 10⁻⁵ : '
            '[H₃O⁺] = √(Ka × C₀) = √(1,8 × 10⁻⁶) = 1,34 × 10⁻³. '
            'pH = 2,87. Le vinaigre de ménage typique de '
            'Douala.',
        'L\'amylase salivaire hydrolyse l\'amidon en maltose : '
            'un exemple de catalyse enzymaque spécifique à '
            '37 °C. La mastication des bâtons de manioc '
            'déjà sucrée grâce à cette enzyme.',
      ],
      codes: [
        'n(CH4) = n(O2)/2\n'
            'm(CH4) = n × M = 0,25 × 16 = 4 g',
        '[H3O+] = sqrt(Ka * C0)\n'
            'pH = -log([H3O+])',
        null,
      ],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt:
            'La différence d\'électroénégativité entre deux '
            'atomes de 2,1 indique une liaison :',
        options: const [
          ExerciseOption(id: 'a', text: 'Covalente pure'),
          ExerciseOption(id: 'b', text: 'Ionique', correct: true),
          ExerciseOption(id: 'c', text: 'Métallique'),
          ExerciseOption(id: 'd', text: 'Van der Waals'),
        ],
        explanation:
            'ΔEN > 1,7 → transfert d\'électrons → '
            'liaison ionique (NaCl par ex.).',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt:
            'Un catalyseur est consommé par la réaction '
            'qu\'il accélère.',
        expectedAnswer: 'Faux',
        explanation:
            'Faux — un catalyseur abaisse Ea sans être '
            'détruit ; il régénère à la fin de chaque cycle '
            'catalytique.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.fillBlank,
        prompt:
            'La loi de ___ impose la conservation de la '
            'masse dans une réaction chimique.',
        blankTemplate: 'Loi de ___ : rien ne se perd',
        expectedAnswer: 'Lavoisier',
        acceptedAnswers: const ['Lavoisier', 'lavoisier'],
        explanation:
            'Antoine Lavoisier (1789) : '
            '"Rien ne se perd, rien ne se crée, tout se '
            'transforme.".',
      ),
      Exercise(
        id: '$id-e4',
        type: ExerciseType.textInput,
        prompt:
            'Quel est le pH d\'une solution à [H₃O⁺] = '
            '1 × 10⁻⁷ M ? (répondre en nombre)',
        acceptedAnswers: const ['7'],
        expectedAnswer: '7',
        explanation:
            'pH = -log(10⁻⁷) = 7 → neutre (eau pure à '
            '25 °C).',
      ),
      Exercise(
        id: '$id-e5',
        type: ExerciseType.qcm,
        prompt: 'ΔH < 0 pour une réaction signifie :',
        options: const [
          ExerciseOption(id: 'a', text: 'Exothermique', correct: true),
          ExerciseOption(id: 'b', text: 'Endothermique'),
          ExerciseOption(id: 'c', text: 'À l\'équilibre'),
          ExerciseOption(id: 'd', text: 'Spontanée à toute T'),
        ],
        explanation:
            'ΔH < 0 : le système libère de la chaleur '
            'vers le milieu extérieur.',
      ),
    ],
  ),
];

// ===========================================================================
//  Lettres, langues, sciences humaines et communication
// ===========================================================================
final _lettresThemes = <_Theme>[
  _Theme(
    label: 'Analyse textuelle et linguistique',
    blurb: 'Approcher un texte par ses structures profondes',
    color: Color(0xFFC2185B),
    icon: Icons.local_library_rounded,
    lessonTitles: [
      'Narratologie : qui parle, qui agit ?',
      'Champs lexicaux et registres',
      'Figures de style et argumentation',
      'Linguistique de corpus et variation',
      'Traduction et équivalence',
    ],
    theoryBank: [
      'La narratologie de Genette distingue l\'histoire (récit '
          'des événements) du récit (discours qui la rapporte). '
          'Le focalisateur interne voit à travers un '
          'personnage ; le focalisateur externe est un '
          'observateur neutre. Un roman comme “Les Pieds '
          'Cents” de Mongo-Mboussa joue sur ces positions.',
      'Un champ lexical est un ensemble de mots appartenant à '
          'la même sphère sémantique. Identifier le champ '
          'lexical dominant d\'un poème de Betendi Ndinga '
          'révèle sa thématique sous-jacente mieux que toute '
          'interprétation subjective.',
      'Les trois registres classiques — lyrique (émotion), '
          'épique (héroïque), didactique (enseigner) — se '
          'reconnaissent à la tonalité, la syntaxe et les '
          'figures privilégiées (apostrophe, hyperbole, '
          'périphrase).',
      'La variation diatopique (spatiale), diastratique '
          '(sociale) et diaphasique (registre de langue) '
          'structure le français parlé au Cameroun. Le '
          'camfrancais (français camerounais) est une '
          'variété linguistique à part entière, étudiée '
          'à l\'Université de '
          'Yaoundé I.',
      'La traduction est un choix, pas un dictionnaire. '
          'Nida oppose équivalence formelle (respecter la '
          'lettre) et équivalence dynamique (reproduire '
          'l\'effet sur le lecteur cible). Traduire un '
          'proverbe Maka en français suppose de créer une '
          'équivalence culturelle, pas lexicale.',
      'L\'analyse du discours (Maingueneau, Charaudeau) '
          'étudie le langage dans sa dimension sociale : '
          'qui parle, à qui, dans quel cadre institutionnel, '
          'avec quels enjeux de pouvoir.',
      'Une figure de style n\'est pas un ornement : elle '
          'produit du sens. Une métaphore (comparaison '
          'sans outil) condense un concept abstrait en '
          'image concrète. « Le temps est un voleur » fait '
          'plus qu\'un long paragraphe philosophique.',
      'En stylistique comparée, on met en parallèle deux '
          'textes pour faire ressortir leurs choix '
          'd\'écriture. Comparer un extrait de Cheikh '
          'Hamidou Kane („L\'Aventure ambiguë“) avec un '
          'extrait de Ferdinand Oyono („Le Vieux Nègre et '
          'la Médaille“) éclaire les stratégies narratives.',
    ],
    example: _ExamplePack(
      titles: [
        'Focalisation dans “L\'Aventure ambiguë”',
        'Analyse d\'un champ lexical',
        'Traduire un proverbe Duala',
      ],
      bodies: [
        'Kane alterne focalisation interne (Diga, le héros '
            'wolof) et externe (le regard occidental). Cette '
            'duplicité produit l\'ambiguïté du titre : le '
            'lecteur ne sait plus qui “aventure” et qui '
            'est “ambigu”.',
        'Dans „Une vie de boy“ de Oyono, le champ lexical '
            'de la lumière occupe 18 occurrences dans le '
            'chapitre 3 : lampe, lueur, flambeau, soleil, '
            'aurore… Thème : l\'aspiration du héros à '
            'échapper à l\'obscurité coloniale.',
        '« Duonda ngombe, e jua ka ngombe » (Duala) → '
            'litéreralement “On attache la vache, on n\'attache '
            'pas le ventre du couteau”. Sens : la propriété '
            'est sacrée. Traduction dynamique : “La propriété '
            'd\'autrui est inviolable.”',
      ],
      codes: [null, null, null],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt: 'La narratologie est l\'étude :',
        options: const [
          ExerciseOption(
            id: 'a',
            text: 'Des structures du récit',
            correct: true,
          ),
          ExerciseOption(id: 'b', text: 'De la phonétique'),
          ExerciseOption(id: 'c', text: 'Des dialectes'),
          ExerciseOption(id: 'd', text: 'De la versification'),
        ],
        explanation:
            'Genette (1972) : ordre, durée, fréquence, '
            'voix, mode… sont les cinq catégories du récit.',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt: 'Le français camerounais n\'est qu\'un argot.',
        expectedAnswer: 'Faux',
        explanation:
            'Faux — c\'est une variété linguistique à '
            'part entière, avec sa phonologie, sa syntaxe '
            'et son lexique propre, étudiée '
            'académiquement.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.textInput,
        prompt:
            'Qui a proposé la notion d\'équivalence dynamique '
            'en traductologie ?',
        acceptedAnswers: const ['Nida', 'Eugene Nida', 'nida'],
        expectedAnswer: 'Nida',
        explanation:
            'Eugene Nida (1964) – Towards a Science '
            'of Translating.',
      ),
      Exercise(
        id: '$id-e4',
        type: ExerciseType.qcm,
        prompt: '“Le temps est un voleur” est un exemple de :',
        options: const [
          ExerciseOption(id: 'a', text: 'Comparaison'),
          ExerciseOption(id: 'b', text: 'Métaphore', correct: true),
          ExerciseOption(id: 'c', text: 'Métonymie'),
          ExerciseOption(id: 'd', text: 'Hypallage'),
        ],
        explanation:
            'Métaphore : comparaison sans outil de '
            'comparaison (“comme”, “tel”, “ainsi”...).',
      ),
      Exercise(
        id: '$id-e5',
        type: ExerciseType.ordering,
        prompt: 'Structure d\'un exposé de dissertation littéraire :',
        orderItems: const [
          'Introduction et problématique',
          'Annonce du plan',
          'Développement en 2 ou 3 parties',
          'Conclusion et ouverture',
        ],
        explanation:
            'Le plan est toujours justifié par la '
            'problématique, jamais arbitraire.',
      ),
    ],
  ),
  _Theme(
    label: 'Communication et société',
    blurb: 'Médias, opinion publique et enjeux numériques',
    color: Color(0xFFEF6C00),
    icon: Icons.campaign_rounded,
    lessonTitles: [
      'Modèles de la communication',
      'Média et opinion publique au Cameroun',
      'Journalisme et déontologie',
      'Communication digitale et réseaux sociaux',
      'Analyse d\'audience et indicateurs',
    ],
    theoryBank: [
      'Le schéma linéaire de Shannon-Weaver (émetteur → '
          'message → récepteur) est complété par le modèle '
          'circulaire de Jakobson avec sa fonction '
          'poétique et sa dimension pragmatique. En '
          'communication de masse, la rétroaction est '
          'partielle.',
      'La théorie du “gatekeeper” (Lewin, 1947) explique '
          'comment les médias sélectionnent l\'information. '
          'Au Cameroun, la CRTV et les radios '
          'régionales sont des '
          'passoirs influents sur l\'agenda setting.',
      'Le code de déontologie des journalistes camerounais '
          '(Syndicat national de la presse camerounaise - '
          'SNJC) exige vérification des sources, '
          'indépendance, respect de la vie privée et '
          'mention de l\'origine des informations.',
      'La communication digitale mesure le taux '
          'd\'engagement (likes, commentaires, partages) '
          'par rapport à la portée. Sur Facebook, '
          'un ER > 3 % est un bon signal au Cameroun, '
          'où les audiences sont très jeunes.',
      'Le modèle d\'agenda setting (McCombs & Shaw, 1972) '
          'montre que les médias ne disent pas quoi penser, '
          'mais à quoi penser. La fréquence de traitement '
          'd\'un sujet corrèle avec son importance perçue '
          'par le public.',
      'La sémiotique visuelle (Barthes, “Rhétorique de '
          'l\'image”) distingue le niveau dénotatif (ce '
          'qui est) du connotatif (ce que ça veut dire '
          'culturellement). Une photo de marché à '
          'Douala n\'évoque pas la même chose qu\'une '
          'photo de marché à Paris.',
      'Les “fake news” exploitent le biais de confirmation '
          '(favoriser les infos qui confortent nos '
          'croyances). Le fact-checking (Africa Check, '
          'CamerounCheck) est devenu un contre-pouvoir '
          'médias et contre-pouvoir '
          'médiatique.',
      'Le plan de communication stratégique suit 5 phases : '
          'audit → objectifs → public → canaux → évaluation. '
          'Sans évaluation mesurable, la communication '
          'dépense sans preuve d\'efficacité.',
    ],
    example: _ExamplePack(
      titles: [
        'Analyse d\'un titre de presse',
        'Plan de communication pour une ONG locale',
        'Métrique engagement Facebook Cameroun',
      ],
      bodies: [
        '“Le camerounais n\'est pas un peuple travailleur” '
            '(titre choc) est une généralisation abusive. '
            'Déconstruction : qui le dit ? Quelle source ? '
            'Quel angle mort ?',
        'ONG “Eau pour Tous” : objectif = +30 % de dons en '
            '6 mois. Cible = cadres urbains 25-45 ans. '
            'Canaux = Facebook + WhatsApp + événements. '
            'KPI = taux de conversion site web, coût '
            'par don.',
        'Page “Camfoot” : portée organique 450 000 / mois, '
            'engagement 6,3 % (supérieur à la moyenne '
            'camerounaise de 3,5 %). Le format vidéo '
            'dépasse l\'image fixe de 40 %.',
      ],
      codes: [null, null, null],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt: 'L\'agenda setting désigne :',
        options: const [
          ExerciseOption(
            id: 'a',
            text:
                'Le fait que les médias '
                'influencent quoi penser',
          ),
          ExerciseOption(
            id: 'b',
            text:
                'Le fait que les médias '
                'influencent à quoi penser',
            correct: true,
          ),
          ExerciseOption(id: 'c', text: 'La ligne éditoriale'),
          ExerciseOption(id: 'd', text: 'Le cadrage juridique'),
        ],
        explanation:
            'McCombs & Shaw : les médias disent '
            'à quoi penser (saillance), pas quoi penser '
            '(opinion).',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt:
            'Le taux d\'engagement mesure le nombre '
            'd\'abonnés.',
        expectedAnswer: 'Faux',
        explanation:
            'Faux — l\'engagement = réactions / '
            'portée × 100 %. Le nombre d\'abonnés mesure '
            'la taille de l\'audience, pas son interaction.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.fillBlank,
        prompt:
            'Selon la théorie du ___, les médias '
            'sélectionnent l\'information.',
        blankTemplate: 'théorie du ___ = sélection info',
        expectedAnswer: 'gatekeeper',
        acceptedAnswers: const ['gatekeeper', 'Gatekeeper'],
        explanation:
            'Kurt Lewin (1947) : le gatekeeper '
            'contrôle l\'accès à l\'information médiatique.',
      ),
      Exercise(
        id: '$id-e4',
        type: ExerciseType.qcm,
        prompt: 'Le biais de confirmation en communication digitale :',
        options: const [
          ExerciseOption(id: 'a', text: 'Vérifier chaque source'),
          ExerciseOption(
            id: 'b',
            text:
                'Favoriser les infos qui '
                'confortent nos croyances',
            correct: true,
          ),
          ExerciseOption(id: 'c', text: 'Interdire le partage'),
          ExerciseOption(id: 'd', text: 'Fact-checking obligatoire'),
        ],
        explanation:
            'Le biais de confirmation explique la '
            'propagation rapide des fake news : on partage '
            'ce qui nous rassure.',
      ),
      Exercise(
        id: '$id-e5',
        type: ExerciseType.ordering,
        prompt: 'Phases d\'un plan de communication :',
        orderItems: const [
          'Audit de la situation',
          'Définition des objectifs',
          'Identification des cibles',
          'Choix des canaux',
          'Évaluation des résultats',
        ],
        explanation:
            'C\'est la trame du modèle SMART appliqué '
            'à la communication stratégique.',
      ),
    ],
  ),
];

// ===========================================================================
//  Générique — pour les disciplines hors info/droit/éco/santé
// ===========================================================================
final _genericThemes = <_Theme>[
  _Theme(
    label: 'Cadrage et vocabulaire',
    blurb: 'Définir le terrain de jeu et les mots justes',
    color: Color(0xFF3F51B5),
    icon: Icons.menu_book_rounded,
    lessonTitles: [
      'Objet et périmètre de la discipline',
      'Vocabulaire technique essentiel',
      'Positionnement historique',
    ],
    theoryBank: [
      'Toute discipline se définit par un objet d\'étude, une '
          'méthode propre et des questions ouvertes. Comprendre '
          'un cours commence par identifier ces trois piliers : '
          'qu\'étudie-t-on exactement, comment, et qu\'est-ce '
          'qu\'on ne sait pas encore.',
      'Le vocabulaire technique n\'est pas un ornement : il '
          'condense des siècles de recherche derrière un mot. '
          'Un étudiant qui maîtrise le lexique peut lire plus '
          'vite, comprendre plus fin et se tromper moins.',
      'L\'histoire d\'une discipline éclaire ses débats '
          'actuels. Connaître les ruptures épistémologiques '
          '(Kuhn, Bachelard) permet de saisir pourquoi '
          'certaines questions polémiques divisent encore la '
          'communauté savante.',
      'Une fiche de lecture efficace se structure en quatre '
          'blocs : question posée par l\'auteur, thèse défendue, '
          'méthode employée, limites identifiées. C\'est le '
          'squelette de tout travail universitaire sérieux.',
      'Le travail intellectuel se nourrit de références. '
          'Apprendre à citer correctement (normes APA, ISO 690) '
          'n\'est pas une contrainte : c\'est une façon de '
          'situer sa pensée dans un dialogue collectif.',
      'Un cours n\'est jamais clos : à chaque génération '
          'd\'étudiants, ses questions se déplacent. Les '
          'enseignants-chercheurs de l\'Université de Yaoundé I '
          'et de Dschang contribuent chaque année à faire '
          'avancer les frontières de leur champ.',
    ],
    example: _ExamplePack(
      titles: [
        'Délimiter un objet de recherche',
        'Lire une fiche technique',
        'Historiser un concept',
      ],
      bodies: [
        'Avant d\'écrire un mémoire de licence, l\'étudiant '
            'dégage une question précise : non pas « les '
            'réseaux sociaux » mais « l\'influence de TikTok '
            'sur les représentations linguistiques des jeunes '
            'anglophones du Nd ». La précision fait la '
            'faisabilité.',
        'Un article scientifique se lit d\'abord par les '
            'extrémités : résumé, mots-clés, conclusion. Puis '
            'on attaque la méthode, enfin les résultats. Cette '
            'lecture stratégique permet de trier 30 articles '
            'en une soirée.',
        'Le concept de « développement durable » naît du '
            'rapport Brundtland (1987), se diffuse au sommet '
            'de Rio (1992) puis se transforme en ODD à '
            'l\'ONU (2015). Tracer cette généalogie aide à '
            'comprendre les débats actuels.',
      ],
      codes: [null, null, null],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt: 'Une question de recherche efficace doit être :',
        options: const [
          ExerciseOption(
            id: 'a',
            text:
                'Précise, faisable et ancrée dans un '
                'débat existant',
            correct: true,
          ),
          ExerciseOption(id: 'b', text: 'Large et générale'),
          ExerciseOption(
            id: 'c',
            text:
                'Personnelle et '
                'subjective',
          ),
          ExerciseOption(
            id: 'd',
            text:
                'Sans lien avec la '
                'bibliographie',
          ),
        ],
        explanation:
            'La qualité d\'un mémoire tient d\'abord '
            'à la pertinence et à la faisabilité de sa '
            'question.',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt:
            'Les normes APA concernent uniquement la '
            'bibliographie.',
        expectedAnswer: 'Faux',
        explanation:
            'Faux — les APA régissent citation, '
            'structure du document, titres, tableaux et '
            'nombreux éléments de style.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.textInput,
        prompt:
            'En quelle année le rapport Brundtland '
            '« Notre avenir à tous » a-t-il été publié ?',
        acceptedAnswers: const ['1987'],
        expectedAnswer: '1987',
        explanation:
            '1987 — c\'est le texte fondateur de la '
            'définition moderne du développement durable.',
      ),
    ],
  ),
  _Theme(
    label: 'Méthodes et outils',
    blurb: 'Démarches scientifiques et outils de terrain',
    color: Color(0xFF00897B),
    icon: Icons.rule_rounded,
    lessonTitles: [
      'Méthode déductive, inductive, hypothético-déductive',
      'Enquêtes quantitatives et qualitatives',
      'Outils numériques et collecte sur le terrain',
    ],
    theoryBank: [
      'Le raisonnement déductif part d\'une règle générale pour '
          'conclure sur un cas particulier (syllogisme). Le '
          'raisonnement inductif observe des cas particuliers '
          'pour dégager une règle générale. L\'approche '
          'hypothético-déductive combine les deux : on pose une '
          'hypothèse, on déduit des prédictions, on les teste.',
      'Une enquête quantitative mesure des fréquences et des '
          'corélations sur un grand échantillon représentatif. '
          'Une enquête qualitative explore les logiques '
          'd\'acteurs sur un échantillon petit mais riche. '
          'Elles se complètent souvent : le «combien» et le '
          '«pourquoi».',
      'La construction d\'un questionnaire suppose de définir '
          'les variables, de reformuler chaque item en langage '
          'accessible et de tester en pré-enquête. Un item '
          'ambigu biaise toute l\'analyse.',
      'Les entretiens semi-directifs laissent une marge de '
          'liberté : on suit un guide mais on relance sur ce '
          'que dit le terrain. La retranscription est une '
          'étape coûteuse — environ six heures pour une heure '
          'd\'enregistrement.',
      'L\'analyse statistique descriptive (moyenne, médiane, '
          'écart-type, fréquences) précède toujours '
          'l\'analyse inférentielle (tests de khi-deux, '
          'ANOVA, régression). On ne teste jamais une hypothèse '
          'sans avoir caractérisé ses données.',
      'Au Cameroun, l\'INS (Institut National de la Statistique) '
          'publie les enquêtes ECA-MFI et RGPH, sources de '
          'référence pour tout mémoire mobilisant des données '
          'nationales.',
    ],
    example: _ExamplePack(
      titles: [
        'Hypothèse de travail en sociologie',
        'Guide d\'entretien sur la commercialisation du cacao',
        'Tableau descriptif dans Excel / R',
      ],
      bodies: [
        'Hypothèse : « La digitalisation des paiements réduit '
            'les délais de recouvrement des petits commerçants '
            'de Douala. » On la teste en comparant deux panels '
            'équipés/non équipés en Mobile Money sur une '
            'période de 6 mois.',
        'Avec 12 cacao-culteurs du Sud-Ouest, un guide de 8 '
            'questions ouvertes explore : prix perçus, '
            'intermédiaires, stockage, confiance dans les '
            'filières certifiées.',
        'Une moyenne de 4,2 ans d\'ancienneté, un écart-type '
            'de 1,8, une médiane de 4 : la population est '
            'relativement homogène. Ce tableau descriptif doit '
            'figurer AVANT tout test statistique.',
      ],
      codes: [null, null, null],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt:
            'Le raisonnement qui part d\'observations '
            'particulières pour dégager une loi générale est :',
        options: const [
          ExerciseOption(id: 'a', text: 'Déductif'),
          ExerciseOption(id: 'b', text: 'Inductif', correct: true),
          ExerciseOption(id: 'c', text: 'Analogique'),
          ExerciseOption(id: 'd', text: 'Abductif'),
        ],
        explanation:
            'Induction : passage du particulier au '
            'général, principe de la démarche empiriste.',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt:
            'Une enquête qualitative vise à produire des '
            'statistiques généralisables.',
        expectedAnswer: 'Faux',
        explanation:
            'Faux — elle vise la compréhension en '
            'profondeur, pas la généralisation statistique.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.fillBlank,
        prompt:
            'Le test qui compare des fréquences observées '
            'et attendues s\'appelle le test du ___.',
        blankTemplate: 'test de comparaison de fréquences = ___',
        expectedAnswer: 'khi-deux',
        acceptedAnswers: const ['khi-deux', 'chi-carré', 'chi2', 'khi deux'],
        explanation:
            'Le khi-deux compare les distributions '
            'observées aux théoriques dans les tableaux de '
            'contingence.',
      ),
    ],
  ),
  _Theme(
    label: 'Synthèse et communication',
    blurb: 'Structurer un propos et le transmettre',
    color: Color(0xFF43A047),
    icon: Icons.fact_check_rounded,
    lessonTitles: [
      'Écrire un plan qui tient debout',
      'Exposer oralement 15 minutes',
      'Produire une soutenance qui convainc',
    ],
    theoryBank: [
      'Un plan en trois parties n\'est pas une coquetterie : '
          'il correspond au mouvement classique thèse / '
          'antithèse / synthèse, ou diagnostic / analyse / '
          'recommandation. Chaque partie doit se justifier par '
          'une question qui découle de la précédente.',
      'La règle des 3 : on retient trois idées, pas dix. Une '
          'introduction qui annonce clairement ces trois '
          'idées, un développement qui les traite '
          'séquentiellement, une conclusion qui les relie à '
          'la problématique.',
      'À l\'oral, chaque slide porte UNE idée. Le texte visible '
          'doit être minimal : c\'est le support du discours, '
          'pas une transcription. Le jury regardera l\'orateur '
          '80 % du temps, la slide 20 %',
      'La soutenance se joue sur trois critères : clarté du '
          'fil conducteur, maîtrise du contenu (réponses aux '
          'questions), et posture (voix, regard, gestuelle). '
          'Une préparation sérieuse passe par trois '
          'répétitions complètes, dont une enregistrée.',
      'Le feedback d\'un jury n\'est pas une sanction : c\'est '
          'une cartographie des points à renforcer. Prendre '
          'des notes pendant les questions, reformuler et '
          'remercier fait partie du savoir-vivre académique.',
      'Écrire pour être compris suppose de connaître son '
          'lecteur. Un mémoire s\'adresse au jury ; une note '
          'de synthèse s\'adresse à un décideur ; un article '
          'de vulgarisation au grand public. Même travail, '
          'trois contrats de lecture.',
    ],
    example: _ExamplePack(
      titles: [
        'Plan en entonnoir',
        'Soutenance minute par minute',
        'Note de synthèse pour un décideur',
      ],
      bodies: [
        'Problématique → contexte → état de l\'art → hypothèse '
            '→ méthode → résultats → discussion → recommandations. '
            'Un mémoire de L3 s\'écrit toujours dans cet ordre, '
            'en entonnoir : large au départ, resserré à la fin.',
        '15 minutes de soutenance : 1 min d\'accroche, 2 min '
            'de problématique, 3 min de méthode, 6 min de '
            'résultats, 2 min de discussion, 1 min de '
            'conclusion. Répéter avec un chronomètre est '
            'indispensable.',
        'Pour un directeur administratif, une note de synthèse '
            'ne dépasse pas une page : trois constats, trois '
            'risques, trois recommandations chiffrées. C\'est '
            'la règle du 3 × 3.',
      ],
      codes: [null, null, null],
    ),
    exercises: (id) => [
      Exercise(
        id: '$id-e1',
        type: ExerciseType.qcm,
        prompt:
            'Combien de parties principales une '
            'démonstration académique classique compte-t-elle ?',
        options: const [
          ExerciseOption(id: 'a', text: '1'),
          ExerciseOption(id: 'b', text: '2'),
          ExerciseOption(id: 'c', text: '3', correct: true),
          ExerciseOption(id: 'd', text: '6'),
        ],
        explanation:
            'Trois parties : thèse / antithèse / '
            'synthèse, ou diagnostic / analyse / '
            'recommandation.',
      ),
      Exercise(
        id: '$id-e2',
        type: ExerciseType.trueFalse,
        prompt:
            'En soutenance, il faut lire ses notes sans '
            'regarder le jury.',
        expectedAnswer: 'Faux',
        explanation:
            'Faux — le contact visuel fait partie de '
            'la posture. On lit rarement plus de 10 % du '
            'temps.',
      ),
      Exercise(
        id: '$id-e3',
        type: ExerciseType.ordering,
        prompt: 'Structure classique d\'un mémoire :',
        orderItems: const [
          'Introduction et problématique',
          'Revue de littérature',
          'Méthodologie',
          'Résultats',
          'Discussion et conclusion',
        ],
        explanation:
            'L\'ordre canonique du mémoire scientifique, '
            'validé par toutes les universités.',
      ),
    ],
  ),
];

String _roman(int n) {
  const map = <int, String>{
    1: 'I',
    2: 'II',
    3: 'III',
    4: 'IV',
    5: 'V',
    6: 'VI',
    7: 'VII',
    8: 'VIII',
    9: 'IX',
    10: 'X',
    11: 'XI',
    12: 'XII',
  };
  return map[n] ?? '$n';
}
