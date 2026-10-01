---
name: customizing-superpowers
description: Use when adding, changing, or landing a customization in this custom-superpowers fork — modifying skill/prompt content to diverge from upstream Superpowers, adding a fork-only skill, updating CUSTOM.md, or syncing a customization doc entry back to main.
---

# Customizing Superpowers

## Overview

This fork tracks upstream Superpowers on `main` and layers customizations on
`custom/main`. Landing a customization is a two-track process: one PR puts
the real change on `custom/main`; a second, later PR puts only the `CUSTOM.md`
doc entry on `main`. This keeps `main` a clean upstream mirror (so periodic
syncs from upstream stay conflict-free) while still letting anyone who pulls
`main` see what the fork changes and why.

**Not for:** syncing `main` from upstream Superpowers itself — that's a
separate periodic-merge task, not a customization.

## Track 1 — land the change on custom/main

1. Update refs before branching — do not cut a branch from a stale local ref:
   ```bash
   git fetch origin && git checkout custom/main && git pull
   ```
2. Branch: `custom/feature/<description>`, cut from `custom/main`.
3. Make the change.
4. Add a dated entry to `CUSTOM.md` under `## Customizations`:
   ```markdown
   ### YYYY-MM-DD — <Title>

   <What changed, why, which files it touches.>
   ```
   The date is required on every entry — use the date you're landing the
   change, not the date you thought of it.
5. Decide whether you need `docs/overlay/<description>.md`: write one only
   if the change **edits existing upstream file content** (a skill, prompt,
   or script upstream also ships). Its job is to survive
   `git rebase <upstream> custom/main` — record what changed file-by-file and
   how to reapply each hunk by hand if the rebase conflicts. Skip it for
   purely additive new files (a new skill, a new script) — upstream has no
   such file, so a rebase can't conflict with it.
6. Commit, push, open a PR against `custom/main` (never `main`). Ask your
   human partner to review and merge.

## Track 2 — sync the doc entry to main

Only after Track 1 is merged into `custom/main`.

1. Update refs:
   ```bash
   git fetch origin && git checkout main && git pull
   ```
2. Branch: `feature/<description>` — same `<description>` as Track 1, no
   `custom/` prefix — cut from `main`.
3. Copy the exact same `CUSTOM.md` entry from `custom/main` onto `main`,
   verbatim.
4. Stage **only** `CUSTOM.md`. Run `git status` before committing to confirm
   nothing else is staged — if any other file shows up, Track 1's behavior
   change has leaked into a branch that's supposed to stay a clean upstream
   mirror.
5. Commit, push, open a PR against `main`. Ask your human partner to review
   and merge.

## Quick reference

| | Track 1 | Track 2 |
|---|---|---|
| Base branch | `custom/main` | `main` |
| Feature branch | `custom/feature/<description>` | `feature/<description>` |
| PR target | `custom/main` | `main` |
| Files changed | the real change + `CUSTOM.md` | `CUSTOM.md` only |
| When | first | after Track 1's PR merges |

## Common mistakes

- Branching off a stale local `main`/`custom/main` — fetch and pull first.
- Missing the date on a `CUSTOM.md` entry.
- Letting the real change leak into the Track 2 commit — check
  `git status`/`git diff --stat --cached` before committing; only
  `CUSTOM.md` should appear.
- Opening the Track 1 PR against `main`, or the Track 2 PR against
  `custom/main`.
- Writing an overlay doc for a purely additive new file — only changes to
  existing upstream content need rebase-reapply instructions.
