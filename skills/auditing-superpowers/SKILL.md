---
name: auditing-superpowers
description: Use when your human partner says to audit superpowers, turn superpowers audit logging on, or stop auditing superpowers
---

# Auditing Superpowers

## Overview

Audit logging records how superpowers planning and subagent-driven development run — plan summaries, dispatch roles, models, tokens, the SDD ledger — so token use and model selection can be tuned. It is off until your human partner turns it on, and stays on until they turn it off.

"Audit superpowers" always means this logging. It does not mean reviewing the plugin or a past session, and you do not ask which. Never add a settings.json hook or an ad-hoc log file for it.

## Turn it on or off

Run the scripts from your project's repository root. The script paths below are relative to this skill's directory; `scripts/` is inside it.

- "Audit superpowers" → `python3 scripts/audit.py on`, then tell your human partner it is on and where data goes.
- "Stop auditing superpowers" → `python3 scripts/audit.py off`. Collected data stays; never delete it.
- Wording without both "audit" and "superpowers" does nothing.

## What it writes

Everything lives in `<repo>/.superpowers/audit/<session-id>/`. The directory ignores itself in git, and nothing ever deletes it, not even the end of a session. `git clean -fdx` does delete it; tell your human partner once if they ask about durability.

| File | Written by |
|---|---|
| `events.jsonl` | `python3 scripts/audit.py event KIND key=value ...` |
| `ledger.md` | `python3 scripts/audit.py copy-ledger WORKSPACE` |
| `usage.json` | `python3 scripts/harvest.py` (model and tokens, from the Claude Code transcript) |

Other harnesses still get events; `usage.json` is simply absent.

## Events

| kind | fields |
|---|---|
| `brainstorm-done` | `path` (spec), `summary`, `model` |
| `plan-written` | `path`, `summary`, `tasks`, `milestones`, `model` |
| `dispatch` | `role`, `milestone`, `task`, `round`, `model`, `agent_id`, `brief_bytes`, `diff_bytes`, `outcome` |
| `review` | `role`, `milestone`, `round`, `critical`, `important`, `minor` |

A summary is 2-4 sentences: what is being built and why. It is not a transcript. Log `agent_id` whenever the dispatch result shows one; `harvest.py` joins tokens on it.

## Two sessions in one repo

The session id is guessed from the newest transcript. If two live sessions share a repo, set `AUDIT_SESSION_ID=<id>` in the environment so a session logs under its own id.
