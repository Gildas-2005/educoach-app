/* ==========================================================================
   Store applicatif — équivalent JS des stores Flutter
   (AuthStore, LearningStore, ChatStore, SubscriptionStore, ThemeStore…)
   Persistance : localStorage. Aucune donnée ne quitte le navigateur.
   ========================================================================== */
import { FILIERES, COURSE_ROWS } from './data/seed.js';
import { buildPath, buildHomework, PLANS, CHAT_ROOMS } from './data/content.js';

export { FILIERES, COURSE_ROWS };

const KEY = 'horry.educoach.v1';

/* ------------------------------------------------------------ utilitaires */
function djb2(text) {
  let h = 5381;
  for (let i = 0; i < text.length; i++) h = ((h << 5) + h + text.charCodeAt(i)) >>> 0;
  return h;
}

const ICONS = ['book', 'layers', 'chart', 'bolt', 'target', 'globe', 'shield', 'sparkles'];
const DAY_MS = 86400000;

const defaultState = () => ({
  version: 1,
  theme: window.matchMedia?.('(prefers-color-scheme: dark)').matches ? 'dark' : 'light',
  lang: 'fr',
  users: [],
  currentUserId: null,
  profile: { filiereId: null, level: null, permissions: {}, onboarded: false },
  progress: {},
  xp: 0,
  streak: 0,
  lastActiveDay: null,
  subscription: { tier: 'discovery', cycle: 'monthly', renewsAt: null, cancelRequested: false, receipts: [] },
  chat: { threads: {}, unread: {} },
  dismissed: {},
});

export const state = Object.assign(defaultState(), readSaved());

function readSaved() {
  try {
    const raw = localStorage.getItem(KEY);
    return raw ? JSON.parse(raw) : {};
  } catch { return {}; }
}

let saveTimer = 0;
export function persist() {
  clearTimeout(saveTimer);
  saveTimer = setTimeout(() => {
    try { localStorage.setItem(KEY, JSON.stringify(state)); } catch { /* quota / mode privé */ }
  }, 120);
}

/* ------------------------------------------------------------------ événements */
const listeners = new Set();
export function subscribe(fn) { listeners.add(fn); return () => listeners.delete(fn); }
export function emit() {
  persist();
  listeners.forEach((fn) => fn(state));
}

/* ------------------------------------------------------------------- catalogue */
export const filiereById = (id) => FILIERES.find((f) => f.id === id) || FILIERES[0];
export const domains = () => [...new Set(FILIERES.map((f) => f.domain))];
export const filieresByDomain = (domain) => FILIERES.filter((f) => f.domain === domain);

function buildCourses() {
  const counters = {};
  return COURSE_ROWS.map((row) => {
    const filiere = filiereById(row.filiereId);
    const idx = (counters[row.filiereId] = (counters[row.filiereId] || 0) + 1);
    const h = djb2(row.code);
    const progress = 0.15 + ((h >> 3) % 78) / 100;
    return {
      id: `c-${row.filiereId}-${row.code}`,
      code: row.code,
      title: row.title,
      teacher: row.teacher,
      level: row.level,
      credits: row.credits,
      weeklyHours: row.weeklyHours,
      filiereId: row.filiereId,
      filiereName: filiere.name,
      color: filiere.color,
      icon: ICONS[(h + idx) % ICONS.length],
      seededProgress: Math.min(1, Math.max(0, progress)),
      semester: row.level.startsWith('M') ? 'Semestre 2' : 'Semestre 1',
      description: `${row.title} — enseignement magistral et travaux dirigés en ${filiere.name} (${row.level}). Volume horaire hebdomadaire : ${row.weeklyHours}h.`,
    };
  });
}

export const ALL_COURSES = buildCourses();
export const courseByCode = (code) => ALL_COURSES.find((c) => c.code === code);

