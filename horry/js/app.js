/* ==========================================================================
   Amorçage de l'application : routes, barre d'onglets, raccourcis
   ========================================================================== */
import { $, icon, setTheme, closeModal } from './lib/dom.js';
import { t } from './lib/i18n.js';
import { route, render, navigate } from './router.js';
import { state, isAuthenticated, currentUser, hasSelection, unreadCount, subscribe } from './store.js';

import { welcome, loginScreen, signupScreen, permissionsScreen, filiereScreen } from './screens/auth.js';
import { home, courses, courseDetail, coursePath, lessonPlayer } from './screens/learn.js';
import { scheduleScreen, gradesScreen } from './screens/study.js';
import { chatList, chatThread } from './screens/social.js';
import { subscriptionScreen, profileScreen, legalScreen } from './screens/account.js';
import { teacherShell, adminShell } from './screens/roles.js';

/* -------------------------------------------------------------------- Routes */
route('/welcome', welcome);
route('/login', loginScreen);
route('/signup', signupScreen);
route('/permissions', permissionsScreen);
route('/filiere', filiereScreen);
route('/', home);
route('/courses', courses);
route('/course/:code', courseDetail);
route('/course/:code/path', coursePath);
route('/course/:code/lesson/:lessonId', lessonPlayer);
route('/schedule', scheduleScreen);
route('/grades', gradesScreen);
route('/chat', chatList);
route('/chat/:id', chatThread);
route('/subscription', subscriptionScreen);
route('/profile', profileScreen);
route('/legal/:doc', legalScreen);
route('/teacher', teacherShell);
route('/admin', adminShell);

/* ---------------------------------------------------------------- Barre d'onglets */
const TABSETS = {
  student: [
    ['/', 'Accueil', 'home'],
    ['/courses', 'Cours', 'book'],
    ['/chat', 'Messages', 'chat'],
    ['/schedule', 'Planning', 'calendar'],
    ['/grades', 'Notes', 'chart'],
    ['/profile', 'Profil', 'user'],
  ],
  teacher: [
    ['/teacher', 'Tableau de bord', 'home'],
    ['/profile', 'Profil', 'user'],
  ],
  admin: [
    ['/admin', 'Console', 'shield'],
    ['/profile', 'Profil', 'user'],
  ],
};

function renderTabbar() {
  const bar = $('#tabbar');
  if (!bar) return;
  const shell = bar.dataset.shell || 'student';
  const user = currentUser();
  const items = TABSETS[shell] || TABSETS.student;
  const path = location.hash.slice(1) || '/';
  const unread = unreadCount();

  bar.innerHTML = items.map(([href, fr, ic]) => {
    const active = path === href || (href !== '/' && path.startsWith(`${href}/`));
    const badge = ic === 'chat' && unread ? `<span class="tabbar__badge">${unread}</span>` : '';
    return `<a class="tabbar__item" href="#${href}" ${active ? 'aria-current="page"' : ''}>
      ${icon(ic)}<span>${t(fr, { Accueil: 'Home', Cours: 'Courses', Messages: 'Chat', Planning: 'Schedule', Notes: 'Grades', Profil: 'Profile', 'Tableau de bord': 'Dashboard', Console: 'Console' }[fr] || fr)}</span>${badge}
    </a>`;
  }).join('') + (user ? '' : '');
}

/* ------------------------------------------------------------------- Démarrage */
function boot() {
  document.documentElement.dataset.theme = state.theme;
  document.documentElement.lang = state.lang;

  document.addEventListener('route:changed', renderTabbar);
  subscribe(() => {
    document.documentElement.dataset.theme = state.theme;
    renderTabbar();
  });

  // Fermeture de modale par délégation (boutons générés dynamiquement).
  document.addEventListener('click', (e) => {
    if (e.target.closest('[data-action="modal-close"]')) closeModal();
  });

  // Raccourcis clavier
  document.addEventListener('keydown', (e) => {
    if (e.target.matches('input, textarea, select')) return;
    if (e.key === 'Escape') closeModal();
    if (e.key === '?' && e.shiftKey) navigate('/profile');
  });

  // Démarrage : splash puis première route.
  const splash = $('#splash');
  setTimeout(() => splash?.classList.add('splash--gone'), 620);
  setTimeout(() => { splash?.remove(); }, 1400);

  if (!location.hash) {
    location.replace(`#${isAuthenticated() ? (currentUser().role === 'admin' ? '/admin' : currentUser().role === 'teacher' ? '/teacher' : hasSelection() ? '/' : '/filiere') : '/welcome'}`);
  }
  render();
  renderTabbar();
}

if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
else boot();
