/* ==========================================================================
   Espaces enseignant et administrateur
   ========================================================================== */
import { icon, esc, $, $$, fmt, toast, openModal, closeModal, confirmDialog } from '../lib/dom.js';
import { t } from '../lib/i18n.js';
import { navigate } from '../router.js';
import {
  state, currentUser, myCourses, courseProgress, ALL_COURSES, filiereById, logout,
  setTheme, setLang, average, gradesFor,
} from '../store.js';
import { TEACHER_SUBMISSIONS, TEACHER_STUDENTS, ADMIN_ACCOUNTS, ADMIN_ACTIVITY } from '../data/content.js';

/* ----------------------------------------------------------------- Enseignant */
export const teacherShell = {
  tabs: 'teacher',
  render() {
    const user = currentUser();
    const courses = ALL_COURSES.filter((c) => c.filiereId === (state.profile.filiereId || 'fi-inf')).slice(0, 6);
    const toGrade = TEACHER_SUBMISSIONS.filter((s) => s.status === 'à corriger');
    const atRisk = TEACHER_STUDENTS.filter((s) => s.risk);
    const avgProgress = Math.round(TEACHER_STUDENTS.reduce((a, s) => a + s.progress, 0) / TEACHER_STUDENTS.length);

    return `
      <div class="page-head">
        <div>
          <span class="page-head__eyebrow">${t('Espace enseignant', 'Teacher space')}</span>
          <h1>${t('Bonjour', 'Hello')} ${esc(user.fullName)} 👋</h1>
          <p>${esc(filiereById(state.profile.filiereId).name)} · ${user.status === 'pending' ? t('compte en attente de validation', 'account awaiting validation') : t('compte actif', 'active account')}</p>
        </div>
        <div class="row">
          <button class="btn btn--ghost btn--sm" data-action="theme">${icon(state.theme === 'dark' ? 'sun' : 'moon')}</button>
          <button class="btn btn--ghost btn--sm" data-action="logout">${icon('logout')} ${t('Quitter', 'Sign out')}</button>
        </div>
      </div>

      ${user.status === 'pending' ? `
        <div class="card" style="border-color:color-mix(in srgb, var(--warning) 45%, var(--border));margin-bottom:20px">
          <div class="row" style="align-items:flex-start;gap:12px">
            <span class="icon-badge" style="background:color-mix(in srgb, var(--warning) 18%, transparent);color:#8a6100">${icon('clock')}</span>
            <div>
              <strong>${t('Ton compte est en attente de validation', 'Your account is awaiting validation')}</strong>
              <p class="muted" style="font-size:13px">${t('Un administrateur doit approuver ton rattachement avant la publication de tes cours. Tu peux préparer ton contenu en attendant.', 'An administrator must approve your attachment before you can publish courses. You can prepare content meanwhile.')}</p>
            </div>
          </div>
        </div>` : ''}

      <div class="kpi-grid">
        ${[
          ['inbox', String(toGrade.length), t('copies à corriger', 'submissions to grade'), 'down'],
          ['users', String(TEACHER_STUDENTS.length), t('étudiants actifs', 'active students'), 'up'],
          ['bolt', '4 260', t('XP distribués cette semaine', 'XP awarded this week'), 'up'],
          ['chart', `${avgProgress}%`, t('progression moyenne', 'average progress'), 'up'],
        ].map(([ic, value, label, trend]) => `
          <div class="card kpi">
            <span class="icon-badge">${icon(ic)}</span>
            <span class="kpi__value">${value}</span>
            <span class="muted" style="font-size:12.5px">${label}</span>
            <span class="kpi__trend kpi__trend--${trend}">${icon(trend === 'up' ? 'arrowUp' : 'chart')} ${trend === 'up' ? '+' : ''}${trend === 'up' ? '12' : '3'}% ${t('vs semaine dernière', 'vs last week')}</span>
          </div>`).join('')}
      </div>

      <div class="section split-2">
        <div class="stack">
          <div class="card">
            <div class="row row--between" style="margin-bottom:12px">
              <div class="card__title">${icon('inbox')} ${t('Rendus récents', 'Recent submissions')}</div>
              <span class="pill">${t('4 derniers', 'last 4')}</span>
            </div>
            <div class="stack" style="gap:8px">
              ${TEACHER_SUBMISSIONS.map((s) => `
                <div class="grade-row">
                  <div class="grow">
                    <strong style="font-size:14px">${esc(s.title)}</strong>
                    <div class="muted" style="font-size:12px">${esc(s.student)} · ${esc(s.course)} · ${fmt.relative(s.at)}</div>
                  </div>
                  <span class="pill ${s.status === 'corrigé' ? 'pill--success' : 'pill--warning'}">${esc(s.status)}</span>
                  <button class="btn btn--soft btn--sm" data-grade="${esc(s.student)}|${esc(s.course)}">${s.status === 'corrigé' ? t('Revoir', 'Review') : t('Corriger', 'Grade')}</button>
                </div>`).join('')}
            </div>
          </div>

          <div class="card">
            <div class="card__title">${icon('alert')} ${t('Étudiants en difficulté', 'Students at risk')}</div>
            <p class="muted" style="font-size:12.5px;margin-top:4px">${t('Moins de 60 % de complétion sur les 14 derniers jours.', 'Under 60% completion over the last 14 days.')}</p>
            <div class="stack" style="gap:8px;margin-top:12px">
              ${atRisk.length ? atRisk.map((s) => `
                <div class="risk-row">
                  <span class="avatar avatar--sm">${esc(s.name.split(' ').map((w) => w[0]).join(''))}</span>
                  <div><strong>${esc(s.name)}</strong><small>${s.xp} XP · ${s.progress}% ${t('de complétion', 'completion')}</small></div>
                  <div class="row" style="gap:6px">
                    <div class="bar bar--sm bar--danger" style="width:64px"><span style="width:${s.progress}%"></span></div>
                    <button class="btn btn--ghost btn--sm" data-message="${esc(s.name)}">${icon('chat')}</button>
                  </div>
                </div>`).join('') : `<div class="empty" style="padding:20px">${icon('check')}<h3>${t('Aucun étudiant en difficulté', 'No student at risk')}</h3></div>`}
            </div>
          </div>
        </div>

        <div class="stack">
          <div class="card">
            <div class="card__title">${icon('book')} ${t('Mes cours', 'My courses')}</div>
            <div class="stack" style="gap:10px;margin-top:12px">
              ${courses.map((c) => `
                <div>
                  <div class="row row--between" style="font-size:13px">
                    <span class="truncate">${esc(c.title)}</span><strong>${courseProgress(c)}%</strong>
                  </div>
                  <div class="bar bar--sm"><span style="width:${courseProgress(c)}%"></span></div>
                  <div class="row" style="gap:6px;margin-top:6px">
                    <span class="pill" style="font-size:10px">${c.code}</span>
                    <span class="pill" style="font-size:10px">${c.level}</span>
                  </div>
                </div>`).join('')}
            </div>
          </div>

          <div class="card">
            <div class="card__title">${icon('send')} ${t('Annonce à la classe', 'Class announcement')}</div>
            <form id="announce" style="margin-top:10px">
              <textarea class="textarea" name="body" rows="3" placeholder="${t('Ex : TP reporté à jeudi 14h…', 'E.g.: lab postponed to Thursday 2pm…')}"></textarea>
              <button class="btn btn--primary btn--block" style="margin-top:10px" type="submit">${icon('send')} ${t('Publier', 'Publish')}</button>
            </form>
          </div>
        </div>
      </div>

      <div class="section">
        <div class="section__head"><h2>${t('Suivi de la promotion', 'Cohort tracking')}</h2></div>
        <div class="card card--flat" style="padding:0;overflow:hidden">
          <div class="table-wrap">
            <table class="table">
              <thead><tr>
                <th>${t('Étudiant', 'Student')}</th><th>${t('Progression', 'Progress')}</th><th>XP</th><th>${t('Statut', 'Status')}</th><th></th>
              </tr></thead>
              <tbody>
                ${TEACHER_STUDENTS.map((s) => `
                  <tr>
                    <td><div class="row" style="gap:8px"><span class="avatar avatar--sm">${esc(s.name.split(' ').map((w) => w[0]).join(''))}</span>${esc(s.name)}</div></td>
                    <td style="min-width:140px">
                      <div class="row" style="gap:8px">
                        <div class="bar bar--sm ${s.progress >= 75 ? 'bar--success' : s.progress >= 50 ? 'bar--warning' : 'bar--danger'}" style="width:90px"><span style="width:${s.progress}%"></span></div>
                        <small class="muted">${s.progress}%</small>
                      </div>
                    </td>
                    <td class="mono">${fmt.nf(s.xp)}</td>
                    <td><span class="pill ${s.risk ? 'pill--danger' : 'pill--success'}">${s.risk ? t('à suivre', 'watch') : t('à jour', 'on track')}</span></td>
                    <td><button class="btn btn--ghost btn--sm" data-message="${esc(s.name)}">${icon('chat')}</button></td>
                  </tr>`).join('')}
              </tbody>
            </table>
          </div>
        </div>
      </div>`;
  },
  mount(root) {
    $('[data-action="theme"]', root).addEventListener('click', () => setTheme(state.theme === 'dark' ? 'light' : 'dark'));
    $('[data-action="logout"]', root).addEventListener('click', () => { logout(); navigate('/welcome'); });

    $$('[data-grade]', root).forEach((btn) => btn.addEventListener('click', () => {
      const [student, course] = btn.dataset.grade.split('|');
      openModal({
        title: t('Corriger la copie', 'Grade submission'),
        body: `
          <p class="soft">${esc(student)} · ${esc(course)}</p>
          <div class="stack" style="margin-top:16px">
            <div class="field"><label for="score">${t('Note sur 20', 'Score out of 20')}</label>
              <input class="input" id="score" type="number" min="0" max="20" step="0.5" placeholder="14.5" /></div>
            <div class="field"><label for="comment">${t('Commentaire', 'Comment')}</label>
              <textarea class="textarea" id="comment" rows="3" placeholder="${t('Bonne structure, attention à la justification…', 'Good structure, mind the justification…')}"></textarea></div>
          </div>`,
        actions: `<button class="btn btn--ghost" data-action="modal-close">${t('Annuler', 'Cancel')}</button>
          <button class="btn btn--primary" data-action="save">${t('Enregistrer la note', 'Save grade')}</button>`,
        onMount(modal) {
          modal.querySelectorAll('[data-action="modal-close"]').forEach((b) => b.addEventListener('click', closeModal));
          modal.querySelector('[data-action="save"]').addEventListener('click', () => {
            const score = Number(modal.querySelector('#score').value);
            if (!(score >= 0 && score <= 20)) { toast(t('Note invalide (0 à 20).', 'Invalid score (0 to 20).'), 'error'); return; }
            closeModal();
            toast(t('Note enregistrée et notifiée à l’étudiant.', 'Grade saved and student notified.'), 'success');
          });
        },
      });
    }));

    $$('[data-message]', root).forEach((btn) => btn.addEventListener('click', () => {
      toast(t(`Message envoyé à ${btn.dataset.message}.`, `Message sent to ${btn.dataset.message}.`), 'success');
    }));

    $('#announce', root).addEventListener('submit', (e) => {
      e.preventDefault();
      const body = e.target.body.value.trim();
      if (body.length < 3) { toast(t('Message trop court.', 'Message too short.'), 'error'); return; }
      e.target.reset();
      toast(t('Annonce publiée à la classe.', 'Announcement published to the class.'), 'success');
    });
  },
};

