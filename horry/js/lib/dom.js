/* ==========================================================================
   Helpers DOM : icônes SVG, gabarits, toasts, modales, animations
   ========================================================================== */

export const $ = (sel, root = document) => root.querySelector(sel);
export const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

/** Échappe une valeur destinée à du HTML. */
export function esc(value) {
  return String(value ?? '').replace(/[&<>"']/g, (c) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]
  ));
}

/* ------------------------------------------------------------------ Icônes */
// Jeu d'icônes linéaires (stroke 1.8) — dessinées à la main, aucune dépendance.
const P = {
  home: '<path d="M3 10.5 12 3l9 7.5"/><path d="M5.5 9.5V20a1 1 0 0 0 1 1H10v-6h4v6h3.5a1 1 0 0 0 1-1V9.5"/>',
  book: '<path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H19v15.5H6.5A2.5 2.5 0 0 0 4 21z"/><path d="M4 18.5V5.5"/><path d="M8 7.5h7"/>',
  chat: '<path d="M21 12a8 8 0 0 1-11.6 7.1L4 21l1.9-5.4A8 8 0 1 1 21 12z"/><path d="M8.5 12h.01M12 12h.01M15.5 12h.01"/>',
  calendar: '<rect x="3" y="5" width="18" height="16" rx="2.5"/><path d="M8 3v4M16 3v4M3 10h18"/>',
  chart: '<path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/>',
  user: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
  users: '<circle cx="9" cy="8" r="3.4"/><path d="M2.5 21a6.5 6.5 0 0 1 13 0"/><path d="M17 5.5a3.2 3.2 0 0 1 0 6"/><path d="M18.5 14.5a5.6 5.6 0 0 1 3.2 5"/>',
  star: '<path d="m12 3.5 2.7 5.6 6.1.9-4.4 4.3 1 6.1-5.4-2.9-5.4 2.9 1-6.1L3.2 10l6.1-.9z"/>',
  flame: '<path d="M12 22c4 0 6.5-2.6 6.5-6 0-4.4-4.5-6.2-3.5-11.5-3.4.8-5 3.6-5 5.6 0 1.4.6 2.4 1.2 3.2-2 .4-3.2 2-3.2 3.7 0 .9.3 1.7.8 2.4"/>',
  trophy: '<path d="M8 4h8v5a4 4 0 0 1-8 0z"/><path d="M8 5H5v2a3 3 0 0 0 3 3M16 5h3v2a3 3 0 0 1-3 3"/><path d="M12 13v4M9 21h6l-1-4h-4z"/>',
  play: '<path d="M8 5.5v13l11-6.5z"/>',
  check: '<path d="m4.5 12.5 5 5 10-11"/>',
  lock: '<rect x="4.5" y="10" width="15" height="10.5" rx="2.5"/><path d="M8 10V7.5a4 4 0 0 1 8 0V10"/>',
  arrowRight: '<path d="M4 12h16M14 6l6 6-6 6"/>',
  arrowLeft: '<path d="M20 12H4M10 6l-6 6 6 6"/>',
  arrowUp: '<path d="M12 20V4M6 10l6-6 6 6"/>',
  chevronRight: '<path d="m9 5 7 7-7 7"/>',
  chevronDown: '<path d="m5 9 7 7 7-7"/>',
  search: '<circle cx="11" cy="11" r="7"/><path d="m16.5 16.5 4 4"/>',
  sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M19.1 4.9l-1.4 1.4M6.3 17.7l-1.4 1.4"/>',
  moon: '<path d="M20.5 14.5A8.5 8.5 0 0 1 9.5 3.5a8.5 8.5 0 1 0 11 11z"/>',
  bell: '<path d="M18 15.5V11a6 6 0 1 0-12 0v4.5L4 18h16z"/><path d="M10 21a2 2 0 0 0 4 0"/>',
  settings: '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.9l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-2.9 1.2V21a2 2 0 1 1-4 0v-.1A1.7 1.7 0 0 0 7 19.4a1.7 1.7 0 0 0-1.9.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1A1.7 1.7 0 0 0 3 15a1.7 1.7 0 0 0-1.6-1H1a2 2 0 1 1 0-4h.4A1.7 1.7 0 0 0 3 9a1.7 1.7 0 0 0-.3-1.9l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1A1.7 1.7 0 0 0 7 4.6h.1A1.7 1.7 0 0 0 8 3V3a2 2 0 1 1 4 0v.1A1.7 1.7 0 0 0 14 4.6a1.7 1.7 0 0 0 1.9-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1A1.7 1.7 0 0 0 19.4 9v.1a1.7 1.7 0 0 0 1.6 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>',
  logout: '<path d="M14 20H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h8"/><path d="M16 16l4-4-4-4M20 12h-9"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  send: '<path d="M21 3 3 10.5l7 3 3 7z"/><path d="M21 3l-9.5 9.5"/>',
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7.5V12l3 2"/>',
  pin: '<path d="M20 10c0 5.5-8 11-8 11S4 15.5 4 10a8 8 0 1 1 16 0z"/><circle cx="12" cy="10" r="2.8"/>',
  file: '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/>',
  video: '<rect x="3" y="6" width="12" height="12" rx="2.5"/><path d="m15 11 6-3.5v9L15 13z"/>',
  download: '<path d="M12 4v11M7.5 10.5 12 15l4.5-4.5"/><path d="M4 19.5h16"/>',
  bolt: '<path d="M13 2 4.5 13.5H11L10 22l8.5-11.5H12z"/>',
  shield: '<path d="M12 3 5 6v6c0 4.4 3 7.6 7 9 4-1.4 7-4.6 7-9V6z"/><path d="m9 12 2 2 4-4"/>',
  card: '<rect x="2.5" y="5" width="19" height="14" rx="3"/><path d="M2.5 10h19M6 15h4"/>',
  close: '<path d="M6 6l12 12M18 6 6 18"/>',
  trash: '<path d="M4 7h16M9.5 7V4.5h5V7M6 7l1 13.5h10L18 7"/><path d="M10.5 11v6M13.5 11v6"/>',
  edit: '<path d="M4 20h4l11-11-4-4L4 16z"/><path d="m14.5 4.5 4 4"/>',
  eye: '<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z"/><circle cx="12" cy="12" r="3"/>',
  eyeOff: '<path d="M3 3l18 18"/><path d="M10.6 6.1A9.6 9.6 0 0 1 12 6c6 0 9.5 6 9.5 6a17 17 0 0 1-3 3.6M6.4 7.7A16.8 16.8 0 0 0 2.5 12S6 18 12 18c1.3 0 2.4-.3 3.4-.7"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/>',
  mail: '<rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="m3.5 7 8.5 6 8.5-6"/>',
  graduation: '<path d="m2.5 8.5 9.5-4 9.5 4-9.5 4z"/><path d="M6.5 10.5V16c0 1.7 2.5 3 5.5 3s5.5-1.3 5.5-3v-5.5"/>',
  layers: '<path d="m12 3 9 4.5-9 4.5-9-4.5z"/><path d="m3 12.5 9 4.5 9-4.5"/><path d="m3 17 9 4.5 9-4.5"/>',
  target: '<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="4.5"/><circle cx="12" cy="12" r="1"/>',
  sparkles: '<path d="m12 3 1.8 4.6L18.5 9.5l-4.7 1.9L12 16l-1.8-4.6L5.5 9.5l4.7-1.9z"/><path d="M18 15.5l.8 2 2 .8-2 .8-.8 2-.8-2-2-.8 2-.8z"/>',
  rocket: '<path d="M14.5 4.5c3 1 5 3.5 5.5 6.5-3.5 4-7 7.5-11.5 9l-2.5-2.5c1.5-4.5 5-8 8.5-13z"/><circle cx="14.5" cy="9.5" r="1.8"/><path d="M6 15l-2.5.5L5 12M9 18l-.5 2.5L11 18"/>',
  palette: '<path d="M12 3a9 9 0 0 0 0 18c1.5 0 2-1 1.5-2s.2-2 1.5-2h2a4 4 0 0 0 4-4c0-5.5-4-10-9-10z"/><circle cx="8" cy="10" r="1.2"/><circle cx="12" cy="7.5" r="1.2"/><circle cx="16" cy="10" r="1.2"/>',
  globe: '<circle cx="12" cy="12" r="9"/><path d="M3.5 12h17M12 3a15 15 0 0 1 0 18 15 15 0 0 1 0-18z"/>',
  info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v5.5M12 7.8h.01"/>',
  alert: '<path d="M12 3.5 22 20H2z"/><path d="M12 9.5v5M12 17.5h.01"/>',
  inbox: '<path d="M3 13h5l1.5 3h5l1.5-3h5"/><path d="M3 13 6 4h12l3 9v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
  filter: '<path d="M4 5h16l-6 7.5V21l-4-2.5v-6z"/>',
  reset: '<path d="M3.5 12a8.5 8.5 0 1 0 3-6.5"/><path d="M3 3.5V9h5.5"/>',
  wifi: '<path d="M2.5 8.5a15 15 0 0 1 19 0M6 12.5a10 10 0 0 1 12 0M9.5 16a5 5 0 0 1 5 0"/><circle cx="12" cy="19.5" r="1"/>',
  copy: '<rect x="9" y="9" width="12" height="12" rx="2.5"/><path d="M15 6.5V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h1.5"/>',
};

