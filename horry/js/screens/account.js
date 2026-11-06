/* ==========================================================================
   Abonnement, profil, documents légaux
   ========================================================================== */
import { icon, esc, $, $$, fmt, toast, openModal, closeModal, confirmDialog, shake } from '../lib/dom.js';
import { t } from '../lib/i18n.js';
import { navigate } from '../router.js';
import {
  state, currentUser as me, priceFor, planFor, purchasePlan, cancelSubscription,
  setTheme, setLang, updateProfile, logout, resetAll, myCourses, courseProgress,
  level, average, gradesFor,
} from '../store.js';
import { PLANS, PAYMENT_METHODS, LEGAL } from '../data/content.js';

/* ---------------------------------------------------------------- Abonnement */
export const subscriptionScreen = {
  tabs: 'student',
  render() {
    const sub = state.subscription;
    const cycle = sub.cycle || 'monthly';
    const active = planFor(sub.tier);
    return `
      <div class="page-head">
        <div><h1>${t('Abonnement', 'Subscription')}</h1><p>${t('Choisis le palier qui te correspond. Annulable à tout moment.', 'Pick the plan that fits. Cancel anytime.')}</p></div>
        <span class="pill ${sub.tier === 'discovery' ? '' : 'pill--success'}">${icon('star')} ${esc(active.label)}</span>
      </div>

      <div class="row" style="justify-content:center;margin-bottom:18px">
        <div class="seg" style="max-width:340px" role="tablist">
          <button role="tab" data-cycle="monthly" aria-selected="${cycle === 'monthly'}">${t('Mensuel', 'Monthly')}</button>
          <button role="tab" data-cycle="yearly" aria-selected="${cycle === 'yearly'}">${t('Annuel', 'Yearly')} · −17 %</button>
        </div>
      </div>

      <div class="plans">
        ${PLANS.map((plan) => {
          const price = cycle === 'yearly' ? plan.yearly : plan.monthly;
          const isCurrent = state.subscription.tier === plan.tier;
          return `
            <article class="card plan ${plan.featured ? 'plan--featured' : ''}">
              ${plan.featured ? `<span class="pill pill--primary plan__badge">${t('Le plus choisi', 'Most popular')}</span>` : ''}
              <div class="row row--between">
                <span class="icon-badge">${icon(plan.icon)}</span>
                ${isCurrent ? `<span class="pill pill--success">${t('Actuel', 'Current')}</span>` : ''}
              </div>
              <div>
                <h3>${esc(plan.label)}</h3>
                <div class="plan__price">
                  <strong>${price === 0 ? t('Gratuit', 'Free') : fmt.fcfa(price)}</strong>
                  ${price ? `<span>/ ${cycle === 'yearly' ? t('an', 'year') : t('mois', 'month')}</span>` : ''}
                </div>
              </div>
              <ul class="plan__perks">
                ${plan.perks.map((perk) => `<li>${icon('check')}<span>${esc(perk)}</span></li>`).join('')}
              </ul>
              <button class="btn ${plan.featured ? 'btn--primary' : 'btn--ghost'} btn--block"
                data-plan="${plan.tier}" ${isCurrent && plan.tier !== 'discovery' ? 'disabled' : ''}>
                ${isCurrent ? t('Palier actuel', 'Current plan') : plan.tier === 'discovery' ? t('Rester gratuit', 'Stay free') : t('Choisir ce palier', 'Choose this plan')}
              </button>
            </article>`;
        }).join('')}
      </div>

      ${sub.tier !== 'discovery' ? `
        <div class="section card">
          <div class="row row--between">
            <div>
              <div class="card__title">${icon('card')} ${t('Abonnement en cours', 'Current subscription')}</div>
              <p class="muted" style="font-size:13px;margin-top:4px">
                ${esc(active.label)} · ${fmt.fcfa(priceFor(sub.tier, sub.cycle))} / ${sub.cycle === 'yearly' ? t('an', 'year') : t('mois', 'month')}
                ${sub.renewsAt ? ` · ${t('renouvellement le', 'renews on')} ${fmt.date(sub.renewsAt)}` : ''}
              </p>
              ${sub.cancelRequested ? `<p class="pill pill--warning" style="margin-top:8px">${icon('info')} ${t('Résiliation programmée en fin de période', 'Cancellation scheduled at period end')}</p>` : ''}
            </div>
            ${sub.cancelRequested ? '' : `<button class="btn btn--ghost btn--sm" data-action="cancel">${t('Résilier', 'Cancel')}</button>`}
          </div>
        </div>` : ''}

      ${sub.receipts.length ? `
        <div class="section">
          <div class="section__head"><h2>${t('Reçus', 'Receipts')}</h2></div>
          <div class="stack" style="gap:8px">
            ${sub.receipts.map((r) => `
              <div class="card card--flat row row--between" style="background:var(--surface-sunken)">
                <div>
                  <strong style="font-size:14px">${esc(planFor(r.tier).label)} · ${fmt.fcfa(r.amount)}</strong>
                  <div class="muted" style="font-size:12px">${fmt.date(r.date)} · ${esc(methodLabel(r.method))} ${r.masked ? `· ${esc(r.masked)}` : ''}</div>
                </div>
                <span class="pill">${esc(r.id)}</span>
              </div>`).join('')}
          </div>
        </div>` : ''}

      <p class="hint center" style="margin-top:26px">
        ${t('Démonstration : aucun paiement réel n’est effectué. Les numéros de carte ne sont jamais stockés — seul un masque court apparaît sur le reçu.', 'Demo: no real payment is made. Card numbers are never stored — only a short mask appears on the receipt.')}
      </p>`;
  },
  mount(root) {
    let cycle = state.subscription.cycle || 'monthly';
    $$('[data-cycle]', root).forEach((btn) => btn.addEventListener('click', () => {
      cycle = btn.dataset.cycle;
      state.subscription.cycle = cycle;
      $$('[data-cycle]', root).forEach((b) => b.setAttribute('aria-selected', String(b === btn)));
      // Redessine les prix sans recharger la vue.
      $$('[data-plan]', root).forEach((b) => {
        const plan = PLANS.find((p) => p.tier === b.dataset.plan);
        const strong = $('strong', b.closest('.plan'));
        const price = cycle === 'yearly' ? plan.yearly : plan.monthly;
        strong.textContent = price === 0 ? t('Gratuit', 'Free') : fmt.fcfa(price);
      });
    }));

    $$('[data-plan]', root).forEach((btn) => btn.addEventListener('click', () => {
      const tier = btn.dataset.plan;
      if (tier === 'discovery') { toast(t('Tu restes sur le palier gratuit.', 'You stay on the free plan.'), 'info'); return; }
      openCheckout(tier, cycle);
    }));

    $('[data-action="cancel"]', root)?.addEventListener('click', async () => {
      const ok = await confirmDialog({
        title: t('Résilier l’abonnement ?', 'Cancel subscription?'),
        message: t('Tu gardes l’accès jusqu’à la fin de la période déjà payée.', 'You keep access until the end of the paid period.'),
        confirmLabel: t('Résilier', 'Cancel plan'),
        danger: true,
      });
      if (ok) {
        cancelSubscription();
        toast(t('Résiliation enregistrée.', 'Cancellation saved.'), 'success');
      }
    });
  },
};