/** Cours visibles pour l'utilisateur connecté (filière + niveau choisis). */
export function myCourses() {
  const { filiereId, level } = state.profile;
  if (!filiereId) return [];
  let list = ALL_COURSES.filter((c) => c.filiereId === filiereId);
  if (level) {
    const exact = list.filter((c) => c.level === level);
    if (exact.length) list = exact;
  }
  return list;
}

/** Tous les cours de la filière, groupés par niveau. */
export function coursesByLevel(filiereId) {
  const out = {};
  ALL_COURSES.filter((c) => c.filiereId === filiereId).forEach((c) => {
    (out[c.level] ||= []).push(c);
  });
  return out;
}

/* -------------------------------------------------------------------- planning */
const ROOMS = ['Amphi A', 'Amphi B', 'Amphi C', 'Salle 101', 'Salle 204', 'Salle 305', 'Lab. Informatique', 'Lab. Réseau', 'Salle 312'];

export function scheduleFor(courses) {
  const out = [];
  courses.forEach((c) => {
    const h = djb2(c.code);
    const types = c.weeklyHours >= 6 ? ['CM', 'TD', 'TP'] : c.weeklyHours >= 4 ? ['CM', 'TD'] : ['CM'];
    let dayOffset = h % 5;
    let start = 8 + ((h >> 2) % 6);
    types.forEach((type) => {
      const day = 1 + (dayOffset % 5);
      const duration = type === 'TP' ? 3 : 2;
      out.push({
        id: `${c.code}-${type}`,
        code: c.code,
        title: c.title,
        teacher: c.teacher,
        color: c.color,
        day,
        start,
        end: Math.min(19, start + duration),
        room: ROOMS[(h + dayOffset * 7) % ROOMS.length],
        type,
      });
      dayOffset += 1 + ((h >> 3) % 2);
      start = 8 + ((start + 1) % 8);
    });
  });
  return out.sort((a, b) => a.day - b.day || a.start - b.start);
}

/* ----------------------------------------------------------------------- notes */
const GRADE_LABELS = ['Contrôle continu', 'Devoir maison', 'Partiel', 'TP noté', 'Exposé', 'Quiz'];

export function gradesFor(courses) {
  const out = [];
  courses.forEach((c) => {
    const h = djb2(c.code);
    if (h % 7 === 0) return;
    const n = 1 + (h % 3);
    for (let i = 0; i < n; i++) {
      const base = 8 + ((h >> (i + 2)) % 12);
      const bonus = ((h >> i) % 3) * 0.5;
      out.push({
        id: `${c.code}-g${i}`,
        code: c.code,
        course: c.title,
        label: GRADE_LABELS[(h + i * 5) % GRADE_LABELS.length],
        score: Math.min(20, Math.max(4, base + bonus)),
        max: 20,
      });
    }
  });
  return out;
}

export function average(grades) {
  if (!grades.length) return 0;
  return grades.reduce((s, g) => s + g.score, 0) / grades.length;
}

/* ------------------------------------------------------------------ ressources */
export function resourcesFor(course) {
  const kinds = [
    ['pdf', 'Chapitre intégral (PDF)', '3.4 Mo'],
    ['slides', 'Slides du CM', '1.2 Mo'],
    ['video', 'Enregistrement vidéo', '42 min'],
    ['audio', 'Podcast de révision', '28 min'],
    ['link', 'Ressource externe', ''],
    ['pdf', 'Fiche de synthèse', '620 Ko'],
  ];
  const h = djb2(course.code);
  const n = 2 + (h % 2);
  return Array.from({ length: n }, (_, i) => {
    const [kind, label, size] = kinds[(h + i * 3) % kinds.length];
    return { kind, title: `${course.title} — ${label}`, size, updated: Date.now() - (i + 1) * DAY_MS * 3 };
  });
}

/* -------------------------------------------------------------------- parcours */
const pathCache = new Map();
export function pathFor(course) {
  if (pathCache.has(course.code)) return pathCache.get(course.code);
  const units = buildPath(course, filiereById(course.filiereId));
  pathCache.set(course.code, units);
  return units;
}

