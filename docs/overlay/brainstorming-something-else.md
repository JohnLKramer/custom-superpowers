# Overlay: brainstorming "something else" option

Branch: `custom/feature/brainstorming-something-else-option`.

## Why

Multiple choice questions during brainstorming can leave no room for an answer the agent did not think of. This adds a rule that every such question includes a "something else" option.

## How to reapply after an upstream update

First try `git rebase <new-upstream> custom/main`. If the hunk conflicts, reapply by hand.

### `skills/brainstorming/SKILL.md`

In "Understanding the idea", directly after the bullet "Prefer multiple choice questions when possible, but open-ended is fine too", add:

```markdown
- When you ask a multiple choice question, ALWAYS include a "something else" option so your human partner can answer outside the choices you listed
```
