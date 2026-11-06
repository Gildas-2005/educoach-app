/* ==========================================================================
   Écrans d'apprentissage : accueil, cours, détail, parcours, leçon
   ========================================================================== */
import { icon, esc, toast, $, $$, fmt, countUp, confetti, xpFloat, revealOnScroll, openModal, closeModal } from '../lib/dom.js';
import { t } from '../lib/i18n.js';
import { navigate } from '../router.js';
import {
  state, myCourses, coursesByLevel, courseByCode, courseProgress, doneCount,
  lessonsOf, pathFor, homeworkFor, resourcesFor, scheduleFor, gradesFor, average,
  isDone, completeLesson, level, levelProgress, nextLevelXp, planFor, filiereById,
} from '../store.js';

const todayIndex = () => (new Date().getDay() + 6) % 7; // lundi = 0

/* -------------------------------------------------------------------- Accueil */
export const home = {
  tabs: 'student',
  render() {
    const courses = myCourses();
    const list = courses.length ? courses : [];
    const first = list.find((c) => courseProgress(c) < 100) || list[0];
    const sessions = scheduleFor(list);
    const grades = gradesFor(list);
    const avg = average(grades);
    const done = list.reduce((sum, c) => sum + doneCount(c), 0);
    const today = new Date();
    const greeting = today.getHours() < 12 ? t('Bonjour', 'Good morning') : today.getHours() < 18 ? t('Bon après-midi', 'Good afternoon') : t('Bonsoir', 'Good evening');
    const mySessions = sessions.filter((s) => s.day === (todayIndex() + 1));

    const week = daysOfWeek(list);
    const plan = planFor(state.subscription.tier);

    return `
      <div class="greet">
        <div>
          <span class="page-head__eyebrow">${esc(filiereById(state.profile.filiereId).name)} · ${esc(state.profile.level || t('tous niveaux', 'all levels'))}</span>
          <h1>${greeting}, ${esc((state.users.find((u) => u.id === state.currentUserId)?.fullName || '').split(' ')[0])} 👋</h1>
          <p>${t('Prêt à gagner tes prochains XP ?', 'Ready for your next XP?')}</p>
        </div>
        <div class="streak" title="${t('Série quotidienne', 'Daily streak')}">
          <span class="flame">${icon('flame')}</span> ${state.streak} ${t('jours', 'days')}
        </div>
      </div>

      <div class="section">
        <div class="home-hero">
          <div>
            <span class="pill" style="background:rgba(255,255,255,.18);color:#fff;border-color:transparent">${icon('bolt')} ${t('Niveau', 'Level')} ${level()}</span>
            <h2 style="margin-top:10px">${first ? esc(first.title) : t('Choisis ton premier cours', 'Pick your first course')}</h2>
            <p>${first ? t('Reprends la leçon là où tu t’es arrêté — 8 minutes suffisent.', 'Resume the lesson where you left off — 8 minutes is enough.') : t('Explore tes cours pour démarrer un parcours.', 'Browse your courses to start a path.')}</p>
            <div class="row" style="margin-top:18px;flex-wrap:wrap">
              <button class="btn" style="background:#fff;color:#3f51b5" data-action="continue">
                ${icon('play')} ${t('Continuer', 'Continue')}
              </button>
              <span class="muted" style="color:rgba(255,255,255,.85);font-size:13px">${nextLevelXp()} XP → ${t('niveau', 'level')} ${level() + 1}</span>
            </div>
          </div>
          <div class="home-hero__level">
            <div class="ring" style="--p:${levelProgress()};--size:86px">
              <svg viewBox="0 0 70 70"><circle cx="35" cy="35" r="28"/><circle cx="35" cy="35" r="28"/></svg>
              <span class="ring__label" style="color:#fff">${state.xp}<small style="font-size:9px;display:block;opacity:.8">XP</small></span>
            </div>
          </div>
        </div>
      </div>

      <div class="section stats-strip">
        ${[
          ['book', String(list.length), t('cours suivis', 'active courses')],
          ['check', String(done), t('leçons terminées', 'lessons completed')],
          ['chart', grades.length ? `${avg.toFixed(1)}/20` : '—', t('moyenne générale', 'overall average')],
          ['trophy', String(state.xp), t('XP cumulés', 'lifetime XP')],
        ].map(([ic, value, label]) => `
          <div class="stat-card">
            <span class="icon-badge icon-badge--sm">${icon(ic)}</span>
            <div><strong>${value}</strong><span>${label}</span></div>
          </div>`).join('')}
      </div>

      <div class="section">
        <div class="section__head">
          <h2>${t('Aujourd’hui', 'Today')}</h2>
          <a class="section__link" href="#/schedule">${t('Tout le planning', 'Full schedule')} ${icon('arrowRight')}</a>
        </div>
        ${mySessions.length ? `<div class="today">${mySessions.map((s) => `
          <button class="today__row" data-course="${s.code}">
            <span class="today__time">${fmt.time(s.start)}<br><small class="muted" style="font-size:10px">${fmt.time(s.end)}</small></span>
            <span class="today__bar today__bar--${s.type}"></span>
            <span style="text-align:left"><strong style="font-size:14px">${esc(s.title)}</strong>
              <small class="muted" style="display:block;font-size:12px">${esc(s.teacher)} · ${esc(s.room)}</small></span>
            <span class="pill">${s.type}</span>
          </button>`).join('')}</div>`
          : `<div class="empty">${icon('calendar')}<h3>${t('Aucune séance aujourd’hui', 'No session today')}</h3><p>${t('Profite-en pour avancer sur un parcours.', 'Good time to move forward on a path.')}</p></div>`}
      </div>

      <div class="section split-2">
        <div>
          <div class="section__head"><h2>${t('Tes cours', 'Your courses')}</h2><a class="section__link" href="#/courses">${t('Voir tout', 'See all')} ${icon('arrowRight')}</a></div>
          <div class="course-grid">
            ${list.slice(0, 4).map((c) => courseCard(c)).join('')}
          </div>
        </div>
        <div class="stack">
          <div class="card">
            <div class="card__title">${icon('chart')} ${t('Activité de la semaine', 'This week')}</div>
            <div class="spark" data-spark>
              ${week.map(([label, value]) => `
                <div class="spark__col" title="${label} : ${value} ${t('leçons', 'lessons')}">
                  <div class="spark__bar" style="height:${Math.max(6, Math.round(value * 100))}%"></div>
                  <small>${label}</small>
                </div>`).join('')}
            </div>
          </div>
          <div class="card">
            <div class="card__title">${icon('star')} ${t('Ton abonnement', 'Your plan')}</div>
            <p class="muted" style="font-size:13px;margin-top:4px">${esc(plan.label)} · ${state.subscription.renewsAt ? t('renouvellement le', 'renews on') + ' ' + fmt.date(state.subscription.renewsAt) : t('gratuit à vie', 'free forever')}</p>
            <button class="btn btn--soft btn--block" style="margin-top:12px" data-action="subscription">
              ${state.subscription.tier === 'discovery' ? t('Passer Premium', 'Go Premium') : t('Gérer mon abonnement', 'Manage plan')}
            </button>
          </div>
        </div>
      </div>

      <div class="section">
        <div class="section__head"><h2>${t('Reprendre un parcours', 'Resume a path')}</h2></div>
        <div class="grid grid--2">
          ${list.slice(0, 2).map((c) => `
            <div class="card continue-card">
              <div class="ring" style="--p:${courseProgress(c) / 100};--size:64px">
                <svg viewBox="0 0 70 70"><circle cx="35" cy="35" r="28"/><circle cx="35" cy="35" r="28"/></svg>
                <span class="ring__label">${courseProgress(c)}%</span>
              </div>
              <div class="grow">
                <strong style="display:block">${esc(c.title)}</strong>
                <small class="muted">${esc(c.code)} · ${doneCount(c)}/${lessonsOf(c).length} ${t('leçons', 'lessons')}</small>
                <div class="bar bar--sm" style="margin-top:8px"><span style="width:${courseProgress(c)}%"></span></div>
              </div>
              <button class="btn btn--primary btn--sm" data-course="${c.code}">${icon('play')} ${t('Reprendre', 'Resume')}</button>
            </div>`).join('')}
        </div>
      </div>`;
  },
  mount(root) {
    const first = myCourses().find((c) => courseProgress(c) < 100) || myCourses()[0];
    $('[data-action="continue"]', root)?.addEventListener('click', () => {
      if (first) navigate(`/course/${first.code}/path`);
    });
    $('[data-action="subscription"]', root).addEventListener('click', () => navigate('/subscription'));
    $$('[data-course]', root).forEach((btn) => btn.addEventListener('click', () => navigate(`/course/${btn.dataset.course}/path`)));
  },
};

