## Summary

The branch `custom/main` carries customizations of the Superpowers framework.

This fork's `main` will continue to periodically sync with the main [Superpowers](https://github.com/obra/superpowers) repository. Then we'll merge changes from `main` to `custom/main`.

### Install from this `custom/main`

Run from any directory. The repo already includes a dev marketplace manifest (`.claude-plugin/marketplace.json`, marketplace name `superpowers-dev`).

```bash
# 1. Register this checkout as a local marketplace
claude plugin marketplace add ${PWD}

# 2. Disable the official superpowers so the two don't conflict
claude plugin disable superpowers@claude-plugins-official

# 3. Install the branch version
claude plugin install superpowers@superpowers-dev
```

Restart Claude Code afterwards.

**Notes:**

- The install snapshots whatever is checked out at the time. Uncommitted changes are included. If the repo is on a different branch, you get that branch.
- The install is a copy, like the official one in `~/.claude/plugins/cache/claude-plugins-official/superpowers/6.4.2`. After editing the repo, refresh it:
  ```bash
  claude plugin marketplace update superpowers-dev
  claude plugin update superpowers@superpowers-dev
  ```

### Try it for one session without installing

This reads the repo directly, so edits take effect on the next launch:

```bash
claude --plugin-dir /Users/john.kramer/source/personal/custom-superpowers \
  --settings '{"enabledPlugins":{"superpowers@claude-plugins-official":false}}'
```

### Revert to the official plugin

```bash
claude plugin uninstall superpowers@superpowers-dev
claude plugin enable superpowers@claude-plugins-official
```

## Customizations

Each entry is dated with the day it landed on `custom/main` (see
`customizing-superpowers` skill).

### 2026-09-30 — Milestone review in subagent-driven development

The `subagent-driven-development` skill now reviews code once per milestone instead of after every task. A milestone is a group of 2-5 tasks from a plan. Each task still gets its own fresh implementer and self-review, and the plan still ends with the strong final review over the whole branch. Only the per-task review step moves to the milestone boundary.

This cuts reviewer seats on plans with many small tasks. A 6-task plan split into 2 milestones now needs 1 review before the final review; the upstream skill needs 6.

The change reaches four files: `subagent-driven-development/SKILL.md`, `task-reviewer-prompt.md`, and `re-review-prompt.md` carry the review-loop rewrite, and `writing-plans/SKILL.md` adds the `## Milestone N: <name>` heading plans use to mark milestone boundaries.

`docs/overlay/milestone-review.md` has the file-by-file change mapping, the test scenarios used to verify it, and the evidence from running those tests against both the overlay and the unmodified skill.

### 2026-09-30 — customizing-superpowers skill

Adds `skills/customizing-superpowers/SKILL.md`, documenting this fork's
two-track process for landing a customization: a `custom/feature/*` branch
off `custom/main` carries the real change plus a dated `CUSTOM.md` entry, and
a later `feature/*` branch off `main` carries only the matching `CUSTOM.md`
entry so `main` stays a clean upstream mirror. Also fixes this file: entries
under `## Customizations` are now dated.

This is a purely additive new file, so no `docs/overlay/` rebase-reapply doc
is needed.