# textstats — word frequency library and CLI

## Purpose
Count word frequencies in a text file and print the most common words.

## Requirements
1. **Tokenizing.** A word is a maximal run of Unicode letters or digits. An
   apostrophe (' or ’) between two letters is part of the word ("don't",
   "o’clock" stay one word); any other apostrophe is a separator. Words are
   lowercased. Unicode letters count ("café", "naïve", "Straße").
2. **Counting.** Frequencies are ordered by count descending; ties are broken
   alphabetically ascending using plain code-point order.
3. **Top N.** `topN(freqs, n)` returns the first n entries. n must be a
   positive integer; anything else throws `RangeError("n must be a positive integer")`.
   If n exceeds the number of distinct words, return all of them.
4. **Stopwords.** An optional stopword list removes words case-insensitively
   before counting.
5. **Input.** The CLI reads the file named by its first argument. A missing
   file prints `textstats: file not found: <path>` to stderr and exits 2.
6. **CLI.** `textstats <file> [--top N] [--stopwords a,b,c] [--json]`.
   Default --top is 10. Plain output: one line per word, `word<TAB>count`.
   `--json` prints a JSON array of `{"word": ..., "count": ...}` objects.
   Empty input prints nothing (or `[]` with --json) and exits 0. An invalid
   --top value prints `textstats: n must be a positive integer` to stderr
   and exits 2.

## Constraints
- Node 20+, ES modules, no dependencies. Tests use `node --test`.