/* -------------------------------------------------------------- Administrateur */
export const adminShell = {
  tabs: 'admin',
  render() {
    const accounts = state.adminAccounts || ADMIN_ACCOUNTS;
    const active = accounts.filter((a) => a.status === 'active').length;
    const pending = accounts.filter((a) => a.status === 'pending').length;
    const blocked = accounts.filter((a) => a.status === 'blocked').length;
    const roles = { student: 0, teacher: 0, admin: 0 };
    accounts.forEach((a) => { roles[a.role] = (roles[a.role] || 0) + 1; });
    const total = accounts.length || 1;

    return `
      <div class="page-head">
        <div>
          <span class="page-head__eyebrow">${t('Console d’administration', 'Admin console')}</span>
          <h1>${t('Pilotage de la plateforme', 'Platform overview')}</h1>
          <p>${t('Comptes, validations et conformité.', 'Accounts, validations and compliance.')}</p>
        </div>
        <div class="row">
          <button class="btn btn--ghost btn--sm" data-action="theme">${icon(state.theme === 'dark' ? 'sun' : 'moon')}</button>
          <button class="btn btn--ghost btn--sm" data-action="logout">${icon('logout')} ${t('Quitter', 'Sign out')}</button>
        </div>
      </div>

      <div class="kpi-grid">
        ${[
          ['users', String(active), t('comptes actifs', 'active accounts'), 'up'],
          ['book', String(ALL_COURSES.length), t('cours publiés', 'published courses'), 'up'],
          ['clock', String(pending), t('validations en attente', 'pending validations'), 'down'],
          ['shield', blocked ? String(blocked) : '0', t('comptes bloqués', 'blocked accounts'), 'down'],
        ].map(([ic, value, label, trend]) => `
          <div class="card kpi">
            <span class="icon-badge">${icon(ic)}</span>
            <span class="kpi__value">${value}</span>
            <span class="muted" style="font-size:12.5px">${label}</span>
            <span class="kpi__trend kpi__trend--${trend}">${icon(trend === 'up' ? 'arrowUp' : 'chart')} ${t('cette semaine', 'this week')}</span>
          </div>`).join('')}
      </div>

      <div class="section split-2">
        <div class="card">
          <div class="card__title">${icon('users')} ${t('Comptes', 'Accounts')}</div>
          <div class="search" style="margin:12px 0">${icon('search')}
            <input id="account-search" type="search" placeholder="${t('Rechercher un compte…', 'Search an account…')}" />
          </div>
          <div class="table-wrap">
            <table class="table" id="accounts-table">
              <thead><tr>
                <th>${t('Utilisateur', 'User')}</th><th>${t('Rôle', 'Role')}</th><th>${t('Statut', 'Status')}</th><th>${t('Actions', 'Actions')}</th>
              </tr></thead>
              <tbody>
                ${accounts.map((a, i) => `
                  <tr data-account="${i}" data-search="${esc(`${a.name} ${a.email} ${a.role}`.toLowerCase())}">
                    <td>
                      <div class="row" style="gap:8px">
                        <span class="avatar avatar--sm ${a.role === 'teacher' ? 'avatar--teacher' : a.role === 'admin' ? 'avatar--admin' : ''}">${esc(a.name.split(' ').map((w) => w[0]).join('').slice(0, 2))}</span>
                        <div><strong style="font-size:13px;display:block">${esc(a.name)}</strong><small class="muted" style="font-size:11px">${esc(a.email)}</small></div>
                      </div>
                    </td>
                    <td><span class="pill" style="font-size:10px">${esc(a.role)}</span></td>
                    <td><span class="pill ${a.status === 'active' ? 'pill--success' : a.status === 'pending' ? 'pill--warning' : 'pill--danger'}" style="font-size:10px">${esc(a.status)}</span></td>
                    <td>
                      <div class="row" style="gap:4px">
                        ${a.status === 'pending' ? `<button class="btn btn--soft btn--sm" data-validate="${i}">${t('Valider', 'Approve')}</button>` : ''}
                        ${a.status !== 'blocked' ? `<button class="btn btn--ghost btn--sm" data-block="${i}">${t('Bloquer', 'Block')}</button>` : ''}
                        ${a.status === 'blocked' ? `<button class="btn btn--ghost btn--sm" data-unblock="${i}">${t('Débloquer', 'Unblock')}</button>` : ''}
                      </div>
                    </td>
                  </tr>`).join('')}
              </tbody>
            </table>
          </div>
        </div>

        <div class="stack">
          <div class="card">
            <div class="card__title">${icon('chart')} ${t('Répartition des rôles', 'Role breakdown')}</div>
            <div class="stack" style="gap:12px;margin-top:14px">
              ${Object.entries(roles).map(([role, count]) => `
                <div>
                  <div class="row row--between" style="font-size:13px"><span style="text-transform:capitalize">${role}</span><strong>${count}</strong></div>
                  <div class="bar bar--sm"><span style="width:${Math.round((count / total) * 100)}%"></span></div>
                </div>`).join('')}
            </div>
          </div>

          <div class="card">
            <div class="card__title">${icon('bolt')} ${t('Activité récente', 'Recent activity')}</div>
            <div class="feed" style="margin-top:12px">
              ${ADMIN_ACTIVITY.map((item) => `
                <div class="feed__item">
                  <span class="feed__line"></span>
                  <span class="feed__dot"></span>
                  <div><strong style="font-size:13px;display:block">${esc(item.label)}</strong>
                    <small>${esc(item.detail)}</small></div>
                  <small>${fmt.relative(item.at)}</small>
                </div>`).join('')}
            </div>
          </div>
        </div>
      </div>

      <div class="section">
        <div class="section__head"><h2>${t('Conformité', 'Compliance')}</h2></div>
        <div class="grid grid--3">
          ${[
            ['file', t('Documents en vigueur', 'Documents in force'), t('CGU v3.1 · Confidentialité v3.1', 'Terms v3.1 · Privacy v3.1')],
            ['shield', t('Consentements actifs', 'Active consents'), t('Notifications 82 % · Analytics 46 %', 'Notifications 82% · Analytics 46%')],
            ['download', t('Demandes de droits', 'Rights requests'), t('2 exports · 1 suppression en cours', '2 exports · 1 deletion in progress')],
          ].map(([ic, title, detail]) => `
            <div class="card">
              <span class="icon-badge">${icon(ic)}</span>
              <strong style="display:block;margin-top:10px;font-size:14px">${title}</strong>
              <p class="muted" style="font-size:12.5px;margin-top:4px">${detail}</p>
            </div>`).join('')}
        </div>
      </div>`;
  },
  mount(root) {
    $('[data-action="theme"]', root).addEventListener('click', () => setTheme(state.theme === 'dark' ? 'light' : 'dark'));
    $('[data-action="logout"]', root).addEventListener('click', () => { logout(); navigate('/welcome'); });

    const search = $('#account-search', root);
    search.addEventListener('input', () => {
      const q = search.value.trim().toLowerCase();
      $$('[data-account]', root).forEach((row) => { row.hidden = q && !row.dataset.search.includes(q); });
    });

    const mutate = (index, patch, message) => {
      // Les comptes affichés viennent de ADMIN_ACCOUNTS ; on garde une copie mutable en state.
      state.adminAccounts = state.adminAccounts || ADMIN_ACCOUNTS.map((a) => ({ ...a }));
      Object.assign(state.adminAccounts[index], patch);
      toast(message, 'success');
      navigate('/admin');
    };

    $$('[data-validate]', root).forEach((b) => b.addEventListener('click', () => mutate(Number(b.dataset.validate), { status: 'active' }, t('Compte validé', 'Account approved'))));
    $$('[data-block]', root).forEach((b) => b.addEventListener('click', () => mutate(Number(b.dataset.block), { status: 'blocked' }, t('Compte bloqué', 'Account blocked'))));
    $$('[data-unblock]', root).forEach((b) => b.addEventListener('click', () => mutate(Number(b.dataset.unblock), { status: 'active' }, t('Compte débloqué', 'Account unblocked'))));
  },
};
