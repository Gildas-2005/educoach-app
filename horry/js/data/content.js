/* ==========================================================================
   Contenu pédagogique — porté depuis lib/core/data/learning_content.dart
   (cours phares rédigés à la main) + générateur thématique pour les autres.
   ========================================================================== */

/** Cours phares : unités et leçons entièrement rédigées. */
export const RICH_COURSES = {
  INF301: {
    units: [
      {
        title: 'Diviser pour régner',
        subtitle: 'Décomposer un problème en sous-problèmes indépendants',
        icon: 'layers',
        lessons: [
          {
            title: 'Le principe de récurrence',
            subtitle: "Fonction qui s'appelle elle-même et cas de base",
            minutes: 12,
            theory: [
              "Diviser pour régner, c'est découper un gros problème en plusieurs petits problèmes du même type, les résoudre indépendamment, puis recomposer la réponse. C'est la stratégie derrière le tri fusion, la recherche binaire ou encore l'algorithme d'Euclide étendu.",
              "Une fonction récursive comporte toujours deux éléments : un cas de base (le plus petit input, traité directement) et un cas récursif (qui réduit la taille du problème avant de se rappeler elle-même). Sans cas de base, la pile des appels déborde : c'est le stack overflow.",
              "Au Cameroun, ce schéma apparaît dans beaucoup de situations quotidiennes : organiser un déménagement en sous-tâches par pièce, diviser un champ en parcelles puis chaque parcelle en sillons. L'algorithmique formalise cette habitude.",
            ],
            examples: [
              {
                title: 'Factorielle récursive',
                body: "n! = n × (n-1)! avec 0! = 1. Le cas de base est atteint dès que n == 0 ; chaque appel réduit n de 1.",
                code: 'factoriel(n):\n    si n == 0 alors retourner 1\n    sinon retourner n * factoriel(n - 1)',
                footnote: 'Complexité : O(n) appels, O(n) de profondeur de pile.',
              },
              {
                title: "Somme des éléments d'un tableau",
                body: 'On sépare le tableau en deux moitiés, on somme chaque moitié récursivement, puis on additionne les deux résultats. Même résultat qu’une boucle, mais parallélisable.',
                code: 'somme(T, g, d):\n    si g == d alors retourner T[g]\n    m ← (g + d) / 2\n    retourner somme(T, g, m) + somme(T, m+1, d)',
              },
            ],
            exercises: [
              {
                type: 'qcm',
                prompt: "Que se passe-t-il si une fonction récursive n'a pas de cas de base ?",
                options: [
                  "Elle boucle à l'infini et provoque un débordement de pile",
                  'Elle retourne 0',
                  'Le compilateur la remplace par une boucle for',
                  "Rien, c'est normal",
                ],
                correct: 0,
                explanation: "Sans cas de base, la condition d'arrêt n'est jamais atteinte : chaque appel empile une nouvelle frame jusqu'au StackOverflowError.",
              },
              {
                type: 'trueFalse',
                prompt: 'Tout algorithme récursif peut être réécrit de façon itérative.',
                answer: true,
                explanation: 'Vrai — on peut simuler la pile avec une structure de données explicite. La version itérative est souvent plus efficace en mémoire.',
              },
              {
                type: 'ordering',
                prompt: "Remets les étapes de factoriel(4) dans l'ordre d'exécution :",
                items: ['factoriel(4)', 'factoriel(3)', 'factoriel(2)', 'factoriel(1)', 'factoriel(0) → 1', 'retour 4 × 3 × 2 × 1 = 24'],
                explanation: "On descend jusqu'au cas de base (0! = 1) puis on remonte en multipliant les résultats.",
              },
            ],
          },
          {
            title: 'Tri fusion (merge sort)',
            subtitle: 'Un diviser-pour-régner classique en O(n log n)',
            minutes: 15,
            theory: [
              'Le tri fusion coupe le tableau en deux, trie chaque moitié récursivement, puis fusionne les deux moitiés triées en un seul tableau trié. La fusion est linéaire : on compare les têtes des deux moitiés et on place la plus petite dans la sortie.',
              "Sa complexité est O(n log n) dans tous les cas, ce qui est optimal pour un tri par comparaison. En revanche, il utilise un tableau auxiliaire de taille n — ce n'est pas un tri en place.",
              "Sur un fichier d'un million de notes d'étudiants, un quicksort mal paramétré peut tomber en O(n²) ; merge sort reste garanti O(n log n), donc plus prévisible.",
            ],
            examples: [
              {
                title: 'Fusion de [3, 7] et [1, 5, 9]',
                body: 'On parcourt les deux tableaux avec deux curseurs ; à chaque étape on sort le plus petit des deux éléments courants.',
                code: '[3,7] [1,5,9]\n→ 1 (min 3,1)\n→ 3 (min 3,5)\n→ 5 (min 7,5)\n→ 7 (min 7,9)\n→ 9 (restant)\nrésultat : [1,3,5,7,9]',
              },
            ],
            exercises: [
              {
                type: 'qcm',
                prompt: 'Quelle est la complexité du tri fusion dans le pire des cas ?',
                options: ['O(n)', 'O(n log n)', 'O(n²)', 'O(log n)'],
                correct: 1,
                explanation: 'Le découpage est logarithmique et la fusion linéaire : le coût total est O(n log n) quel que soit l’ordre initial.',
              },
              {
                type: 'trueFalse',
                prompt: 'Le tri fusion est un tri en place.',
                answer: false,
                explanation: 'Il nécessite un tableau auxiliaire de taille n pour la fusion, donc O(n) de mémoire supplémentaire.',
              },
            ],
          },
          {
            title: 'Recherche binaire',
            subtitle: 'Diviser un intervalle trié en deux à chaque étape',
            minutes: 10,
            theory: [
              'La recherche binaire suppose un tableau trié. À chaque étape on compare la valeur cherchée au milieu : si elle est plus grande, on cherche à droite ; plus petite, à gauche. L’intervalle est divisé par deux à chaque itération.',
              'Complexité O(log n) : sur un million d’éléments, 20 comparaisons suffisent. C’est la raison pour laquelle les index de bases de données sont triés.',
            ],
            examples: [
              {
                title: 'Chercher 42 dans 1…1000',
                body: 'On teste 500 → trop grand, 250 → trop petit, 375 → … environ 10 étapes suffisent au lieu de 1000.',
                code: 'chercher(T, x):\n    g ← 0 ; d ← longueur(T) - 1\n    tant que g <= d:\n        m ← (g + d) / 2\n        si T[m] == x alors retourner m\n        si T[m] < x alors g ← m + 1\n        sinon d ← m - 1\n    retourner -1',
                footnote: 'Attention au calcul du milieu : (g + d) / 2 peut déborder sur de très grands entiers.',
              },
            ],
            exercises: [
              {
                type: 'qcm',
                prompt: 'Combien de comparaisons au maximum pour chercher dans un tableau de 1024 éléments triés ?',
                options: ['10', '32', '512', '1024'],
                correct: 0,
                explanation: 'log₂(1024) = 10 : chaque comparaison élimine la moitié des candidats restants.',
              },
            ],
          },
        ],
      },
      {
        title: 'Programmation dynamique',
        subtitle: 'Réutiliser les sous-résultats au lieu de les recalculer',
        icon: 'bolt',
        lessons: [
          {
            title: 'Mémoïsation',
            subtitle: 'Un cache pour les appels récursifs',
            minutes: 14,
            theory: [
              'La programmation dynamique s’applique quand un problème possède des sous-problèmes qui se répètent. On stocke chaque résultat dans une table pour ne le calculer qu’une fois.',
              'Sans mémoïsation, Fibonacci récursif est en O(2ⁿ) ; avec un cache, il devient O(n). La différence est spectaculaire : fib(40) passe de plusieurs minutes à quelques microsecondes.',
            ],
            examples: [
              {
                title: 'Fibonacci mémoïsé',
                body: 'On garde un dictionnaire des valeurs déjà calculées.',
                code: 'memo ← {0: 0, 1: 1}\nfib(n):\n    si n dans memo alors retourner memo[n]\n    memo[n] ← fib(n-1) + fib(n-2)\n    retourner memo[n]',
                footnote: 'Espace O(n) pour le cache, temps O(n).',
              },
            ],
            exercises: [
              {
                type: 'qcm',
                prompt: 'Quel est l’intérêt principal de la mémoïsation ?',
                options: [
                  'Réduire le temps en évitant de recalculer les mêmes sous-problèmes',
                  'Réduire la mémoire utilisée',
                  'Rendre le code plus lisible',
                  'Supprimer la récursion',
                ],
                correct: 0,
                explanation: 'On échange de la mémoire (le cache) contre du temps de calcul.',
              },
            ],
          },
          {
            title: 'Sac à dos (knapsack)',
            subtitle: 'Optimisation sous contrainte : un classique des examens',
            minutes: 18,
            theory: [
              'On dispose d’objets ayant chacun un poids et une valeur, et d’un sac de capacité limitée. Il faut maximiser la valeur transportée. Le problème est NP-difficile en général, mais la version avec des poids entiers se résout en O(n × capacité) par programmation dynamique.',
              'On construit une table où dp[i][c] = meilleure valeur avec les i premiers objets et une capacité c. Chaque case se déduit de deux choix : prendre l’objet ou non.',
            ],
            examples: [
              {
                title: 'Deux objets, capacité 5',
                body: 'Objet A : poids 3, valeur 7. Objet B : poids 4, valeur 9. Avec une capacité de 5, on prend A seul (7) plutôt que B seul (9) ? Non — B passe et vaut 9, A+B ne rentre pas.',
                code: 'dp[i][c] = max(\n  dp[i-1][c],\n  dp[i-1][c - poids[i]] + valeur[i]  // si ça rentre\n)',
              },
            ],
            exercises: [
              {
                type: 'trueFalse',
                prompt: 'Le problème du sac à dos avec poids entiers se résout en temps pseudo-polynomial.',
                answer: true,
                explanation: 'O(n × capacité) est polynomial en la valeur de la capacité, pas en sa taille d’écriture — d’où le terme pseudo-polynomial.',
              },
            ],
          },
        ],
      },
    ],
  },

  ECO101: {
    units: [
      {
        title: 'Offre, demande et équilibre',
        subtitle: 'Le marché comme mécanisme de coordination',
        icon: 'chart',
        lessons: [
          {
            title: 'Équilibre de marché',
            subtitle: 'Où l’offre rencontre la demande',
            minutes: 13,
            theory: [
              'La demande décroît avec le prix : plus un bien est cher, moins on en achète. L’offre croît avec le prix : plus le prix est élevé, plus les producteurs ont intérêt à vendre. Le prix d’équilibre est celui qui égalise les deux quantités.',
              'Un prix supérieur à l’équilibre crée un excédent (invendus) qui pousse le prix à la baisse ; un prix inférieur crée une pénurie qui le pousse à la hausse.',
              'Au Cameroun, le prix du kilo de tomate sur le marché de Mokolo varie fortement entre saison sèche et saison des pluies : c’est exactement ce mécanisme d’ajustement.',
            ],
            examples: [
              {
                title: 'Résolution chiffrée',
                body: 'Demande : Qd = 200 − 2P. Offre : Qo = 50 + 3P. À l’équilibre Qd = Qo.',
                code: '200 − 2P = 50 + 3P\n150 = 5P\nP* = 30 FCFA\nQ* = 200 − 60 = 140 kg',
                footnote: 'Une taxe de 5 FCFA/kg déplace l’offre et réduit la quantité échangée.',
              },
            ],
            exercises: [
              {
                type: 'qcm',
                prompt: 'Si le prix est fixé au-dessus du prix d’équilibre, que se passe-t-il ?',
                options: ['Une pénurie', 'Un excédent (offre > demande)', 'Un équilibre stable', 'Une hausse de la demande'],
                correct: 1,
                explanation: 'À un prix élevé, les producteurs offrent plus que les consommateurs ne demandent : il reste des invendus.',
              },
              {
                type: 'textInput',
                prompt: 'Avec Qd = 100 − P et Qo = 20 + 2P, quel est le prix d’équilibre (en FCFA) ?',
                accept: ['26,67', '26.67', '26,7', '26.7', '80/3'],
                explanation: '100 − P = 20 + 2P → 3P = 80 → P ≈ 26,67 FCFA.',
              },
            ],
          },
          {
            title: 'Élasticité-prix',
            subtitle: 'La sensibilité de la demande au prix',
            minutes: 11,
            theory: [
              'L’élasticité-prix mesure la variation relative de la quantité demandée pour une variation relative du prix : e = (ΔQ/Q) / (ΔP/P). Une demande élastique (|e| > 1) réagit fortement ; inélastique (|e| < 1), faiblement.',
              'Les biens de première nécessité (sel, médicaments essentiels) ont une demande inélastique. Les produits de luxe ou substituables sont élastiques.',
            ],
            examples: [
              {
                title: 'Carburant à la pompe',
                body: 'Le prix du super passe de 750 à 825 FCFA (+10 %) et la consommation baisse de 3 %. L’élasticité vaut −0,3 : demande inélastique.',
                code: 'e = (−3 %) / (+10 %) = −0,3',
              },
            ],
            exercises: [
              {
                type: 'qcm',
                prompt: 'Une élasticité de −2,5 signifie que la demande est…',
                options: ['Inélastique', 'Élastique', 'Parfaitement rigide', 'Unitaire'],
                correct: 1,
                explanation: '|−2,5| > 1 : la quantité varie proportionnellement plus que le prix.',
              },
            ],
          },
        ],
      },
      {
        title: 'Inflation et politique monétaire',
        subtitle: 'Mesurer et contenir la hausse des prix',
        icon: 'globe',
        lessons: [
          {
            title: 'Mesurer l’inflation',
            subtitle: 'Indice des prix et panier de consommation',
            minutes: 12,
            theory: [
              'L’inflation est la hausse généralisée et durable des prix, mesurée par la variation d’un indice des prix à la consommation construit sur un panier représentatif.',
              'Un taux d’inflation de 5 % signifie qu’un panier qui coûtait 100 FCFA en base coûte 105 FCFA cette année. Les causes typiques : excès de demande, hausse des coûts, ou création monétaire excessive.',
              'Dans la zone CEMAC, la BEAC conduit la politique monétaire et la monnaie est indexée sur l’euro via le FCFA, ce qui limite fortement l’inflation importée.',
            ],
            examples: [
              {
                title: 'Indice simple',
                body: 'Panier 2024 : 200 FCFA, panier 2025 : 210 FCFA.',
                code: 'Inflation = (210 − 200) / 200 × 100 = 5 %',
              },
            ],
            exercises: [
              {
                type: 'trueFalse',
                prompt: 'Une hausse du prix d’un seul bien suffit à parler d’inflation.',
                answer: false,
                explanation: 'L’inflation est généralisée : une hausse isolée est une variation de prix relatif, pas de l’inflation.',
              },
            ],
          },
        ],
      },
    ],
  },

  DRP201: {
    units: [
      {
        title: 'Introduction au droit civil',
        subtitle: 'Personnes, biens et obligations',
        icon: 'shield',
        lessons: [
          {
            title: 'La personnalité juridique',
            subtitle: 'Naissance, capacité et représentation',
            minutes: 12,
            theory: [
              'La personnalité juridique est l’aptitude à être titulaire de droits et d’obligations. Elle s’acquiert à la naissance, à condition de naître vivant et viable, et s’éteint au décès.',
              'La capacité d’exercice est la possibilité de faire soi-même les actes de la vie civile. Un mineur non émancipé est titulaire de droits mais ne peut, en principe, les exercer seul : il agit par l’intermédiaire de son représentant légal.',
            ],
            examples: [
              {
                title: 'Un mineur achète un téléphone',
                body: 'L’acte est un acte de la vie courante : il est valable s’il est conclu à des conditions normales. Un crédit de 500 000 FCFA, en revanche, excède les actes de la vie courante et peut être annulé.',
                footnote: 'La distinction vie courante / hors vie courante est un classique d’examen.',
              },
            ],
            exercises: [
              {
                type: 'qcm',
                prompt: 'La personnalité juridique s’acquiert en principe…',
                options: ['À la majorité', 'À la naissance si l’enfant naît vivant et viable', 'Au mariage', 'À l’inscription à l’état civil'],
                correct: 1,
                explanation: 'L’inscription à l’état civil constate la naissance, elle ne la conditionne pas.',
              },
            ],
          },
          {
            title: 'La responsabilité civile',
            subtitle: 'Faute, dommage et lien de causalité',
            minutes: 16,
            theory: [
              'Trois conditions cumulatives : une faute (ou un fait générateur), un dommage certain, et un lien de causalité entre les deux. L’absence d’un seul élément fait tomber l’action.',
              'La responsabilité peut être contractuelle (inexécution d’un contrat) ou délictuelle (dommage causé hors contrat). Les régimes spéciaux — produits défectueux, accidents de la circulation — allègent la preuve pour la victime.',
            ],
            examples: [
              {
                title: 'Litige de 5 millions FCFA',
                body: 'Un transporteur livre une marchandise avec deux jours de retard ; le client subit une pénalité contractuelle. Il faut prouver le retard, le dommage chiffré et le lien entre les deux.',
              },
            ],
            exercises: [
              {
                type: 'qcm',
                prompt: 'Quels éléments sont nécessaires à la responsabilité civile délictuelle ?',
                options: ['Faute, dommage, lien de causalité', 'Contrat et préjudice', 'Intention et dol', 'Preuve écrite et témoins'],
                correct: 0,
                explanation: 'Ce sont les trois conditions classiques de l’article fondateur de la responsabilité délictuelle.',
              },
            ],
          },
        ],
      },
    ],
  },

  INF102: {
    units: [
      {
        title: 'Structures de données de base',
        subtitle: 'Tableaux, listes, piles et files',
        icon: 'layers',
        lessons: [
          {
            title: 'Tableaux et complexité',
            subtitle: 'Accès direct, insertion coûteuse',
            minutes: 12,
            theory: [
              'Un tableau stocke des éléments contigus en mémoire : l’accès à l’indice i est immédiat (O(1)). En revanche, insérer au milieu impose de décaler les éléments suivants (O(n)).',
              'Le choix d’une structure dépend du profil d’usage : beaucoup de lectures → tableau ; beaucoup d’insertions/suppressions en tête → liste chaînée.',
            ],
            examples: [
              {
                title: 'Coût d’une insertion',
                body: 'Dans un tableau de 10 000 éléments, insérer en position 0 déplace 10 000 éléments. Insérer à la fin ne déplace rien (si la capacité le permet).',
                code: 'T.insert(0, x)  → O(n)\nT.append(x)      → O(1) amorti',
              },
            ],
            exercises: [
              {
                type: 'qcm',
                prompt: 'Quelle est la complexité de l’accès à T[i] dans un tableau ?',
                options: ['O(1)', 'O(log n)', 'O(n)', 'O(n log n)'],
                correct: 0,
                explanation: 'L’adresse se calcule directement : adresse de base + i × taille d’un élément.',
              },
            ],
          },
          {
            title: 'Piles et files',
            subtitle: 'LIFO contre FIFO',
            minutes: 10,
            theory: [
              'Une pile (stack) fonctionne en LIFO : le dernier entré sort le premier. Une file (queue) fonctionne en FIFO : le premier entré sort le premier.',
              'Les piles servent à la récursion, à l’historique (undo) et à l’évaluation d’expressions. Les files servent à l’ordonnancement, aux parcours en largeur et aux buffers de messages.',
            ],
            examples: [
              {
                title: 'Parcours en largeur d’un graphe',
                body: 'On enfile les voisins non visités, puis on les dépile un par un — c’est ce qui garantit l’ordre par distance.',
                code: 'file ← [départ]\ntant que file non vide:\n    u ← file.défiler()\n    pour v dans voisins(u):\n        si v non visité: visiter(v) ; file.enfiler(v)',
              },
            ],
            exercises: [
              {
                type: 'trueFalse',
                prompt: 'Une file est une structure LIFO.',
                answer: false,
                explanation: 'Une file est FIFO. C’est la pile qui est LIFO.',
              },
            ],
          },
        ],
      },
    ],
  },

  MED201: {
    units: [
      {
        title: 'Sémiologie clinique',
        subtitle: 'Recueillir les signes et construire l’hypothèse',
        icon: 'shield',
        lessons: [
          {
            title: 'Interrogatoire et symptômes',
            subtitle: 'L’anamnèse comme première étape du raisonnement',
            minutes: 14,
            theory: [
              'L’interrogatoire recueille le motif de consultation, l’histoire de la maladie, les antécédents, les traitements et le contexte social. Il oriente déjà 70 % des diagnostics.',
              'On caractérise chaque symptôme par son début, son siège, son type, son intensité, ses facteurs déclenchants et son évolution. Une douleur thoracique n’a pas la même valeur selon qu’elle est constrictive à l’effort ou punctiforme à l’inspiration.',
            ],
            examples: [
              {
                title: 'Douleur thoracique',
                body: 'Constrictive, irradiant au bras gauche, déclenchée par l’effort et soulagée par le repos : évocatrice d’angor. Majorée par l’inspiration et la toux : plutôt péricardique ou pleurale.',
              },
            ],
            exercises: [
              {
                type: 'qcm',
                prompt: 'Quel élément fait partie de l’anamnèse ?',
                options: ['Les antécédents médicaux', 'Le résultat de la radiographie', 'Le bilan sanguin', 'L’électrocardiogramme'],
                correct: 0,
                explanation: 'L’anamnèse est l’histoire racontée par le patient ; les examens viennent ensuite.',
              },
            ],
          },
        ],
      },
    ],
  },

  INF330: {
    units: [
      {
        title: 'Sécurité applicative',
        subtitle: 'Menaces web et contre-mesures',
        icon: 'shield',
        lessons: [
          {
            title: 'Injection SQL',
            subtitle: 'Quand une donnée devient du code',
            minutes: 13,
            theory: [
              'Une injection SQL survient quand une entrée utilisateur est concaténée dans une requête. L’attaquant peut lire, modifier ou supprimer des données, voire exécuter des commandes.',
              'La seule défense fiable est la requête paramétrée : la base traite la valeur comme une donnée, jamais comme du code. Les échappements maison et les listes noires sont contournables.',
            ],
            examples: [
              {
                title: 'Requête vulnérable vs paramétrée',
                body: 'La version concaténée accepte une entrée qui ferme la chaîne et ajoute une condition toujours vraie.',
                code: "// vulnérable\n\"SELECT * FROM users WHERE email = '\" + email + \"'\"\n\n// sûr\nquery('SELECT * FROM users WHERE email = $1', [email])",
                footnote: 'Même principe pour les commandes shell, LDAP, XML, ORM mal utilisés.',
              },
            ],
            exercises: [
              {
                type: 'qcm',
                prompt: 'Quelle est la protection principale contre l’injection SQL ?',
                options: ['Les requêtes paramétrées', 'Masquer les messages d’erreur', 'Un pare-feu', 'Chiffrer la base'],
                correct: 0,
                explanation: 'Les paramètres séparent code et données ; le reste est de la défense en profondeur.',
              },
              {
                type: 'trueFalse',
                prompt: 'Échapper les apostrophes suffit à bloquer toute injection SQL.',
                answer: false,
                explanation: 'Les encodages, les commentaires SQL et les requêtes numériques permettent de contourner un échappement artisanal.',
              },
            ],
          },
          {
            title: 'Mots de passe : hachage et sel',
            subtitle: 'Pourquoi bcrypt et pas SHA-256',
            minutes: 12,
            theory: [
              'Un mot de passe ne se chiffre pas, il se hache. On y ajoute un sel aléatoire par utilisateur pour que deux mots de passe identiques produisent des empreintes différentes.',
              'Les fonctions rapides (SHA-256, MD5) sont vulnérables au cassage par GPU. Il faut une fonction lente et paramétrable : bcrypt, scrypt ou Argon2.',
            ],
            examples: [
              {
                title: 'Vérification',
                body: 'On ne compare jamais les mots de passe en clair : on recalcule le hachage et on compare les empreintes.',
                code: 'hash = bcrypt.hash(password, 12)\nok   = bcrypt.compare(saisie, hash)',
                footnote: '12 tours ≈ 250 ms : imperceptible pour un humain, ruineux pour un attaquant.',
              },
            ],
            exercises: [
              {
                type: 'qcm',
                prompt: 'Pourquoi ajouter un sel aux mots de passe ?',
                options: [
                  'Empêcher les tables de correspondance précalculées',
                  'Accélérer la vérification',
                  'Compresser le stockage',
                  'Chiffrer la base',
                ],
                correct: 0,
                explanation: 'Le sel rend chaque empreinte unique : une rainbow table devient inutilisable.',
              },
            ],
          },
        ],
      },
    ],
  },
};