export function lessonsOf(course) {
  return pathFor(course).flatMap((u) => u.lessons);
}

export function homeworkFor(course) {
  return buildHomework(course, pathFor(course));
}

/* ------------------------------------------------------------------ progression */
export const isDone = (lessonId) => Boolean(state.progress[lessonId]);
export const doneCount = (course) => lessonsOf(course).filter((l) => isDone(l.id)).length;
export function courseProgress(course) {
  const total = lessonsOf(course).length;
  if (!total) return 0;
  const done = doneCount(course);
  return done === 0 ? Math.round(course.seededProgress * 100) : Math.round((done / total) * 100);
}

export function completeLesson(lesson) {
  if (isDone(lesson.id)) return 0;
  state.progress[lesson.id] = Date.now();
  state.xp += lesson.xp;
  touchStreak();
  emit();
  return lesson.xp;
}

export function touchStreak() {
  const today = new Date().toDateString();
  if (state.lastActiveDay === today) return;
  const yesterday = new Date(Date.now() - DAY_MS).toDateString();
  state.streak = state.lastActiveDay === yesterday ? state.streak + 1 : 1;
  state.lastActiveDay = today;
}

export const level = () => Math.floor(state.xp / 500) + 1;
export const levelProgress = () => (state.xp % 500) / 500;
export const nextLevelXp = () => 500 - (state.xp % 500);

/* ------------------------------------------------------------------------ auth */
async function hashCode(password) {
  const data = new TextEncoder().encode(`edu·${password}`);
  if (globalThis.crypto?.subtle) {
    const buf = await crypto.subtle.digest('SHA-256', data);
    return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
  }
  // Repli non cryptographique (contexte non sécurisé) — démo uniquement.
  return String(djb2(`edu·${password}`));
}

export const currentUser = () => state.users.find((u) => u.id === state.currentUserId) || null;
export const isAuthenticated = () => Boolean(currentUser());
export const hasSelection = () => Boolean(state.profile.filiereId);

export const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[a-z]{2,}$/i;

export const ROLES = {
  student: { label: 'Étudiant', icon: 'graduation', desc: 'Parcours, planning, notes' },
  teacher: { label: 'Enseignant', icon: 'users', desc: 'Cours, copies, étudiants' },
  admin: { label: 'Administrateur', icon: 'shield', desc: 'Pilotage et conformité' },
};

export async function signup({ fullName, email, password, role }) {
  const normalized = String(email || '').trim().toLowerCase();
  if (state.users.some((u) => u.email === normalized)) {
    throw new Error('Cet email est déjà utilisé.');
  }
  const user = {
    id: `u-${Date.now().toString(36)}`,
    fullName: String(fullName).trim(),
    email: normalized,
    passwordHash: await hashCode(password),
    role,
    status: role === 'teacher' ? 'pending' : 'active',
    createdAt: Date.now(),
  };
  state.users.push(user);
  state.currentUserId = user.id;
  emit();
  return user;
}

export async function login(email, password) {
  const normalized = String(email || '').trim().toLowerCase();
  const user = state.users.find((u) => u.email === normalized);
  if (!user) throw new Error('Email ou mot de passe incorrect.');
  const hash = await hashCode(password);
  if (hash !== user.passwordHash) throw new Error('Email ou mot de passe incorrect.');
  if (user.status === 'blocked') throw new Error('Ce compte est bloqué.');
  state.currentUserId = user.id;
  touchStreak();
  emit();
  return user;
}

export function logout() {
  state.currentUserId = null;
  emit();
}

export function updateProfile(patch) {
  Object.assign(state.profile, patch);
  emit();
}

export function setTheme(theme) {
  state.theme = theme === 'dark' ? 'dark' : 'light';
  document.documentElement.dataset.theme = state.theme;
  emit();
}

export function setLang(lang) {
  state.lang = lang === 'en' ? 'en' : 'fr';
  document.documentElement.lang = state.lang;
  emit();
}

