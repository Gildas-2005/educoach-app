/* ==========================================================================
   Planning et notes
   ========================================================================== */
import { icon, esc, $, $$, fmt } from '../lib/dom.js';
import { t } from '../lib/i18n.js';
import { navigate } from '../router.js';
import { myCourses, scheduleFor, gradesFor, average, courseByCode, courseProgress } from '../store.js';

const DAY_NAMES = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
const todayIndex = () => (new Date().getDay() + 6) % 7;

/* ------------------------------------------------------------------ Planning */
export const scheduleScreen = {
  tabs: 'student',
  render() {
    const list = myCourses();
    const sessions = scheduleFor(list);
    const week = Array.from({ length: 5 }, (_, i) => sessions.filter((s) => s.day === i + 1));
    const today = todayIndex();
    const totalHours = sessions.reduce((s, x) => s + (x.end - x.start), 0);

    return `
      <div class="page-head">
        <div><h1>${t('Planning', 'Schedule')}</h1><p>${t('Semaine du', 'Week of')} ${fmt.date(Date.now())}</p></div>
        <div class="row">
          <span class="pill pill--primary">${icon('clock')} ${totalHours}h ${t('cette semaine', 'this week')}</span>
        </div>
      </div>

      <div class="row row--between" style="margin-bottom:16px;flex-wrap:wrap;gap:10px">
        <div class="row" style="gap:8px;flex-wrap:wrap">
          ${[['CM', t('Cours magistral', 'Lecture')], ['TD', t('Travaux dirigés', 'Tutorial')], ['TP', t('Travaux pratiques', 'Lab')]].map(([k, label]) => `
            <span class="chip" style="cursor:default"><span class="tag-dot" style="background:${k === 'CM' ? 'var(--primary)' : k === 'TD' ? 'var(--secondary)' : 'var(--accent)'}"></span>${label}</span>`).join('')}
        </div>
        <button class="btn btn--ghost btn--sm" data-action="ical">${icon('download')} ${t('Exporter (.ics)', 'Export (.ics)')}</button>
      </div>

      <div class="week">
        ${week.map((daySessions, i) => `
          <div class="week__day ${i === today ? 'week__day--today' : ''}">
            <header>${DAY_NAMES[i].slice(0, 3)}<br><span style="font-weight:600;text-transform:none;letter-spacing:0">${daySessions.length || '—'}</span></header>
            ${daySessions.length ? daySessions.map((s) => `
              <button class="session session--${s.type}" data-course="${s.code}">
                <span class="session__time">${fmt.time(s.start)} – ${fmt.time(s.end)}</span>
                <strong>${esc(s.title)}</strong>
                <small>${esc(s.room)} · ${esc(s.teacher.split(' ').slice(-1)[0])}</small>
              </button>`).join('')
              : `<div class="muted center" style="font-size:12px;padding:16px 0">${t('Libre', 'Free')}</div>`}
          </div>`).join('')}
      </div>

      <div class="section split-2">
        <div class="card">
          <div class="card__title">${icon('calendar')} ${t('Charge par cours', 'Load per course')}</div>
          <div class="stack" style="margin-top:14px;gap:10px">
            ${list.slice(0, 6).map((c) => {
              const count = sessions.filter((s) => s.code === c.code).length;
              const hours = sessions.filter((s) => s.code === c.code).reduce((a, s) => a + (s.end - s.start), 0);
              return `
                <div class="row" style="gap:10px">
                  <span class="tag-dot" style="background:${c.color}"></span>
                  <span class="grow truncate" style="font-size:13px">${esc(c.title)}</span>
                  <span class="pill">${count} ${t('séances', 'sessions')}</span>
                  <span class="pill">${hours}h</span>
                </div>`;
            }).join('')}
          </div>
        </div>
        <div class="card">
          <div class="card__title">${icon('info')} ${t('Bon à savoir', 'Good to know')}</div>
          <ul class="stack" style="margin-top:12px;gap:10px;font-size:13px;color:var(--text-soft)">
            <li class="row" style="align-items:flex-start;gap:10px">${icon('clock')}<span>${t('Les séances sont calculées depuis le volume horaire de chaque cours.', 'Sessions are derived from each course’s weekly hours.')}</span></li>
            <li class="row" style="align-items:flex-start;gap:10px">${icon('wifi')}<span>${t('L’export .ics fonctionne hors ligne, sans compte externe.', 'The .ics export works offline, with no external account.')}</span></li>
            <li class="row" style="align-items:flex-start;gap:10px">${icon('bell')}<span>${t('Active les notifications dans ton profil pour les rappels.', 'Enable notifications in your profile for reminders.')}</span></li>
          </ul>
        </div>
      </div>`;
  },
  mount(root) {
    $$('[data-course]', root).forEach((b) => b.addEventListener('click', () => navigate(`/course/${b.dataset.course}`)));
    $('[data-action="ical"]', root).addEventListener('click', () => exportIcs());
  },
};