/* --------------------------------------------------- Générateur thématique */
const THEMES = {
  'Sciences & Technologies': [
    ['Modélisation', 'Traduire un phénomène réel en modèle calculable', ['Un modèle est une simplification assumée : on garde les variables qui expliquent l’essentiel et on ignore le reste.', 'La validation compare les prédictions du modèle aux mesures. Un modèle non validé reste une hypothèse.']],
    ['Mesure et incertitude', 'Chiffrer ce qu’on ignore', ['Toute mesure porte une incertitude : instrument, opérateur, conditions.', 'On écrit un résultat sous la forme x ± u, avec u l’incertitude élargie.']],
    ['Optimisation', 'Faire mieux sous contrainte', ['Optimiser, c’est maximiser un objectif sous des contraintes de ressources.', 'Un optimum local n’est pas toujours global : il faut vérifier la convexité ou explorer plusieurs départs.']],
  ],
  'Sciences fondamentales': [
    ['Raisonnement formel', 'Définitions, hypothèses, démonstration', ['Une démonstration part des hypothèses et applique des règles explicites jusqu’à la conclusion.', 'Un contre-exemple suffit à réfuter une proposition universelle.']],
    ['Structures et invariants', 'Ce qui ne change pas quand tout change', ['Un invariant est une propriété conservée par transformation.', 'Repérer l’invariant simplifie souvent radicalement un problème.']],
    ['Estimation', 'Ordres de grandeur et asymptotiques', ['Avant le calcul exact, l’estimation donne le comportement dominant.', 'Les ordres de grandeur évitent les erreurs de facteur 1000.']],
  ],
  'Sciences de la Vie': [
    ['Observation', 'Du terrain au protocole', ['L’observation précède l’hypothèse ; le protocole la teste.', 'Un échantillon non représentatif invalide la conclusion, même avec de bons calculs.']],
    ['Mécanismes', 'Relier structure et fonction', ['En biologie, la fonction découle de la structure à toutes les échelles.', 'Les boucles de rétroaction maintiennent l’homéostasie.']],
    ['Évolution', 'Variation, sélection, transmission', ['La variation précède la sélection : elle n’est pas dirigée par le besoin.', 'La dérive génétique explique les changements sans avantage sélectif.']],
  ],
  'Sciences de la Santé': [
    ['Démarche clinique', 'Du symptôme au diagnostic raisonné', ['Le diagnostic se construit par hypothèses successives, chacune testée par un examen pertinent.', 'Un examen n’a de valeur que si sa sensibilité et sa spécificité sont connues dans ce contexte.']],
    ['Prévention', 'Réduire le risque avant la maladie', ['La prévention primaire agit avant la maladie, secondaire avant les complications.', 'L’observance est le principal déterminant d’efficacité d’un traitement chronique.']],
    ['Éthique du soin', 'Consentement et proportionnalité', ['Le consentement éclairé est un préalable, pas une formalité.', 'La proportionnalité des soins arbitre bénéfice et charge.']],
  ],
  'Sciences économiques': [
    ['Arbitrage', 'Coût d’opportunité et incitations', ['Chaque choix a un coût d’opportunité : la meilleure alternative abandonnée.', 'Les incitations modifient les comportements, souvent de façon imprévue.']],
    ['Marchés', 'Concurrence et défaillances', ['La concurrence pure et parfaite suppose atomicité, homogénéité, information parfaite et libre entrée.', 'Externalités et biens publics justifient l’intervention publique.']],
    ['Macroéconomie', 'Croissance, inflation, chômage', ['La croissance mesurée par le PIB ignore l’informel et les inégalités.', 'Le chômage structurel ne se résorbe pas par la seule demande.']],
  ],
  'Sciences juridiques': [
    ['Qualification', 'Nommer juridiquement les faits', ['Qualifier, c’est rattacher un fait à une catégorie juridique pour lui appliquer ses règles.', 'Une mauvaise qualification entraîne l’application du mauvais régime.']],
    ['Sources du droit', 'Hiérarchie des normes', ['Constitution, traités, lois, règlements, jurisprudence : la hiérarchie tranche les conflits.', 'Le juge ne crée pas la loi mais son interprétation fait jurisprudence.']],
    ['Preuve', 'Charge et moyens', ['La charge de la preuve pèse en principe sur le demandeur.', 'L’écrit est exigé pour certains actes ; le témoignage suffit ailleurs.']],
  ],
  'Sciences sociales': [
    ['Enquête', 'Échantillon, biais, causalité', ['Corrélation n’est pas causalité : un troisième facteur peut expliquer les deux.', 'Un échantillon aléatoire permet d’inférer sur la population.']],
    ['Institutions', 'Règles et coordination', ['Les institutions réduisent l’incertitude en fixant des règles du jeu.', 'Une norme informelle peut être plus contraignante qu’une loi.']],
    ['Terrain', 'Observer sans transformer', ['L’observation participante enrichit mais risque la réification.', 'La position du chercheur fait partie des données.']],
  ],
  'Sciences humaines': [
    ['Interprétation', 'Sens et contexte', ['Comprendre un texte, c’est le situer dans son contexte de production.', 'L’anachronisme consiste à projeter des catégories actuelles sur le passé.']],
    ['Argumentation', 'Thèse, thèse adverse, preuve', ['Un bon argument expose la thèse adverse avant de la réfuter.', 'Un exemple illustre, il ne démontre pas.']],
    ['Méthode', 'Sources et critique', ['Toute source est située : il faut en établir l’auteur, la date et l’intention.', 'La critique externe vérifie l’authenticité ; la critique interne, la cohérence.']],
  ],
  'Lettres & Langues': [
    ['Analyse textuelle', 'Forme et fond', ['Le commentaire relie procédés formels et effets de sens.', 'Nommer un procédé sans en expliquer l’effet ne vaut rien.']],
    ['Expression', 'Clarté, syntaxe, registre', ['Une phrase claire a un sujet, un verbe, un complément identifiable.', 'Le registre doit rester constant dans un même texte.']],
    ['Traduction', 'Fidélité et équivalence', ['Traduire, c’est restituer un effet, pas des mots.', 'Les faux amis et les idiomes révèlent les limites du mot à mot.']],
  ],
  'Sciences du sport': [
    ['Physiologie', 'Filières énergétiques', ['Effort bref et intense : filière anaérobie alactique. Effort long : aérobie.', 'La récupération fait partie de l’entraînement.']],
    ['Entraînement', 'Charge, récupération, adaptation', ['La surcharge progressive déclenche l’adaptation ; l’excès mène au surentraînement.', 'La spécificité impose de s’entraîner dans les conditions de la compétition.']],
    ['Motricité', 'Apprentissage et feedback', ['Le feedback externe accélère l’apprentissage moteur.', 'La variabilité des exercices améliore le transfert.']],
  ],
  Éducation: [
    ['Didactique', 'Transposition et obstacles', ['La transposition didactique transforme un savoir savant en savoir enseignable.', 'Les conceptions initiales des élèves sont des obstacles à identifier.']],
    ['Évaluation', 'Diagnostique, formative, sommative', ['L’évaluation formative informe l’élève pendant l’apprentissage.', 'Une évaluation valide mesure ce qu’elle prétend mesurer.']],
    ['Classe', 'Gestion et différenciation', ['Différencier, c’est varier les chemins vers un même objectif.', 'Les consignes floues produisent des malentendus durables.']],
  ],
};

