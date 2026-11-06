/* ==========================================================================
   Écrans publics : bienvenue, connexion, inscription, permissions, filière
   ========================================================================== */
import { icon, esc, toast, shake, $, $$ } from '../lib/dom.js';
import { t } from '../lib/i18n.js';
import { navigate } from '../router.js';
import {
  state, FILIERES, domains, filieresByDomain, signup, login, ROLES,
  EMAIL_RE, updateProfile, setTheme, ensureDemo,
} from '../store.js';

/* ------------------------------------------------------------------ Bienvenue */
export const welcome = {
  bare: true,
  render() {
    const stats = [
      [FILIERES.length, t('filières couvertes', 'programmes covered')],
      ['256', t('cours avec parcours', 'courses with paths')],
      ['6', t('cours rédigés en entier', 'fully written courses')],
    ];
    return `
      <div class="welcome">
        <div class="welcome__top">
          <div class="brand">
            <span class="brand__mark">${icon('graduation')}</span>
            <span>Educoach<small>${t('apprendre autrement', 'learn differently')}</small></span>
          </div>
          <div class="row">
            <button class="btn btn--ghost btn--sm" data-action="toggle-theme" aria-label="${t('Changer de thème', 'Toggle theme')}">
              ${icon(state.theme === 'dark' ? 'sun' : 'moon')}<span class="hide-sm">${state.theme === 'dark' ? t('Clair', 'Light') : t('Sombre', 'Dark')}</span>
            </button>
            <button class="btn btn--ghost btn--sm" data-action="toggle-lang">${icon('globe')}<span>${state.lang === 'fr' ? 'EN' : 'FR'}</span></button>
          </div>
        </div>

        <section class="welcome__hero">
          <div>
            <span class="pill pill--primary">${icon('sparkles')} ${t('Nouveau : parcours type jeu', 'New: game-like paths')}</span>
            <h1 class="welcome__title" style="margin-top:14px">
              ${t('Tes cours deviennent', 'Your courses become')}<br><em>${t('un jeu qui te fait progresser', 'a game that moves you forward')}</em>
            </h1>
            <p class="welcome__lead">
              ${t(
                'Parcours par semestre, exercices corrigés, planning, notes et messagerie avec tes profs. Tout ce qu’il faut pour réviser sans t’éparpiller — même avec une connexion instable.',
                'Semester paths, corrected exercises, schedule, grades and chat with your teachers. Everything you need to study without scattering — even on a weak connection.')}
            </p>
            <div class="welcome__actions">
              <button class="btn btn--primary btn--lg" data-action="go-signup">${icon('rocket')} ${t('Créer mon compte', 'Create my account')}</button>
              <button class="btn btn--ghost btn--lg" data-action="go-login">${t('J’ai déjà un compte', 'I already have an account')}</button>
            </div>
            <div class="welcome__proof">
              ${stats.map(([v, l]) => `<div><strong>${v}</strong>${l}</div>`).join('')}
            </div>
          </div>

          <div class="device" aria-hidden="true">
            <div class="device__notch"></div>
            <div class="device__screen">
              <div class="device__mini-hero">
                <small style="opacity:.8;font-size:11px">${t('BON RETOUR, AWA', 'WELCOME BACK, AWA')}</small>
                <strong>${t('Niveau 6', 'Level 6')}</strong>
                <div class="bar" style="margin-top:10px;background:rgba(255,255,255,.3)"><span style="width:64%;background:#fff"></span></div>
                <small style="opacity:.85;font-size:11px">320 / 500 XP</small>
              </div>
              ${['Algorithmique avancée|78', 'Réseaux et protocoles|42', 'Droit civil|61'].map((row) => {
                const [name, pct] = row.split('|');
                return `<div class="device__mini-row"><span class="tag-dot" style="background:#7c4dff"></span>
                  <span class="truncate grow">${name}</span><span class="bar"><span style="width:${pct}%"></span></span>
                  <small class="muted">${pct}%</small></div>`;
              }).join('')}
              <div class="device__mini-row" style="background:var(--hero);color:#fff;justify-content:center">
                ${icon('play')} ${t('Reprendre la leçon', 'Resume lesson')}
              </div>
            </div>
          </div>
        </section>

        <section class="section reveal">
          <div class="section__head"><h2>${t('Pensé pour réussir ton semestre', 'Built to get you through the semester')}</h2></div>
          <div class="feature-grid">
            ${[
              ['target', t('Parcours progressifs', 'Progressive paths'), t('Chaque cours est découpé en unités et leçons courtes, avec théorie, exemples chiffrés et exercices corrigés.', 'Every course is split into units and short lessons, with theory, worked examples and corrected exercises.')],
              ['calendar', t('Planning et notes au même endroit', 'Schedule and grades in one place'), t('Tes séances de la semaine, tes notes et ta moyenne se mettent à jour automatiquement.', 'Your weekly sessions, grades and average update automatically.')],
              ['chat', t('Profs joignables', 'Reach your teachers'), t('Messagerie par classe ou en direct, avec les annonces des enseignants.', 'Class or direct messaging, with teacher announcements.')],
              ['shield', t('Données maîtrisées', 'Data you control'), t('Mots de passe hachés, aucune donnée envoyée à un tiers, export et suppression depuis ton profil.', 'Hashed passwords, no data sent to third parties, export and deletion from your profile.')],
            ].map(([ic, title, body]) => `
              <div class="card feature">
                <span class="feature__icon">${icon(ic)}</span>
                <h3>${title}</h3><p>${body}</p>
              </div>`).join('')}
          </div>
        </section>

        <section class="section reveal">
          <div class="section__head"><h2>${t('Trois étapes, et tu révises', 'Three steps and you’re studying')}</h2></div>
          <div class="steps">
            ${[
              [t('Choisis ta filière', 'Pick your programme'), t('40 filières, de la L1 au M2, avec les cours réels de ton parcours.', '40 programmes, from year 1 to master, with the real courses.')],
              [t('Suis ton parcours', 'Follow your path'), t('Une leçon à la fois, avec XP, série quotidienne et progression visible.', 'One lesson at a time, with XP, daily streak and visible progress.')],
              [t('Mesure tes progrès', 'Measure progress'), t('Notes, moyenne, statistiques et prochaines séances : tout est chiffré.', 'Grades, average, stats and upcoming sessions: all measured.')],
            ].map(([h, p]) => `<div class="step"><h4>${h}</h4><p>${p}</p></div>`).join('')}
          </div>
        </section>

        <section class="section">
          <div class="card card--hero sheen center" style="padding:44px 24px">
            <h2 style="font-size:clamp(22px,3.4vw,32px)">${t('Prêt à commencer ?', 'Ready to start?')}</h2>
            <p style="color:rgba(255,255,255,.85);margin-top:8px">${t('Gratuit, sans carte bancaire. Ton palier Découverte inclut tous les parcours.', 'Free, no credit card. Your Discovery tier includes every path.')}</p>
            <div class="row" style="justify-content:center;margin-top:22px;flex-wrap:wrap">
              <button class="btn btn--lg" style="background:#fff;color:#3f51b5" data-action="go-signup">${t('Créer mon compte', 'Create my account')} ${icon('arrowRight')}</button>
              <button class="btn btn--lg btn--ghost" style="color:#fff;border-color:rgba(255,255,255,.5)" data-action="go-login">${t('Se connecter', 'Sign in')}</button>
            </div>
          </div>
        </section>

        <footer class="row row--wrap" style="justify-content:center;gap:18px;color:var(--text-muted);font-size:13px;padding-bottom:20px">
          <span>© 2026 Educoach</span>
          <a href="#/legal/terms">${t('Conditions', 'Terms')}</a>
          <a href="#/legal/privacy">${t('Confidentialité', 'Privacy')}</a>
          <span>${t('Fait pour les universités du Cameroun', 'Made for universities in Cameroon')}</span>
        </footer>
      </div>`;
  },
  mount(root) {
    $('[data-action="toggle-theme"]', root).addEventListener('click', () => {
      setTheme(state.theme === 'dark' ? 'light' : 'dark');
    });
    $('[data-action="toggle-lang"]', root).addEventListener('click', async () => {
      const { setLang } = await import('../store.js');
      setLang(state.lang === 'fr' ? 'en' : 'fr');
    });
    $$('[data-action="go-signup"]', root).forEach((b) => b.addEventListener('click', () => navigate('/signup')));
    $$('[data-action="go-login"]', root).forEach((b) => b.addEventListener('click', () => navigate('/login')));
  },
};

