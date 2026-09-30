## Addendum: local milestone-review overlay (not for upstream)

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