const EXERCISE_SEEDS = [
  {
    type: 'qcm',
    prompt: 'Quelle affirmation résume le mieux la notion « {theme} » ?',
    options: [
      'Elle structure le raisonnement en posant un cadre explicite',
      'Elle ne sert qu’aux exercices scolaires',
      'Elle est vraie uniquement en laboratoire',
      'Elle remplace la vérification empirique',
    ],
    correct: 0,
    explanation: 'Le cadre explicite évite les raisonnements implicites non contrôlés — c’est tout l’intérêt de la notion.',
  },
  {
    type: 'trueFalse',
    prompt: 'Dans « {theme} », une erreur de méthode invalide la conclusion, même si le résultat final est correct.',
    answer: true,
    explanation: 'Un résultat juste obtenu par un raisonnement faux ne démontre rien : c’est l’erreur classique en évaluation.',
  },
  {
    type: 'ordering',
    prompt: 'Remets les étapes d’une démarche correcte sur « {theme} » :',
    items: [
      'Identifier la question posée',
      'Explorer les connaissances existantes',
      'Formuler une hypothèse testable',
      'Confronter l’hypothèse aux faits',
      'Conclure et discuter les limites',
    ],
    explanation: 'La démarche scientifique est itérative, mais cet ordre reste la colonne vertébrale.',
  },
];

