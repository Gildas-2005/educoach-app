/* ==========================================================================
   Traduction — même contrat que AppTexts.t(fr, en) du projet Flutter
   ========================================================================== */
import { state } from '../store.js';

export const t = (fr, en) => (state.lang === 'en' ? en : fr);