/* --------------------------------------------------------------------- Cours */
export const courses = {
  tabs: 'student',
  render() {
    const list = myCourses();
    const levels = [...new Set(list.map((c) => c.level))].sort();
    return `
      <div class="page-head">
        <div><h1>${t('Mes cours', 'My courses')}</h1><p>${list.length} ${t('cours dans ta filière', 'courses in your programme')}</p></div>
        <button class="btn btn--ghost btn--sm" data-action="change-filiere">${icon('layers')} ${t('Changer de filière', 'Change programme')}</button>
      </div>

      <div class="stack">
        <div class="search">${icon('search')}
          <input id="course-search" type="search" placeholder="${t('Rechercher un cours, un enseignant, un code…', 'Search a course, a teacher, a code…')}" />
        </div>
        <div class="filters">
          <button class="chip is-active" data-level="">${t('Tous', 'All')}</button>
          ${levels.map((l) => `<button class="chip" data-level="${l}">${l}</button>`).join('')}
        </div>
      </div>

      <div class="section course-grid" id="course-grid">
        ${list.map((c) => courseCard(c)).join('')}
      </div>
      <div class="empty" id="course-empty" hidden style="margin-top:20px">${icon('search')}<h3>${t('Aucun cours trouvé', 'No course found')}</h3><p>${t('Essaie un autre mot-clé ou change de niveau.', 'Try another keyword or level.')}</p></div>`;
  },
  mount(root) {
    const grid = $('#course-grid', root);
    let levelFilter = '';
    const search = $('#course-search', root);

    const apply = () => {
      const q = search.value.trim().toLowerCase();
      let visible = 0;
      $$('[data-course-card]', root).forEach((card) => {
        const matchLevel = !levelFilter || card.dataset.level === levelFilter;
        const matchQuery = !q || card.dataset.search.includes(q);
        card.hidden = !(matchLevel && matchQuery);
        if (!card.hidden) visible++;
      });
      $('#course-empty', root).hidden = visible > 0;
    };

    search.addEventListener('input', apply);
    $$('[data-level]', root).forEach((chip) => chip.addEventListener('click', () => {
      levelFilter = chip.dataset.level;
      $$('[data-level]', root).forEach((c) => c.classList.toggle('is-active', c === chip));
      apply();
    }));
    $('[data-action="change-filiere"]', root).addEventListener('click', () => navigate('/filiere'));
    $$('[data-course-card]').forEach((card) => card.addEventListener('click', () => navigate(`/course/${card.dataset.courseCard}`)));
    grid.addEventListener('click', (e) => {
      const card = e.target.closest('[data-course-card]');
      if (card) navigate(`/course/${card.dataset.courseCard}`);
    });
  },
};