/** Construit un parcours de cours (cours phare ou généré). */
export function buildPath(course, filiere) {
  const rich = RICH_COURSES[course.code];
  if (rich) {
    return rich.units.map((unit, ui) => ({
      id: `${course.code}-s1-u${ui + 1}`,
      semester: 1,
      title: `Unité ${roman(ui + 1)} · ${unit.title}`,
      subtitle: unit.subtitle,
      icon: unit.icon,
      lessons: unit.lessons.map((lesson, li) => ({
        ...lesson,
        id: `${course.code}-s1-u${ui + 1}-l${li + 1}`,
        unitId: `${course.code}-s1-u${ui + 1}`,
        xp: 25 + li * 5,
      })),
    }));
  }

  const themes = THEMES[filiere?.domain] || THEMES['Sciences & Technologies'];
  const units = [];
  const unitCount = 4;
  for (let u = 0; u < unitCount; u++) {
    const [label, blurb, paragraphs] = themes[u % themes.length];
    const lessons = [];
    for (let l = 0; l < 3; l++) {
      const seed = EXERCISE_SEEDS[l % EXERCISE_SEEDS.length];
      lessons.push({
        id: `${course.code}-s1-u${u + 1}-l${l + 1}`,
        unitId: `${course.code}-s1-u${u + 1}`,
        title: ['Fondamentaux', 'Approfondissement', 'Application guidée'][l] + ` · ${label}`,
        subtitle: blurb,
        minutes: 9 + l * 3,
        xp: 20 + l * 5,
        theory: [
          paragraphs[l % paragraphs.length],
          `Dans le cadre de « ${course.title} », cette notion se travaille sur des situations concrètes : on part d’un cas réel, on explicite les étapes, puis on vérifie le résultat.`,
          paragraphs[(l + 1) % paragraphs.length],
        ],
        examples: [
          {
            title: `Cas pratique — ${label}`,
            body: `Application directe à ${course.title.toLowerCase()} : identifier les données, choisir la méthode, vérifier la cohérence du résultat.`,
            code: `données → méthode → vérification\ncas : ${course.title}\nenseignant : ${course.teacher}`,
            footnote: `Volume horaire hebdomadaire : ${course.weeklyHours}h · ${course.credits} crédits.`,
          },
        ],
        exercises: [
          {
            type: seed.type,
            prompt: seed.prompt.replace('{theme}', label.toLowerCase()),
            options: seed.options,
            correct: seed.correct,
            answer: seed.answer,
            items: seed.items,
            accept: seed.accept,
            explanation: seed.explanation,
          },
        ],
      });
    }
    units.push({
      id: `${course.code}-s1-u${u + 1}`,
      semester: 1,
      title: `Unité ${roman(u + 1)} · ${label}`,
      subtitle: blurb,
      icon: ['layers', 'bolt', 'target', 'graduation'][u],
      lessons,
    });
  }
  return units;
}