/* ------------------------------------------------------------------ Connexion */
export const loginScreen = {
  bare: true,
  render() {
    return `
      <div class="auth">
        <aside class="auth__aside">
          <div class="brand" style="color:#fff">
            <span class="brand__mark" style="background:rgba(255,255,255,.18)">${icon('graduation')}</span>
            <span>Educoach</span>
          </div>
          <h2>${t('Reprends là où tu t’es arrêté.', 'Pick up where you left off.')}</h2>
          <p>${t('Ta progression, ta série et tes prochaines séances t’attendent.', 'Your progress, streak and upcoming sessions are waiting.')}</p>
          <blockquote class="auth__quote">${t('« J’ai gagné 3 points de moyenne en un semestre en suivant le parcours d’algorithmique. »', '"I gained 3 grade points in one semester by following the algorithms path."')}</blockquote>
          <small style="opacity:.75">— ${t('Awa D., L3 Informatique', 'Awa D., CS year 3')}</small>
        </aside>

        <div class="auth__card">
          <form class="auth__form" novalidate>
            <div>
              <h1 style="font-size:28px">${t('Bon retour', 'Welcome back')}</h1>
              <p class="muted">${t('Connecte-toi pour continuer ton parcours.', 'Sign in to continue your path.')}</p>
            </div>

            <div class="field" data-field="email">
              <label for="email">${t('Adresse email', 'Email address')}</label>
              <div class="input-group">${icon('mail')}
                <input class="input" id="email" name="email" type="email" autocomplete="email" placeholder="prenom.nom@edu.cm" required />
              </div>
              <p class="error" hidden></p>
            </div>

            <div class="field" data-field="password">
              <label for="password">${t('Mot de passe', 'Password')}</label>
              <div class="input-group">${icon('lock')}
                <input class="input" id="password" name="password" type="password" autocomplete="current-password" placeholder="••••••••" required />
                <button class="input-group__action" type="button" data-action="toggle-pass" aria-label="${t('Afficher le mot de passe', 'Show password')}">${icon('eye')}</button>
              </div>
              <p class="error" hidden></p>
            </div>

            <button class="btn btn--primary btn--block" type="submit">${t('Se connecter', 'Sign in')} ${icon('arrowRight')}</button>

            <p class="auth__switch">${t('Pas encore de compte ?', 'No account yet?')} <a href="#/signup">${t('Créer un compte', 'Create one')}</a></p>

            <div class="divider"></div>
            <p class="hint">${t('Comptes de démonstration — accès en un clic :', 'Demo accounts — one click sign-in:')}</p>
            <div class="row row--wrap">
              <button class="btn btn--ghost btn--sm" type="button" data-demo="student">${icon('graduation')} ${t('Étudiant', 'Student')}</button>
              <button class="btn btn--ghost btn--sm" type="button" data-demo="teacher">${icon('users')} ${t('Enseignant', 'Teacher')}</button>
              <button class="btn btn--ghost btn--sm" type="button" data-demo="admin">${icon('shield')} ${t('Admin', 'Admin')}</button>
            </div>
          </form>
        </div>
      </div>`;
  },
  mount(root) {
    const form = $('form', root);
    const passField = $('[data-field="password"] input', root);
    $('[data-action="toggle-pass"]', root).addEventListener('click', (e) => {
      const show = passField.type === 'password';
      passField.type = show ? 'text' : 'password';
      e.currentTarget.innerHTML = icon(show ? 'eyeOff' : 'eye');
    });

    const setError = (name, message) => {
      const field = $(`[data-field="${name}"]`, root);
      const p = $('.error', field);
      p.hidden = !message;
      p.textContent = message || '';
      field.classList.toggle('field--invalid', Boolean(message));
    };

    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const button = $('button[type="submit"]', form);
      const email = form.email.value.trim();
      const password = form.password.value;
      setError('email', EMAIL_RE.test(email) ? '' : t('Email invalide.', 'Invalid email.'));
      setError('password', password ? '' : t('Mot de passe requis.', 'Password required.'));
      if (!EMAIL_RE.test(email) || !password) { shake(form); return; }

      button.dataset.loading = 'true';
      try {
        await login(email, password);
        toast(t('Connexion réussie', 'Signed in'), 'success');
        navigate(state.profile.filiereId ? '/' : '/filiere');
      } catch (err) {
        setError('password', err.message);
        shake(form);
      } finally {
        delete button.dataset.loading;
      }
    });

    $$('[data-demo]', root).forEach((b) => b.addEventListener('click', async () => {
      b.dataset.loading = 'true';
      try {
        await ensureDemo(b.dataset.demo);
        navigate(b.dataset.demo === 'student' ? '/' : `/${b.dataset.demo}`);
      } catch (err) {
        toast(err.message, 'error');
      } finally {
        delete b.dataset.loading;
      }
    }));
  },
};

