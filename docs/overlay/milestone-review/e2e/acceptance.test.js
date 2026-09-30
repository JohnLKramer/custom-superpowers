// Held-out acceptance tests. Run from project root: node --test /tmp/sdd-ab/hidden/acceptance.test.js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { writeFileSync, mkdtempSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
const root = process.cwd();
const { tokenize } = await import(join(root, 'src/tokenize.js'));
const { frequencies } = await import(join(root, 'src/frequencies.js'));
const { topN } = await import(join(root, 'src/topn.js'));
const dir = mkdtempSync(join(tmpdir(), 'ts-'));
const file = (name, body) => { const p = join(dir, name); writeFileSync(p, body); return p; };
const cli = (...args) => spawnSync('node', [join(root, 'bin/textstats.js'), ...args], { encoding: 'utf8' });

test('contractions stay whole', () => assert.deepEqual(tokenize("Don't stop"), ["don't", 'stop']));
test('curly apostrophe contraction', () => assert.deepEqual(tokenize('o’clock'), ['o’clock']));
test('edge apostrophes are separators', () => assert.deepEqual(tokenize("'tis the dogs' bone"), ['tis', 'the', 'dogs', 'bone']));
test('unicode letters', () => assert.deepEqual(tokenize('Café naïve Straße'), ['café', 'naïve', 'straße']));
test('digits are word chars', () => assert.deepEqual(tokenize('abc123 4 x-y'), ['abc123', '4', 'x', 'y']));
test('empty text', () => assert.deepEqual(tokenize(''), []));
test('tie order code point', () => assert.deepEqual(frequencies(['b', 'a', 'B'.toLowerCase(), 'a', 'c']).map(e => e.word), ['a', 'b', 'c']));
test('stopwords case-insensitive', () => assert.deepEqual(frequencies(['the', 'cat'], ['THE']), [{ word: 'cat', count: 1 }]));
for (const bad of [0, -3, 2.5, NaN, '3', Infinity]) {
  test(`topN rejects ${String(bad)}`, () => assert.throws(() => topN([{ word: 'a', count: 1 }], bad), { name: 'RangeError', message: 'n must be a positive integer' }));
}
test('topN larger than list', () => assert.equal(topN([{ word: 'a', count: 1 }], 5).length, 1));
test('cli plain output', () => { const r = cli(file('a.txt', 'b a a')); assert.equal(r.status, 0); assert.equal(r.stdout, 'a\t2\nb\t1\n'); });
test('cli json output', () => { const r = cli(file('j.txt', 'x'), '--json'); assert.deepEqual(JSON.parse(r.stdout), [{ word: 'x', count: 1 }]); });
test('cli empty file', () => { const r = cli(file('e.txt', '')); assert.equal(r.status, 0); assert.equal(r.stdout, ''); });
test('cli empty file json', () => { const r = cli(file('e2.txt', ''), '--json'); assert.equal(r.status, 0); assert.deepEqual(JSON.parse(r.stdout), []); });
test('cli missing file', () => { const p = join(dir, 'nope.txt'); const r = cli(p); assert.equal(r.status, 2); assert.equal(r.stderr.trim(), `textstats: file not found: ${p}`); });
for (const bad of ['0', '-3', 'abc', '2.5']) {
  test(`cli --top ${bad}`, () => { const r = cli(file('t.txt', 'a'), '--top', bad); assert.equal(r.status, 2); assert.equal(r.stderr.trim(), 'textstats: n must be a positive integer'); });
}
test('cli --top 1', () => { const r = cli(file('t1.txt', 'a a b'), '--top', '1'); assert.equal(r.stdout, 'a\t2\n'); });
test('cli default top 10', () => { const r = cli(file('t10.txt', 'a b c d e f g h i j k l')); assert.equal(r.stdout.trim().split('\n').length, 10); });
test('cli stopwords', () => { const r = cli(file('s.txt', 'The cat the dog'), '--stopwords', 'the'); assert.equal(r.stdout, 'cat\t1\ndog\t1\n'); });