function courseCard(c) {
  const pct = courseProgress(c);
  const colorClass = pct >= 75 ? 'success' : pct >= 40 ? 'warning' : 'danger';
  return `
    <article class="card card--hoverable course-card" data-course-card="${c.code}" data-level="${c.level}"
      data-search="${esc(`${c.title} ${c.code} ${c.teacher} ${c.level}`.toLowerCase())}" style="--c-color:${c.color}">
      <div class="course-card__top">
        <span class="course-card__badge">${esc(c.code.slice(0, 4))}</span>
        <div class="grow">
          <h3>${esc(c.title)}</h3>
          <div class="course-card__meta">
            <span>${esc(c.teacher)}</span><span>·</span><span>${c.level}</span><span>·</span><span>${c.credits} ${t('crédits', 'credits')}</span>
          </div>
        </div>
      </div>
      <div class="row" style="gap:8px">
        <div class="bar bar--sm bar--${colorClass} grow"><span style="width:${pct}%"></span></div>
        <span class="course-card__pct">${pct}%</span>
      </div>
      <div class="course-card__foot">
        <small class="muted">${doneCount(c)}/${lessonsOf(c).length} ${t('leçons', 'lessons')} · ${c.weeklyHours}h/sem</small>
        <span class="section__link">${icon('arrowRight')}</span>
      </div>
    </article>`;
}