/* ----------------------------------------------------------------- Inscription */
export const signupScreen = {
  bare: true,
  render() {
    const roles = ['student', 'teacher'];
    return `
      <div class="auth">
        <aside class="auth__aside">
          <div class="brand" style="color:#fff">
            <span class="brand__mark" style="background:rgba(255,255,255,.18)">${icon('graduation')}</span>
            <span>Educoach</span>
          </div>
          <h2>${t('Ton semestre commence ici.', 'Your semester starts here.')}</h2>
          <p>${t('Choisis ta filière, suis ton parcours, et laisse la série quotidienne faire le reste.', 'Pick your programme, follow your path, and let the daily streak do the rest.')}</p>
          <ul style="display:grid;gap:12px;margin-top:6px">
            ${[[t('Gratuit, sans carte', 'Free, no card'), 'sparkles'], [t('Progression sauvegardée', 'Saved progress'), 'shield'], [t('Sans publicité', 'No ads'), 'check']]
              .map(([label, ic]) => `<li class="row" style="gap:10px;color:rgba(255,255,255,.9)">${icon(ic)}<span>${label}</span></li>`).join('')}
          </ul>
        </aside>

        <div class="auth__card">
          <form class="auth__form" novalidate>
            <div>
              <h1 style="font-size:28px">${t('Créer mon compte', 'Create my account')}</h1>
              <p class="muted">${t('30 secondes, et c’est parti.', '30 seconds and you’re in.')}</p>
            </div>

            <div class="field">
              <span class="label">${t('Je suis…', 'I am…')}</span>
              <div class="roles">
                ${roles.map((r, i) => `
                  <button type="button" class="role" data-role="${r}" aria-pressed="${i === 0}">
                    <span class="role__icon">${icon(ROLES[r].icon)}</span>
                    <strong>${ROLES[r].label}</strong>
                    <span>${ROLES[r].desc}</span>
                  </button>`).join('')}
              </div>
              <input type="hidden" name="role" value="student" />
            </div>

            <div class="field" data-field="fullName">
              <label for="fullName">${t('Nom complet', 'Full name')}</label>
              <div class="input-group">${icon('user')}
                <input class="input" id="fullName" name="fullName" autocomplete="name" placeholder="Awa Diop" required />
              </div>
              <p class="error" hidden></p>
            </div>

            <div class="field" data-field="email">
              <label for="email">${t('Adresse email', 'Email address')}</label>
              <div class="input-group">${icon('mail')}
                <input class="input" id="email" name="email" type="email" autocomplete="email" placeholder="prenom.nom@edu.cm" required />
              </div>
              <p class="error" hidden></p>
            </div>

            <div class="field" data-field="password">
              <label for="password">${t('Mot de passe', 'Password')}</label>
              <div class="input-group">${icon('lock')}
                <input class="input" id="password" name="password" type="password" autocomplete="new-password" placeholder="${t('8 caractères minimum', '8 characters minimum')}" required />
                <button class="input-group__action" type="button" data-action="toggle-pass" aria-label="${t('Afficher', 'Show')}">${icon('eye')}</button>
              </div>
              <div class="meter" data-score="0" aria-hidden="true"><i></i><i></i><i></i><i></i></div>
              <p class="hint">${t('Ajoute une majuscule et un chiffre pour un mot de passe solide.', 'Add a capital letter and a digit for a strong password.')}</p>
              <p class="error" hidden></p>
            </div>

            <div class="field" data-field="confirm">
              <label for="confirm">${t('Confirmer le mot de passe', 'Confirm password')}</label>
              <div class="input-group">${icon('lock')}
                <input class="input" id="confirm" name="confirm" type="password" autocomplete="new-password" placeholder="••••••••" required />
              </div>
              <p class="error" hidden></p>
            </div>

            <label class="check">
              <input type="checkbox" name="terms" />
              <span>${t('J’accepte les', 'I accept the')} <a href="#/legal/terms" target="_blank" style="color:var(--primary)">${t('conditions', 'terms')}</a>
              ${t('et la', 'and the')} <a href="#/legal/privacy" target="_blank" style="color:var(--primary)">${t('politique de confidentialité', 'privacy policy')}</a>.</span>
            </label>
            <p class="error" data-terms-error hidden></p>

            <button class="btn btn--primary btn--block" type="submit">${t('Créer mon compte', 'Create my account')} ${icon('arrowRight')}</button>
            <p class="auth__switch">${t('Déjà inscrit ?', 'Already registered?')} <a href="#/login">${t('Se connecter', 'Sign in')}</a></p>
          </form>
        </div>
      </div>`;
  },
  mount(root) {
    const form = $('form', root);
    const pass = $('[name="password"]', form);
    const meter = $('.meter', root);

    $$('.role', root).forEach((btn) => btn.addEventListener('click', () => {
      $$('.role', root).forEach((b) => b.setAttribute('aria-pressed', String(b === btn)));
      form.role.value = btn.dataset.role;
    }));

    $('[data-action="toggle-pass"]', root).addEventListener('click', (e) => {
      const show = pass.type === 'password';
      pass.type = show ? 'text' : 'password';
      e.currentTarget.innerHTML = icon(show ? 'eyeOff' : 'eye');
    });

    pass.addEventListener('input', () => {
      const v = pass.value;
      let score = 0;
      if (v.length >= 8) score++;
      if (/[A-Z]/.test(v) && /[a-z]/.test(v)) score++;
      if (/\d/.test(v)) score++;
      if (/[^A-Za-z0-9]/.test(v) && v.length >= 12) score++;
      meter.dataset.score = String(score);
    });

    const setError = (name, message) => {
      const field = $(`[data-field="${name}"]`, root);
      if (!field) return;
      const p = $('.error', field);
      p.hidden = !message;
      p.textContent = message || '';
      field.classList.toggle('field--invalid', Boolean(message));
    };

    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const button = $('button[type="submit"]', form);
      const fullName = form.fullName.value.trim();
      const email = form.email.value.trim();
      const password = form.password.value;
      const confirm = form.confirm.value;
      const termsError = $('[data-terms-error]', root);

      setError('fullName', fullName.length < 2 ? t('Indique ton nom complet.', 'Enter your full name.') : '');
      setError('email', EMAIL_RE.test(email) ? '' : t('Email invalide.', 'Invalid email.'));
      setError('password', password.length < 8 ? t('8 caractères minimum.', 'At least 8 characters.') : '');
      setError('confirm', confirm !== password ? t('Les mots de passe ne correspondent pas.', 'Passwords do not match.') : '');
      termsError.hidden = form.terms.checked;
      termsError.textContent = form.terms.checked ? '' : t('Tu dois accepter les conditions.', 'You must accept the terms.');

      const invalid = fullName.length < 2 || !EMAIL_RE.test(email) || password.length < 8 || confirm !== password || !form.terms.checked;
      if (invalid) { shake(form); return; }

      button.dataset.loading = 'true';
      try {
        const user = await signup({ fullName, email, password, role: form.role.value });
        toast(t('Compte créé, bienvenue !', 'Account created, welcome!'), 'success');
        navigate(user.role === 'teacher' ? '/teacher' : '/permissions');
      } catch (err) {
        setError('email', err.message);
        shake(form);
      } finally {
        delete button.dataset.loading;
      }
    });
  },
};