const ROMAN = ['', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];
export function roman(n) { return ROMAN[n] || String(n); }

/* ------------------------------------------------------------------ Devoirs */
export function buildHomework(course, units) {
  return units.slice(0, 2).map((unit, i) => {
    const lesson = unit.lessons[unit.lessons.length - 1];
    return {
      id: `${course.code}-hw${i + 1}`,
      courseCode: course.code,
      title: `Devoir ${roman(i + 1)} · ${lesson.title}`,
      instruction: `Révise la leçon « ${lesson.title} » puis traite les exercices ci-dessous. Tu disposes de 7 jours ; la correction détaillée s'affichera après la validation.`,
      due: Date.now() + (4 + i * 2) * 86400000,
      points: 20,
      exercises: lesson.exercises,
    };
  });
}

/* ------------------------------------------------------------ Abonnements */
export const PLANS = [
  { tier: 'discovery', label: 'Découverte', monthly: 0, yearly: 0, icon: 'graduation',
    perks: ['Accès complet aux parcours de cours', 'Planning et notes', 'Chat avec les professeurs'] },
  { tier: 'premium', label: 'Premium', monthly: 2500, yearly: 25000, icon: 'star', featured: true,
    perks: ['Tout Découverte, plus :', 'Examens blancs illimités', 'Correction prioritaire par les profs', 'Statistiques avancées de progression'] },
  { tier: 'excellence', label: 'Excellence', monthly: 5000, yearly: 50000, icon: 'trophy',
    perks: ['Tout Premium, plus :', 'Coach individuel (sessions 1-to-1)', 'Sessions live en petit groupe', 'Badge Excellence sur ton profil'] },
];

