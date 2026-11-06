/* ==========================================================================
   Routeur par hash + gardes de rôle
   (équivalent de generateRoute / _guardRoute dans lib/main.dart)
   ========================================================================== */
import { $, revealOnScroll } from './lib/dom.js';
import { state, isAuthenticated, currentUser, hasSelection } from './store.js';

const routes = [];
let currentPath = null;
let mountCleanup = null;

/** Déclare une route. `screen` = { render(params), mount?(root, params) }. */
export function route(path, screen, options = {}) {
  routes.push({ ...compile(path), screen, ...options });
}

function compile(pattern) {
  const keys = [];
  const base = pattern.length > 1 ? pattern.replace(/\/$/, '') : pattern;
  const regex = new RegExp(`^${base
    .replace(/:[a-zA-Z]+/g, (m) => { keys.push(m.slice(1)); return '([^/]+)'; })}$`);
  return { pattern, regex, keys };
}

export function navigate(path, { replace = false } = {}) {
  const target = path.startsWith('#') ? path : `#${path}`;
  if (location.hash === target) { render(); return; }
  if (replace) history.replaceState(null, '', target);
  else history.pushState(null, '', target);
  render();
}

export const currentRoute = () => currentPath;
export const back = () => history.back();

function match(path) {
  const clean = path.split('?')[0].replace(/\/$/, '') || '/';
  for (const r of routes) {
    const m = clean.match(r.regex);
    if (m) {
      const params = {};
      r.keys.forEach((k, i) => { params[k] = decodeURIComponent(m[i + 1]); });
      return { entry: r, params };
    }
  }
  return null;
}

/** Garde centralisée : renvoie une redirection ou null. */
function guard(path) {
  const authed = isAuthenticated();
  const role = currentUser()?.role;
  const publicPaths = ['/welcome', '/login', '/signup', '/legal/terms', '/legal/privacy'];
  const isPublic = publicPaths.some((p) => path === p || path.startsWith(`${p}/`));

  if (!authed && !isPublic) return '/welcome';
  if (authed && (path === '/welcome' || path === '/login' || path === '/signup')) {
    if (role === 'admin') return '/admin';
    if (role === 'teacher') return '/teacher';
    return hasSelection() ? '/' : '/filiere';
  }
  if (authed && role === 'admin' && path !== '/admin' && path !== '/profile' && !path.startsWith('/legal')) return '/admin';
  if (authed && role === 'teacher' && !path.startsWith('/teacher') && !path.startsWith('/legal') && path !== '/profile') return '/teacher';
  if (authed && role === 'student' && (path === '/teacher' || path === '/admin')) return '/';
  if (authed && role === 'student' && !hasSelection() && path !== '/filiere' && path !== '/permissions' && !path.startsWith('/legal')) {
    return '/filiere';
  }
  return null;
}

export function render() {
  const raw = location.hash.slice(1) || '/';
  const found = match(raw);
  const main = $('#main');
  if (!main) return;

  if (!found) {
    navigate('/', { replace: true });
    return;
  }

  const redirect = guard(found.params ? raw.split('?')[0] : raw);
  if (redirect) { navigate(redirect, { replace: true }); return; }

  if (mountCleanup) { try { mountCleanup(); } catch { /* ignore */ } mountCleanup = null; }

  const { entry, params } = found;
  const ctx = { params, path: raw };
  const html = entry.screen.render(ctx);

  main.className = entry.bare ? 'app app--bare' : 'app';
  main.innerHTML = `<div class="view">${html}</div>`;
  currentPath = raw;

  const root = $('.view', main);
  const cleanup = entry.screen.mount?.(root, ctx);
  if (typeof cleanup === 'function') mountCleanup = cleanup;

  // La barre d'onglets n'apparaît que dans les coquilles utilisateur.
  const tabbar = $('#tabbar');
  const showTabs = Boolean(entry.tabs);
  if (tabbar) {
    tabbar.hidden = !showTabs;
    if (showTabs) tabbar.dataset.shell = entry.tabs;
  }
  document.body.dataset.shell = entry.tabs || '';

  revealOnScroll(main);
  if (!entry.keepScroll) window.scrollTo({ top: 0, behavior: 'instant' in window ? 'instant' : 'auto' });
  document.dispatchEvent(new CustomEvent('route:changed', { detail: { path: raw, state } }));
}

window.addEventListener('hashchange', render);
window.addEventListener('popstate', render);

/** Routes par défaut selon le rôle (après connexion). */
export function homeForRole(role) {
  if (role === 'admin') return '/admin';
  if (role === 'teacher') return '/teacher';
  return hasSelection() ? '/' : '/filiere';
}
