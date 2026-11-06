import 'package:flutter/material.dart';

import '../models/learning_models.dart';

/// Cours phares Educoach — contenu entièrement rédigé à la main.
///
/// Chaque cours "riche" possède plusieurs semestres, unités, leçons avec
/// théorie, exemples concrets et exercices variés. Les corrections
/// s'affichent après la réponse avec l'explication pédagogique.
final Map<String, List<Semester> Function(String)> richCourseBuilders = {
  'INF301': _buildInf301,
  'INF102': _buildInf102,
  'DRP201': _buildDrp201,
  'ECO101': _buildEco101,
  'MED201': _buildMed201,
  'INF330': _buildInf330,
};

// ==================================================================
//  INF301 — Algorithmique avancée (L3 Informatique)
// ==================================================================
List<Semester> _buildInf301(String code) {
  final s1 = _sem(
    code: code,
    index: 1,
    units: [
      _unit(
        code: code,
        semIndex: 1,
        unitIndex: 1,
        title: 'Diviser pour régner',
        subtitle: 'Décomposer un problème en sous-problèmes indépendants',
        color: const Color(0xFF3F51B5),
        icon: Icons.call_split_rounded,
        lessons: [
          _lesson(
            code: code,
            sem: 1,
            unit: 1,
            lesson: 1,
            title: 'Le principe de récurrence',
            subtitle: 'Fonction qui s\'appelle elle-même et cas de base',
            icon: Icons.loop_rounded,
            theory: const [
              'Diviser pour régner, c\'est découper un gros problème en '
                  'plusieurs petits problèmes du même type, les résoudre '
                  'indépendamment, puis recomposer la réponse. C\'est la '
                  'stratégie derrière le tri fusion, la recherche binaire '
                  'ou encore l\'algorithme d\'Euclide étendu.',
              'Une fonction récursive comporte toujours deux éléments : un '
                  'cas de base (le plus petit input, traité directement) '
                  'et un cas récursif (qui réduit la taille du problème '
                  'avant de se rappeler elle-même). Sans cas de base, la '
                  'pile des appels déborde : c\'est le stack overflow.',
              'Au Cameroun, ce schéma apparaît dans beaucoup de situations '
                  'quotidiennes : organiser un déménagement en sous-tâches '
                  'par pièce, diviser un champ en parcelles puis chaque '
                  'parcelle en sillons, etc. L\'algorithmique formalise '
                  'cette habitude.',
            ],
            examples: const [
              Example(
                title: 'Factorielle récursive',
                body:
                    'n! = n × (n-1)! avec 0! = 1. Le cas de base est '
                    'atteint dès que n == 0 ; chaque appel réduit n de 1.',
                code:
                    'factoriel(n):\n'
                    '    si n == 0 alors retourner 1\n'
                    '    sinon retourner n * factoriel(n - 1)',
                footnote:
                    'Complexité : O(n) appels, O(n) de profondeur de pile.',
              ),
              Example(
                title: 'Somme des éléments d\'un tableau',
                body:
                    'On sépare le tableau en deux moitiés, on somme chaque '
                    'moitié récursivement, puis on additionne les deux '
                    'résultats. Même résultat qu\'une boucle, mais '
                    'parallélisable.',
                code:
                    'somme(T, g, d):\n'
                    '    si g == d alors retourner T[g]\n'
                    '    m ← (g + d) / 2\n'
                    '    retourner somme(T, g, m) + somme(T, m+1, d)',
              ),
            ],
            exercises: [
              Exercise(
                id: '$code-s1u1l1-e1',
                type: ExerciseType.qcm,
                prompt:
                    'Que se passe-t-il si une fonction récursive n\'a '
                    'pas de cas de base ?',
                options: const [
                  ExerciseOption(
                    id: 'a',
                    text:
                        'Elle boucle à l\'infini '
                        'et provoque un débordement de pile',
                    correct: true,
                  ),
                  ExerciseOption(id: 'b', text: 'Elle retourne 0'),
                  ExerciseOption(
                    id: 'c',
                    text:
                        'Le compilateur la remplace '
                        'par une boucle for',
                  ),
                  ExerciseOption(id: 'd', text: 'Rien, c\'est normal'),
                ],
                explanation:
                    'Sans cas de base, la condition d\'arrêt '
                    'n\'est jamais atteinte : chaque appel empile une '
                    'nouvelle frame jusqu\'au StackOverflowError.',
              ),
              Exercise(
                id: '$code-s1u1l1-e2',
                type: ExerciseType.trueFalse,
                prompt:
                    'Tout algorithme récursif peut être réécrit de '
                    'façon itérative.',
                expectedAnswer: 'Vrai',
                explanation:
                    'Vrai — on peut simuler la pile avec une '
                    'structure de données explicite. La version itérative '
                    'est souvent plus efficace en mémoire.',
              ),
              Exercise(
                id: '$code-s1u1l1-e3',
                type: ExerciseType.ordering,
                prompt:
                    'Remets les étapes de factoriel(4) dans l\'ordre '
                    'd\'exécution :',
                orderItems: const [
                  'factoriel(4)',
                  'factoriel(3)',
                  'factoriel(2)',
                  'factoriel(1)',
                  'factoriel(0) → 1',
                  'retour 4 × 3 × 2 × 1 = 24',
                ],
                explanation:
                    'On descend jusqu\'au cas de base (0! = 1) '
                    'puis on remonte en multipliant les résultats.',
              ),
            ],
          ),
          _lesson(
            code: code,
            sem: 1,
            unit: 1,
            lesson: 2,
            title: 'Tri fusion (merge sort)',
            subtitle: 'Un diviser-pour-régner classique en O(n log n)',
            icon: Icons.merge_type_rounded,
            theory: const [
              'Le tri fusion coupe le tableau en deux, trie chaque moitié '
                  'récursivement, puis fusionne les deux moitiés triées en '
                  'un seul tableau trié. La fusion est linéaire : on '
                  'compare les têtes des deux moitiés et on place la plus '
                  'petite dans la sortie.',
              'Sa complexité est O(n log n) dans tous les cas (meilleur, '
                  'pire, moyen) ce qui est optimal pour un tri par '
                  'comparaison. En revanche, il utilise un tableau '
                  'auxiliaire de taille n — ce n\'est pas un tri en place.',
              'Sur un fichier de 1 million de notes d\'étudiants à '
                  'l\'Université de Douala, un quicksort empirique peut '
                  'tomber en O(n²) si les pivots sont mal choisis ; merge '
                  'sort reste garanti O(n log n), donc plus prévisible.',
            ],
            examples: const [
              Example(
                title: 'Fusion de [3, 7] et [1, 5, 9]',
                body:
                    'On parcourt les deux tableaux avec deux curseurs ; '
                    'à chaque étape on sort le plus petit des deux '
                    'éléments courants.',
                code:
                    '[3,7] [1,5,9]\n'
                    '→ 1 (min 3,1)\n'
                    '→ 3 (min 3,5)\n'
                    '→ 5 (min 7,5)\n'
                    '→ 7 (min 7,9)\n'
                    '→ 9 (restant)\n'
                    'résultat : [1,3,5,7,9]',
              ),
            ],
            exercises: [
              Exercise(
                id: '$code-s1u1l2-e1',
                type: ExerciseType.qcm,
                prompt:
                    'Quelle est la complexité dans le PIRE cas de '
                    'merge sort ?',
                options: const [
                  ExerciseOption(id: 'a', text: 'O(n)'),
                  ExerciseOption(id: 'b', text: 'O(n log n)', correct: true),
                  ExerciseOption(id: 'c', text: 'O(n²)'),
                  ExerciseOption(id: 'd', text: 'O(log n)'),
                ],
                explanation:
                    'Merge sort garantit O(n log n) : à chaque '
                    'niveau de l\'arbre de récursion on fusionne n '
                    'éléments, et l\'arbre a log n niveaux.',
              ),
              Exercise(
                id: '$code-s1u1l2-e2',
                type: ExerciseType.fillBlank,
                prompt:
                    'Complète la stratégie : « diviser, ___ , '
                    'combiner ».',
                blankTemplate: 'diviser, ___, combiner',
                acceptedAnswers: const ['régner', 'conquérir'],
                expectedAnswer: 'régner',
                explanation:
                    'Diviser pour régner : on divise, on « règne '
                    '» (résout chaque sous-problème), puis on combine les '
                    'solutions.',
              ),
            ],
          ),
          _lesson(
            code: code,
            sem: 1,
            unit: 1,
            lesson: 3,
            title: 'Recherche binaire',
            subtitle: 'Trouver en O(log n) dans un tableau trié',
            icon: Icons.search_rounded,
            theory: const [
              'La recherche binaire suppose le tableau TRIÉ. À chaque '
                  'étape on compare la cible au milieu : si égal on a '
                  'trouvé, sinon on élimine la moitié où la cible ne peut '
                  'pas être. Le nombre d\'éléments candidats est divisé '
                  'par deux à chaque itération.',
              'Sur un tableau d\'un million d\'entrées, il faut au plus '
                  '⌈log₂ 1 000 000⌉ = 20 comparaisons. C\'est la '
                  'différence entre chercher une page dans un livre trié '
                  'en ouvrant au milieu, ou tout lire ligne par ligne.',
            ],
            examples: const [
              Example(
                title: 'Chercher 13 dans [2, 5, 7, 11, 13, 17, 19, 23]',
                body:
                    'Milieu = indice 3 (valeur 11) → 13 > 11, on garde '
                    'la moitié droite [13, 17, 19, 23]. Milieu = 17 → 13 '
                    '< 17, on garde [13, 17]… puis [13] → trouvé.',
              ),
            ],
            exercises: [
              Exercise(
                id: '$code-s1u1l3-e1',
                type: ExerciseType.trueFalse,
                prompt:
                    'La recherche binaire fonctionne aussi sur un '
                    'tableau non trié.',
                expectedAnswer: 'Faux',
                explanation:
                    'Faux : la recherche binaire exige un tableau '
                    'trié, sinon l\'élimination d\'une moitié n\'est pas '
                    'justifiée.',
              ),
              Exercise(
                id: '$code-s1u1l3-e2',
                type: ExerciseType.qcm,
                prompt:
                    'Combien d\'étapes au pire pour trouver un élément '
                    'dans un tableau de 1024 entrées ?',
                options: const [
                  ExerciseOption(id: 'a', text: '10', correct: true),
                  ExerciseOption(id: 'b', text: '512'),
                  ExerciseOption(id: 'c', text: '1024'),
                  ExerciseOption(id: 'd', text: '32'),
                ],
                explanation:
                    'log₂(1024) = 10 : la taille est divisée par '
                    'deux à chaque étape.',
              ),
            ],
          ),
        ],
      ),
      _unit(
        code: code,
        semIndex: 1,
        unitIndex: 2,
        title: 'Algorithmes gloutons',
        subtitle: 'Faire le meilleur choix local à chaque étape',
        color: const Color(0xFF00897B),
        icon: Icons.park_rounded,
        lessons: [
          _lesson(
            code: code,
            sem: 1,
            unit: 2,
            lesson: 1,
            title: 'Rendu de monnaie (FCFA)',
            subtitle: 'Un glouton parfait grâce aux pièces canoniques',
            icon: Icons.payments_rounded,
            theory: const [
              'Le problème du rendu de monnaie : donner N francs CFA avec '
                  'le moins de pièces possible. Avec le système UEMCA '
                  '(1, 5, 10, 25, 50, 100, 500…) la stratégie gloutonne — '
                  'prendre la plus grande pièce qui tient — est optimale.',
              'Un algorithme est glouton quand à chaque étape il fait le '
                  'choix qui semble le meilleur sur le moment, sans '
                  'revenir en arrière. Ce n\'est PAS toujours optimal : '
                  'si les pièces valaient 1, 3, 4 et qu\'il faut rendre '
                  '6, le glouton donne 4+1+1 = 3 pièces alors que 3+3 = '
                  '2 pièces est optimal.',
            ],
            examples: const [
              Example(
                title: 'Rendre 1 375 FCFA',
                body:
                    '1×1000 → reste 375 ; 1×100 → 275 ; 2×100 ne tient '
                    'pas, 1×100 ; 3×100 ne tient pas, donc on passe à '
                    '10 → 3×100 = 300 ; reste 75 → 1×50 ; reste 25 → '
                    '1×25. Total : 5 pièces.',
              ),
            ],
            exercises: [
              Exercise(
                id: '$code-s1u2l1-e1',
                type: ExerciseType.qcm,
                prompt: 'Dans quel cas le glouton n\'est-il PAS optimal ?',
                options: const [
                  ExerciseOption(
                    id: 'a',
                    text: 'Pièces {1, 3, 4}, rendu de 6',
                    correct: true,
                  ),
                  ExerciseOption(
                    id: 'b',
                    text: 'Pièces {1, 5, 10, 25}, rendu de 30',
                  ),
                  ExerciseOption(id: 'c', text: 'Tri fusion'),
                  ExerciseOption(id: 'd', text: 'Recherche binaire'),
                ],
                explanation:
                    'Contre-exemple classique : glouton donne '
                    '4+1+1 = 3 pièces, optimum 3+3 = 2 pièces.',
              ),
            ],
          ),
        ],
      ),
    ],
  );

  final s2 = _sem(
    code: code,
    index: 2,
    units: [
      _unit(
        code: code,
        semIndex: 2,
        unitIndex: 1,
        title: 'Programmation dynamique',
        subtitle: 'Mémoriser les sous-problèmes pour éviter les recalculs',
        color: const Color(0xFFF4511E),
        icon: Icons.layers_rounded,
        lessons: [
          _lesson(
            code: code,
            sem: 2,
            unit: 1,
            lesson: 1,
            title: 'Fibonacci avec mémoïsation',
            subtitle: 'De O(2ⁿ) à O(n)',
            icon: Icons.functions_rounded,
            theory: const [
              'Le calcul naïf de Fibonacci refait sans arrêt les mêmes '
                  'appels : fib(n-2) est recalculé des dizaines de fois. '
                  'La programmation dynamique stocke chaque résultat dans '
                  'un tableau pour ne le calculer qu\'une seule fois.',
              'Deux implémentations : top-down (récursion + cache, dite '
                  'mémoïsation) ou bottom-up (boucle qui remplit le '
                  'tableau de 0 vers n). Les deux sont en O(n) de temps '
                  'et O(n) d\'espace ; la version bottom-up peut se '
                  'ramener à O(1) en ne gardant que deux variables.',
            ],
            examples: const [
              Example(
                title: 'Bottom-up',
                body:
                    'On itère de 0 à n en gardant uniquement les deux '
                    'dernières valeurs.',
                code:
                    'a ← 0 ; b ← 1\n'
                    'pour i de 2 à n:\n'
                    '    c ← a + b\n'
                    '    a ← b ; b ← c\n'
                    'retourner b',
              ),
            ],
            exercises: [
              Exercise(
                id: '$code-s2u1l1-e1',
                type: ExerciseType.qcm,
                prompt:
                    'Quelle est la complexité temporelle de Fibonacci '
                    'mémoïsé ?',
                options: const [
                  ExerciseOption(id: 'a', text: 'O(2ⁿ)'),
                  ExerciseOption(id: 'b', text: 'O(n)', correct: true),
                  ExerciseOption(id: 'c', text: 'O(n²)'),
                  ExerciseOption(id: 'd', text: 'O(log n)'),
                ],
                explanation:
                    'Chaque valeur fib(i) n\'est calculée '
                    'qu\'une fois → n appels utiles.',
              ),
              Exercise(
                id: '$code-s2u1l1-e2',
                type: ExerciseType.trueFalse,
                prompt:
                    'La programmation dynamique s\'applique quand les '
                    'sous-problèmes se recouvrent.',
                expectedAnswer: 'Vrai',
                explanation:
                    'Vrai : le principe même de la PD est '
                    'd\'éviter de recalculer des sous-problèmes '
                    'chevauchés, contrairement au diviser-pour-régner '
                    'pur.',
              ),
            ],
          ),
        ],
      ),
    ],
  );

  return [s1, s2];
}

