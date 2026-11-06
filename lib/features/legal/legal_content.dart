import 'legal_document_page.dart';

/// Version du texte, à faire progresser à chaque modification matérielle.
const _termsVersion = '1.0';
const _privacyVersion = '1.0';

/// Conditions Générales d'Utilisation d'Educoach, rédigées pour le cadre
/// juridique camerounais (Loi n° 2010/012 du 21 décembre 2010 relative à
/// la cybersécurité et à la prévention de la cybercriminalité — Livre V)
/// et alignées sur les meilleures pratiques internationales (RGPD pour
/// les étudiants résidant dans l'UE/EEE).
final termsDocument = LegalDocument(
  routeName: '/legal/terms',
  title: 'Conditions générales',
  subtitle:
      'Contrat entre toi, étudiant inscrit dans un établissement '
      'd\'enseignement supérieur camerounais, et Educoach.',
  lastUpdated: '1er novembre 2026 · v$_termsVersion',
  issuer:
      'Educoach SARL — Yaoundé, Cameroun · RC n° O022-2026-B-0000 · '
      'Autorité : MINPOSTEL / ART (Livre V, loi 2010/012)',
  intro:
      'Les présentes conditions générales d\'utilisation (ci-après « CGU ») '
      'régissent l\'accès et l\'usage de l\'application mobile Educoach '
      '(ci-après « l\'Application »). En créant un compte ou en utilisant '
      'l\'Application, tu reconnais avoir lu, compris et accepté sans '
      'réserve les CGU, dans leur version affichée au moment de ton '
      'inscription. Si tu as moins de 18 ans, l\'accord de ton '
      'représentant légal est requis.',
  articles: const <LegalArticle>[
    LegalArticle(
      number: 1,
      title: 'Objet et définitions',
      body:
          'L\'Application est un compagnon d\'études universitaires '
          'permettant à l\'étudiant de consulter ses cours, son emploi du '
          'temps, ses notes, ses ressources et de suivre des parcours '
          'd\'apprentissage interactifs.',
      clauses: <String>[
        '« Contenu » : les supports pédagogiques, explications, exemples, '
            'exercices, corrections et quiz mis à disposition par Educoach ou '
            'par les établissements partenaires.',
        '« Données personnelles » : toute information se rapportant à une '
            'personne physique identifiée ou identifiable, au sens de '
            'l\'article 40 de la loi n° 2010/012.',
        '« Utilisateur » ou « tu » : toute personne physique inscrite '
            'via un compte Educoach, étudiant ou enseignant.',
      ],
    ),
    LegalArticle(
      number: 2,
      title: 'Inscription et compte',
      body:
          'L\'accès complet à l\'Application suppose la création d\'un '
          'compte gratuit via une adresse email institutionnelle ou '
          'personnelle.',
      clauses: <String>[
        'Tu garantisses l\'exactitude des informations fournies '
            '(nom, prénom, filière, niveau, matricule).',
        'Tu es responsable de la confidentialité de ton mot de passe. '
            'Toute action effectuée depuis ton compte te présume autorisé.',
        'Un seul compte par étudiant ; Educoach peut clôturer les '
            'comptes manifestement frauduleux ou en double.',
        'Les utilisateurs mineurs doivent obtenir une autorisation '
            'parentale avant validation de l\'inscription.',
      ],
    ),
    LegalArticle(
      number: 3,
      title: 'Accès, évolutions et disponibilité',
      body:
          'Educoach s\'efforce d\'assurer une disponibilité maximale, sans '
          'toutefois garantir un service exempt d\'interruptions.',
      clauses: <String>[
        'L\'Application peut évoluer sans préavis ; les versions '
            'publiées sur les stores restent conformes aux présentes CGU.',
        'Educoach se réserve le droit de suspendre temporairement un '
            'service pour maintenance, mise à jour de sécurité ou incident.',
      ],
    ),
    LegalArticle(
      number: 4,
      title: 'Contenus pédagogiques et propriété intellectuelle',
      body:
          'Les contenus (cours, exercices, corrections, marques, logos) '
          'sont protégés par le droit d\'auteur camerounais (loi n° 2000/11 '
          'du 19 décembre 2000) et les conventions internationales '
          'applicables.',
      clauses: <String>[
        'Toute reproduction, redistribution, revente ou entraînement '
            'd\'un modèle d\'IA sur ces contenus est interdite sans '
            'autorisation écrite préalable.',
        'Les cours produits par les enseignants partenaires restent '
            'la propriété de l\'établissement ; Educoach n\'en détient '
            'qu\'une licence d\'affichage pour le compte des étudiants '
            'inscrits.',
      ],
    ),
    LegalArticle(
      number: 5,
      title: 'Données personnelles',
      body:
          'Le traitement des données personnelles est décrit dans la '
          'Politique de confidentialité annexée. En acceptant les CGU, '
          'tu reconnais en avoir pris connaissance.',
      clauses: <String>[
        'Le responsable de traitement est Educoach SARL, représenté par '
            'son gérant.',
        'Les données sont collectées pour la finalité strictement '
            'liée à l\'accompagnement pédagogique (article 60, loi 2010/012).',
        'Tu disposes d\'un droit d\'accès, de rectification, '
            'd\'opposition, d\'effacement et de portabilité, exerçable '
            'auprès du DPO ou directement dans l\'Application.',
        'La réclamation peut être portée devant l\'ART ou toute '
            'autorité compétente.',
      ],
    ),
    LegalArticle(
      number: 6,
      title: 'Permissions système',
      body:
          'Educoach ne demande l\'accès aux fonctions matérielles du '
          'terminal (notifications, appareil photo, stockage, calendrier, '
          'microphone, localisation) que lorsque la fonction l\'exige.',
      clauses: <String>[
        'Chaque permission peut être révoquée à tout moment depuis '
            'l\'écran « Confidentialité & permissions » ou depuis les '
            'paramètres du système.',
        'Le refus d\'une permission non essentielle n\'empêche pas '
            'l\'utilisation de base.',
      ],
    ),
    LegalArticle(
      number: 7,
      title: 'Conduite de l\'utilisateur',
      body:
          'Tu t\'engages à ne pas porter atteinte à l\'intégrité du '
          'service ni aux droits des autres utilisateurs.',
      clauses: <String>[
        'Sont interdits : l\'ingestion automatique non autorisée de '
            'contenus, la diffusion de contenus diffamatoires, haineux '
            'ou contraires aux bonnes mœurs, la triche en quiz via '
            'script ou outil externe.',
        'Educoach peut suspendre ou supprimer un compte en cas de '
            'manquement grave, avec notification préalable par email.',
      ],
    ),
    LegalArticle(
      number: 8,
      title: 'Responsabilités et garantie',
      body:
          'L\'Application est fournie « en l\'état ». Educoach ne '
          'saurait être tenue responsable d\'un échec académique '
          'lié à une information erronée consultée dans l\'Application.',
      clauses: <String>[
        'En cas de conflit entre une information affichée dans '
            'l\'Application et celle publiée par ton établissement, '
            'cette dernière fait foi.',
        'La responsabilité d\'Educoach ne peut être engagée pour des '
            'dommages indirects (perte de données, perte d\'exploitation).',
      ],
    ),
    LegalArticle(
      number: 9,
      title: 'Rémunération et abonnements',
      body:
          'L\'usage de base est gratuit. Certaines fonctionnalités '
          'peuvent être proposées sous forme d\'abonnement payant ; '
          'leurs modalités sont présentées avant tout engagement.',
      clauses: <String>[
        'Paiement via Mobile Money (MTN MoMo, Orange Money) ou '
            'carte, avec confirmation par email.',
        'Droit de rétractation de sept (7) jours pour tout achat '
            'effectué à distance, conformément au droit camerounais '
            'de la consommation.',
      ],
    ),
    LegalArticle(
      number: 10,
      title: 'Durée, résiliation et suppression',
      body:
          'Le compte reste actif tant que tu ne demandes pas sa '
          'suppression.',
      clauses: <String>[
        'Tu peux supprimer définitivement ton compte depuis Profil → '
            'Supprimer mon compte. Les données sont effacées dans un '
            'délai de 30 jours, hors obligations légales d\'archivage.',
        'Educoach peut clôturer un compte inactif depuis 24 mois, '
            'après deux relances par email.',
      ],
    ),
    LegalArticle(
      number: 11,
      title: 'Droit applicable et juridiction',
      body:
          'Les CGU sont régies par le droit camerounais. Tout litige '
          'sera soumis, à défaut d\'accord amiable, aux tribunaux '
          'compétents de Yaoundé.',
      clauses: <String>[
        'Pour les utilisateurs européens, le RGPD s\'applique en '
            'complément et les réclamations peuvent être portées '
            'devant l\'autorité de contrôle du pays de résidence.',
      ],
    ),
  ],
  contactLabel: 'Contact DPO',
  contactValue: 'contact@educoach.sn · +237 6 00 00 00 00 · Yaoundé, Cameroun',
);