/* --------------------------------------------------------------- Permissions */
export const permissionsScreen = {
  bare: true,
  render() {
    const items = [
      ['notifications', 'bell', t('Notifications de cours', 'Course notifications'), t('Rappels de séance, nouveaux devoirs, corrections.', 'Session reminders, new homework, corrections.')],
      ['calendar', 'calendar', t('Synchroniser le planning', 'Sync the schedule'), t('Ajoute tes séances à ton calendrier.', 'Add your sessions to your calendar.')],
      ['analytics', 'chart', t('Statistiques anonymes', 'Anonymous analytics'), t('Aide à améliorer les parcours, sans donnée personnelle.', 'Helps improve paths, with no personal data.')],
    ];
    return `
      <div style="max-width:620px;margin:40px auto">
        <div class="page-head">
          <div><span class="page-head__eyebrow">${t('Étape 1 sur 2', 'Step 1 of 2')}</span><h1>${t('Reste informé', 'Stay in the loop')}</h1>
          <p>${t('Tu peux tout changer plus tard dans ton profil.', 'You can change all this later in your profile.')}</p></div>
        </div>
        <div class="stack stagger">
          ${items.map(([id, ic, title, body]) => `
            <div class="card row" style="justify-content:space-between">
              <div class="row" style="align-items:flex-start">
                <span class="icon-badge">${icon(ic)}</span>
                <div><strong>${title}</strong><p class="muted" style="font-size:13px">${body}</p></div>
              </div>
              <label class="switch"><input type="checkbox" data-perm="${id}" ${id === 'notifications' ? 'checked' : ''} /><span class="sr-only">${title}</span></label>
            </div>`).join('')}
        </div>
        <div class="row" style="justify-content:space-between;margin-top:24px">
          <button class="btn btn--ghost" data-action="skip">${t('Plus tard', 'Later')}</button>
          <button class="btn btn--primary" data-action="continue">${t('Continuer', 'Continue')} ${icon('arrowRight')}</button>
        </div>
      </div>`;
  },
  mount(root) {
    const perms = {};
    $$('[data-perm]', root).forEach((input) => {
      perms[input.dataset.perm] = input.checked;
      input.addEventListener('change', () => { perms[input.dataset.perm] = input.checked; });
    });
    const go = () => {
      updateProfile({ permissions: perms });
      navigate('/filiere');
    };
    $('[data-action="continue"]', root).addEventListener('click', go);
    $('[data-action="skip"]', root).addEventListener('click', go);
  },
};