export const PAYMENT_METHODS = [
  { id: 'mtnMoMo', label: 'MTN MoMo', hint: 'Confirmation via #126# sur ton téléphone', short: 'MoMo', color: '#ffcb05', fg: '#1a1a1a' },
  { id: 'orangeMoney', label: 'Orange Money', hint: 'Confirmation via *354# sur ton téléphone', short: 'OM', color: '#ff7900', fg: '#fff' },
  { id: 'visaCard', label: 'Carte Visa', hint: 'Paiement sécurisé 3-D Secure', short: 'VISA', color: '#1a1f71', fg: '#fff' },
];

/* -------------------------------------------------------------------- Chat */
export const CHAT_ROOMS = [
  { id: 'r1', name: 'Promo L3 Informatique', kind: 'group', members: 48,
    messages: [
      { author: 'Dr. S. Fall', teacher: true, body: 'Rappel : le TP de réseaux est reporté à jeudi 14h, salle Lab. Réseau.', at: Date.now() - 7200000 },
      { author: 'Awa D.', body: 'Merci ! Est-ce que le rapport reste à rendre vendredi ?', at: Date.now() - 6800000 },
      { author: 'Dr. S. Fall', teacher: true, body: 'Oui, vendredi 18h au plus tard, en PDF.', at: Date.now() - 6600000 },
    ] },
  { id: 'r2', name: 'Algorithmique avancée', kind: 'group', members: 32,
    messages: [
      { author: 'Pr. M. Diallo', teacher: true, body: 'Les corrections du devoir 2 sont en ligne. Relisez la question 3, beaucoup d’erreurs de récurrence.', at: Date.now() - 86400000 },
    ] },
  { id: 'r3', name: 'Pr. M. Diallo', kind: 'direct', members: 2,
    messages: [
      { author: 'Moi', body: 'Bonjour professeur, je bloque sur l’exercice 4 du TD.', at: Date.now() - 172800000 },
      { author: 'Pr. M. Diallo', teacher: true, body: 'Commence par écrire l’invariant de boucle, on en reparle en TD.', at: Date.now() - 170000000 },
    ] },
  { id: 'r4', name: 'Entraide éco & droit', kind: 'group', members: 76,
    messages: [
      { author: 'Fatou S.', body: 'Quelqu’un a les annales de droit civil 2023 ?', at: Date.now() - 300000000 },
      { author: 'Ibrahim K.', body: 'Je les ai scannées, je dépose ce soir.', at: Date.now() - 290000000 },
    ] },
];