function methodLabel(id) {
  return PAYMENT_METHODS.find((m) => m.id === id)?.label || id;
}

/* --------------------------------------------------------------- Tunnel de paiement */
function openCheckout(tier, cycle) {
  const plan = planFor(tier);
  const price = priceFor(tier, cycle);
  let method = 'mtnMoMo';

  openModal({
    title: t('Paiement', 'Checkout'),
    wide: true,
    body: `
      <div class="checkout">
        <div class="stack">
          <div class="card card--flat" style="background:var(--surface-sunken)">
            <div class="row row--between">
              <div>
                <strong style="font-size:15px">${esc(plan.label)}</strong>
                <p class="muted" style="font-size:13px">${cycle === 'yearly' ? t('Facturation annuelle', 'Annual billing') : t('Facturation mensuelle', 'Monthly billing')}</p>
              </div>
              <strong style="font-size:20px">${fmt.fcfa(price)}</strong>
            </div>
          </div>

          <div>
            <span class="label">${t('Moyen de paiement', 'Payment method')}</span>
            <div class="methods" style="margin-top:8px">
              ${PAYMENT_METHODS.map((m) => `
                <button type="button" class="method" data-method="${m.id}" aria-pressed="${m.id === method}">
                  <span class="method__logo" style="background:${m.color};color:${m.fg}">${m.short}</span>
                  <strong>${esc(m.label)}</strong>
                  <small>${esc(m.hint)}</small>
                </button>`).join('')}
            </div>
          </div>

          <div id="method-fields"></div>

          <label class="check">
            <input type="checkbox" name="consent" checked />
            <span>${t('J’autorise le prélèvement et j’accepte les conditions.', 'I authorize the charge and accept the terms.')}</span>
          </label>
          <p class="error" data-error hidden></p>
        </div>

        <aside class="card card--flat" style="background:var(--surface-sunken)">
          <div class="card__title">${icon('shield')} ${t('Sécurité', 'Security')}</div>
          <ul class="stack" style="gap:10px;margin-top:12px;font-size:13px;color:var(--text-soft)">
            <li class="row" style="gap:8px;align-items:flex-start">${icon('check')}<span>${t('Aucun numéro de carte n’est stocké.', 'No card number is stored.')}</span></li>
            <li class="row" style="gap:8px;align-items:flex-start">${icon('check')}<span>${t('Confirmation par code USSD sur ton téléphone.', 'USSD confirmation on your phone.')}</span></li>
            <li class="row" style="gap:8px;align-items:flex-start">${icon('check')}<span>${t('Reçu disponible immédiatement.', 'Receipt available immediately.')}</span></li>
          </ul>
          <div class="divider"></div>
          <div class="receipt">
            <div class="receipt__row"><span>${t('Palier', 'Tier')}</span><span>${esc(plan.label)}</span></div>
            <div class="receipt__row"><span>${t('Cycle', 'Cycle')}</span><span>${cycle === 'yearly' ? t('Annuel', 'Yearly') : t('Mensuel', 'Monthly')}</span></div>
            <div class="receipt__row"><span>${t('Total', 'Total')}</span><span>${fmt.fcfa(price)}</span></div>
          </div>
        </aside>
      </div>`,
    actions: `
      <button class="btn btn--ghost" data-action="modal-close">${t('Annuler', 'Cancel')}</button>
      <button class="btn btn--primary" data-action="pay">${t('Payer', 'Pay')} ${fmt.fcfa(price)}</button>`,
    onMount(modal) {
      const fields = modal.querySelector('#method-fields');
      const error = modal.querySelector('[data-error]');

      const renderFields = () => {
        fields.innerHTML = method === 'visaCard' ? `
          <div class="stack" style="gap:12px">
            <div class="field"><label for="card">${t('Numéro de carte', 'Card number')}</label>
              <input class="input mono" id="card" inputmode="numeric" placeholder="4242 4242 4242 4242" maxlength="19" /></div>
            <div class="row" style="gap:12px">
              <div class="field grow"><label for="exp">${t('Expiration', 'Expiry')}</label>
                <input class="input mono" id="exp" placeholder="MM/AA" maxlength="5" /></div>
              <div class="field grow"><label for="cvv">CVV</label>
                <input class="input mono" id="cvv" type="password" placeholder="•••" maxlength="4" /></div>
            </div>
          </div>` : `
          <div class="field"><label for="phone">${t('Numéro de téléphone', 'Phone number')}</label>
            <div class="input-group">${icon('user')}
              <input class="input" id="phone" inputmode="tel" placeholder="6XX XXX XXX" maxlength="12" />
            </div>
            <p class="hint">${esc(PAYMENT_METHODS.find((m) => m.id === method).hint)}</p>
          </div>`;
        fields.querySelector('input')?.focus();
      };
      renderFields();

      modal.querySelectorAll('[data-method]').forEach((btn) => btn.addEventListener('click', () => {
        method = btn.dataset.method;
        modal.querySelectorAll('[data-method]').forEach((b) => b.setAttribute('aria-pressed', String(b === btn)));
        renderFields();
      }));

      modal.querySelectorAll('[data-action="modal-close"]').forEach((b) => b.addEventListener('click', closeModal));

      modal.querySelector('[data-action="pay"]').addEventListener('click', (e) => {
        const btn = e.currentTarget;
        const consent = modal.querySelector('[name="consent"]').checked;
        const showError = (msg) => { error.hidden = false; error.textContent = msg; shake(error); };

        let masked = '';
        if (!consent) { showError(t('Tu dois accepter le prélèvement.', 'You must accept the charge.')); return; }

        if (method === 'visaCard') {
          const card = modal.querySelector('#card').value.replace(/\s/g, '');
          const exp = modal.querySelector('#exp').value;
          const cvv = modal.querySelector('#cvv').value;
          if (!luhn(card)) { showError(t('Numéro de carte invalide.', 'Invalid card number.')); return; }
          if (!/^\d{2}\/\d{2}$/.test(exp)) { showError(t('Date d’expiration invalide (MM/AA).', 'Invalid expiry (MM/YY).')); return; }
          if (!/^\d{3,4}$/.test(cvv)) { showError(t('CVV invalide.', 'Invalid CVV.')); return; }
          masked = `•••• ${card.slice(-4)}`;
        } else {
          const phone = modal.querySelector('#phone').value.replace(/[\s.-]/g, '');
          if (!/^6\d{8}$/.test(phone)) { showError(t('Numéro camerounais invalide (6XXXXXXXX).', 'Invalid Cameroonian number (6XXXXXXXX).')); return; }
          masked = `•••• ${phone.slice(-3)}`;
        }

        error.hidden = true;
        btn.dataset.loading = 'true';
        btn.textContent = t('Paiement en cours…', 'Processing…');

        setTimeout(() => {
          const receipt = purchasePlan(tier, cycle, method, masked);
          closeModal();
          toast(t('Paiement accepté', 'Payment accepted'), 'success');
          openModal({
            title: t('Reçu de paiement', 'Payment receipt'),
            body: `
              <div class="center" style="padding:8px 0 16px">
                <div style="width:64px;height:64px;border-radius:50%;background:color-mix(in srgb, var(--success) 16%, transparent);display:grid;place-items:center;margin:0 auto 12px;color:var(--success)">
                  ${icon('check')}
                </div>
                <h3>${t('Bienvenue dans', 'Welcome to')} ${esc(plan.tier === 'excellence' ? 'Excellence' : 'Premium')} !</h3>
                <p class="muted" style="font-size:13px">${t('Ton accès est actif immédiatement.', 'Your access is active right away.')}</p>
              </div>
              <div class="receipt">
                <div class="receipt__row"><span>${t('Référence', 'Reference')}</span><span>${esc(receipt.id)}</span></div>
                <div class="receipt__row"><span>${t('Date', 'Date')}</span><span>${fmt.date(receipt.date)}</span></div>
                <div class="receipt__row"><span>${t('Palier', 'Tier')}</span><span>${esc(plan.label)}</span></div>
                <div class="receipt__row"><span>${t('Montant', 'Amount')}</span><span>${fmt.fcfa(receipt.amount)}</span></div>
                <div class="receipt__row"><span>${t('Moyen', 'Method')}</span><span>${esc(methodLabel(receipt.method))} ${esc(receipt.masked)}</span></div>
              </div>`,
            actions: `<button class="btn btn--primary" data-action="done">${t('Terminer', 'Done')}</button>`,
            onMount(m) { m.querySelector('[data-action="done"]').addEventListener('click', closeModal); },
          });
        }, 1400);
      });
    },
  });
}