/* ------------------------------------------------------------ Choix de filière */
export const filiereScreen = {
  bare: true,
  render() {
    const groups = domains();
    return `
      <div class="picker">
        <div class="page-head">
          <div>
            <span class="page-head__eyebrow">${t('Étape 2 sur 2', 'Step 2 of 2')}</span>
            <h1>${t('Quelle est ta filière ?', 'What is your programme?')}</h1>
            <p>${t('40 filières, de la première année au master. Ton choix filtre tous tes cours.', '40 programmes, from first year to master. Your choice filters every course.')}</p>
          </div>
          <button class="btn btn--ghost btn--icon" data-action="logout" aria-label="${t('Se déconnecter', 'Sign out')}">${icon('logout')}</button>
        </div>

        <div class="search">
          ${icon('search')}
          <input id="filiere-search" type="search" placeholder="${t('Rechercher une filière (informatique, droit, médecine…)', 'Search a programme (computer science, law, medicine…)')}" />
        </div>

        <div id="filiere-results" class="stack">
          ${groups.map((domain) => `
            <section data-domain="${esc(domain)}">
              <div class="domain-title">${esc(domain)}</div>
              <div class="picker__grid">
                ${filieresByDomain(domain).map((f) => `
                  <button class="filiere" data-filiere="${f.id}" data-search="${esc(`${f.name} ${f.code} ${f.tagline} ${domain}`.toLowerCase())}"
                    aria-pressed="${state.profile.filiereId === f.id}" style="--fi-color:${f.color}">
                    <div class="row" style="gap:10px">
                      <span class="filiere__code">${f.code}</span>
                      <div class="grow">
                        <strong>${esc(f.name)}</strong>
                        <small>${esc(f.tagline)}</small>
                      </div>
                    </div>
                    <div class="row" style="gap:6px;flex-wrap:wrap;margin-top:4px">
                      ${f.levels.map((l) => `<span class="pill" style="padding:2px 8px">${l}</span>`).join('')}
                    </div>
                  </button>`).join('')}
              </div>
            </section>`).join('')}
        </div>
        <div id="filiere-empty" class="empty" hidden>${icon('search')}<h3>${t('Aucune filière trouvée', 'No programme found')}</h3><p>${t('Essaie un autre mot-clé.', 'Try another keyword.')}</p></div>

        <div class="card card--glass row row--between" style="position:sticky;bottom:calc(var(--tabbar-h) + 10px);z-index:20">
          <div class="grow">
            <strong data-selected-name>${t('Aucune filière sélectionnée', 'No programme selected')}</strong>
            <p class="muted" style="font-size:13px">${t('Tu pourras changer plus tard.', 'You can change it later.')}</p>
          </div>
          <select class="select" id="level-select" style="max-width:150px">
            <option value="">${t('Niveau', 'Level')}</option>
            ${['L1', 'L2', 'L3', 'M1', 'M2'].map((l) => `<option value="${l}" ${state.profile.level === l ? 'selected' : ''}>${l}</option>`).join('')}
          </select>
          <button class="btn btn--primary" data-action="confirm-filiere" disabled>${t('Continuer', 'Continue')} ${icon('arrowRight')}</button>
        </div>
      </div>`;
  },
  mount(root) {
    let selected = state.profile.filiereId;
    const confirmBtn = $('[data-action="confirm-filiere"]', root);
    const nameLabel = $('[data-selected-name]', root);
    const levelSelect = $('#level-select', root);

    const sync = () => {
      confirmBtn.disabled = !selected;
      const f = FILIERES.find((x) => x.id === selected);
      nameLabel.textContent = f ? f.name : t('Aucune filière sélectionnée', 'No programme selected');
    };
    sync();

    $$('[data-filiere]', root).forEach((btn) => btn.addEventListener('click', () => {
      selected = btn.dataset.filiere;
      $$('[data-filiere]', root).forEach((b) => b.setAttribute('aria-pressed', String(b === btn)));
      sync();
    }));

    const search = $('#filiere-search', root);
    search.addEventListener('input', () => {
      const q = search.value.trim().toLowerCase();
      let visible = 0;
      $$('[data-filiere]', root).forEach((btn) => {
        const show = !q || btn.dataset.search.includes(q);
        btn.hidden = !show;
        if (show) visible++;
      });
      // Masque les domaines vides.
      $$('[data-domain]', root).forEach((section) => {
        section.hidden = $$('[data-filiere]', section).every((b) => b.hidden);
      });
      $('#filiere-empty', root).hidden = visible > 0;
    });

    confirmBtn.addEventListener('click', () => {
      updateProfile({ filiereId: selected, level: levelSelect.value || null, onboarded: true });
      toast(t('Filière enregistrée', 'Programme saved'), 'success');
      navigate('/');
    });

    $('[data-action="logout"]', root)?.addEventListener('click', async () => {
      const { logout } = await import('../store.js');
      logout();
      navigate('/welcome');
    });
  },
};