/* --------------------------------------------------------------- Détail cours */
export const courseDetail = {
  tabs: 'student',
  render({ params }) {
    const course = courseByCode(params.code);
    if (!course) return notFound(t('Cours introuvable', 'Course not found'));
    const units = pathFor(course);
    const hw = homeworkFor(course);
    const pct = courseProgress(course);
    const next = lessonsOf(course).find((l) => !isDone(l.id));

    return `
      <div class="row" style="margin-bottom:14px">
        <button class="btn btn--ghost btn--sm" data-action="back">${icon('arrowLeft')} ${t('Retour', 'Back')}</button>
      </div>

      <header class="course-hero course-hero--dynamic" style="--c-color:${course.color}">
        <div class="row" style="gap:8px;flex-wrap:wrap">
          <span class="pill" style="background:rgba(255,255,255,.2);color:#fff;border-color:transparent">${esc(course.code)}</span>
          <span class="pill" style="background:rgba(255,255,255,.2);color:#fff;border-color:transparent">${course.level}</span>
          <span class="pill" style="background:rgba(255,255,255,.2);color:#fff;border-color:transparent">${course.semester}</span>
        </div>
        <h1 style="margin-top:12px">${esc(course.title)}</h1>
        <p style="color:rgba(255,255,255,.88);margin-top:8px;max-width:62ch">${esc(course.description)}</p>
        <div class="course-hero__meta">
          <span>${icon('user')} ${esc(course.teacher)}</span>
          <span>${icon('clock')} ${course.weeklyHours}h / ${t('semaine', 'week')}</span>
          <span>${icon('layers')} ${units.length} ${t('unités', 'units')}</span>
          <span>${icon('book')} ${lessonsOf(course).length} ${t('leçons', 'lessons')}</span>
        </div>
        <div class="row" style="margin-top:20px;flex-wrap:wrap">
          <button class="btn" style="background:#fff;color:#3f51b5" data-action="start">
            ${icon('play')} ${next ? t('Continuer le parcours', 'Continue path') : t('Revoir le parcours', 'Review path')}
          </button>
          <span style="color:rgba(255,255,255,.9);font-size:13px">${pct}% ${t('terminé', 'completed')}</span>
        </div>
      </header>

      <div class="section split-2">
        <div class="stack">
          <div class="card">
            <div class="row row--between" style="margin-bottom:14px">
              <div class="card__title">${icon('layers')} ${t('Contenu du cours', 'Course content')}</div>
              <a class="section__link" href="#/course/${course.code}/path">${t('Vue parcours', 'Path view')} ${icon('arrowRight')}</a>
            </div>
            <div class="stack" style="gap:14px">
              ${units.map((unit, ui) => `
                <details ${ui === 0 ? 'open' : ''}>
                  <summary class="row" style="cursor:pointer;list-style:none;justify-content:space-between">
                    <span class="row" style="gap:10px">
                      <span class="icon-badge icon-badge--sm">${icon(unit.icon)}</span>
                      <span><strong style="display:block;font-size:14px">${esc(unit.title)}</strong>
                        <small class="muted">${esc(unit.subtitle)}</small></span>
                    </span>
                    <span class="pill">${unit.lessons.filter((l) => isDone(l.id)).length}/${unit.lessons.length}</span>
                  </summary>
                  <div class="stack" style="gap:8px;margin-top:12px">
                    ${unit.lessons.map((lesson, li) => `
                      <button class="lesson-row ${isDone(lesson.id) ? 'lesson-row--done' : ''}" data-lesson="${lesson.id}">
                        <span class="lesson-row__num">${isDone(lesson.id) ? icon('check') : li + 1}</span>
                        <span style="text-align:left">
                          <h4 style="font-size:14px;font-weight:650">${esc(lesson.title)}</h4>
                          <small class="muted" style="font-size:12px">${lesson.minutes} min · ${lesson.xp} XP</small>
                        </span>
                        <span class="muted">${icon(isDone(lesson.id) ? 'check' : 'chevronRight')}</span>
                      </button>`).join('')}
                  </div>
                </details>`).join('')}
            </div>
          </div>

          <div class="card">
            <div class="card__title">${icon('inbox')} ${t('Devoirs', 'Homework')}</div>
            <div class="stack" style="margin-top:12px;gap:10px">
              ${hw.map((h) => `
                <div class="homework-card card card--flat" style="background:var(--surface-sunken)">
                  <div class="homework-card__head">
                    <strong style="font-size:14px">${esc(h.title)}</strong>
                    <span class="pill pill--warning">${icon('clock')} ${fmt.shortDate(h.due)}</span>
                  </div>
                  <p class="muted" style="font-size:13px">${esc(h.instruction)}</p>
                  <div class="row" style="gap:8px">
                    <span class="pill">${h.points} pts</span>
                    <span class="pill">${h.exercises.length} ${t('exercices', 'exercises')}</span>
                    <button class="btn btn--soft btn--sm" data-homework="${h.id}">${t('Commencer', 'Start')}</button>
                  </div>
                </div>`).join('')}
            </div>
          </div>
        </div>

        <aside class="stack">
          <div class="card">
            <div class="card__title">${icon('file')} ${t('Ressources', 'Resources')}</div>
            <div class="stack" style="gap:2px;margin-top:10px">
              ${resourcesFor(course).map((r) => `
                <button class="resource-row" data-resource="${esc(r.title)}">
                  <span class="resource-row__kind">${r.kind}</span>
                  <span class="grow" style="text-align:left">
                    <span style="font-size:13px;font-weight:600;display:block" class="truncate">${esc(r.title)}</span>
                    <small class="muted" style="font-size:11px">${r.size || 'lien'} · ${fmt.relative(r.updated)}</small>
                  </span>
                  ${icon('download')}
                </button>`).join('')}
            </div>
          </div>

          <div class="card">
            <div class="card__title">${icon('chart')} ${t('Ta progression', 'Your progress')}</div>
            <div class="row" style="margin-top:12px;gap:16px">
              <div class="ring" style="--p:${pct / 100};--size:76px">
                <svg viewBox="0 0 70 70"><circle cx="35" cy="35" r="28"/><circle cx="35" cy="35" r="28"/></svg>
                <span class="ring__label">${pct}%</span>
              </div>
              <div class="grow">
                <div class="stat"><span class="stat__value" style="font-size:20px">${doneCount(course)}/${lessonsOf(course).length}</span><span class="stat__label">${t('leçons terminées', 'lessons completed')}</span></div>
              </div>
            </div>
            <button class="btn btn--primary btn--block" style="margin-top:16px" data-action="start">${icon('play')} ${t('Reprendre', 'Resume')}</button>
          </div>

          <div class="card">
            <div class="card__title">${icon('users')} ${t('Classe', 'Class')}</div>
            <p class="muted" style="font-size:13px;margin-top:6px">${esc(course.teacher)} · ${esc(course.filiereName)}</p>
            <button class="btn btn--ghost btn--block btn--sm" style="margin-top:12px" data-action="chat">${icon('chat')} ${t('Poser une question', 'Ask a question')}</button>
          </div>
        </aside>
      </div>`;
  },
  mount(root, { params }) {
    const course = courseByCode(params.code);
    $('[data-action="back"]', root).addEventListener('click', () => history.back());
    window.scrollTo({ top: 0 });
    const go = () => navigate(`/course/${course.code}/path`);
    $$('[data-action="start"]', root).forEach((b) => b.addEventListener('click', go));
    $$('[data-lesson]', root).forEach((b) => b.addEventListener('click', () => navigate(`/course/${course.code}/lesson/${b.dataset.lesson}`)));
    $$('[data-resource]', root).forEach((b) => b.addEventListener('click', () => toast(t('Ressource de démonstration — aucun fichier réel n’est stocké.', 'Demo resource — no real file is stored.'), 'info')));
    $$('[data-homework]', root).forEach((b) => b.addEventListener('click', () => {
      const hw = homeworkFor(course).find((h) => h.id === b.dataset.homework);
      openModal({
        title: hw.title,
        wide: true,
        body: `<p class="soft">${esc(hw.instruction)}</p>
          <div class="stack" style="margin-top:16px">
            ${hw.exercises.map((ex, i) => `<div class="card card--flat" style="background:var(--surface-sunken)">
              <strong style="font-size:14px">${i + 1}. ${esc(ex.prompt)}</strong>
              ${ex.options ? `<ol class="muted" style="font-size:13px;margin-top:6px;padding-left:18px;list-style:disc">${ex.options.map((o) => `<li>${esc(o)}</li>`).join('')}</ol>` : ''}
            </div>`).join('')}
          </div>`,
        actions: `<button class="btn btn--ghost" data-action="modal-close">${t('Fermer', 'Close')}</button>
          <button class="btn btn--primary" data-action="hw-submit">${t('Déposer mon travail', 'Submit work')}</button>`,
        onMount(modal) {
          modal.querySelector('[data-action="hw-submit"]').addEventListener('click', () => {
            closeModal();
            toast(t('Travail déposé — correction sous 48h.', 'Work submitted — feedback within 48h.'), 'success');
          });
          modal.querySelectorAll('[data-action="modal-close"]').forEach((b) => b.addEventListener('click', closeModal));
        },
      });
    }));
    $('[data-action="chat"]', root)?.addEventListener('click', () => navigate('/chat'));
  },
};