function luhn(number) {
  if (!/^\d{13,19}$/.test(number)) return false;
  let sum = 0;
  let double = false;
  for (let i = number.length - 1; i >= 0; i--) {
    let digit = Number(number[i]);
    if (double) { digit *= 2; if (digit > 9) digit -= 9; }
    sum += digit;
    double = !double;
  }
  return sum % 10 === 0;
}

/* --------------------------------------------------------------------- Profil */
export const profileScreen = {
  tabs: 'student',
  render() {
    const user = me();
    if (!user) return '';
    const courses = myCourses();
    const avg = average(gradesFor(courses));
    const plan = planFor(state.subscription.tier);
    const roleLabel = { student: t('Étudiant', 'Student'), teacher: t('Enseignant', 'Teacher'), admin: t('Administrateur', 'Administrator') }[user.role];

    return `
      <div class="profile-head card">
        <span class="avatar avatar--lg avatar--ring">${esc(initials(user.fullName))}</span>
        <div>
          <h1>${esc(user.fullName)}</h1>
          <p class="muted">${esc(user.email)}</p>
          <div class="badges">
            <span class="pill pill--primary">${icon('graduation')} ${roleLabel}</span>
            <span class="pill">${esc(plan.label)}</span>
            ${user.status === 'pending' ? `<span class="pill pill--warning">${icon('clock')} ${t('En attente de validation', 'Awaiting validation')}</span>` : ''}
            <span class="pill">${icon('bolt')} ${t('Niveau', 'Level')} ${level()}</span>
          </div>
        </div>
        <button class="btn btn--ghost btn--sm" data-action="edit">${icon('edit')} ${t('Modifier', 'Edit')}</button>
      </div>

      <div class="section stats-strip">
        ${[
          ['book', String(courses.length), t('cours', 'courses')],
          ['bolt', String(state.xp), 'XP'],
          ['chart', avg ? `${avg.toFixed(1)}/20` : '—', t('moyenne', 'average')],
          ['flame', `${state.streak} ${t('j', 'd')}`, t('série', 'streak')],
        ].map(([ic, v, l]) => `
          <div class="stat-card"><span class="icon-badge icon-badge--sm">${icon(ic)}</span>
            <div><strong>${v}</strong><span>${l}</span></div></div>`).join('')}
      </div>

      <div class="section split-2">
        <div class="stack">
          <div>
            <div class="menu-group__title">${t('Apparence et langue', 'Appearance and language')}</div>
            <div class="menu">
              <div class="menu-row">
                <span class="icon-badge icon-badge--sm">${icon(state.theme === 'dark' ? 'moon' : 'sun')}</span>
                <div><strong>${t('Thème', 'Theme')}</strong><small>${state.theme === 'dark' ? t('Sombre', 'Dark') : t('Clair', 'Light')}</small></div>
                <label class="switch"><input type="checkbox" data-setting="theme" ${state.theme === 'dark' ? 'checked' : ''} /><span class="sr-only">${t('Thème sombre', 'Dark theme')}</span></label>
              </div>
              <button class="menu-row" data-action="lang">
                <span class="icon-badge icon-badge--sm">${icon('globe')}</span>
                <div><strong>${t('Langue', 'Language')}</strong><small>${state.lang === 'fr' ? 'Français' : 'English'}</small></div>
                <span class="menu-row__chev">${icon('chevronRight')}</span>
              </button>
            </div>
          </div>

          <div>
            <div class="menu-group__title">${t('Notifications', 'Notifications')}</div>
            <div class="menu">
              ${[['notifications', 'bell', t('Rappels de cours', 'Course reminders')],
                 ['calendar', 'calendar', t('Synchronisation planning', 'Schedule sync')],
                 ['analytics', 'chart', t('Statistiques anonymes', 'Anonymous analytics')]].map(([id, ic, label]) => `
                <div class="menu-row">
                  <span class="icon-badge icon-badge--sm">${icon(ic)}</span>
                  <div><strong>${label}</strong><small>${id === 'analytics' ? t('Sans donnée personnelle', 'No personal data') : t('Modifiable à tout moment', 'Change anytime')}</small></div>
                  <label class="switch"><input type="checkbox" data-perm="${id}" ${state.profile.permissions?.[id] ? 'checked' : ''} /><span class="sr-only">${label}</span></label>
                </div>`).join('')}
            </div>
          </div>

          <div>
            <div class="menu-group__title">${t('Données et confidentialité', 'Data and privacy')}</div>
            <div class="menu">
              <button class="menu-row" data-action="export">
                <span class="icon-badge icon-badge--sm">${icon('download')}</span>
                <div><strong>${t('Exporter mes données', 'Export my data')}</strong><small>${t('Fichier JSON, immédiat', 'JSON file, instant')}</small></div>
                <span class="menu-row__chev">${icon('chevronRight')}</span>
              </button>
              <a class="menu-row" href="#/legal/terms">
                <span class="icon-badge icon-badge--sm">${icon('file')}</span>
                <div><strong>${t('Conditions générales', 'Terms of service')}</strong><small>${t('Version', 'Version')} 3.1</small></div>
                <span class="menu-row__chev">${icon('chevronRight')}</span>
              </a>
              <a class="menu-row" href="#/legal/privacy">
                <span class="icon-badge icon-badge--sm">${icon('shield')}</span>
                <div><strong>${t('Politique de confidentialité', 'Privacy policy')}</strong><small>${t('Mise à jour', 'Updated')} ${t('octobre 2026', 'October 2026')}</small></div>
                <span class="menu-row__chev">${icon('chevronRight')}</span>
              </a>
            </div>
          </div>
        </div>

        <div class="stack">
          <div class="card">
            <div class="card__title">${icon('star')} ${t('Abonnement', 'Subscription')}</div>
            <p class="muted" style="font-size:13px;margin-top:6px">${esc(plan.label)} · ${state.subscription.tier === 'discovery' ? t('gratuit', 'free') : fmt.fcfa(priceFor(state.subscription.tier, state.subscription.cycle))}</p>
            <button class="btn btn--primary btn--block" style="margin-top:12px" data-action="plan">${t('Voir les paliers', 'See plans')}</button>
          </div>

          <div class="card">
            <div class="card__title">${icon('target')} ${t('Progression', 'Progress')}</div>
            <div class="stack" style="margin-top:12px;gap:10px">
              ${myCourses().slice(0, 4).map((c) => `
                <div>
                  <div class="row row--between" style="font-size:13px"><span class="truncate">${esc(c.title)}</span><strong>${courseProgress(c)}%</strong></div>
                  <div class="bar bar--sm"><span style="width:${courseProgress(c)}%"></span></div>
                </div>`).join('')}
            </div>
          </div>

          <div class="menu">
            <button class="menu-row menu-row--danger" data-action="logout">
              <span class="icon-badge icon-badge--sm">${icon('logout')}</span>
              <div><strong>${t('Se déconnecter', 'Sign out')}</strong><small>${t('Tes données restent enregistrées', 'Your data stays saved')}</small></div>
              <span class="menu-row__chev">${icon('chevronRight')}</span>
            </button>
            <button class="menu-row menu-row--danger" data-action="reset">
              <span class="icon-badge icon-badge--sm">${icon('trash')}</span>
              <div><strong>${t('Tout effacer', 'Erase everything')}</strong><small>${t('Comptes, progression, messages', 'Accounts, progress, messages')}</small></div>
              <span class="menu-row__chev">${icon('chevronRight')}</span>
            </button>
          </div>
        </div>
      </div>`;
  },
  mount(root) {
    $('[data-setting="theme"]', root).addEventListener('change', (e) => setTheme(e.target.checked ? 'dark' : 'light'));
    $$('[data-perm]', root).forEach((input) => input.addEventListener('change', () => {
      updateProfile({ permissions: { ...state.profile.permissions, [input.dataset.perm]: input.checked } });
      toast(t('Préférence enregistrée', 'Preference saved'), 'success');
    }));
    $('[data-action="lang"]', root).addEventListener('click', () => setLang(state.lang === 'fr' ? 'en' : 'fr'));
    $('[data-action="plan"]', root).addEventListener('click', () => navigate('/subscription'));
    $('[data-action="export"]', root).addEventListener('click', () => {
      const data = {
        exportedAt: new Date().toISOString(),
        user: { ...currentUser(), passwordHash: undefined },
        profile: state.profile,
        xp: state.xp,
        streak: state.streak,
        progress: state.progress,
        subscription: state.subscription,
        chat: state.chat,
      };
      const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
      const a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = 'educoach-donnees.json';
      a.click();
      toast(t('Export téléchargé', 'Export downloaded'), 'success');
    });
    $('[data-action="logout"]', root).addEventListener('click', () => { logout(); navigate('/welcome'); });
    $('[data-action="reset"]', root).addEventListener('click', async () => {
      const ok = await confirmDialog({
        title: t('Tout effacer ?', 'Erase everything?'),
        message: t('Comptes, progression, messages et abonnement seront supprimés de ce navigateur. Action irréversible.', 'Accounts, progress, messages and subscription will be removed from this browser. Irreversible.'),
        confirmLabel: t('Effacer', 'Erase'),
        danger: true,
      });
      if (ok) { resetAll(); navigate('/welcome'); }
    });
    $('[data-action="edit"]', root).addEventListener('click', () => {
      const user = me();
      openModal({
        title: t('Modifier mon profil', 'Edit profile'),
        body: `
          <div class="stack">
            <div class="field"><label for="name">${t('Nom complet', 'Full name')}</label>
              <input class="input" id="name" value="${esc(user.fullName)}" /></div>
            <div class="field"><label for="email">${t('Email', 'Email')}</label>
              <input class="input" id="email" value="${esc(user.email)}" disabled />
              <p class="hint">${t('L’email ne peut pas être modifié dans cette démo.', 'Email cannot be changed in this demo.')}</p></div>
          </div>`,
        actions: `<button class="btn btn--ghost" data-action="modal-close">${t('Annuler', 'Cancel')}</button>
          <button class="btn btn--primary" data-action="save">${t('Enregistrer', 'Save')}</button>`,
        onMount(modal) {
          modal.querySelectorAll('[data-action="modal-close"]').forEach((b) => b.addEventListener('click', closeModal));
          modal.querySelector('[data-action="save"]').addEventListener('click', () => {
            const name = modal.querySelector('#name').value.trim();
            if (name.length < 2) { toast(t('Nom trop court', 'Name too short'), 'error'); return; }
            const user2 = state.users.find((u) => u.id === state.currentUserId);
            user2.fullName = name;
            closeModal();
            toast(t('Profil mis à jour', 'Profile updated'), 'success');
            navigate('/profile');
          });
        },
      });
    });
  },
};

