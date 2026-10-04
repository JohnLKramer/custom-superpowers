# Overlay: audit logging

Local overlay on upstream Superpowers. Branch: `CLAUDE/audit-logging`.

## Why

Tuning token use and model selection needs data on how planning and
subagent-driven development actually run. This overlay adds an opt-in audit
log: "audit superpowers" turns it on, "stop auditing superpowers" turns it
off. While on, the hooked skills log plan summaries, dispatch records (role,
model, round, brief and diff sizes, outcome), review finding counts, and a
copy of the SDD ledger before its workspace is deleted. A harvest script
joins token usage from the Claude Code transcript. Data lives in
`<repo>/.superpowers/audit/<session-id>/` and is never committed or deleted.

The new files (`skills/auditing-superpowers/`, `tests/claude-code/test-audit.sh`,
`tests/claude-code/test-audit-hooks.sh`) do not touch upstream content. Only
the edits below do.

## How to reapply after an upstream update

First try `git rebase <new-upstream> CLAUDE/audit-logging`. If hunks conflict,
reapply each intent below by hand. Each change is an appended trailing
`## Audit` section, or two added lines in a test array, and none of them
depends on line numbers.

### `skills/brainstorming/SKILL.md`

Append this section at the end of the file:

    ## Audit

    Run `python3 ../auditing-superpowers/scripts/audit.py enabled`. When it exits 0, audit logging is on:

    - End every question you put to your human partner with this line: "Audit logging is ON — say 'stop auditing superpowers' to disable."
    - When the spec is approved (or the bounded or spike path ends), run `python3 ../auditing-superpowers/scripts/audit.py event brainstorm-done path=<spec path or none> summary="<2-4 sentences: what is being built and why>" model=<your model id>`, then `python3 ../auditing-superpowers/scripts/harvest.py`.

    When it exits 1, skip this section.

### `skills/writing-plans/SKILL.md`

Append this section at the end of the file:

    ## Audit

    Run `python3 ../auditing-superpowers/scripts/audit.py enabled`. When it exits 0, audit logging is on:

    - End every question you put to your human partner with this line: "Audit logging is ON — say 'stop auditing superpowers' to disable."
    - After the plan is saved, run `python3 ../auditing-superpowers/scripts/audit.py event plan-written path=<plan path> summary="<2-4 sentences: what the plan builds and how it is split>" tasks=<task count> milestones=<milestone count> model=<your model id>`, then `python3 ../auditing-superpowers/scripts/harvest.py`.

    When it exits 1, skip this section.

### `skills/subagent-driven-development/SKILL.md`

Append this section at the end of the file:

    ## Audit

    Run `python3 ../auditing-superpowers/scripts/audit.py enabled`. When it exits 0, audit logging is on:

    - End every question you put to your human partner with this line: "Audit logging is ON — say 'stop auditing superpowers' to disable."
    - After each dispatch returns, run `python3 ../auditing-superpowers/scripts/audit.py event dispatch role=<implementer|milestone-reviewer|re-review|final-review|fix> milestone=<M> task=<N> round=<R> model=<the model you passed> agent_id=<id from the result, when shown> brief_bytes=<wc -c of the brief> diff_bytes=<wc -c of the review package, for review dispatches> outcome=<ok|findings|blocked>`.
    - After each review verdict, run `python3 ../auditing-superpowers/scripts/audit.py event review role=<role> milestone=<M> round=<R> critical=<n> important=<n> minor=<n>`.
    - At each milestone end, run `python3 ../auditing-superpowers/scripts/harvest.py`.
    - Before deleting the plan's workspace after the final review, run `python3 ../auditing-superpowers/scripts/audit.py copy-ledger <workspace>`, then `python3 ../auditing-superpowers/scripts/harvest.py`. The workspace is deleted as usual; the audit copy stays.

    When it exits 1, skip this section.

### `skills/executing-plans/SKILL.md`

Append this section at the end of the file:

    ## Audit

    Run `python3 ../auditing-superpowers/scripts/audit.py enabled`. When it exits 0, audit logging is on:

    - End every question you put to your human partner with this line: "Audit logging is ON — say 'stop auditing superpowers' to disable."
    - Before deleting the plan's workspace after the final review, run `python3 ../auditing-superpowers/scripts/audit.py copy-ledger <workspace>`, then `python3 ../auditing-superpowers/scripts/harvest.py`. The workspace is deleted as usual; the audit copy stays.

    When it exits 1, skip this section.

### `tests/claude-code/run-skill-tests.sh`

Add `"test-audit.sh"` and `"test-audit-hooks.sh"` as two lines in the `tests`
array, next to the other fast tests.