/* ------------------------------------------------------------------ Parcours */
export const coursePath = {
  tabs: 'student',
  render({ params }) {
    const course = courseByCode(params.code);
    if (!course) return notFound(t('Cours introuvable', 'Course not found'));
    const units = pathFor(course);
    const all = lessonsOf(course);
    const currentId = (all.find((l) => !isDone(l.id)) || all[all.length - 1]).id;
    const pct = courseProgress(course);

    return `
      <div class="page-head">
        <div>
          <button class="btn btn--ghost btn--sm" data-action="back" style="margin-bottom:8px">${icon('arrowLeft')} ${esc(course.code)}</button>
          <h1>${esc(course.title)}</h1>
          <p>${t('Parcours', 'Path')} · ${all.filter((l) => isDone(l.id)).length}/${all.length} ${t('leçons', 'lessons')} · ${pct}%</p>
        </div>
        <div class="row">
          <span class="pill pill--primary">${icon('bolt')} ${state.xp} XP</span>
        </div>
      </div>

      <div class="bar" style="margin-bottom:24px"><span style="width:${pct}%"></span></div>

      <div class="path">
        ${units.map((unit, ui) => `
          <section class="path__unit">
            <div class="path__unit-head">
              <span class="icon-badge">${icon(unit.icon)}</span>
              <h3>${esc(unit.title)}</h3>
              <small>${esc(unit.subtitle)}</small>
            </div>
            <div class="path__nodes">
              ${unit.lessons.map((lesson, li) => {
                const done = isDone(lesson.id);
                const current = lesson.id === currentId && !done;
                const locked = !done && !current;
                const cls = done ? 'node--done' : current ? 'node--current' : 'node--locked';
                return `
                  <button class="node ${cls}" data-lesson="${lesson.id}" ${locked ? 'disabled' : ''}>
                    <span class="node__bubble">${icon(done ? 'check' : locked ? 'lock' : 'play')}</span>
                    <span class="node__label">${esc(lesson.title.split(' · ')[0])}</span>
                    <span class="node__sub">${lesson.minutes} min · ${lesson.xp} XP</span>
                  </button>`;
              }).join('')}
            </div>
          </section>`).join('')}
      </div>`;
  },
  mount(root, { params }) {
    $('[data-action="back"]', root).addEventListener('click', () => navigate(`/course/${params.code}`));
    $$('[data-lesson]', root).forEach((n) => n.addEventListener('click', () => {
      if (n.disabled) { toast(t('Termine d’abord la leçon en cours.', 'Finish the current lesson first.'), 'info'); return; }
      navigate(`/course/${params.code}/lesson/${n.dataset.lesson}`);
    }));
  },
};

/* --------------------------------------------------------------------- Leçon */
let session = null;