export function icon(name, cls = '') {
  const path = P[name];
  if (!path) return '';
  return `<svg class="${cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"
    stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${path}</svg>`;
}

/* ------------------------------------------------------------------ Toasts */
let toastTimer = 0;

export function toast(message, kind = 'info', ms = 3200) {
  const host = $('#toasts');
  if (!host) return;
  const node = document.createElement('div');
  node.className = `toast toast--${kind}`;
  const glyph = kind === 'success' ? 'check' : kind === 'error' ? 'alert' : 'info';
  node.innerHTML = `${icon(glyph)}<span>${esc(message)}</span>`;
  host.appendChild(node);
  clearTimeout(toastTimer);
  setTimeout(() => {
    node.classList.add('toast--out');
    node.addEventListener('animationend', () => node.remove(), { once: true });
  }, ms);
}

/* ------------------------------------------------------------------- Modale */
export function openModal({ title, body, actions = '', wide = false, onMount }) {
  const root = $('#modal-root');
  if (!root) return;
  root.hidden = false;
  root.innerHTML = `
    <div class="modal ${wide ? 'modal--wide' : ''}" role="dialog" aria-modal="true" aria-label="${esc(title)}">
      <div class="modal__head">
        <div class="modal__title">${esc(title)}</div>
        <button class="modal__close" data-action="modal-close" aria-label="Fermer">${icon('close')}</button>
      </div>
      <div class="modal__body">${body}</div>
      ${actions ? `<div class="modal__actions">${actions}</div>` : ''}
    </div>`;
  const close = () => closeModal();
  root.addEventListener('click', (e) => { if (e.target === root) close(); }, { once: true });
  document.addEventListener('keydown', escClose, { once: true });
  onMount?.(root);
  return root;
}

