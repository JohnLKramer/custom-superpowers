# Overlay: milestone reviews in subagent-driven development

Local overlay on upstream Superpowers. Branch: `CLAUDE/milestone-review`.

## Why

Upstream SDD sends every task to a reviewer and runs a fix loop of up to 5
rounds per task, then a final whole-branch review on the most capable model.
On small tasks, most of the cost is the per-task review seats. This overlay
moves the review gate to milestones (groups of tasks) and keeps the strong
final review:

- Tasks are still implemented one fresh subagent at a time, with self-review
  and tests.
- A reviewer runs once per milestone, over the milestone's whole diff, with
  every task's brief and report.
- The plan's last milestone gets no milestone review. The final review is
  its gate, and it gets that milestone's briefs.
- Plans without milestone headings get one milestone per three tasks.

For a 6-task plan with 2 milestones, reviews before the final review drop
from 6 to 1.

## How to reapply after an upstream update

First try `git rebase <new-upstream> CLAUDE/milestone-review`. If hunks
conflict, reapply each intent below by hand. Every change is a wording swap
or a small insertion, and none of them depends on line numbers.

### `skills/subagent-driven-development/SKILL.md`

1. **Intro, Core principle, and "vs. Executing Plans":** "task review ...
   after each" becomes "milestone review ... after each milestone".
2. **Process flowchart:**
   - The implementer node now leads to "Append task completion to ledger,
     mark todo complete".
   - That node leads to a diamond, "Task ends a milestone that is not the
     plan's last?". Yes goes to the review node. No goes to "More tasks
     remain?".
   - The review node is renamed "Generate milestone review package, dispatch
     milestone reviewer".
   - Every review exit (clean, all addressed, parked) goes to "Append
     milestone review line to ledger", which then goes to "More tasks
     remain?".
3. **Setup, ledger recovery:** a milestone whose tasks are all complete but
   which has no `Milestone <M>: reviewed` line is due its review before any
   new task. A mid-loop fix round is tracked per milestone.
4. **Setup, after "create a todo per task":** read the `## Milestone <M>:`
   headings, or fall back to one milestone per three tasks. Write
   `Milestone <M>: Tasks <a>-<b>` to the ledger. The last milestone is
   gated by the final review.
5. **Task Loop §1:** the BASE of a milestone's first task is MILESTONE_BASE.
6. **§2 DONE:** ledger `Task <N>: complete`. If the task ends a milestone
   that is not the plan's last, run review-package MILESTONE_BASE..HEAD and
   dispatch the milestone reviewer. Otherwise dispatch the next task.
7. **§3 is renamed "Review the milestone":** the reviewer gets every brief
   and report in the milestone, plus a package built from MILESTONE_BASE.
8. **§4 fix loop:**
   - The ledger prefixes change from `Task <N>:` to `Milestone <M>:`
     (minor, fix round, parked, Ruling).
   - The cap is 5 rounds per milestone.
   - Rounds 1-3 resume the implementer of the task that owns the findings.
     If the findings span several tasks, dispatch ONE fresh fixer with all
     of them, and never one fixer per task. A cross-task fixer appends to
     the milestone's last report.
9. **§5 is renamed "Complete the milestone":** ledger
   `Milestone <M>: reviewed (...)`. The next milestone waits until open
   Critical/Important findings are fixed or parked.
10. **Final Review:** also pass the briefs of the last milestone's tasks.
11. **Rationalization table, worker-spawned-reviewer row:** "task review is
    the gate" becomes "milestone review is the gate".
12. **Example Workflow:**
    - The ledger map is Milestone 1: Tasks 1-2.
    - Task 1 gets no review.
    - Task 2 ends the milestone, so the review covers a1b2c3d..HEAD.
    - Fix round lines use `Milestone 1:`.
    - The final review carries the last milestone's briefs.

### `skills/subagent-driven-development/task-reviewer-prompt.md`

The template reviews a milestone instead of a single task:

- `[BRIEF_FILE]` becomes `[BRIEF_FILES]`, and the reviewer checks each task
  against its own brief.