export const lessonPlayer = {
  tabs: 'student',
  render({ params }) {
    const course = courseByCode(params.code);
    if (!course) return notFound(t('Cours introuvable', 'Course not found'));
    const lesson = lessonsOf(course).find((l) => l.id === params.lessonId);
    if (!lesson) return notFound(t('Leçon introuvable', 'Lesson not found'));

    session = {
      course,
      lesson,
      steps: buildSteps(lesson),
      index: 0,
      answered: false,
      correct: false,
      picked: null,
      order: [],
      errors: 0,
      completed: false,
    };
    return `<div class="lesson" id="lesson-root">${renderStep(session)}</div>`;
  },
  mount(root, { params }) {
    if (!session) return;
    const rootEl = $('#lesson-root', root);
    const paint = () => {
      rootEl.innerHTML = renderStep(session);
      bind();
      rootEl.classList.remove('view');
      void rootEl.offsetWidth;
      revealOnScroll(rootEl);
    };
    const bind = () => {
      $('[data-action="quit"]', rootEl)?.addEventListener('click', () => navigate(`/course/${params.code}/path`));

      // Choix QCM
      $$('[data-option]', rootEl).forEach((opt) => opt.addEventListener('click', () => {
        if (session.answered) return;
        session.picked = Number(opt.dataset.option);
        $$('[data-option]', rootEl).forEach((o) => o.classList.toggle('option--selected', o === opt));
      }));

      // Vrai / faux
      $$('[data-tf]', rootEl).forEach((btn) => btn.addEventListener('click', () => {
        if (session.answered) return;
        session.picked = btn.dataset.tf === 'true';
        $$('[data-tf]', rootEl).forEach((b) => b.classList.toggle('option--selected', b === btn));
      }));

      // Ordonnancement
      $$('[data-order]', rootEl).forEach((item) => item.addEventListener('click', () => {
        if (session.answered) return;
        const value = item.dataset.order;
        if (session.order.includes(value)) session.order = session.order.filter((v) => v !== value);
        else session.order.push(value);
        paintOrder(rootEl);
      }));

      // Saisie libre
      $('[data-text-answer]', rootEl)?.addEventListener('input', (e) => { session.picked = e.target.value; });

      $('[data-action="check"]', rootEl)?.addEventListener('click', () => {
        const step = session.steps[session.index];
        if (step.type !== 'exercise') { next(); return; }
        if (!session.answered) {
          if (!isAnswerReady(session, step.ex)) {
            toast(t('Choisis une réponse avant de vérifier.', 'Pick an answer before checking.'), 'info');
            return;
          }
          session.answered = true;
          session.correct = evaluate(session, step.ex);
          if (!session.correct) session.errors += 1;
          paint();
          return;
        }
        next();
      });

      $('[data-action="exit"]', rootEl)?.addEventListener('click', () => navigate(`/course/${params.code}/path`));
      $('[data-action="retry"]', rootEl)?.addEventListener('click', () => {
        session.answered = false; session.correct = false; session.picked = null; session.order = [];
        paint();
      });
    };

    const next = () => {
      if (session.index >= session.steps.length - 1) return;
      session.index++;
      session.answered = false;
      session.correct = false;
      session.picked = null;
      session.order = [];
      paint();
      if (session.steps[session.index]?.type === 'done') finish();
    };

    // Enregistre la progression une seule fois, puis célèbre le résultat.
    const finish = () => {
      if (session.completed) return;
      session.completed = true;
      const gained = completeLesson(session.lesson);
      if (gained) {
        const anchor = $('.lesson__card', rootEl);
        xpFloat(gained, anchor);
      }
      confetti(70);
      paint();
    };

    bind();
  },
};

function buildSteps(lesson) {
  return [
    { type: 'intro' },
    ...lesson.theory.map((paragraph, i) => ({ type: 'theory', paragraph, index: i })),
    ...lesson.examples.map((example) => ({ type: 'example', example })),
    ...lesson.exercises.map((ex) => ({ type: 'exercise', ex })),
    { type: 'done' },
  ];
}

