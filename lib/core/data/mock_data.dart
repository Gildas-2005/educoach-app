import 'package:flutter/material.dart';

import '../models/models.dart';
import 'seed.dart';

/// Jeu de données de démonstration pour Educoach.
///
/// La source de vérité est [seed.dart] : filières + table de cours. Tout le
/// reste (planning, ressources, notes, devoirs) est dérivé
/// déterministiquement du hash du code de cours, afin de rester cohérent
/// d'une session à l'autre sans base de données.
class MockData {
  const MockData._();

  // ---------------------------------------------------------------------------
  // Filières : directement depuis le seed.
  // ---------------------------------------------------------------------------
  static final List<Filiere> filieres = List<Filiere>.unmodifiable(filiereSeed);

  static final Map<String, Filiere> _filiereIndex = {
    for (final f in filieres) f.id: f,
  };

  /// Filières groupées par domaine, pour l'écran de sélection.
  static Map<String, List<Filiere>> filieresByDomain() {
    final out = <String, List<Filiere>>{};
    for (final f in filieres) {
      out.putIfAbsent(f.domain, () => <Filiere>[]).add(f);
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Cours : dérivés du seed avec icône, couleur, avancement et description.
  // ---------------------------------------------------------------------------
  static final List<Course> courses = List<Course>.unmodifiable(
    _buildCourses(),
  );

  static List<Course> _buildCourses() {
    final byFiliere = <String, int>{}; // compteur pour varier la teinte
    final out = <Course>[];
    for (final row in courseSeed) {
      final f = _filiereIndex[row.filiereId]!;
      final idx = byFiliere[row.filiereId] =
          (byFiliere[row.filiereId] ?? 0) + 1;
      final hash = _h(row.code);
      final progress = 0.15 + ((hash >> 3) % 78) / 100; // 0.15 – 0.92
      final color = _shift(f.color, ((hash >> 5) % 3) - 1, idx);
      out.add(
        Course(
          id: 'c-${row.filiereId}-${row.code}',
          code: row.code,
          title: row.title,
          teacher: row.teacher,
          semester: _semesterFor(row.level),
          credits: row.credits,
          progress: progress.clamp(0.0, 1.0),
          color: color,
          icon: iconFor(row.title, row.code),
          description:
              '${row.title} — enseignement magistral et travaux dirigés en '
              '${f.name} (${row.level}). Volume horaire hebdomadaire : '
              '${row.weeklyHours}h.',
          filiereId: row.filiereId,
          level: row.level,
          weeklyHours: row.weeklyHours,
        ),
      );
    }
    return out;
  }

  static final Map<String, Course> _courseIndex = {
    for (final c in courses) c.code: c,
  };

  // ---------------------------------------------------------------------------
  // Planning : 2 à 3 séances par cours, réparties sur la semaine.
  // ---------------------------------------------------------------------------
  static final List<ScheduleBlock> schedule = List<ScheduleBlock>.unmodifiable(
    _buildSchedule(),
  );

  static List<ScheduleBlock> _buildSchedule() {
    const rooms = <String>[
      'Amphi A',
      'Amphi B',
      'Amphi C',
      'Amphi D',
      'Salle 101',
      'Salle 102',
      'Salle 204',
      'Salle 305',
      'Salle 312',
      'Lab. Informatique',
      'Lab. Réseau',
      'Lab. BD',
      'Lab. Mobile',
      'TP Hall 1',
      'TP Hall 2',
    ];
    final out = <ScheduleBlock>[];
    for (final c in courses) {
      final h = _h(c.code);
      final hours = c.weeklyHours;
      final types = hours >= 6
          ? const <String>['CM', 'TD', 'TP']
          : hours >= 4
          ? const <String>['CM', 'TD']
          : const <String>['CM'];
      var dayOffset = h % 5;
      var start = 8 + (h >> 2) % 6; // 8h – 13h
      for (final t in types) {
        final day = 1 + (dayOffset % 5);
        final dur = t == 'TP' ? 3 : 2;
        final room = rooms[(h + dayOffset * 7) % rooms.length];
        out.add(
          ScheduleBlock(
            courseCode: c.code,
            title: c.title,
            dayOfWeek: day,
            startHour: start,
            endHour: (start + dur).clamp(0, 19),
            room: room,
            type: t,
          ),
        );
        dayOffset += 1 + ((h >> 3) % 2);
        start = 8 + ((start + 1) % 8);
      }
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Ressources : 2 à 3 par cours.
  // ---------------------------------------------------------------------------
  static final List<CourseResource> resources =
      List<CourseResource>.unmodifiable(_buildResources());

  static List<CourseResource> _buildResources() {
    final kinds = <(String, String, String)>[
      ('pdf', 'Chapitre intégral (PDF)', '3.4 Mo'),
      ('slide', 'Slides du CM', '1.2 Mo'),
      ('video', 'Enregistrement vidéo', '42 min'),
      ('audio', 'Podcast de révision', '28 min'),
      ('link', 'Ressource externe', ''),
      ('pdf', 'Fiche de synthèse', '620 Ko'),
    ];
    final out = <CourseResource>[];
    for (final c in courses) {
      final h = _h(c.code);
      final n = 2 + h % 2; // 2 ou 3 ressources
      for (var i = 0; i < n; i++) {
        final k = kinds[(h + i * 3) % kinds.length];
        out.add(
          CourseResource(
            courseCode: c.code,
            title: '${c.title} — ${k.$1}',
            kind: k.$2,
            updatedAt: _d(-(1 + ((h >> 2) % 30) + i * 4)),
            sizeLabel: k.$3,
          ),
        );
      }
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Notes : 1 à 3 par cours.
  // ---------------------------------------------------------------------------
  static final List<Grade> grades = List<Grade>.unmodifiable(_buildGrades());

  static List<Grade> _buildGrades() {
    const labels = <String>[
      'Contrôle continu',
      'Devoir maison',
      'Partiel',
      'TP noté',
      'Exposé',
      'Quiz',
    ];
    final out = <Grade>[];
    for (final c in courses) {
      final h = _h(c.code);
      // Certains cours n'ont pas encore de note pour varier l'affichage.
      if (h % 7 == 0) continue;
      final n = 1 + h % 3;
      for (var i = 0; i < n; i++) {
        final base = 8 + ((h >> (i + 2)) % 12); // 8..19
        final bonus = ((h >> i) % 3) * 0.5;
        out.add(
          Grade(
            courseCode: c.code,
            label: labels[(h + i * 5) % labels.length],
            score: (base + bonus).clamp(4.0, 20.0),
            max: 20,
            date: _d(-(6 + ((h >> 3) % 60) + i * 5)),
            weight: i == 0 ? 1 : ((h >> i) % 3) + 1,
          ),
        );
      }
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Devoirs à rendre.
  // ---------------------------------------------------------------------------
  static final List<Assignment> assignments = List<Assignment>.unmodifiable(
    _buildAssignments(),
  );

  static List<Assignment> _buildAssignments() {
    const templates = <String>[
      'TD %s à rendre',
      'Mini-projet %s',
      'Lecture critique — %s',
      'Rapport de TP %s',
      'Préparation partiel %s',
    ];
    final out = <Assignment>[];
    for (final c in courses) {
      final h = _h(c.code);
      if (h % 3 == 0) continue; // tous les cours n'ont pas de devoir en cours
      final n = 1 + h % 2;
      for (var i = 0; i < n; i++) {
        final days = -4 + ((h >> 2) % 21) + i * 3;
        out.add(
          Assignment(
            courseCode: c.code,
            title: templates[(h + i) % templates.length].replaceFirst(
              '%s',
              c.code,
            ),
            dueDate: _d(days),
            done: days < 0 && (h % 2 == 0),
          ),
        );
      }
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Helpers publics
  // ---------------------------------------------------------------------------
  static Filiere? filiereById(String id) => _filiereIndex[id];
  static Course? courseByCode(String code) => _courseIndex[code];

  /// Cours rattachés à une filière (et éventuellement un niveau précis).
  static List<Course> coursesFor({String? filiereId, String? level}) {
    return [
      for (final c in courses)
        if ((filiereId == null || c.filiereId == filiereId) &&
            (level == null || level.isEmpty || c.level == level))
          c,
    ];
  }

  static List<ScheduleBlock> scheduleForDay(int day) =>
      (schedule.where((b) => b.dayOfWeek == day).toList())
        ..sort((a, b) => a.startHour.compareTo(b.startHour));

  static List<CourseResource> resourcesFor(String courseCode) =>
      resources.where((r) => r.courseCode == courseCode).toList();

  static List<Grade> gradesFor(String courseCode) =>
      grades.where((g) => g.courseCode == courseCode).toList();

  static List<Assignment> assignmentsFor(String courseCode) =>
      assignments.where((a) => a.courseCode == courseCode).toList();

  static List<Assignment> upcomingAssignmentsFor(Iterable<String> codes) {
    final now = DateTime.now();
    final list =
        assignments
            .where(
              (a) =>
                  !a.done &&
                  codes.contains(a.courseCode) &&
                  a.dueDate.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  /// Moyenne pondérée sur une sélection de codes de cours (sur 20).
  static double weightedAverageFor(Iterable<String> codes) {
    var totalWeight = 0.0;
    var total = 0.0;
    for (final g in grades) {
      if (!codes.contains(g.courseCode)) continue;
      total += g.noteSur20 * g.weight;
      totalWeight += g.weight;
    }
    return totalWeight == 0 ? 0 : total / totalWeight;
  }

  /// Nombre de cours proposés pour une filière/niveau (utilis dans l'UI).
  static int courseCountFor(String filiereId, {String? level}) =>
      coursesFor(filiereId: filiereId, level: level).length;

  // ---------------------------------------------------------------------------
  // Utilitaires internes
  // ---------------------------------------------------------------------------
  static int _h(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7FFFFFFF;
    }
    return h;
  }

  static DateTime _d(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + days);
  }

  static String _semesterFor(String level) {
    // Niveaux impairs → S1, pairs → S2. Approche simple, purement visuelle.
    final h = _h(level);
    final s = (h % 2 == 0) ? 'S1' : 'S2';
    return '$s · 2025-2026';
  }

  /// Petit décalage de teinte pour varier les cours d'une même filière.
  static Color _shift(Color base, int direction, int idx) {
    if (direction == 0) return base;
    final hsl = HSLColor.fromColor(base);
    final hue = (hsl.hue + direction * 12 + idx * 3) % 360;
    return hsl.withHue(hue < 0 ? hue + 360 : hue).toColor();
  }

  /// Icône thématique déterministe basée sur le titre / code du cours.
  static IconData iconFor(String title, String code) {
    final t = title.toLowerCase();
    bool has(String s) => t.contains(s);
    if (has('algorithme') || has('structure de donnée') || has('graphe')) {
      return Icons.account_tree_rounded;
    }
    if (has('programmation') ||
        has('java') ||
        has('flutter') ||
        has('mobile') ||
        has('développement')) {
      return Icons.code_rounded;
    }
    if (has('base de données') || has('sql')) return Icons.storage_rounded;
    if (has('réseau') || has('protocole') || has('routage')) {
      return Icons.lan_rounded;
    }
    if (has('intelligence artificielle') ||
        has('ia') ||
        has('deep learning') ||
        has('neurone')) {
      return Icons.auto_awesome_rounded;
    }
    if (has('sécurité') || has('cyber')) return Icons.security_rounded;
    if (has('système') || has('linux') || has('unix')) return Icons.dns_rounded;
    if (has('stat')) return Icons.query_stats_rounded;
    if (has('probabilit')) return Icons.casino_rounded;
    if (has('math') ||
        has('analyse') ||
        has('algèbre') ||
        has('topolog') ||
        has('discrète')) {
      return Icons.functions_rounded;
    }
    if (has('physique') ||
        has('onde') ||
        has('quantique') ||
        has('nucléaire')) {
      return Icons.science_rounded;
    }
    if (has('thermodynamique')) return Icons.thermostat_rounded;
    if (has('chimie')) return Icons.biotech_rounded;
    if (has('biochimie') || has('métabolisme') || has('enzym')) {
      return Icons.water_drop_rounded;
    }
    if (has('biologie') || has('botanique') || has('zoologie')) {
      return Icons.eco_rounded;
    }
    if (has('génétique') || has('génom')) return Icons.bubble_chart_rounded;
    if (has('microbiologie')) return Icons.coronavirus_rounded;
    if (has('anatomie') || has('histolog')) {
      return Icons.medical_information_rounded;
    }
    if (has('pharmac')) return Icons.local_pharmacy_rounded;
    if (has('clinique') || has('sémiolog') || has('patholog')) {
      return Icons.monitor_heart_rounded;
    }
    if (has('dent') || has('odont')) return Icons.medical_services_rounded;
    if (has('vétérinaire') || has('animale')) return Icons.pets_rounded;
    if (has('élec') || has('machine') || has('automat') || has('puissance')) {
      return Icons.memory_rounded;
    }
    if (has('mécanique')) return Icons.settings_rounded;
    if (has('béton') || has('pont') || has('ouvrage') || has('topograph')) {
      return Icons.foundation_rounded;
    }
    if (has('hydraulique')) return Icons.water_rounded;
    if (has('production') ||
        has('qualité') ||
        has('logistique') ||
        has('lean')) {
      return Icons.factory_rounded;
    }
    if (has('robotique')) return Icons.smart_toy_rounded;
    if (has('droit') ||
        has('constitutionnel') ||
        has('obligation') ||
        has('contrat') ||
        has('procédure') ||
        has('liberté') ||
        has('administratif')) {
      return Icons.gavel_rounded;
    }
    if (has('économie') || has('micro') || has('macro') || has('économétr')) {
      return Icons.trending_up_rounded;
    }
    if (has('comptab') || has('fiscal') || has('audit')) {
      return Icons.calculate_rounded;
    }
    if (has('finance') || has('banque') || has('marché financier')) {
      return Icons.savings_rounded;
    }
    if (has('marketing') || has('branding') || has('publicité')) {
      return Icons.campaign_rounded;
    }
    if (has('gestion') ||
        has('management') ||
        has('stratégie') ||
        has('entreprise') ||
        has('rh')) {
      return Icons.business_center_rounded;
    }
    if (has('anglais') || has('espagnol') || has('langue') || has('traduct')) {
      return Icons.translate_rounded;
    }
    if (has('communication') ||
        has('média') ||
        has('journalisme') ||
        has('rp')) {
      return Icons.podcasts_rounded;
    }
    if (has('histoire')) return Icons.history_edu_rounded;
    if (has('géographie') || has('sig') || has('télédétection')) {
      return Icons.map_rounded;
    }
    if (has('socio')) return Icons.groups_rounded;
    if (has('psycholog')) return Icons.psychology_rounded;
    if (has('philosoph') || has('éthique')) return Icons.lightbulb_rounded;
    if (has('littérature') ||
        has('stylistique') ||
        has('linguistique') ||
        has('lettres')) {
      return Icons.auto_stories_rounded;
    }
    if (has('sport') || has('effort') || has('biomécanique')) {
      return Icons.sports_volleyball_rounded;
    }
    if (has('éduc') || has('pédagog') || has('didactique')) {
      return Icons.school_rounded;
    }
    if (has('télécom') || has('antenne') || has('fibre') || has('5g')) {
      return Icons.router_rounded;
    }
    if (has('environnement') ||
        has('écologie') ||
        has('climat') ||
        has('développement durable')) {
      return Icons.nature_rounded;
    }
    if (has('agro') || has('agriculture') || has('sol') || has('phyto')) {
      return Icons.agriculture_rounded;
    }
    if (has('cloud') || has('devops')) return Icons.cloud_rounded;
    if (has('big data') || has('analytic')) return Icons.insights_rounded;
    if (has('santé publique') || has('épidémiologie')) {
      return Icons.public_rounded;
    }
    // Repli basé sur le préfixe du code.
    return switch (code.substring(0, 3)) {
      'INF' => Icons.computer_rounded,
      'MAT' => Icons.calculate_rounded,
      'PHY' => Icons.science_rounded,
      'CHM' => Icons.biotech_rounded,
      'BIO' => Icons.eco_rounded,
      'MED' => Icons.local_hospital_rounded,
      'DRP' || 'DPB' => Icons.gavel_rounded,
      'ECO' => Icons.show_chart_rounded,
      'GES' => Icons.work_outline_rounded,
      'ANG' || 'ESP' => Icons.translate_rounded,
      _ => Icons.menu_book_rounded,
    };
  }
}
