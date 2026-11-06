// Génère horry/js/data/seed.js depuis lib/core/data/seed.dart.
// Usage : node horry/tools/parse-seed.mjs   (depuis la racine du dépôt)
import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '..', '..');
const src = fs.readFileSync(path.join(root, 'lib/core/data/seed.dart'), 'utf8');

const unquote = (s) => s.replace(/\\'/g, "'").replace(/\\\\/g, '\\');

/** Coupe un corps d'appel sur les virgules de premier niveau. */
function splitArgs(body) {
  const out = [];
  let buf = '';
  let depth = 0;
  let quote = false;
  for (let i = 0; i < body.length; i++) {
    const ch = body[i];
    if (quote) {
      buf += ch;
      if (ch === '\\') { buf += body[++i] ?? ''; continue; }
      if (ch === "'") quote = false;
      continue;
    }
    if (ch === "'") { quote = true; buf += ch; continue; }
    if ('([{<'.includes(ch)) depth++;
    if (')]}>'.includes(ch)) depth--;
    if (ch === ',' && depth === 0) { out.push(buf.trim()); buf = ''; continue; }
    buf += ch;
  }
  if (buf.trim()) out.push(buf.trim());
  return out;
}

/** Extrait l'appel `name(` ... `)` équilibré à partir de `from`. */
function callAt(block, from) {
  let depth = 0;
  let quote = false;
  for (let i = from; i < block.length; i++) {
    const ch = block[i];
    if (quote) {
      if (ch === '\\') { i++; continue; }
      if (ch === "'") quote = false;
      continue;
    }
    if (ch === "'") { quote = true; continue; }
    if (ch === '(') depth++;
    else if (ch === ')') { depth--; if (depth === 0) return { body: block.slice(from + 1, i), end: i + 1 }; }
  }
  throw new Error('appel non fermé');
}

// ---------------------------------------------------------------- filières
const filiereBlock = src.slice(src.indexOf('final filiereSeed'), src.indexOf('/// Une ligne de graine de cours'));
const filieres = [];
for (let i = 0; (i = filiereBlock.indexOf('const Filiere(', i)) !== -1; ) {
  const { body, end } = callAt(filiereBlock, i + 'const Filiere'.length);
  const field = (key) => {
    const m = body.match(new RegExp(`${key}:\\s*'((?:[^'\\\\]|\\\\.)*)'`));
    return m ? unquote(m[1]) : null;
  };
  const color = body.match(/Color\(0xFF([0-9A-Fa-f]{6})\)/);
  const levels = body.match(/degreeLevels:\s*<String>\[([^\]]*)\]/);
  filieres.push({
    id: field('id'),
    code: field('code'),
    name: field('name'),
    tagline: field('tagline'),
    domain: field('domain'),
    color: color ? `#${color[1].toLowerCase()}` : '#3f51b5',
    levels: levels ? splitArgs(levels[1]).map((s) => unquote(s.trim().replace(/^'|'$/g, ''))) : [],
  });
  i = end;
}

// ------------------------------------------------------------------- cours
const courseBlock = src.slice(src.indexOf('final courseSeed'));
const courses = [];
for (let i = 0; (i = courseBlock.indexOf('_row(', i)) !== -1; ) {
  const { body, end } = callAt(courseBlock, i + '_row'.length);
  const clean = body.replace(/\/\/[^\n]*/g, '');
  const args = splitArgs(clean);
  const pos = args.filter((a) => !/^\w+\s*:/.test(a));
  const str = (k) => (pos[k] && pos[k].startsWith("'") ? unquote(pos[k].slice(1, -1)) : null);
  const num = (k) => (pos[k] && /^\d+$/.test(pos[k]) ? Number(pos[k]) : null);
  const weekly = clean.match(/weekly:\s*(\d+)/);
  if (str(0) && str(2) && num(5) !== null && num(6) !== null) {
    courses.push({
      filiereId: str(0),
      level: str(1),
      code: str(2),
      title: str(3),
      teacher: str(4),
      credits: num(5),
      weeklyHours: num(6),
      weekly: weekly ? Number(weekly[1]) : 12,
    });
  }
  i = end;
}

const out = `// Généré depuis lib/core/data/seed.dart par horry/tools/parse-seed.mjs.
// Ne pas éditer à la main : régénérer avec \`node horry/tools/parse-seed.mjs\`.
export const FILIERES = ${JSON.stringify(filieres, null, 1)};

export const COURSE_ROWS = ${JSON.stringify(courses)};
`;
fs.writeFileSync(path.join(root, 'horry/js/data/seed.js'), out);

console.log(`filières : ${filieres.length}`);
console.log(`cours    : ${courses.length}`);
const domains = [...new Set(filieres.map((f) => f.domain))];
console.log(`domaines : ${domains.length} (${domains.join(', ')})`);
const orphans = courses.filter((c) => !filieres.some((f) => f.id === c.filiereId));
console.log(`cours sans filière : ${orphans.length}`);