function renderStep(session) {
  const step = session.steps[session.index];
  const total = session.steps.length;
  const pct = Math.round((session.index / (total - 1)) * 100);
  const lesson = session.lesson;
  const head = `
    <div class="lesson__top">
      <button class="btn btn--ghost btn--icon btn--sm" data-action="quit" aria-label="${t('Quitter', 'Quit')}">${icon('close')}</button>
      <div class="lesson__progress"><span style="width:${pct}%"></span></div>
      <span class="xp-pill">${icon('bolt')} ${lesson.xp} XP</span>
    </div>`;

  if (step.type === 'intro') {
    return `${head}
      <div class="lesson__card stagger">
        <span class="lesson__kicker">${esc(session.course.code)} · ${t('Leçon', 'Lesson')}</span>
        <h1 style="margin:10px 0 6px">${esc(lesson.title)}</h1>
        <p class="soft">${esc(lesson.subtitle)}</p>
        <div class="row" style="gap:14px;margin-top:18px;flex-wrap:wrap">
          <span class="pill">${icon('clock')} ${lesson.minutes} min</span>
          <span class="pill">${icon('book')} ${lesson.theory.length} ${t('points de théorie', 'theory points')}</span>
          <span class="pill">${icon('target')} ${lesson.exercises.length} ${t('exercices', 'exercises')}</span>
        </div>
        <div class="lesson__foot" style="margin-top:24px">
          <span class="muted" style="font-size:13px">${t('Utilise ← → pour naviguer', 'Use ← → to navigate')}</span>
          <button class="btn btn--primary" data-action="check">${t('Commencer', 'Start')} ${icon('arrowRight')}</button>
        </div>
      </div>`;
  }

  if (step.type === 'theory') {
    return `${head}
      <div class="lesson__card view">
        <span class="lesson__kicker">${t('Théorie', 'Theory')} ${step.index + 1}/${lesson.theory.length}</span>
        <div class="theory" style="margin-top:14px">
          <p style="font-size:16px;line-height:1.75">${esc(step.paragraph)}</p>
        </div>
        <div class="lesson__foot" style="margin-top:24px">
          <span class="muted" style="font-size:13px">${session.index + 1} / ${total}</span>
          <button class="btn btn--primary" data-action="check">${t('Suivant', 'Next')} ${icon('arrowRight')}</button>
        </div>
      </div>`;
  }

  if (step.type === 'example') {
    const ex = step.example;
    return `${head}
      <div class="lesson__card view">
        <span class="lesson__kicker">${t('Exemple', 'Example')}</span>
        <h2 style="margin:8px 0 10px;font-size:20px">${esc(ex.title)}</h2>
        <p class="soft" style="line-height:1.7">${esc(ex.body)}</p>
        ${ex.code ? `<pre class="code" style="margin-top:16px">${esc(ex.code)}</pre>` : ''}
        ${ex.footnote ? `<p class="muted" style="font-size:12.5px;margin-top:10px">${esc(ex.footnote)}</p>` : ''}
        <div class="lesson__foot" style="margin-top:24px">
          <span class="muted" style="font-size:13px">${t('Prends le temps de relire', 'Take your time')}</span>
          <button class="btn btn--primary" data-action="check">${t('Suivant', 'Next')} ${icon('arrowRight')}</button>
        </div>
      </div>`;
  }

  if (step.type === 'exercise') {
    const ex = step.ex;
    const exerciseIndex = session.steps.slice(0, session.index + 1).filter((s) => s.type === 'exercise').length;
    const totalEx = lesson.exercises.length;
    const feedback = session.answered ? renderFeedback(session, ex) : '';
    const actionLabel = session.answered ? (session.correct ? t('Continuer', 'Continue') : t('Continuer quand même', 'Continue anyway')) : t('Vérifier', 'Check');

    return `${head}
      <div class="lesson__card view">
        <div class="row row--between" style="margin-bottom:14px">
          <span class="lesson__kicker">${t('Exercice', 'Exercise')} ${exerciseIndex}/${totalEx}</span>
          <span class="pill">${t({ qcm: 'Choix multiple', trueFalse: 'Vrai / faux', ordering: 'Ordre', textInput: 'Réponse libre' }[ex.type], { qcm: 'Multiple choice', trueFalse: 'True / false', ordering: 'Ordering', textInput: 'Free answer' }[ex.type])}</span>
        </div>
        <div class="exercise">
          <p class="exercise__prompt">${esc(ex.prompt)}</p>
          ${ex.type === 'qcm' ? `
            <div class="options">
              ${ex.options.map((opt, i) => {
                let cls = 'option';
                if (session.answered) {
                  if (i === ex.correct) cls += ' option--correct';
                  else if (i === session.picked) cls += ' option--wrong';
                } else if (i === session.picked) cls += ' option--selected';
                return `<button class="${cls}" data-option="${i}">
                  <span class="option__key">${String.fromCharCode(65 + i)}</span>
                  <span>${esc(opt)}</span>
                </button>`;
              }).join('')}
            </div>` : ''}

          ${ex.type === 'trueFalse' ? `
            <div class="tf-grid">
              ${[[true, t('Vrai', 'True')], [false, t('Faux', 'False')]].map(([value, label]) => {
                let cls = 'option';
                if (session.answered) {
                  if (value === ex.answer) cls += ' option--correct';
                  else if (value === session.picked) cls += ' option--wrong';
                } else if (value === session.picked) cls += ' option--selected';
                return `<button class="${cls}" data-tf="${value}" style="justify-content:center">
                  <span class="option__key">${value ? 'V' : 'F'}</span>${label}</button>`;
              }).join('')}
            </div>` : ''}

          ${ex.type === 'ordering' ? `
            <p class="order-slot__hint">${t('Clique dans le bon ordre :', 'Click in the right order:')}</p>
            <div class="ordering" data-ordering>
              ${ex.items.map((item) => {
                const pos = session.order.indexOf(item);
                return `<button class="order-item ${pos >= 0 ? 'is-picked' : ''}" data-order="${esc(item)}">
                  <span class="order-item__idx" ${pos >= 0 ? '' : 'style="visibility:hidden"'}>${pos >= 0 ? pos + 1 : ''}</span>
                  <span>${esc(item)}</span>
                </button>`;
              }).join('')}
            </div>` : ''}

          ${ex.type === 'textInput' ? `
            <div class="field">
              <input class="input" data-text-answer value="${esc(session.picked || '')}" placeholder="${t('Ta réponse…', 'Your answer…')}"
                ${session.answered ? 'disabled' : ''} />
              <p class="hint">${t('Les décimales peuvent être écrites avec une virgule.', 'Decimals may use a comma.')}</p>
            </div>` : ''}

          ${feedback}
        </div>

        <div class="lesson__foot" style="margin-top:24px">
          ${session.answered && !session.correct
            ? `<button class="btn btn--ghost" data-action="retry">${t('Réessayer', 'Try again')}</button>`
            : `<span class="muted" style="font-size:13px">${t('Pas de pression, tu peux refaire la leçon.', 'No pressure, you can replay the lesson.')}</span>`}
          <button class="btn btn--primary" data-action="check">${actionLabel}</button>
        </div>
      </div>`;
  }

  // Fin
  const done = isDone(lesson.id);
  const perfect = session.errors === 0;
  return `${head}
    <div class="lesson__card center stagger">
      <div style="font-size:44px;line-height:1">${perfect || done ? '🎉' : '💪'}</div>
      <h1 style="margin-top:12px">${t('Leçon terminée !', 'Lesson complete!')}</h1>
      <p class="soft">${esc(lesson.title)}</p>
      <div class="row" style="justify-content:center;gap:14px;margin-top:18px;flex-wrap:wrap">
        <span class="pill pill--success">${icon('bolt')} +${lesson.xp} XP</span>
        <span class="pill">${icon('flame')} ${t('série', 'streak')} ${state.streak} ${t('jours', 'days')}</span>
      </div>
      <div class="lesson__foot" style="margin-top:26px;justify-content:center;gap:10px;flex-wrap:wrap">
        <button class="btn btn--ghost" data-action="retry">${t('Revoir', 'Review')}</button>
        <button class="btn btn--primary" data-action="exit">${t('Retour au parcours', 'Back to path')} ${icon('arrowRight')}</button>
      </div>
    </div>`;
}