/* ------------------------------------------------------------------- Légal */
export const LEGAL = {
  terms: {
    title: "Conditions générales d'utilisation",
    updated: '12 octobre 2026',
    version: '3.1',
    sections: [
      { title: '1. Objet', paragraphs: ["Educoach est une plateforme d’accompagnement pédagogique destinée aux étudiants de l’enseignement supérieur. L’accès aux parcours, au planning, aux notes et à la messagerie suppose la création d’un compte."] },
      { title: '2. Compte et sécurité', paragraphs: ["Tu es responsable de la confidentialité de tes identifiants. Toute activité réalisée depuis ton compte t’est attribuée jusqu’à notification d’un accès non autorisé.", "Un compte enseignant est créé en attente de validation ; un compte administrateur ne peut jamais être créé depuis l’inscription publique."] },
      { title: '3. Contenus', paragraphs: ["Les contenus pédagogiques sont fournis pour un usage personnel d’apprentissage. La reproduction, la revente ou la diffusion publique sans autorisation sont interdites."] },
      { title: '4. Abonnements et paiement', paragraphs: ["Le palier Découverte est gratuit. Les paliers Premium et Excellence sont facturés mensuellement ou annuellement en FCFA. Aucun numéro de carte complet ni cryptogramme n’est stocké : seul un masque court est conservé pour le reçu."] },
      { title: '5. Résiliation', paragraphs: ["Tu peux résilier à tout moment depuis ton profil ; l’accès au palier payant reste actif jusqu’à la fin de la période en cours."] },
      { title: '6. Droit applicable', paragraphs: ["Les présentes conditions sont soumises au droit camerounais. En cas de litige, une solution amiable sera recherchée avant toute action judiciaire."] },
    ],
  },
  privacy: {
    title: 'Politique de confidentialité',
    updated: '12 octobre 2026',
    version: '3.1',
    sections: [
      { title: '1. Données collectées', paragraphs: ["Nom, adresse e-mail, filière et niveau, progression pédagogique, messages échangés et historique d’abonnement. Aucune donnée de localisation précise n’est collectée."] },
      { title: '2. Finalités', paragraphs: ["Personnaliser les parcours, afficher ton planning et tes notes, permettre la messagerie, gérer les abonnements et améliorer la qualité pédagogique."] },
      { title: '3. Base légale', paragraphs: ["Exécution du contrat pour les données nécessaires au service ; consentement pour les notifications et les statistiques d’usage ; intérêt légitime pour la sécurité des comptes."] },
      { title: '4. Durée de conservation', paragraphs: ["Compte actif : pendant la durée d’utilisation. Après suppression : 30 jours de rétention technique, puis effacement définitif, hors obligations comptables."] },
      { title: '5. Tes droits', paragraphs: ["Accès, rectification, effacement, limitation, opposition et portabilité. Les demandes sont traitées sous 30 jours depuis ton profil, section Confidentialité."] },
      { title: '6. Sécurité', paragraphs: ["Mots de passe hachés avec sel (bcrypt), sessions par jetons à durée limitée, chiffrement des échanges en HTTPS, accès aux données limité par rôle."] },
    ],
  },
};

