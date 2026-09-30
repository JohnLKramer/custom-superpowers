# textstats Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Word-frequency library and CLI per the spec.
**Architecture:** Pure functions in `src/`, thin CLI in `bin/`.
**Tech Stack:** Node 20+, ESM, `node --test`.
**Spec:** docs/specs/textstats.md

## Global Constraints
- Node 20+, ES modules, zero dependencies; tests with `node --test`, files under `test/`.
- Error text is exact: `n must be a positive integer`, `textstats: file not found: <path>`.
- Plain output line format is exactly `word<TAB>count`.

## Review Focus
- Apostrophes at word edges ('tis, dogs') are separators, not word characters.
- Non-ASCII letters (café, Straße) tokenize as single words.
- Count ties must sort alphabetically by code point.
- `--top 0`, `--top -3`, `--top abc`, `--top 2.5` are all rejected with exit 2.
- Empty file: no output, exit 0 (`[]` with --json).

## Milestone 1: Library core

### Task 1: Tokenizer
**Files:** Create `src/tokenize.js`, `test/tokenize.test.js`
**Produces:** `export function tokenize(text: string): string[]`
Implement spec requirement 1. Tests must cover contractions, edge
apostrophes, curly apostrophes, digits, and non-ASCII letters. TDD: write the
failing tests first, run them, implement, run again, commit.

### Task 2: Frequency counting
**Files:** Create `src/frequencies.js`, `test/frequencies.test.js`
**Consumes:** nothing (takes a token array)
**Produces:** `export function frequencies(tokens: string[], stopwords?: string[]): Array<{word: string, count: number}>`
Implement spec requirements 2 and 4 (ordering and stopwords). TDD, commit.

### Task 3: Top N
**Files:** Create `src/topn.js`, `test/topn.test.js`
**Produces:** `export function topN(freqs: Array<{word, count}>, n: number): Array<{word, count}>`
Implement spec requirement 3, including the exact RangeError. TDD, commit.

## Milestone 2: CLI

### Task 4: Input reading
**Files:** Create `src/input.js`, `test/input.test.js`
**Produces:** `export async function readInput(path: string): Promise<string>`; throws an
Error whose `code` is `'ENOENT_TEXTSTATS'` and message is `file not found: <path>` for a missing file.
TDD, commit.

### Task 5: CLI
**Files:** Create `bin/textstats.js`, `test/cli.test.js`
**Consumes:** tokenize, frequencies, topN, readInput
Implement spec requirements 5 and 6: argument parsing, exit codes, plain and
JSON output. Test by spawning the CLI with `node`. TDD, commit.

### Task 6: README
**Files:** Create `README.md`
Document installation-free usage, every flag, output formats, and exit codes. Commit.