/* ------------------------------------------------------------------- chat */
export function threads() {
  const base = CHAT_ROOMS.map((room) => {
    const saved = state.chat.threads[room.id];
    return { ...room, messages: saved || room.messages };
  });
  return base;
}

export function threadById(id) {
  return threads().find((t) => t.id === id);
}

export function sendMessage(threadId, body) {
  const thread = CHAT_ROOMS.find((t) => t.id === threadId);
  if (!thread) return;
  const list = state.chat.threads[threadId] || [...thread.messages];
  list.push({ author: 'Moi', body, at: Date.now(), mine: true });
  state.chat.threads[threadId] = list;
  emit();
}

export function markRead(threadId) {
  delete state.chat.unread[threadId];
  persist();
}

export function unreadCount() {
  return Object.values(state.chat.unread).reduce((a, b) => a + b, 0);
}

/* -------------------------------------------------------------- abonnements */
export const planFor = (tier) => PLANS.find((p) => p.tier === tier) || PLANS[0];
export const priceFor = (tier, cycle) => {
  const plan = planFor(tier);
  return cycle === 'yearly' ? plan.yearly : plan.monthly;
};

export function purchasePlan(tier, cycle, method, hint) {
  const price = priceFor(tier, cycle);
  const now = Date.now();
  const receipt = {
    id: `REC-${now.toString(36).toUpperCase()}`,
    date: now,
    tier,
    cycle,
    method,
    amount: price,
    masked: hint,
  };
  state.subscription.tier = tier;
  state.subscription.cycle = cycle;
  state.subscription.cancelRequested = false;
  state.subscription.renewsAt = now + (cycle === 'yearly' ? 365 : 30) * DAY_MS;
  state.subscription.receipts.unshift(receipt);
  emit();
  return receipt;
}

export function cancelSubscription() {
  state.subscription.cancelRequested = true;
  emit();
}

/**
 * Comptes de démonstration : créés à la volée, jamais écrasés.
 * Mot de passe commun « demo1234 » — affiché sur l'écran de connexion.
 */
export const DEMO_PASSWORD = 'demo1234';
const DEMO_USERS = {
  student: { fullName: 'Awa Diop', email: 'awa.diop@edu.cm', role: 'student', filiereId: 'fi-inf', level: 'L3' },
  teacher: { fullName: 'Pr. M. Diallo', email: 'm.diallo@edu.cm', role: 'teacher', filiereId: 'fi-inf', level: 'L3' },
  admin: { fullName: 'Admin Educoach', email: 'admin@edu.cm', role: 'admin', filiereId: null, level: null },
};

export async function ensureDemo(kind) {
  const demo = DEMO_USERS[kind] || DEMO_USERS.student;
  let user = state.users.find((u) => u.email === demo.email);
  if (!user) {
    user = {
      id: `demo-${kind}`,
      fullName: demo.fullName,
      email: demo.email,
      passwordHash: await hashCode(DEMO_PASSWORD),
      role: demo.role,
      status: 'active',
      createdAt: Date.now(),
    };
    state.users.push(user);
  }
  state.currentUserId = user.id;
  if (demo.filiereId && !state.profile.filiereId) {
    state.profile.filiereId = demo.filiereId;
    state.profile.level = demo.level;
    state.profile.onboarded = true;
  }
  if (!state.xp) state.xp = kind === 'student' ? 1240 : 0;
  if (!state.streak) state.streak = kind === 'student' ? 6 : 0;
  state.lastActiveDay = new Date().toDateString();
  // Quelques leçons déjà terminées pour que les écrans soient parlants.
  if (kind === 'student') {
    myCourses().slice(0, 3).forEach((course, i) => {
      lessonsOf(course).slice(0, i === 0 ? 2 : 1).forEach((lesson) => {
        state.progress[lesson.id] = state.progress[lesson.id] || Date.now();
      });
    });
  }
  emit();
  return user;
}

export function resetAll() {
  Object.assign(state, defaultState());
  localStorage.removeItem(KEY);
  emit();
}