- `[REPORT_FILE]` becomes `[REPORT_FILES]`.
- `[BASE_SHA]` is MILESTONE_BASE.
- The description, intro, and purpose lines now say "milestone".

The filename stays the same, so no references change.

### `skills/subagent-driven-development/re-review-prompt.md`

The `[BRIEF_FILE]` placeholder doc now reads "brief file(s) of the task(s)
whose code the findings touch".

### `skills/writing-plans/SKILL.md`

1. **Task Right-Sizing:** drop "worth a fresh reviewer's gate" and the
   "split only where a reviewer could reject" rule. Add the milestone
   paragraph: `## Milestone N: <name>` headings, 2-5 tasks each, ending
   where later tasks start building on the milestone's interfaces.
2. **Task Structure template:** add `## Milestone N: [Slice Name]` above
   `### Task N`.
3. **Execution handoff, Subagent-driven bullet:** "checks it before the next
   one starts" becomes "checks each milestone before the next one starts".

Not changed: `executing-plans` (Native), the scripts, `implementer-prompt.md`,
and `requesting-code-review`.

## How to re-verify

**Micro-tests (cheap, about 1 minute per rep):**

1. Copy `skills/subagent-driven-development` to `/tmp/sdd-ms/green/skill`.
2. Copy `milestone-review/micro/*` to `/tmp/sdd-ms/fixtures/`.
3. Dispatch 5 fresh subagents, each told: "Read
   /tmp/sdd-ms/fixtures/scenarios.md and follow it.
   SKILL_PATH=/tmp/sdd-ms/green/skill/SKILL.md".

Expected answers:

| Scenario | Expected action |
|---|---|
| S1 | No review; dispatch Task 3 |
| S2 | Milestone review over aaa..ddd with all 3 briefs |
| S3 | Fallback grouping, then milestone review |
| S4 | Review Milestone 1 before Task 4 |
| S5 | ONE fresh fixer for cross-task findings |
| S6 | Refuse to skip the review |

Final count: 1. The unmodified skill answers 6.

**End-to-end A/B (about $10-30 per arm):**

`milestone-review/e2e/run-arm.sh <arm> <plugin-dir>` runs a real sonnet
controller on the textstats fixture. It disables the installed superpowers
plugin and loads only `<plugin-dir>`. The script expects the fixture at
`/tmp/sdd-ab/fixture`. Afterwards, from `/tmp/sdd-ab/run-<arm>`, run
`node --test /path/to/acceptance.test.js` to count the defects that
shipped.

## Evidence (2026-09-23)

**Micro-tests (sonnet controller, 5 reps per arm):**

- **Baseline:** 5 of 5 reps dispatched 6 reviews. In S5, 4 of 5 split the
  cross-task findings into separate per-task fix loops.
- **Overlay:** 5 of 5 took the correct action in every scenario. One rep
  reported a count of 3, but it had added up reviews across scenarios
  instead of counting per plan. That is a flaw in the test instrument, not a
  behavior failure. No wording changes were needed after GREEN.

**End-to-end A/B (textstats fixture, sonnet controller, n=1 per arm):**

| | A: upstream (per-task) | B: overlay (milestone) |
|---|---|---|
| Completed | Milestone 1 only (killed at 84 min) | All 6 tasks + final review (about 18 min) |
| Review seats in Milestone 1 | 6 (3 reviews + 3 re-reviews) | 2 (1 review + 1 re-review) |
| Review-seat cache read / write, Milestone 1 | 937k / 347k | 313k / 188k |
| Controller cache read | 39.8M (Milestone 1 only) | 7.0M (whole plan) |
| Held-out library tests (15) | 15/15 | 15/15 |
| Held-out CLI tests (12) | not reached | 12/12 |
| Total cost | not recorded (killed) | $3.59 |

In B, the opus final review caught real defects (Unicode NFD
normalization, and a test script broken on Node 22+), and one fix wave
cleared them.

**Caveats:**

- n=1 per arm.
- A's controller context is inflated by its long run, which may have
  stalled, so the controller comparison overstates the gap. The
  review-seat comparison is the cleaner signal.
- Quality parity is shown only at Milestone 1, on a small plan.