/// Politique de confidentialité conforme à la loi camerounaise
/// n° 2010/012 (Livre V) et, le cas échéant, au RGPD.
final privacyDocument = LegalDocument(
  routeName: '/legal/privacy',
  title: 'Confidentialité',
  subtitle:
      'Comment nous collectons, utilisons, partageons et protégeons tes '
      'données personnelles.',
  lastUpdated: '1er novembre 2026 · v$_privacyVersion',
  issuer:
      'Educoach SARL · Représentant légal : le gérant · Notification ART '
      'n° ART/DPO/2026/0000',
  intro:
      'Educoach accorde une importance centrale à la vie privée de ses '
      'utilisateurs. Cette politique explique quelles données sont '
      'collectées, pourquoi, avec qui elles sont partagées, combien de '
      'temps elles sont conservées et comment exercer tes droits. Elle '
      's\'inscrit dans le cadre de la loi camerounaise n° 2010/012 '
      'relative à la cybersécurité et à la prévention de la '
      'cybercriminalité (Livre V) et des recommandations de l\'Agence '
      'de Régulation des Télécommunications (ART).',
  articles: const <LegalArticle>[
    LegalArticle(
      number: 1,
      title: 'Responsable de traitement et délégué',
      body:
          'Le responsable de traitement est Educoach SARL, société de '
          'droit camerounais. Un Délégué à la Protection des Données '
          '(DPO) est désigné et joignable aux coordonnées indiquées '
          'en pied de document.',
    ),
    LegalArticle(
      number: 2,
      title: 'Données que nous collectons',
      body:
          'Les données collectées se limitent à ce qui est strictement '
          'nécessaire à la finalité pédagogique.',
      clauses: <String>[
        'Identité et scolarité : prénom, nom, email, téléphone, '
            'filière, niveau, matricule, photo de profil '
            '(optionnelle).',
        'Données de progression : cours consultés, leçons terminées, '
            'scores aux exercices, XP, série d\'activité, temps passé.',
        'Données techniques : identifiant d\'installation, version de '
            'l\'application, modèle d\'appareil, système d\'exploitation, '
            'journal d\'erreurs anonymisé, adresse IP tronquée.',
        'Nous ne collectons pas sciemment de données sensibles '
            '(santé, opinions, biométrie) ; si une question pédagogique '
            'en laissait transparaître, elles seraient supprimées à la '
            'réception.',
      ],
    ),
    LegalArticle(
      number: 3,
      title: 'Finalités et bases légales',
      body:
          'Chaque traitement repose sur une base légale prévue par le '
          'Livre V de la loi 2010/012 (ou par le RGPD pour les '
          'résidents UE/EEE).',
      clauses: <String>[
        'Exécution du service (création, affichage et suivi de ton '
            'parcours) — base : contrat.',
        'Consentement explicite pour les communications marketing et '
            'les permissions optionnelles (notifications, calendrier, '
            'localisation).',
        'Intérêt légitime pour la sécurité, la prévention de la '
            'fraude et l\'amélioration statistique agrégée.',
        'Obligation légale pour la conservation de preuves '
            'de consentement et de transactions.',
      ],
    ),
    LegalArticle(
      number: 4,
      title: 'Destinataires des données',
      body:
          'Tes données ne sont ni vendues, ni louées, ni cédées à des '
          'tiers publicitaires.',
      clauses: <String>[
        'Équipe interne Educoach habilitée (pédagogie, support, '
            'ingénierie), sous strictes règles d\'accès.',
        'Prestataires techniques (hébergement, email transactionnel, '
            'crash-reporting) uniquement pour la fourniture du '
            'service, liés par contrat de sous-traitance.',
        'Établissement d\'enseignement partenaire sur demande '
            'expresse de ta part ou pour les cas encadrés par la '
            'convention Educoach-établissement.',
        'Autorités compétentes sur réquisition judiciaire.',
      ],
    ),
    LegalArticle(
      number: 5,
      title: 'Durée de conservation',
      body:
          'Les durées suivent le principe de minimisation : les données '
          'ne sont conservées que pour la durée strictement '
          'nécessaire.',
      clauses: <String>[
        'Compte et scolarité : jusqu\'à la suppression du compte, '
            'puis archivage 12 mois à des fins probatoires avant '
            'effacement définitif.',
        'Progression pédagogique : tant que le compte est actif.',
        'Journaux techniques : 90 jours glissants.',
        'Logs de consentement : 5 ans (preuve légale).',
      ],
    ),
    LegalArticle(
      number: 6,
      title: 'Sécurité',
      body:
          'Les mesures techniques et organisationnelles sont conformes '
          'à l\'article 67 de la loi 2010/012.',
      clauses: <String>[
        'Chiffrement TLS 1.3 en transit, AES-256 au repos.',
        'Hachage des mots de passe avec algorithme lent (bcrypt / '
            'argon2), sel unique par utilisateur.',
        'Journalisation des accès administratifs et double '
            'validation pour les exports de données.',
        'Notification aux utilisateurs sous 72 h en cas d\'incident '
            'de sécurité affectant leurs données.',
      ],
    ),
    LegalArticle(
      number: 7,
      title: 'Transferts internationaux',
      body:
          'Les données sont hébergées en priorité dans des centres '
          'situés au Cameroun ou dans l\'Union africaine. Un transfert '
          'hors de ces zones n\'intervient qu\'avec des garanties de '
          'niveau adéquat (clauses contractuelles types, décision '
          'd\'adéquation).',
    ),
    LegalArticle(
      number: 8,
      title: 'Tes droits',
      body:
          'Conformément au chapitre II du Livre V de la loi 2010/012 '
          '(et aux articles 15 à 22 du RGPD pour les personnes '
          'résidant dans l\'UE/EEE), tu disposes de droits '
          'exercables gratuitement.',
      clauses: <String>[
        'Droit d\'accès et de communication de tes données.',
        'Droit de rectification et de mise à jour.',
        'Droit à l\'effacement (« droit à l\'oubli »), dans les '
            'limites des obligations légales de conservation.',
        'Droit d\'opposition et de retrait du consentement, à tout '
            'moment.',
        'Droit à la portabilité (export dans un format structuré).',
        'Droit de définir des directives post-mortem.',
        'Droit d\'introduire une réclamation auprès de l\'ART ou, le '
            'cas échéant, de l\'autorité européenne compétente.',
      ],
    ),
    LegalArticle(
      number: 9,
      title: 'Cookies et traceurs',
      body:
          'L\'application mobile ne dépose pas de cookie tiers à '
          'finalité publicitaire. Un identifiant technique interne '
          '(crash, analytics agrégées) est utilisé, avec option de '
          'retrait depuis les réglages.',
    ),
    LegalArticle(
      number: 10,
      title: 'Mineurs',
      body:
          'L\'inscription d\'une personne mineure exige le consentement '
          'vérifiable d\'un titulaire de l\'autorité parentale, '
          'conformément à la loi camerounaise sur la protection de '
          'l\'enfant (loi n° 2005/007, art. 1).',
    ),
    LegalArticle(
      number: 11,
      title: 'Modification de la politique',
      body:
          'Toute modification substantielle sera annoncée dans '
          'l\'application avec nouvelle version datée. Si toi '
          'nouvel utilisateur, tu devras réaccepter avant de '
          'poursuivre.',
    ),
  ],
  contactLabel: 'Exercer tes droits / Contacter le DPO',
  contactValue:
      'E-mail : dpo@educoach.sn · Téléphone : +237 6 00 00 00 00 · '
      'Courrier : Educoach SARL — DPO, BP 0000 Yaoundé, Cameroun. '
      'Réclamation : Agence de Régulation des Télécommunications '
      '(ART), BP 11005 Yaoundé, Cameroun.',
);