// ==================================================================
//  INF102 — Algorithmique & structures de données (L1)
// ==================================================================
List<Semester> _buildInf102(String code) {
  return [
    _sem(
      code: code,
      index: 1,
      units: [
        _unit(
          code: code,
          semIndex: 1,
          unitIndex: 1,
          title: 'Tableaux et listes',
          subtitle: 'Les deux structures séquentielles incontournables',
          color: const Color(0xFF3F51B5),
          icon: Icons.view_list_rounded,
          lessons: [
            _lesson(
              code: code,
              sem: 1,
              unit: 1,
              lesson: 1,
              title: 'Tableau statique',
              subtitle: 'Accès O(1) par indice, taille figée',
              icon: Icons.grid_on_rounded,
              theory: const [
                'Un tableau est une suite contiguë de cases mémoire du même '
                    'type. On accède directement à la case i en calculant '
                    'adresse_debut + i × taille_cas → O(1).',
                'En contrepartie, la taille est fixée à la création : '
                    'insérer au milieu impose de décaler tous les éléments '
                    'suivants, donc O(n).',
              ],
              examples: const [
                Example(
                  title: 'Carnet de notes',
                  body:
                      'Un tableau de 40 notes pour une classe de L1 à '
                      'l\'Université de Yaoundé I. Lire la note de '
                      'l\'étudiant no 17 se fait immédiatement.',
                ),
              ],
              exercises: [
                Exercise(
                  id: '$code-s1u1l1-e1',
                  type: ExerciseType.qcm,
                  prompt:
                      'Quel est le coût d\'un accès par indice dans un '
                      'tableau ?',
                  options: const [
                    ExerciseOption(id: 'a', text: 'O(1)', correct: true),
                    ExerciseOption(id: 'b', text: 'O(log n)'),
                    ExerciseOption(id: 'c', text: 'O(n)'),
                    ExerciseOption(id: 'd', text: 'O(n²)'),
                  ],
                  explanation:
                      'Le calcul d\'adresse est une simple '
                      'addition : accès constant.',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];
}

// ==================================================================
//  DRP201 — Obligations civiles (L2 Droit privé, OHADA / Cameroun)
// ==================================================================
List<Semester> _buildDrp201(String code) {
  return [
    _sem(
      code: code,
      index: 1,
      units: [
        _unit(
          code: code,
          semIndex: 1,
          unitIndex: 1,
          title: 'La formation du contrat',
          subtitle: 'Consentement, objet et cause selon l\'AUDCG OHADA',
          color: const Color(0xFF5E35B1),
          icon: Icons.gavel_rounded,
          lessons: [
            _lesson(
              code: code,
              sem: 1,
              unit: 1,
              lesson: 1,
              title: 'Le consentement et ses vices',
              subtitle: 'Erreur, dol, violence : les conditions de validité',
              icon: Icons.handshake_rounded,
              theory: const [
                'Le contrat suppose un consentement libre et éclairé. L\'acte '
                    'uniforme OHADA relatif au droit des contrats (AUDCG) '
                    'énumère les vices du consentement : l\'erreur, le dol et '
                    'la violence. La seule crainte révérencielle (le respect '
                    'dû à une autorité) n\'est pas tenue pour un vice.',
                'L\'erreur doit porter sur la substance de la chose ou sur la '
                    'personne avec laquelle on contracte pour vicier le '
                    'consentement ; une simple erreur sur la valeur ou sur un '
                    'motif purement personnel reste indifférente. Le dol, lui, '
                    'exige des manœuvres ou affirmations mensongères '
                    'déterminantes,commises avec l\'intention de tromper.',
                'Au Cameroun, le dol se prouve souvent par présomptions graves '
                    'et concordantes : un vendeur de plantation de cacao à '
                    'Campo qui dissimule un litige foncier portant sur la '
                    'parcelle commet un dol par réticence, car le silence '
                    'recouvre une manœuvre.',
              ],
              examples: const [
                Example(
                  title: 'Dol par réticence',
                  body:
                      'Un particulier vend à Yaoundé un terrain dont il sait '
                      'le bornage contesté, sans en informer l\'acheteur. Le '
                      'silence sur un fait déterminant équivaut à des '
                      'manœuvres dolosives et ouvre une action en nullité.',
                  footnote: 'Sans le dol, l\'acheteur n\'aurait pas contracté.',
                ),
              ],
              exercises: [
                Exercise(
                  id: '$code-s1u1l1-e1',
                  type: ExerciseType.qcm,
                  prompt:
                      'Quel élément n\'est PAS un vice du consentement au '
                      'sens de l\'AUDCG ?',
                  options: const [
                    ExerciseOption(id: 'a', text: 'L\'erreur sur la substance'),
                    ExerciseOption(id: 'b', text: 'Le dol'),
                    ExerciseOption(
                      id: 'c',
                      text: 'La crainte révérencielle',
                      correct: true,
                    ),
                    ExerciseOption(id: 'd', text: 'La violence'),
                  ],
                  explanation:
                      'Le respect dû à une autorité (père, époux) n\'est '
                      'pas assimilé à la violence : ce n\'est donc pas un vice de '
                      'consentement.',
                ),
                Exercise(
                  id: '$code-s1u1l1-e2',
                  type: ExerciseType.trueFalse,
                  prompt:
                      'Toute erreur sur la valeur de la chose entraîne la '
                      'nullité du contrat.',
                  expectedAnswer: 'Faux',
                  explanation:
                      'L\'erreur sur la simple valeur ou sur un motif '
                      'personnel est indifférente ; seule l\'erreur sur la '
                      'substance ou sur la personne est protectrice.',
                ),
              ],
            ),
            _lesson(
              code: code,
              sem: 1,
              unit: 1,
              lesson: 2,
              title: 'Objet licite et cause licite',
              subtitle: 'Ce sur quoi et pourquoi l\'on s\'engage',
              icon: Icons.balance_rounded,
              theory: const [
                'L\'objet de l\'obligation doit être déterminé (ou du moins '
                    'déterminable) et licite : on ne peut promettre une chose '
                    'hors du commerce juridique. Une obligation portant sur un '
                    'immeuble dont la vente est interdite par une règle de '
                    'l\'ordre public est nulle de nullité absolue.',
                'La cause est la raison économique et abstraite qui pousse à '
                    's\'engager : dans une vente, la cause de l\'obligation de '
                    'livrer est le prix. Une cause fausse ou illicite (par '
                    'exemple financer une activité prohibée) frappe le contrat '
                    'de nullité.',
                'La réforme et l\'AUDCG tendent à recentrer le contrôle sur le '
                    'contenu et le but du contrat plutôt que sur la cause '
                    'traditionnelle, mais l\'examen de la licéité demeure un '
                    'réflexe central du juriste camerounais.',
              ],
              examples: const [
                Example(
                  title: 'Objet hors du commerce',
                  body:
                      'Une convention portant sur la cession de terres '
                      'domaniales sans l\'accord de l\'autorité compétente '
                      'heurte l\'ordre public foncier camerounais : l\'objet est '
                      'illicite, le contrat est nul.',
                ),
              ],
              exercises: [
                Exercise(
                  id: '$code-s1u1l2-e1',
                  type: ExerciseType.fillBlank,
                  prompt:
                      'Complète : dans une vente, la ___ de l\'obligation de '
                      'livrer la chose est le prix convenu.',
                  blankTemplate:
                      'la ___ de l\'obligation de livrer est le prix',
                  acceptedAnswers: const ['cause'],
                  expectedAnswer: 'cause',
                  explanation:
                      'La cause est le contre-aval abstract qui '
                      'justifie l\'engagement : ici, recevoir le prix.',
                ),
                Exercise(
                  id: '$code-s1u1l2-e2',
                  type: ExerciseType.qcm,
                  prompt: 'La nullité pour objet illicite est en principe :',
                  options: const [
                    ExerciseOption(id: 'a', text: 'Relative'),
                    ExerciseOption(id: 'b', text: 'Absolue', correct: true),
                    ExerciseOption(
                      id: 'c',
                      text:
                          'Nulle, on ne peut jamais '
                          'l\'invoquer',
                    ),
                    ExerciseOption(
                      id: 'd',
                      text:
                          'Automatiquement convertible '
                          'en dommages-intérêts',
                    ),
                  ],
                  explanation:
                      'La protection de l\'ordre public appelle une '
                      'nullité absolue, invocable par tout intéressé et '
                      'relevable d\'office par le juge.',
                ),
              ],
            ),
          ],
        ),
        _unit(
          code: code,
          semIndex: 1,
          unitIndex: 2,
          title: 'L\'inexécution du contrat',
          subtitle: 'Responsabilité contractuelle et réparation',
          color: const Color(0xFF3949AB),
          icon: Icons.report_problem_rounded,
          lessons: [
            _lesson(
              code: code,
              sem: 1,
              unit: 2,
              lesson: 1,
              title: 'La responsabilité contractuelle',
              subtitle: 'Faute, lien causal et mise en demeure',
              icon: Icons.warning_amber_rounded,
              theory: const [
                'L\'inexécution d\'une obligation contractuelle suppose en '
                    'principe une faute imputable au débiteur. Le créancier '
                    'réclame l\'exécution forcée ou la résolution, assorties de '
                    'dommages-intérêts. La simple impossibilité matérielle ne '
                    'suffit pas : encore faut-il un fait générateur.',
                'La mise en demeure — lettre recommandée, acte d\'huissier ou '
                    'somation — fait courir les intérêts et fige le point de '
                    'départ du préjudice. En pratique camerounaise, un '
                    'fournisseur impayé de Douala ne peut guère obtenir de '
                    'réparation sans avoir d\'abord mis son cocontractant en '
                    'demeure.',
                'Le débiteur peut s\'exonérer en invoquant la force majeure : '
                    'un événement imprévisible, irrésistible et extérieur. Une '
                    'crue exceptionnelle du fleuve Wouri qui coupe toute route '
                    'd\'approvisionnement peut, sous conditions, constituer un '
                    'tel cas.',
              ],
              examples: const [
                Example(
                  title: 'Mise en demeure préalable',
                  body:
                      'Une PME de Bafoussam livre du café à un grossiste qui '
                      'retarde le paiement. Elle adresse une sommation par '
                      'huissier : à compter de cette date, les intérêts et le '
                      'préjudice de trésorerie commencent à courir.',
                ),
              ],
              exercises: [
                Exercise(
                  id: '$code-s1u2l1-e1',
                  type: ExerciseType.ordering,
                  prompt:
                      'Remets dans l\'ordre la chaîne de la responsabilité '
                      'contractuelle :',
                  orderItems: const [
                    'Naissance d\'une obligation valide',
                    'Inexécution imputable au débiteur',
                    'Mise en demeure du créancier',
                    'Preuve d\'un préjudice et lien causal',
                    'Réparation (dommages-intérêts)',
                  ],
                  explanation:
                      'Sans faute, sans lien causal et sans mise en '
                      'demeure, la réparation contractuelle ne peut être '
                      'allouée.',
                ),
                Exercise(
                  id: '$code-s1u2l1-e2',
                  type: ExerciseType.trueFalse,
                  prompt:
                      'La force majeure doit être imprévisible pour '
                      'exonérer le débiteur.',
                  expectedAnswer: 'Vrai',
                  explanation:
                      'La force majeure cumule trois caractères : '
                      'imprévisibilité, irrésistibilité et extériorité.',
                ),
              ],
            ),
            _lesson(
              code: code,
              sem: 1,
              unit: 2,
              lesson: 2,
              title: 'L\'évaluation du préjudice',
              subtitle: 'Perte éprouvée et gain manqué',
              icon: Icons.show_chart_rounded,
              theory: const [
                'Réparer, c\'est replacer la victime dans la situation où elle '
                    'serait sans l\'inexécution, sans l\'enrichir. Le préjudice '
                    'comprend la perte éprouvée (le dommage positif) et le gain '
                    'manqué (le lucro cessante), pourvu que ce dernier soit une '
                    'perte de chance sérieuse et non une simple espérance.',
                'Le juge évalue souverainement le dommage : il peut allouer une '
                    'provision en attendant l\'expertise. Les clauses limitatives '
                    'de réparation sont admises sauf en cas de faute lourde ou '
                    'dolosive du débiteur, qui les réduit à néant.',
                'En droit OHADA, la réparation du préjudice commercial intègre '
                    'souvent le coût du crédit et la perte de marge : un '
                    'transporteur défaillant à Kribi devra indemniser le '
                    'chargeur pour la marchandise pourrie, mais aussi pour la '
                    'clientèle perdue de façon établie.',
              ],
              examples: const [
                Example(
                  title: 'Perte de chance sérieuse',
                  body:
                      'Un avocat manque le délai d\'appel d\'un dossier : son '
                      'client ne perd pas définitivement son procès, mais une '
                      'chance sérieuse d\'obtenir l\'infirmation. L\'indemnité '
                      'proportionne la réparation à la chance évanouie.',
                ),
              ],
              exercises: [
                Exercise(
                  id: '$code-s1u2l2-e1',
                  type: ExerciseType.qcm,
                  prompt: 'Le « lucro cessante » désigne :',
                  options: const [
                    ExerciseOption(id: 'a', text: 'La perte déjà subie'),
                    ExerciseOption(
                      id: 'b',
                      text:
                          'Le gain dont la victime a été '
                          'privée',
                      correct: true,
                    ),
                    ExerciseOption(
                      id: 'c',
                      text: 'La peine infligée au débiteur',
                    ),
                    ExerciseOption(id: 'd', text: 'Les frais de justice'),
                  ],
                  explanation:
                      'Le lucro cessante est le gain manqué, par '
                      'opposition au damnum emergens (la perte éprouvée).',
                ),
                Exercise(
                  id: '$code-s1u2l2-e2',
                  type: ExerciseType.textInput,
                  prompt:
                      'Quelle faute rend inopposable la clause limitative de '
                      'réparation ? (un seul mot)',
                  acceptedAnswers: const ['dol', 'faute dolosive', 'lourde'],
                  expectedAnswer: 'dol',
                  explanation:
                      'Le dol (et la faute lourde équiparée) neutralise '
                      'la clause limitative : on ne peut se protégrer contre sa '
                      'propre déloyauté.',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];
}

// ==================================================================
//  ECO101 — Microéconomie I (L1 Économie)
// ==================================================================
List<Semester> _buildEco101(String code) {
  return [
    _sem(
      code: code,
      index: 1,
      units: [
        _unit(
          code: code,
          semIndex: 1,
          unitIndex: 1,
          title: 'Offre, demande et équilibre',
          subtitle: 'Comment le prix se forme sur un marché concurrentiel',
          color: const Color(0xFF00897B),
          icon: Icons.trending_up_rounded,
          lessons: [
            _lesson(
              code: code,
              sem: 1,
              unit: 1,
              lesson: 1,
              title: 'La loi de la demande',
              subtitle:
                  'Utilité marginale décroissante et contrainte de budget',
              icon: Icons.shopping_bag_rounded,
              theory: const [
                'Toutes choses égales par ailleurs, la quantité demandée d\'un '
                    'bien diminue quand son prix augmente : c\'est la loi de '
                    'demande. Elle repose sur l\'utilité marginale décroissante : '
                    'le nième sac de riz acheté rapporte moins de satisfaction '
                    'que le premier, donc on n\'accepte de le payer qu\'à un prix '
                    'plus bas.',
                'Le consommateur maximise son utilité sous contrainte '
                    'budgétaire : il arbitre jusqu\'à égaliser le rapport '
                    'utilité marginale / prix entre tous les biens. Si le prix '
                    'd\'un bien monte, son « rendement par franc » tombe sous '
                    'celui des autres et l\'agent substitue vers eux.',
                'Au marché de Mokolo à Yaoundé, quand le prix du manioc '
                    'double, les ménages basculent vers le plantain ou le '
                    'macabo : c\'est l\'effet de substitution observable, '
                    'indépendamment de l\'effet de revenu qui réduit le pouvoir '
                    'd\'achat global.',
              ],
              examples: const [
                Example(
                  title: 'Arbitrage utilité / prix',
                  body:
                      'Le pain procure 30 utils pour 150 F, le riz 40 utils '
                      'pour 200 F. Le rapport est 0,20 utils/F pour le riz '
                      'contre 0,20 pour le pain : l\'acheteur est indifférent à '
                      'la marge ; au-delà il déplace son budget.',
                  code: 'règle : UM_biens / P_biens = UM_autre / P_autre',
                ),
              ],
              exercises: [
                Exercise(
                  id: '$code-s1u1l1-e1',
                  type: ExerciseType.qcm,
                  prompt: 'L\'utilité marginale d\'un bien est généralement :',
                  options: const [
                    ExerciseOption(
                      id: 'a',
                      text: 'Croissante avec la quantité',
                    ),
                    ExerciseOption(
                      id: 'b',
                      text: 'Décroissante avec la quantité',
                      correct: true,
                    ),
                    ExerciseOption(id: 'c', text: 'Constante'),
                    ExerciseOption(
                      id: 'd',
                      text: 'Négative dès la première unité',
                    ),
                  ],
                  explanation:
                      'Chaque unité supplémentaire apporte une '
                      'satisfaction additionnelle plus faible : d\'où la pente '
                      'négative de la courbe de demande.',
                ),
                Exercise(
                  id: '$code-s1u1l1-e2',
                  type: ExerciseType.trueFalse,
                  prompt:
                      'Un bien de Giffen voit sa demande augmenter quand son '
                      'prix augmente.',
                  expectedAnswer: 'Vrai',
                  explanation:
                      'Chez le bien de Giffen, l\'effet de revenu '
                      'négatif l\'emporte sur l\'effet de substitution, cassant '
                      'la loi de demande.',
                ),
              ],
            ),
            _lesson(
              code: code,
              sem: 1,
              unit: 1,
              lesson: 2,
              title: 'Les élasticités',
              subtitle: 'Mesurer la sensibilité des quantités au prix',
              icon: Icons.straighten_rounded,
              theory: const [
                'L\'élasticité-prix de la demande est le pourcentage de variation '
                    'des quantités divisé par le pourcentage de variation du '
                    'prix. Elle est élastique (> 1 en valeur absolue) quand une '
                    'hausse modique du prix fait chuter fortement la demande, '
                    'inélastique (< 1) pour les produits de première nécessité.',
                'Le sel, la farine de manioc ou les médicaments essentiels sont '
                    'peu élastiques au Cameroun : le ménage en a besoin quel que '
                    'soit le prix. À l\'inverse, les boissons sucrées ou les '
                    'loisirs sont élastiques et se réduisent vite en période de '
                    'chère.',
                'L\'élasticité croisée renseigne sur la substituabilité : '
                    'positive entre substituts (café / thé), négative entre '
                    'compléments (imprimante / cartouche).',
              ],
              examples: const [
                Example(
                  title: 'Calcul d\'élasticité d\'arc',
                  body:
                      'Le prix du litre d\'essence passe de 700 à 770 F '
                      '(+ 10 %) et la consommation recule de 6 %. Élasticité '
                      '= - 6 / 10 = - 0,6 : la demande est inélastique, la '
                      'recette de l\'État augmente donc avec le prix.',
                  code: 'E = (%ΔQ) / (%ΔP)',
                ),
              ],
              exercises: [
                Exercise(
                  id: '$code-s1u1l2-e1',
                  type: ExerciseType.textInput,
                  prompt:
                      'Le prix baisse de 20 % et les ventes grimpent de 40 %. '
                      'Quelle est l\'élasticité-prix (valeur absolue) ? '
                      'Réponds par un nombre.',
                  acceptedAnswers: const ['2', '2,0', '2.0'],
                  expectedAnswer: '2',
                  explanation:
                      '40 / 20 = 2 : la demande est élastique, une '
                      'baisse de prix accroît le chiffre d\'affaires.',
                ),
                Exercise(
                  id: '$code-s1u1l2-e2',
                  type: ExerciseType.qcm,
                  prompt:
                      'Un producteur de médicaments essentiels (demande '
                      'inélastique) veut maximiser sa recette ; il doit :',
                  options: const [
                    ExerciseOption(id: 'a', text: 'Baisser ses prix'),
                    ExerciseOption(
                      id: 'b',
                      text: 'Augmenter ses prix',
                      correct: true,
                    ),
                    ExerciseOption(id: 'c', text: 'Rien changer'),
                    ExerciseOption(
                      id: 'd',
                      text:
                          'Doubler la production au '
                          'même prix',
                    ),
                  ],
                  explanation:
                      'Quand la demande est inélastique (|E| < 1), '
                      'hausser le prix fait augmenter la recette puisque les '
                      'quantités vendues baissent peu.',
                ),
              ],
            ),
          ],
        ),
        _unit(
          code: code,
          semIndex: 1,
          unitIndex: 2,
          title: 'Le producteur et les coûts',
          subtitle: 'Du coût marginal à l\'équilibre concurrentiel',
          color: const Color(0xFF6D4C41),
          icon: Icons.factory_rounded,
          lessons: [
            _lesson(
              code: code,
              sem: 1,
              unit: 2,
              lesson: 1,
              title: 'Structure des coûts',
              subtitle: 'Fixes, variables, marginaux et moyens',
              icon: Icons.payments_rounded,
              theory: const [
                'Le coût total se décompose en coûts fixes (loyer de l\'atelier, '
                    'salaire du gérant, indépendants de la production) et coûts '
                    'variables (farine, énergie, main-d\'œuvre à l\'heure). Le '
                    'coût marginal est le surcoût d\'une unité produite de plus.',
                'Tant que le coût marginal est inférieur au prix de vente, '
                    'produire une unité supplémentaire rapporte ; l\'entreprise '
                    'optimale s\'arrête là où coût marginal = recette marginale. '
                    'Les rendements d\'échelle expliquent la forme en U du coût '
                    'moyen.',
                'Une micro-boulangerie de Danga qui achète un four plus grand '
                    'réduit son coût moyen par pain (économies d\'échelle) '
                    'jusqu\'à ce que l\'engorgement et la surveillance fassent '
                    'remonter les coûts (déséconomies).',
              ],
              examples: const [
                Example(
                  title: 'Seuil de rentabilité',
                  body:
                      'Charges fixes 500 000 F/mois, coût variable 250 F/pain, '
                      'prix de vente 400 F. Marge unitaire = 150 F, donc seuil '
                      '= 500 000 / 150 ≈ 3 334 pains/mois. En dessous, la '
                      'boulangerie perd de l\'argent.',
                  code: 'seuil = CF / (P - CVu)',
                ),
              ],
              exercises: [
                Exercise(
                  id: '$code-s1u2l1-e1',
                  type: ExerciseType.ordering,
                  prompt:
                      'Ordre logique de raisonnement du producteur qui accroît '
                      'sa production :',
                  orderItems: const [
                    'Le coût marginal est sous le prix',
                    'Produire une unité de plus',
                    'Les rendements décroissent',
                    'Le coût marginal atteint le prix',
                    'On stoppe l\'extension',
                  ],
                  explanation:
                      'On produit tant que CM < P ; l\' optimum est à '
                      'CM = P.',
                ),
                Exercise(
                  id: '$code-s1u2l1-e2',
                  type: ExerciseType.fillBlank,
                  prompt:
                      'Le surcoût d\'une unité supplémentaire s\'appelle le '
                      'coût ___.',
                  blankTemplate: 'coût ___',
                  acceptedAnswers: const ['marginal'],
                  expectedAnswer: 'marginal',
                  explanation:
                      'Le coût marginal mesure le coût additionnel de '
                      'la dernière unité produite.',
                ),
              ],
            ),
            _lesson(
              code: code,
              sem: 1,
              unit: 2,
              lesson: 2,
              title: 'La concurrence parfaite',
              subtitle: 'Price-taker, libre entrée et profit nul à terme',
              icon: Icons.grid_on_rounded,
              theory: const [
                'En concurrence parfaite, une foule d\'offreurs et de demandeurs '
                    'échangent un produit homogène, l\'information est libre et '
                    'l\'entrée-sortie du marché est sans barrière. Chaque '
                    'entreprise est preneuse de prix (price-taker) : sa courbe '
                    'de demande est horizontale au prix du marché.',
                'Le marché du maïs sur les plateaux de l\'Adamaoua s\'approche de '
                    'ce modèle : de nombreux producteurs, un produit peu '
                    'différencié, et un prix qui s\'ajuste chaque semaine selon '
                    'l\'offre et la demande globales.',
                'À long terme, le jeu des entrées-sorties annule les profits '
                    'exceptionnels : si les places rapportent, de nouvelles '
                    'entreprises entrent, l\'offre augmente, le prix baisse '
                    'jusqu\'au profit nul (recette = coût moyen minimum).',
              ],
              examples: const [
                Example(
                  title: 'Entrées et écrêtement du profit',
                  body:
                      'Un producteur d\'ananas réalise des profits grâce à une '
                      'demande d\'export. D\'autres planteurs entrent, l\'offre '
                      'sature, le prix chute et l\'excédent de profit disparaît '
                      'à long terme : c\'est l\'auto-discipline du marché libre.',
                ),
              ],
              exercises: [
                Exercise(
                  id: '$code-s1u2l2-e1',
                  type: ExerciseType.qcm,
                  prompt:
                      'En concurrence parfaite, la courbe de demande perçue '
                      'par une entreprise individuelle est :',
                  options: const [
                    ExerciseOption(
                      id: 'a',
                      text: 'Horizontale au prix de marché',
                      correct: true,
                    ),
                    ExerciseOption(id: 'b', text: 'Vertical'),
                    ExerciseOption(id: 'c', text: 'Pente négative forte'),
                    ExerciseOption(id: 'd', text: 'Identique à son coût moyen'),
                  ],
                  explanation:
                      'L\'entreprise est price-taker : elle peut vendre '
                      'autant qu\'elle veut au prix du marché, d\'où une demande '
                      'parfaitement élastique (horizontale).',
                ),
                Exercise(
                  id: '$code-s1u2l2-e2',
                  type: ExerciseType.trueFalse,
                  prompt:
                      'À long terme, les entreprises en concurrence parfaite '
                      'réalisent un profit économique nul.',
                  expectedAnswer: 'Vrai',
                  explanation:
                      'La libre entrée annule les profits '
                      'exceptionnels : on converge vers le profit nul (P = coût '
                      'moyen minimum).',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];
}

// ==================================================================
//  MED201 — Physiologie humaine (DFGSM2 Médecine)
// ==================================================================
List<Semester> _buildMed201(String code) {
  return [
    _sem(
      code: code,
      index: 1,
      units: [
        _unit(
          code: code,
          semIndex: 1,
          unitIndex: 1,
          title: 'Physiologie cardiovasculaire',
          subtitle: 'Du cycle cardiaque à la régulation tensionnelle',
          color: const Color(0xFFD81B60),
          icon: Icons.favorite_rounded,
          lessons: [
            _lesson(
              code: code,
              sem: 1,
              unit: 1,
              lesson: 1,
              title: 'Le cycle cardiaque et le débit',
              subtitle: 'Systole, diastole et loi de Frank-Starling',
              icon: Icons.monitor_heart_rounded,
              theory: const [
                'Le cœur fonctionne en cycles : la systole ventriculaire éjeecte '
                    'le sang (volume d\'éjection ~ 70 mL), la diastole laisse les '
                    'cavités se remplir. Le débit cardiaque = volume d\'éjection '
                    '× fréquence cardiaque ; au repos chez un adulte, ~ 70 mL '
                    '× 75/min ≈ 5 L/min.',
                'La loi de Frank-Starling édit qu\'un muscle cardiaque plus '
                    'étiré (remplissage veineux accru, précharge) se contracte '
                    'plus fortement : le cœur adapte automatiquement son '
                    'éjection au retour veineux, sans commande nerveuse.',
                'Chez un étudiant en médecine de Dschang, une fièvre palustre '
                    'augmente la fréquence cardiaque et donc le débit ; le '
                    'volume d\'éjection, lui, dépend de la précharge et de la '
                    'contractilité, deux paramètres que le clinicien surveille.',
              ],
              examples: const [
                Example(
                  title: 'Calcul du débit cardiaque',
                  body:
                      'Volume d\'éjection 70 mL, fréquence 75/min : DC = 70 × '
                      '75 = 5 250 mL/min ≈ 5,25 L/min. À l\'effort, la fréquence '
                      'monte à 150 et le volume d\'éjection à 110 mL : DC ≈ 16,5 '
                      'L/min.',
                  code: 'DC (L/min) = Vd (mL) × FC (bpm) / 1000',
                ),
              ],
              exercises: [
                Exercise(
                  id: '$code-s1u1l1-e1',
                  type: ExerciseType.textInput,
                  prompt:
                      'Calcule le débit cardiaque (en L/min) pour Vd = 70 mL '
                      'et FC = 80/min. Réponds par un nombre.',
                  acceptedAnswers: const ['5,6', '5.6', '5,6l', '5.6'],
                  expectedAnswer: '5,6',
                  explanation: '70 × 80 = 5 600 mL/min = 5,6 L/min.',
                ),
                Exercise(
                  id: '$code-s1u1l1-e2',
                  type: ExerciseType.qcm,
                  prompt: 'La loi de Frank-Starling décrit le lien entre :',
                  options: const [
                    ExerciseOption(
                      id: 'a',
                      text:
                          'Précharge (étirement) et '
                          'force de contraction',
                      correct: true,
                    ),
                    ExerciseOption(
                      id: 'b',
                      text: 'Fréquence et tension artérielle',
                    ),
                    ExerciseOption(
                      id: 'c',
                      text: 'Oxygène et débit respiratoire',
                    ),
                    ExerciseOption(id: 'd', text: 'Pouls et température'),
                  ],
                  explanation:
                      'Plus la fibre est étirée par le remplissage, '
                      'plus elle se contracte fort : le cœur s\'adapte au retour '
                      'veineux.',
                ),
              ],
            ),
            _lesson(
              code: code,
              sem: 1,
              unit: 1,
              lesson: 2,
              title: 'Régulation de la pression artérielle',
              subtitle: 'Baroréflexe, système réine-angiotensine',
              icon: Icons.speed_rounded,
              theory: const [
                'La pression artérielle est le produit du débit cardiaque par les '
                    'résistances vasculaires périphériques (PA = DC × RVP). Tout '
                    'mécanisme qui agit sur l\'un ou l\'autre paramètre modifie '
                    'la tension : c\'est la base de lecture du choc et de '
                    'l\'hypertension.',
                'Le baroréflexe corrige les variations brutales : des capteurs '
                    'du sinus carotidien détectent la montée de PA et freinent '
                    'le cœur via le nerf vague. À l\'inverse, une hypotension '
                    'déclenche tachycardie et vasoconstriction.',
                'Le système réine-angiotensine-aldostérone (SRAA) ajuste la '
                    'volémie à plus long terme : rein, angiotensine II '
                    '(vasoconstricteur) et aldostérone (rétention sodée). Les '
                    'inhibiteurs de l\'enzyme de conversion utilisés au '
                    'Cameroun bloquent cette voie.',
              ],
              examples: const [
                Example(
                  title: 'Passage debout rapide',
                  body:
                      'Au lever brusque, le sang stagne dans les membres '
                      'inférieurs ; la PA chute un instant puis le baroréflexe '
                      'relève la fréquence et les résistances. Un baroréflexe '
                      'défaillant donne l\'hypotension orthostatique et le '
                      'malaise.',
                ),
              ],
              exercises: [
                Exercise(
                  id: '$code-s1u1l2-e1',
                  type: ExerciseType.fillBlank,
                  prompt:
                      'Complète la relation fondamentale : PA = DC × ___ '
                      '(périphériques).',
                  blankTemplate: 'PA = DC × ___',
                  acceptedAnswers: const ['rvp', 'résistances', 'resistances'],
                  expectedAnswer: 'rvp',
                  explanation:
                      'Pression = Débit × Résistances vasculaires '
                      'périphériques (RVP).',
                ),
                Exercise(
                  id: '$code-s1u1l2-e2',
                  type: ExerciseType.trueFalse,
                  prompt: 'L\'angiotensine II est un puissant vasodilatateur.',
                  expectedAnswer: 'Faux',
                  explanation:
                      'L\'angiotensine II est vasoconstrictrice ; elle '
                      'éléve la pression et stimule la sécrétion d\'aldostérone.',
                ),
              ],
            ),
          ],
        ),
        _unit(
          code: code,
          semIndex: 1,
          unitIndex: 2,
          title: 'Physiologie respiratoire',
          subtitle: 'Hématose et transport des gaz',
          color: const Color(0xFF039BE5),
          icon: Icons.air_rounded,
          lessons: [
            _lesson(
              code: code,
              sem: 1,
              unit: 2,
              lesson: 1,
              title: 'L\'hématose alvéolaire',
              subtitle: 'Diffusion O₂/CO₂ à travers la membrane',
              icon: Icons.whatshot_rounded,
              theory: const [
                'L\'hématose est l\'échange gazeux entre l\'air alvéolaire et '
                    'le sang capillaire : l\'O₂ diffuse vers le sang, le CO₂ en '
                    'sens inverse. La force motrice est la différence de '
                    'pression partielle (PO₂ alvéolaire ~ 100 mmHg contre ~ 40 '
                    'mmHg dans le sang veineux).',
                'La loi de Fick rappelle que le flux de gaz croît avec la '
                    'surface d\'échange et le gradient, et décroît avec '
                    'l\'épaisseur de la membrane. Un épaississement (fibrose, '
                    'œdème pulmonaire) ou une surface réduite (emphysème) '
                    'limitent l\'oxygénation.',
                'Le rapport ventilation/perfusion (V/Q) doit être équilibré : '
                    'une zone mal ventilée mais bien perfusée crée un shunt, '
                    'source d\'hypoxémie — mécanisme central de la détresse '
                    'respiratoire du paludisme grave.',
              ],
              examples: const [
                Example(
                  title: 'Gradient de diffusion',
                  body:
                      'PO₂ : 100 mmHg dans l\'alvéole contre 40 mmHg dans le '
                      'capillaire → l\'O₂ passe dans le sang. PCO₂ : 46 contre '
                      '40 mmHg → le CO₂ sort. Le sang quitte le poumon à ~ 100 '
                      'mmHg de PO₂.',
                ),
              ],
              exercises: [
                Exercise(
                  id: '$code-s1u2l1-e1',
                  type: ExerciseType.qcm,
                  prompt:
                      'Quel facteur diminue la diffusion des gaz selon Fick ?',
                  options: const [
                    ExerciseOption(
                      id: 'a',
                      text:
                          'L\'augmentation du gradient '
                          'de pression',
                    ),
                    ExerciseOption(
                      id: 'b',
                      text:
                          'L\'épaississement de la '
                          'membrane alvéolo-capillaire',
                      correct: true,
                    ),
                    ExerciseOption(
                      id: 'c',
                      text: 'L\'augmentation de la surface',
                    ),
                    ExerciseOption(id: 'd', text: 'La baisse de l\'épaisseur'),
                  ],
                  explanation:
                      'Le flux est inversement proportionnel à '
                      'l\'épaisseur : membrane épaissie = diffusion réduite.',
                ),
                Exercise(
                  id: '$code-s1u2l1-e2',
                  type: ExerciseType.trueFalse,
                  prompt:
                      'Dans le sang veineux arrivant au poumon, la PO₂ est '
                      'd\'environ 40 mmHg.',
                  expectedAnswer: 'Vrai',
                  explanation:
                      'Le sang veineux mixte a une PO₂ ~ 40 mmHg, d\'où '
                      'la diffusion d\'O₂ depuis l\'alvéole (~ 100 mmHg).',
                ),
              ],
            ),
            _lesson(
              code: code,
              sem: 1,
              unit: 2,
              lesson: 2,
              title: 'Transport du O₂ et du CO₂',
              subtitle: 'Hémoglobine, courbe de dissociation, effet Bohr',
              icon: Icons.bloodtype_rounded,
              theory: const [
                'L\'oxygène circule presque entièrement lié à l\'hémoglobine '
                    '(~ 1,34 mL O₂ par gramme de Hb) ; seul le reste est dissous '
                    'dans le plasma. La courbe sigmoïde de dissociation décrit '
                    'la saturation selon la PO₂.',
                'L\'effet Bohr : l\'acidose (↑ CO₂, ↓ pH) et la hausse de la '
                    'température déplacent la courbe vers la droite, ce qui '
                    'facilite la libération d\'O₂ aux tissus actifs — un muscle '
                    'qui travaille reçoit plus d\'oxygène.',
                'Le CO₂, lui, est transporté surtout sous forme de bicarbonates '
                    '(~ 70 %), lié à l\'Hb (~ 20 %) et dissous (~ 10 %). La '
                    'réaction est catalysée par l\'anhydrase carbonique des '
                    'globules rouges.',
              ],
              examples: const [
                Example(
                  title: 'Anémie et capacité d\'O₂',
                  body:
                      'Une femme de Yaoundé dont l\'Hb chute à 7 g/dL (au lieu '
                      'de 14) voit sa capacité d\'O₂ divisée par deux : le sang '
                      'ne peut plus transporter assez d\'oxygène, d\'où essouffle '
                      'et tachycardie compensatrice.',
                ),
              ],
              exercises: [
                Exercise(
                  id: '$code-s1u2l2-e1',
                  type: ExerciseType.qcm,
                  prompt: 'La forme majoritaire de transport du CO₂ dans le sang est :',
                  options: const [
                    ExerciseOption(id: 'a', text: 'Dissoute dans le plasma'),
                    ExerciseOption(
                      id: 'b',
                      text: 'Sous forme de bicarbonates',
                      correct: true,
                    ),
                    ExerciseOption(id: 'c', text: 'Liée à l\'hémoglobine'),
                    ExerciseOption(id: 'd', text: 'Sous forme de CO₂ pur'),
                  ],
                  explanation:
                      'Environ 70 % du CO₂ circule comme bicarbonate '
                      '(HCO₃⁻), grâce à l\'anhydrase carbonique.',
                ),
                Exercise(
                  id: '$code-s1u2l2-e2',
                  type: ExerciseType.trueFalse,
                  prompt:
                      'L\'acidose déplace la courbe de dissociation de '
                      'l\'Hb vers la droite.',
                  expectedAnswer: 'Vrai',
                  explanation:
                      'Effet Bohr : pH bas / CO₂ haut → courbe à '
                      'droite → l\'Hb relâche plus d\'O₂ aux tissus.',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];
}

// ==================================================================
//  INF330 — Intelligence artificielle (L3 Informatique)
// ==================================================================
List<Semester> _buildInf330(String code) {
  return [
    _sem(
      code: code,
      index: 1,
      units: [
        _unit(
          code: code,
          semIndex: 1,
          unitIndex: 1,
          title: 'Résolution de problèmes par recherche',
          subtitle: 'Heuristiques, A* et jeux adverses',
          color: const Color(0xFF512DA8),
          icon: Icons.psychology_rounded,
          lessons: [
            _lesson(
              code: code,
              sem: 1,
              unit: 1,
              lesson: 1,
              title: 'Recherche heuristique et A*',
              subtitle: 'Combiner coût réel et estimation',
              icon: Icons.alt_route_rounded,
              theory: const [
                'Un algorithme de recherche aveugle (largeur, profondeur) explore '
                    'sans connaissance du but et explose combinatoirement. Les '
                    'méthodes heuristiques guident l\'exploration grâce à une '
                    'estimation du coût restant, ce qui réduit drastiquement les '
                    'nœuds développés.',
                'A* évalue chaque nœud par f(n) = g(n) + h(n), où g est le coût '
                    'réel déjà parcouru et h l\'estimation optimiste du coût '
                    'restant. Il est optimal si h est admissible (ne surestime '
                    'jamais) et complet.',
                'Si de plus h est cohérente (inégalité triangulaire), A* ne '
                    'ré-ouvre jamais un nœud déjà traité. Dans un routage '
                    'Yaoundé-Douala, la distance à vol d\'oiseau sert d\'h '
                    'admissible : elle sous-estime toujours la vraie route.',
              ],
              examples: const [
                Example(
                  title: 'A* sur une grille',
                  body:
                      'Pour aller d\'un coin à l\'autre d\'une grille, h = '
                      'distance de Manhattan (admissible car jamais inférieure '
                      'au vrai chemin en obstacles). A* explore moins de cases '
                      'qu\'un BFS car il privilégie les nœuds proches du but.',
                  code:
                      'f(n) = g(n) + h(n)\n'
                      'g = coût réel départ → n\n'
                      'h = estimation optimiste n → but',
                ),
              ],
              exercises: [
                Exercise(
                  id: '$code-s1u1l1-e1',
                  type: ExerciseType.qcm,
                  prompt:
                      'Pour garantir l\'optimalité de A*, l\'heuristique h '
                      'doit être :',
                  options: const [
                    ExerciseOption(
                      id: 'a',
                      text:
                          'Admissible (ne jamais '
                          'surestimer)',
                      correct: true,
                    ),
                    ExerciseOption(id: 'b', text: 'Aléatoire'),
                    ExerciseOption(id: 'c', text: 'Toujours nulle'),
                    ExerciseOption(
                      id: 'd',
                      text: 'Proportionnelle au temps CPU',
                    ),
                  ],
                  explanation:
                      'Une heuristique admissible (h ≤ vrai coût) '
                      'empêche A* de négliger le plus court chemin.',
                ),
                Exercise(
                  id: '$code-s1u1l1-e2',
                  type: ExerciseType.fillBlank,
                  prompt:
                      'La formule d\'évaluation de A* est f(n) = ___ + h(n).',
                  blankTemplate: 'f(n) = ___ + h(n)',
                  acceptedAnswers: const ['g(n)', 'g', 'g du nœud', 'g de n'],
                  expectedAnswer: 'g(n)',
                  explanation:
                      'f = g (coût réel déjà payé) + h (coût estimé '
                      'restant).',
                ),
              ],
            ),
            _lesson(
              code: code,
              sem: 1,
              unit: 1,
              lesson: 2,
              title: 'Jeux et minimax',
              subtitle: 'Anticiper l\'adversaire et élaguer',
              icon: Icons.sports_esports_rounded,
              theory: const [
                'Dans un jeu à deux joueurs à information complète (échecs, '
                    'othello), minimax suppose que l\'adversaire joue au mieux : '
                    'le maximizing player choisit le coup maximisant son '
                    'minimum garanti, en explorant l\'arbre de jeux.',
                'L\'élagage alpha-bêta évite d\'explorer des branches inutiles : '
                    'si un coup est déjà moins bon qu\'une alternative connue, '
                    'on le coupe. Le résultat reste identique à minimax mais '
                    'beaucoup plus vite.',
                'Comme les échecs ne peuvent être résolus jusqu\'à la fin, on '
                    's\'arrête à une profondeur limitée et une fonction '
                    'd\'évaluation heuristique (matériel, mobilité) estime la '
                    'qualité d\'une position feuille.',
              ],
              examples: const [
                Example(
                  title: 'Ordre des coupes et élagage',
                  body:
                      'En explorant d\'abord les meilleurs coups (grâce à un '
                      'tri), alpha-bêta élague davantage : l\'arbre effectif '
                      'passe de b^d à environ b^(d/2), doublant presque la '
                      'profondeur atteignable à budget égal.',
                ),
              ],
              exercises: [
                Exercise(
                  id: '$code-s1u1l2-e1',
                  type: ExerciseType.trueFalse,
                  prompt:
                      'Alpha-bêta modifie le coup final choisi par rapport à '
                      'minimax.',
                  expectedAnswer: 'Faux',
                  explanation:
                      'Alpha-bêta est seulement un élagage : il '
                      'conserve la même décision que minimax mais explore moins '
                      'de nœuds.',
                ),
                Exercise(
                  id: '$code-s1u1l2-e2',
                  type: ExerciseType.qcm,
                  prompt: 'Minimax suppose que l\'adversaire :',
                  options: const [
                    ExerciseOption(id: 'a', text: 'Joue au hasard'),
                    ExerciseOption(
                      id: 'b',
                      text: 'Joue optimalement contre nous',
                      correct: true,
                    ),
                    ExerciseOption(id: 'c', text: 'Ne peut pas gagner'),
                    ExerciseOption(id: 'd', text: 'Ignore notre stratégie'),
                  ],
                  explanation:
                      'Minimax est pessimiste : il maximise le pire '
                      'cas face à un adversaire parfait.',
                ),
              ],
            ),
          ],
        ),
        _unit(
          code: code,
          semIndex: 1,
          unitIndex: 2,
          title: 'Apprentissage statistique',
          subtitle: 'Des modèles au compromis biais-variance',
          color: const Color(0xFF00897B),
          icon: Icons.auto_awesome_rounded,
          lessons: [
            _lesson(
              code: code,
              sem: 1,
              unit: 2,
              lesson: 1,
              title: 'Classification et régression',
              subtitle: 'Prédire une catégorie ou une valeur',
              icon: Icons.category_rounded,
              theory: const [
                'Un problème de régression prédit une quantité continue (prix '
                    'd\'une parcelle à Douala selon sa surface) ; la '
                    'régression linéaire ajuste une droite minimisant l\'erreur '
                    'quadratique. Un problème de classification prédit une '
                    'classe (malade / non malade).',
                'k plus proches voisins (k-NN) étiquette un point par le vote '
                    'majoritaire de ses k voisins les plus proches : simple, '
                    'non paramétrique, mais sensible à l\'échelle des variables '
                    '(normaliser avant !).',
                'La qualité d\'un classifieur se juge par matrice de confusion, '
                    'précision et rappel : dépister le paludisme exige un bon '
                    'rappel (ne manquer aucun cas) quitte à accepter moins de '
                    'précision.',
              ],
              examples: const [
                Example(
                  title: 'Précision vs rappel',
                  body:
                      'Un test détecte 95 malades sur 100 (rappel 0,95) mais '
                      '20 sains sur 95 sont classés positifs à tort. En '
                      'screening, le rappel prime ; en publicité ciblée, la '
                      'précision compte davantage.',
                ),
              ],
              exercises: [
                Exercise(
                  id: '$code-s1u2l1-e1',
                  type: ExerciseType.qcm,
                  prompt:
                      'Estimer le prix continu d\'une maison est un '
                      'problème de :',
                  options: const [
                    ExerciseOption(id: 'a', text: 'Classification'),
                    ExerciseOption(id: 'b', text: 'Régression', correct: true),
                    ExerciseOption(id: 'c', text: 'Clustering'),
                    ExerciseOption(id: 'd', text: 'Réduction de dimension'),
                  ],
                  explanation:
                      'Une sortie numérique continue relève de la '
                      'régression ; une étiquette discrète relève de la '
                      'classification.',
                ),
                Exercise(
                  id: '$code-s1u2l1-e2',
                  type: ExerciseType.trueFalse,
                  prompt:
                      'Pour le dépistage d\'une maladie grave, on privilégie '
                      'le rappel à la précision.',
                  expectedAnswer: 'Vrai',
                  explanation:
                      'Manquer un malade (faux négatif) est grave : on '
                      'maximise le rappel, quitte à revoir certains faux '
                      'positifs.',
                ),
              ],
            ),
            _lesson(
              code: code,
              sem: 1,
              unit: 2,
              lesson: 2,
              title: 'Surapprentissage et validation',
              subtitle: 'Trouver le juste compromis biais-variance',
              icon: Icons.balance_rounded,
              theory: const [
                'Le surapprentissage (overfitting) apparaît quand un modèle '
                    'mémorise le bruit d\'entraînement : excellent en train, '
                    'médiocre en test. À l\'inverse, un modèle trop simple '
                    'sous-apprend (underfitting) et rate aussi bien train que '
                    'test.',
                'Le compromis biais-variance structure ce choix : un modèle '
                    'complexe réduit le biais mais augmente la variance. La '
                    'validation croisée (k-fold) estime honnêtement la '
                    'généralisation en jouant chaque fold comme test.',
                'La régularisation (pénalités L1/L2 sur les poids) et le '
                    'maintien d\'un jeu de test intouchable sont les gardes-fous '
                    'contre l\'auto-illusion ; sans eux, un « 99 % en '
                    'entraînement » ne veut rien dire.',
              ],
              examples: const [
                Example(
                  title: 'Choisir k par validation croisée',
                  body:
                      'Pour k-NN, on teste k = 1, 3, 5, 7 en 5-fold CV : k=1 '
                      'sur-apprend (variance énorme, bruit), k=7 donne le '
                      'meilleur score de généralisation retenu.',
                ),
              ],
              exercises: [
                Exercise(
                  id: '$code-s1u2l2-e1',
                  type: ExerciseType.qcm,
                  prompt:
                      'Un modèle à 99 % en entraînement mais 60 % en test '
                      'souffre surtout de :',
                  options: const [
                    ExerciseOption(id: 'a', text: 'Sous-apprentissage'),
                    ExerciseOption(
                      id: 'b',
                      text: 'Surapprentissage',
                      correct: true,
                    ),
                    ExerciseOption(id: 'c', text: 'Manque de variables'),
                    ExerciseOption(id: 'd', text: 'Trop de données'),
                  ],
                  explanation:
                      'L\'écart entraînement/test signale un modèle qui '
                      'a mémorisé le bruit : c\'est l\'overfitting.',
                ),
                Exercise(
                  id: '$code-s1u2l2-e2',
                  type: ExerciseType.textInput,
                  prompt:
                      'Quelle technique découpe les données en plis pour '
                      'estimer la généralisation ? (deux mots)',
                  acceptedAnswers: const [
                    'validation croisée',
                    'cross validation',
                    'k-fold',
                  ],
                  expectedAnswer: 'validation croisée',
                  explanation:
                      'La validation croisée (k-fold) alterne '
                      'entraînement et test sur chaque plié.',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];
}

// ==================================================================
//  Helpers de construction
// ==================================================================
Semester _sem({
  required String code,
  required int index,
  required List<Unit> units,
}) => Semester(
  id: '$code-s$index',
  courseCode: code,
  index: index,
  label: 'Semestre $index',
  units: units,
);

Unit _unit({
  required String code,
  required int semIndex,
  required int unitIndex,
  required String title,
  required String subtitle,
  required Color color,
  required IconData icon,
  required List<Lesson> lessons,
}) {
  final id = '$code-s$semIndex-u$unitIndex';
  return Unit(
    id: id,
    semesterId: '$code-s$semIndex',
    title: title,
    subtitle: subtitle,
    color: color,
    icon: icon,
    lessons: lessons,
  );
}

Lesson _lesson({
  required String code,
  required int sem,
  required int unit,
  required int lesson,
  required String title,
  required String subtitle,
  required List<String> theory,
  required List<Example> examples,
  required List<Exercise> exercises,
  IconData? icon,
  int xpReward = 25,
}) => Lesson(
  id: '$code-s${sem}u${unit}l$lesson',
  courseCode: code,
  unitId: '$code-s$sem-u$unit',
  title: title,
  subtitle: subtitle,
  theory: theory,
  examples: examples,
  exercises: exercises,
  xpReward: xpReward,
  icon: icon,
);