function renderFeedback(session, ex) {
  return `
    <div class="feedback ${session.correct ? 'feedback--ok' : 'feedback--ko'}">
      <strong>${icon(session.correct ? 'check' : 'alert')} ${session.correct ? t('Bonne réponse !', 'Correct!') : t('Pas tout à fait.', 'Not quite.')}</strong>
      <p>${esc(ex.explanation || t('Relis la théorie puis réessaie.', 'Reread the theory and try again.'))}</p>
    </div>`;
}

function paintOrder(rootEl) {
  $$('[data-order]', rootEl).forEach((item) => {
    const pos = session.order.indexOf(item.dataset.order);
    item.classList.toggle('is-picked', pos >= 0);
    const idx = $('.order-item__idx', item);
    idx.textContent = pos >= 0 ? String(pos + 1) : '';
    idx.style.visibility = pos >= 0 ? 'visible' : 'hidden';
  });
}

function isAnswerReady(session, ex) {
  if (ex.type === 'qcm') return session.picked !== null && session.picked !== undefined;
  if (ex.type === 'trueFalse') return typeof session.picked === 'boolean';
  if (ex.type === 'ordering') return session.order.length === ex.items.length;
  if (ex.type === 'textInput') return String(session.picked || '').trim().length > 0;
  return true;
}

function evaluate(session, ex) {
  if (ex.type === 'qcm') return session.picked === ex.correct;
  if (ex.type === 'trueFalse') return session.picked === ex.answer;
  if (ex.type === 'ordering') return session.order.every((value, i) => value === ex.items[i]);
  if (ex.type === 'textInput') {
    const normalize = (s) => String(s).toLowerCase().replace(/\s+/g, '').replace(',', '.');
    return (ex.accept || []).some((a) => normalize(a) === normalize(session.picked));
  }
  return true;
}

/* ------------------------------------------------------------- utilitaires */
function courseCardLite(course) {
  return `<button class="card course-card" data-course="${course.code}" style="--c-color:${course.color}">
    <span class="course-card__badge">${esc(course.code.slice(0, 4))}</span>
    <strong style="font-size:14px">${esc(course.title)}</strong>
    <small class="muted">${courseProgress(course)}% · ${course.level}</small>
  </button>`;
}

function daysOfWeek(list) {
  const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  const lessons = list.flatMap((c) => lessonsOf(c));
  const doneLessons = lessons.filter((l) => isDone(l.id)).length;
  return labels.map((label, i) => {
    const base = lessons.length ? doneLessons / Math.max(1, lessons.length) : 0;
    const value = Math.min(1, 0.18 + (((djb(i + 3) % 60) / 100) * (0.5 + base)));
    return [label, Number(value.toFixed(2))];
  });
}

function djb(n) {
  let h = 5381;
  for (let i = 0; i < String(n).length; i++) h = ((h << 5) + h + String(n).charCodeAt(i)) >>> 0;
  return h % 100;
}

function notFound(message) {
  return `<div class="empty" style="margin-top:60px">${icon('alert')}<h3>${esc(message)}</h3>
    <p>${t('Le lien est peut-être périmé.', 'The link may be out of date.')}</p>
    <button class="btn btn--primary" onclick="location.hash='#/'">${t('Retour à l’accueil', 'Back home')}</button></div>`;
}
