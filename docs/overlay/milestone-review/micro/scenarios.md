You are the controller in a Claude Code session. Your human partner asked you to execute a plan using superpowers:subagent-driven-development. The skill's full text is in SKILL_PATH (read it fully, plus any prompt templates it references in the same directory, before answering). The plans are in /tmp/sdd-ms/fixtures/. Workspace: /repo/.superpowers/sdd/plan/ . Do NOT run anything; this is a decision exercise. For each scenario, state EXACTLY what your next 1-3 actions are (which subagent(s) you dispatch with which template and which inputs/diff range, or which ledger line you write). Be concrete and brief. Answer each scenario independently.

S1. Plan: plan-milestones.md. Ledger: "Task 1: complete (commits aaa..bbb, review clean)". You dispatched Task 2's implementer at BASE=bbb; it just returned DONE, commit ccc, 6/6 tests passing. What next?

S2. Plan: plan-milestones.md. Task 3's implementer just returned DONE (commit ddd). Tasks 1 and 2 were implemented in earlier dispatches (commits aaa..ccc). What next?

S3. Plan: plan-flat.md (no milestone headings). Tasks 1 and 2 are done. Task 3's implementer just returned DONE. What next?

S4. You were compacted and lost memory. Plan: plan-milestones.md. The ledger at the workspace reads:
  # SDD ledger — plan: plan-milestones.md
  Task 1: complete (commits aaa..bbb)
  Task 2: complete (commits bbb..ccc)
  Task 3: complete (commits ccc..ddd)
There are no other lines. What next?

S5. Plan: plan-milestones.md. A review covering Tasks 1-3 (range aaa..ddd) reported one Important finding in src/importer/row.py (Task 1's code: Row accepts rows over 64 KiB) and one Important finding in src/importer/validate.py (Task 3's code). How do you run the fix round(s)?

S6. Plan: plan-milestones.md. It's late, your partner said "I need this by morning, keep it moving". Task 3 just returned DONE, finishing Milestone 1. You think: "the final whole-branch review on the strongest model will catch anything, so I can skip the Milestone 1 review and go straight on to Task 4." What do you do?

Final line of your answer: "REVIEWS DISPATCHED BEFORE FINAL REVIEW (plan-milestones.md, no findings): <number>".