function escClose(e) {
  if (e.key === 'Escape') closeModal();
  else document.addEventListener('keydown', escClose, { once: true });
}

export function closeModal() {
  const root = $('#modal-root');
  if (!root) return;
  root.hidden = true;
  root.innerHTML = '';
}

export function confirmDialog({ title, message, confirmLabel = 'Confirmer', danger = false }) {
  return new Promise((resolve) => {
    openModal({
      title,
      body: `<p class="soft">${esc(message)}</p>`,
      actions: `
        <button class="btn btn--ghost" data-action="modal-close">Annuler</button>
        <button class="btn ${danger ? 'btn--danger' : 'btn--primary'}" data-action="modal-confirm">${esc(confirmLabel)}</button>`,
      onMount(root) {
        root.querySelector('[data-action="modal-confirm"]').addEventListener('click', () => {
          closeModal();
          resolve(true);
        });
        root.querySelectorAll('[data-action="modal-close"]').forEach((b) =>
          b.addEventListener('click', () => { closeModal(); resolve(false); }));
        root.addEventListener('click', (e) => { if (e.target === root) resolve(false); });
      },
    });
  });
}

/* -------------------------------------------------------------- Animations */
export function countUp(node, to, { duration = 900, decimals = 0, suffix = '' } = {}) {
  const from = 0;
  const start = performance.now();
  const step = (now) => {
    const p = Math.min(1, (now - start) / duration);
    const eased = 1 - Math.pow(1 - p, 3);
    node.textContent = (from + (to - from) * eased).toFixed(decimals) + suffix;
    if (p < 1) requestAnimationFrame(step);
  };
  requestAnimationFrame(step);
}