export const PERMISSIONS = [
  { id: 'notifications', icon: 'bell', title: 'Notifications de cours', body: 'Rappels de séances, nouveaux devoirs et corrections.' },
  { id: 'calendar', icon: 'calendar', title: 'Synchronisation du planning', body: 'Ajouter tes séances à ton calendrier pour ne rien manquer.' },
  { id: 'analytics', icon: 'chart', title: 'Statistiques anonymes', body: 'Nous aider à améliorer les parcours, sans donnée personnelle.' },
];

/* ------------------------------------------- Données enseignants / admin */
export const TEACHER_SUBMISSIONS = [
  { student: 'Awa Diop', course: 'INF301', title: 'Devoir II · Tri fusion', at: Date.now() - 5400000, status: 'à corriger' },
  { student: 'Ibrahim Kane', course: 'INF102', title: 'Devoir I · Complexité', at: Date.now() - 10800000, status: 'à corriger' },
  { student: 'Fatou Sow', course: 'INF301', title: 'Devoir II · Tri fusion', at: Date.now() - 86400000, status: 'corrigé' },
  { student: 'Moussa Ba', course: 'INF330', title: 'Devoir I · Injection SQL', at: Date.now() - 172800000, status: 'à corriger' },
];

export const TEACHER_STUDENTS = [
  { name: 'Awa Diop', progress: 82, xp: 3120, risk: false },
  { name: 'Ibrahim Kane', progress: 58, xp: 1980, risk: true },
  { name: 'Fatou Sow', progress: 74, xp: 2640, risk: false },
  { name: 'Moussa Ba', progress: 41, xp: 1220, risk: true },
  { name: 'Ndeye Fall', progress: 91, xp: 3980, risk: false },
  { name: 'Oumar Sy', progress: 66, xp: 2210, risk: false },
];

export const ADMIN_ACCOUNTS = [
  { name: 'Awa Diop', email: 'awa.diop@edu.cm', role: 'student', status: 'active', since: '2026-02-14' },
  { name: 'Pr. M. Diallo', email: 'm.diallo@edu.cm', role: 'teacher', status: 'active', since: '2025-09-02' },
  { name: 'Ibrahim Kane', email: 'i.kane@edu.cm', role: 'student', status: 'active', since: '2026-03-08' },
  { name: 'Dr. S. Fall', email: 's.fall@edu.cm', role: 'teacher', status: 'pending', since: '2026-10-21' },
  { name: 'Moussa Ba', email: 'm.ba@edu.cm', role: 'student', status: 'blocked', since: '2026-01-19' },
  { name: 'Admin Educoach', email: 'admin@edu.cm', role: 'admin', status: 'active', since: '2025-06-01' },
];

export const ADMIN_ACTIVITY = [
  { label: 'Nouvelle inscription étudiante', detail: 'Ndeye Fall · L2 Droit', at: Date.now() - 600000 },
  { label: 'Cours publié', detail: 'INF330 · Sécurité applicative', at: Date.now() - 5400000 },
  { label: 'Demande de validation enseignant', detail: 'Dr. S. Fall', at: Date.now() - 14400000 },
  { label: 'Abonnement Premium souscrit', detail: 'Awa Diop · 2 500 FCFA/mois', at: Date.now() - 86400000 },
  { label: 'Export de données RGPD', detail: 'Ibrahim Kane · 1 fichier', at: Date.now() - 172800000 },
  { label: 'Compte bloqué', detail: 'Moussa Ba · motif : usurpation', at: Date.now() - 259200000 },
];