function exportIcs() {
  const sessions = scheduleFor(myCourses());
  const pad = (n) => String(n).padStart(2, '0');
  const now = new Date();
  const monday = new Date(now);
  monday.setDate(now.getDate() - ((now.getDay() + 6) % 7));
  const stamp = (d) => `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}T${pad(d.getHours())}${pad(d.getMinutes())}00`;

  const lines = ['BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:-//Educoach//FR', 'CALSCALE:GREGORIAN'];
  sessions.forEach((s) => {
    const start = new Date(monday);
    start.setDate(monday.getDate() + (s.day - 1));
    start.setHours(Math.floor(s.start), Math.round((s.start % 1) * 60), 0, 0);
    const end = new Date(start);
    end.setHours(Math.floor(s.end), 0, 0, 0);
    lines.push(
      'BEGIN:VEVENT',
      `UID:${s.code}-${s.type}@educoach`,
      `DTSTAMP:${stamp(now)}`,
      `DTSTART:${stamp(start)}`,
      `DTEND:${stamp(end)}`,
      `SUMMARY:${s.title} (${s.type})`,
      `LOCATION:${s.room}`,
      `DESCRIPTION:${s.teacher}`,
      'END:VEVENT',
    );
  });
  lines.push('END:VCALENDAR');

  const blob = new Blob([lines.join('\r\n')], { type: 'text/calendar;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'educoach-planning.ics';
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 1500);
}

/* --------------------------------------------------------------------- Notes */
export const gradesScreen = {
  tabs: 'student',
  render() {
    const list = myCourses();
    const grades = gradesFor(list);
    const avg = average(grades);
    const best = grades.reduce((a, g) => (!a || g.score > a.score ? g : a), null);
    const worst = grades.reduce((a, g) => (!a || g.score < a.score ? g : a), null);
    const validated = grades.filter((g) => g.score >= 10).length;
    const distribution = [0, 0, 0, 0];
    grades.forEach((g) => {
      if (g.score < 10) distribution[0]++;
      else if (g.score < 14) distribution[1]++;
      else if (g.score < 17) distribution[2]++;
      else distribution[3]++;
    });

    return `
      <div class="page-head">
        <div><h1>${t('Mes notes', 'My grades')}</h1><p>${grades.length} ${t('évaluations enregistrées', 'recorded assessments')}</p></div>
        <span class="pill ${avg >= 10 ? 'pill--success' : 'pill--danger'}">${icon('chart')} ${t('Moyenne', 'Average')} ${avg.toFixed(2)}/20</span>
      </div>

      <div class="grid grid--2">
        <div class="card">
          <div class="row row--between">
            <div class="card__title">${icon('target')} ${t('Moyenne générale', 'Overall average')}</div>
            <span class="pill ${avg >= 10 ? 'pill--success' : 'pill--danger'}">${validated}/${grades.length} ${t('validés', 'passed')}</span>
          </div>
          <div class="row" style="gap:20px;margin-top:16px">
            <div class="ring" style="--p:${Math.min(1, avg / 20)};--size:96px">
              <svg viewBox="0 0 70 70"><circle cx="35" cy="35" r="28"/><circle cx="35" cy="35" r="28"/></svg>
              <span class="ring__label" style="font-size:16px">${avg.toFixed(1)}</span>
            </div>
            <div class="grow">
              <div class="stat"><span class="stat__value">${best ? best.score.toFixed(1) : '—'}</span><span class="stat__label">${t('meilleure note', 'best grade')}</span></div>
              <div class="stat" style="margin-top:8px"><span class="stat__value" style="font-size:18px">${worst ? worst.score.toFixed(1) : '—'}</span><span class="stat__label">${t('note la plus basse', 'lowest grade')}</span></div>
            </div>
          </div>
          <div class="dist" style="margin-top:18px">
            ${[['< 10', 'danger'], ['10-14', 'warning'], ['14-17', 'primary'], ['17-20', 'success']].map(([label], i) => `
              <div><strong>${distribution[i]}</strong><span>${label}</span></div>`).join('')}
          </div>
        </div>

        <div class="card">
          <div class="card__title">${icon('book')} ${t('Moyenne par cours', 'Average per course')}</div>
          <div class="stack" style="margin-top:14px;gap:12px">
            ${list.slice(0, 6).map((c) => {
              const gs = grades.filter((g) => g.code === c.code);
              const m = average(gs);
              return `
                <div>
                  <div class="row row--between" style="font-size:13px;margin-bottom:4px">
                    <span class="truncate">${esc(c.title)}</span>
                    <strong style="font-variant-numeric:tabular-nums">${gs.length ? m.toFixed(1) : '—'}</strong>
                  </div>
                  <div class="bar bar--sm ${m >= 14 ? 'bar--success' : m >= 10 ? 'bar--warning' : m > 0 ? 'bar--danger' : ''}">
                    <span style="width:${gs.length ? Math.min(100, (m / 20) * 100) : 0}%"></span>
                  </div>
                </div>`;
            }).join('')}
          </div>
        </div>
      </div>

      <div class="section">
        <div class="section__head"><h2>${t('Détail des évaluations', 'Assessment details')}</h2></div>
        <div class="grade-list">
          ${grades.slice(0, 18).map((g) => {
            const cls = g.score >= 14 ? 'ok' : g.score >= 10 ? 'mid' : 'ko';
            return `
              <div class="grade-row">
                <div class="grow">
                  <strong style="font-size:14px">${esc(g.label)}</strong>
                  <div class="muted" style="font-size:12px">${esc(g.course)} · ${esc(g.code)}</div>
                </div>
                <span class="pill">${(g.score / g.max) >= 0.5 ? t('validé', 'passed') : t('à rattraper', 'to retake')}</span>
                <span class="grade-score grade-score--${cls}">${g.score.toFixed(1)}<small class="muted" style="font-size:11px">/${g.max}</small></span>
              </div>`;
          }).join('')}
        </div>
      </div>`;
  },
};