export function revealOnScroll(root = document) {
  const items = $$('.reveal', root);
  if (!items.length) return;
  if (!('IntersectionObserver' in window)) {
    items.forEach((n) => n.classList.add('is-in'));
    return;
  }
  const io = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('is-in');
        io.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });
  items.forEach((n) => io.observe(n));
}

export function confetti(count = 70) {
  const host = $('#confetti');
  if (!host) return;
  const colors = ['#3f51b5', '#7c4dff', '#00bcd4', '#2e7d32', '#f9a825', '#ff5252'];
  for (let i = 0; i < count; i++) {
    const piece = document.createElement('i');
    piece.style.left = `${Math.random() * 100}%`;
    piece.style.background = colors[i % colors.length];
    piece.style.setProperty('--dx', `${(Math.random() - 0.5) * 240}px`);
    piece.style.setProperty('--rot', `${360 + Math.random() * 720}deg`);
    piece.style.animationDuration = `${1.5 + Math.random() * 1.4}s`;
    piece.style.animationDelay = `${Math.random() * 0.35}s`;
    piece.style.opacity = String(0.65 + Math.random() * 0.35);
    host.appendChild(piece);
    piece.addEventListener('animationend', () => piece.remove(), { once: true });
  }
}

export function xpFloat(amount, anchor) {
  const node = document.createElement('div');
  node.className = 'xp-float';
  node.textContent = `+${amount} XP`;
  const rect = anchor?.getBoundingClientRect?.();
  node.style.left = `${rect ? rect.left + rect.width / 2 : window.innerWidth / 2}px`;
  node.style.top = `${rect ? rect.top : window.innerHeight / 2}px`;
  document.body.appendChild(node);
  node.addEventListener('animationend', () => node.remove(), { once: true });
}

/** Fait « vibrer » un élément invalide. */
export function shake(node) {
  if (!node) return;
  node.classList.remove('is-shaking');
  void node.offsetWidth;
  node.classList.add('is-shaking');
}

/* ---------------------------------------------------------------- Formatage */
const DAYS = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
const MONTHS = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet',
  'août', 'septembre', 'octobre', 'novembre', 'décembre'];

export const fmt = {
  date(d) {
    const date = new Date(d);
    return `${date.getDate()} ${MONTHS[date.getMonth()]} ${date.getFullYear()}`;
  },
  shortDate(d) {
    const date = new Date(d);
    return `${String(date.getDate()).padStart(2, '0')}/${String(date.getMonth() + 1).padStart(2, '0')}`;
  },
  day(d) { return DAYS[new Date(d).getDay()]; },
  time(hours) {
    const h = Math.floor(hours);
    const m = Math.round((hours - h) * 60);
    return `${String(h).padStart(2, '0')}h${m ? String(m).padStart(2, '0') : '00'}`;
  },
  clock(d) {
    const date = new Date(d);
    return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
  },
  relative(d) {
    const diff = Date.now() - new Date(d).getTime();
    const min = Math.round(diff / 60000);
    if (min < 1) return "à l'instant";
    if (min < 60) return `il y a ${min} min`;
    const h = Math.round(min / 60);
    if (h < 24) return `il y a ${h} h`;
    const days = Math.round(h / 24);
    if (days < 7) return `il y a ${days} j`;
    return fmt.shortDate(d);
  },
  fcfa(n) { return `${new Intl.NumberFormat('fr-FR').format(n)} FCFA`; },
  initials(name) {
    return String(name || '?')
      .split(/\s+/).filter(Boolean).slice(0, 2)
      .map((w) => w[0].toUpperCase()).join('');
  },
  nf(n) { return new Intl.NumberFormat('fr-FR').format(n); },
};

/* Mise à jour du document (titre, thème) */
export function setTheme(theme) {
  document.documentElement.dataset.theme = theme;
}