function initials(name) {
  return String(name).split(/\s+/).filter(Boolean).slice(0, 2).map((w) => w[0].toUpperCase()).join('');
}

/* ---------------------------------------------------------------------- Légal */
export const legalScreen = {
  bare: true,
  render({ params }) {
    const doc = LEGAL[params.doc] || LEGAL.terms;
    return `
      <div style="max-width:820px;margin-inline:auto;padding-top:16px">
        <button class="btn btn--ghost btn--sm" data-action="back" style="margin-bottom:16px">${icon('arrowLeft')} ${t('Retour', 'Back')}</button>
        <div class="page-head">
          <div>
            <span class="page-head__eyebrow">${t('Document légal', 'Legal document')}</span>
            <h1>${esc(doc.title)}</h1>
            <div class="legal__meta" style="margin-top:8px">
              <span>${t('Version', 'Version')} ${esc(doc.version)}</span>
              <span>${t('Mise à jour :', 'Updated:')} ${esc(doc.updated)}</span>
            </div>
          </div>
        </div>
        <div class="legal">
          ${doc.sections.map((section) => `
            <article class="card">
              <h2>${esc(section.title)}</h2>
              ${section.paragraphs.map((p) => `<p>${esc(p)}</p>`).join('')}
            </article>`).join('')}
        </div>
        <p class="hint center" style="margin-top:24px">${t('Document de démonstration — à faire valider juridiquement avant mise en production.', 'Demo document — have it legally reviewed before going live.')}</p>
      </div>`;
  },
  mount(root) {
    $('[data-action="back"]', root).addEventListener('click', () => {
      if (history.length > 1) history.back();
      else navigate('/welcome');
    });
  },
};
