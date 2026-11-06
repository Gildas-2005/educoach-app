/* ==========================================================================
   Messagerie
   ========================================================================== */
import { icon, esc, $, $$, fmt, toast } from '../lib/dom.js';
import { t } from '../lib/i18n.js';
import { navigate } from '../router.js';
import { threads, threadById, sendMessage, markRead, state, currentUser } from '../store.js';

const REPLIES = [
  "Bien reçu. Regarde d'abord l'exemple de la leçon, il traite exactement ce cas.",
  "Bonne question — c'est le point qui bloque le plus souvent. On en reparle en TD.",
  "Oui, c'est ça. Pense à justifier chaque étape dans ta copie.",
  "Je corrige les copies ce soir, tu auras le retour avant demain.",
  "Vérifie que ton invariant est vrai avant la boucle et conservé après chaque itération.",
];

/* ------------------------------------------------------------- Liste des fils */
export const chatList = {
  tabs: 'student',
  render() {
    const list = threads();
    const me = currentUser();
    return `
      <div class="page-head">
        <div><h1>${t('Messages', 'Messages')}</h1><p>${list.length} ${t('conversations', 'conversations')}</p></div>
        <span class="pill">${icon('shield')} ${t('Chiffré côté appareil', 'Encrypted on device')}</span>
      </div>

      <div class="search" style="margin-bottom:16px">${icon('search')}
        <input id="room-search" type="search" placeholder="${t('Rechercher une conversation…', 'Search a conversation…')}" />
      </div>

      <div class="chat-list" id="room-list">
        ${list.map((room) => {
          const last = room.messages[room.messages.length - 1];
          const unread = state.chat.unread[room.id] || 0;
          return `
            <button class="room" data-room="${room.id}" data-search="${esc(`${room.name} ${last?.body || ''}`.toLowerCase())}">
              <span class="avatar ${room.kind === 'group' ? '' : 'avatar--teacher'}">${room.kind === 'group' ? esc(initials(room.name)) : esc(initials(room.name))}</span>
              <span>
                <strong>${esc(room.name)}</strong>
                <small>${last?.mine ? t('Toi : ', 'You: ') : ''}${esc(last?.body || '')}</small>
              </span>
              <span class="room__meta">
                <span>${last ? fmt.relative(last.at) : ''}</span>
                ${unread ? `<span class="room__unread">${unread}</span>` : ''}
              </span>
            </button>`;
        }).join('')}
      </div>

      <div class="section card card--flat" style="background:var(--surface-sunken)">
        <div class="row" style="align-items:flex-start;gap:12px">
          <span class="icon-badge icon-badge--sm">${icon('info')}</span>
          <div>
            <strong style="font-size:14px">${t('Messagerie de démonstration', 'Demo messaging')}</strong>
            <p class="muted" style="font-size:13px">${t('Tes messages restent dans ton navigateur. Une réponse automatique du professeur simule l’échange, le temps que l’API soit branchée.', 'Your messages stay in your browser. An automatic teacher reply simulates the exchange until the API is wired.')}</p>
          </div>
        </div>
      </div>`;
  },
  mount(root) {
    const search = $('#room-search', root);
    search.addEventListener('input', () => {
      const q = search.value.trim().toLowerCase();
      $$('[data-room]', root).forEach((r) => { r.hidden = q && !r.dataset.search.includes(q); });
    });
    $$('[data-room]', root).forEach((r) => r.addEventListener('click', () => navigate(`/chat/${r.dataset.room}`)));
  },
};

/* ---------------------------------------------------------------- Conversation */
export const chatThread = {
  tabs: 'student',
  render({ params }) {
    const room = threadById(params.id);
    if (!room) return `<div class="empty">${icon('inbox')}<h3>${t('Conversation introuvable', 'Conversation not found')}</h3></div>`;
    markRead(room.id);
    return `
      <div class="thread">
        <div class="thread__head">
          <button class="btn btn--ghost btn--icon btn--sm" data-action="back" aria-label="${t('Retour', 'Back')}">${icon('arrowLeft')}</button>
          <span class="avatar ${room.kind === 'group' ? '' : 'avatar--teacher'}">${esc(initials(room.name))}</span>
          <div class="grow">
            <strong style="font-size:14px;display:block">${esc(room.name)}</strong>
            <small class="muted" style="font-size:12px">${room.kind === 'group' ? `${room.members} ${t('membres', 'members')}` : t('conversation directe', 'direct message')}</small>
          </div>
          <button class="btn btn--ghost btn--icon btn--sm" aria-label="${t('Infos', 'Info')}" data-action="info">${icon('info')}</button>
        </div>

        <div class="messages" id="messages">
          ${room.messages.map((m) => renderBubble(m)).join('')}
        </div>

        <form class="composer" id="composer">
          <textarea class="input textarea" name="body" rows="1" placeholder="${t('Écris ton message…', 'Write your message…')}" aria-label="${t('Message', 'Message')}"></textarea>
          <button class="btn btn--primary btn--icon" type="submit" aria-label="${t('Envoyer', 'Send')}">${icon('send')}</button>
        </form>
      </div>`;
  },
  mount(root, { params }) {
    const messages = $('#messages', root);
    const form = $('#composer', root);
    const scrollDown = () => { messages.scrollTop = messages.scrollHeight; };
    scrollDown();

    $('[data-action="back"]', root).addEventListener('click', () => navigate('/chat'));
    $('[data-action="info"]', root).addEventListener('click', () => {
      const room = threadById(params.id);
      toast(room.kind === 'group' ? `${room.members} ${t('membres dans ce groupe', 'members in this group')}` : t('Conversation directe avec un enseignant', 'Direct conversation with a teacher'), 'info');
    });

    const body = form.body;
    body.addEventListener('input', () => {
      body.style.height = 'auto';
      body.style.height = `${Math.min(140, body.scrollHeight)}px`;
    });
    body.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); form.requestSubmit(); }
    });

    form.addEventListener('submit', (e) => {
      e.preventDefault();
      const value = body.value.trim();
      if (!value) return;
      sendMessage(params.id, value);
      messages.insertAdjacentHTML('beforeend', renderBubble({ author: 'Moi', body: value, at: Date.now(), mine: true }));
      body.value = '';
      body.style.height = 'auto';
      scrollDown();
      simulateReply(messages, scrollDown);
    });
  },
};

function simulateReply(container, scrollDown) {
  const typing = document.createElement('div');
  typing.className = 'bubble bubble--system';
  typing.innerHTML = `<span class="typing"><i></i><i></i><i></i></span>`;
  container.appendChild(typing);
  scrollDown();
  setTimeout(() => {
    typing.remove();
    const reply = REPLIES[Math.floor(Math.random() * REPLIES.length)];
    container.insertAdjacentHTML('beforeend', renderBubble({
      author: 'Pr. M. Diallo', teacher: true, body: reply, at: Date.now(),
    }));
    scrollDown();
  }, 1400);
}

function renderBubble(m) {
  if (m.mine) return `<div class="bubble bubble--me"><p>${esc(m.body)}</p><time>${fmt.clock(m.at)}</time></div>`;
  return `<div class="bubble">
    <div class="bubble__author">${esc(m.author)}${m.teacher ? ' · ' + t('enseignant', 'teacher') : ''}</div>
    <p>${esc(m.body)}</p><time>${fmt.clock(m.at)}</time>
  </div>`;
}

function initials(name) {
  return String(name).replace(/^(Dr\.|Pr\.|Ms\.|M\.)\s*/i, '').split(/\s+/).slice(0, 2).map((w) => w[0]?.toUpperCase() || '').join('');
}
