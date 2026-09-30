#!/usr/bin/env bash
# usage: run-arm.sh <arm-name> <plugin-dir>
set -euo pipefail
arm=$1; plugin=$2
run=/tmp/sdd-ab/run-$arm
rm -rf "$run"; cp -R /tmp/sdd-ab/fixture "$run"; cd "$run"
printf '.superpowers/\nnode_modules/\n' > .gitignore
git init -q -b main && git config user.email t@t && git config user.name t && git add . && git commit -qm "initial: spec and plan"
prompt="Execute the implementation plan at docs/superpowers/plans/2026-09-23-textstats.md using the superpowers:subagent-driven-development skill. This is a throwaway scratch repository: you have my explicit consent to work and commit directly on main here — do not create a worktree or branch. Do not ask me anything; run the plan to completion, including the final review, then stop before finishing-a-development-branch's merge options."
claude -p "$prompt" \
  --plugin-dir "$plugin" \
  --settings '{"enabledPlugins":{"superpowers@claude-plugins-official":false}}' \
  --model sonnet --permission-mode bypassPermissions --max-budget-usd 30 \
  --output-format stream-json --verbose > "/tmp/sdd-ab/$arm.stream.jsonl" 2> "/tmp/sdd-ab/$arm.stderr" || echo "claude exit $?"
echo "done $arm"
