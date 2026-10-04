#!/usr/bin/env python3
"""Switch and event log for superpowers audit logging.

Usage:
  audit.py on                      turn audit on for this repo
  audit.py off                     turn audit off (collected data is kept)
  audit.py enabled                 exit 0 if on, 1 if off
  audit.py session                 print (and create) this session's audit dir
  audit.py event KIND [key=value ...]   append one JSON line (no-op when off)
  audit.py copy-ledger WORKSPACE   copy WORKSPACE/progress.md to ledger.md (no-op when off)

Environment:
  AUDIT_SESSION_ID     pin the session id instead of guessing from transcripts
  AUDIT_PROJECTS_DIR   replaces ~/.claude/projects
"""
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


def repo_root():
    out = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True
    )
    if out.returncode != 0:
        sys.exit("audit: not inside a git repository")
    return Path(out.stdout.strip())


def base_dir(root):
    return root / ".superpowers" / "audit"


def now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def projects_dir():
    override = os.environ.get("AUDIT_PROJECTS_DIR")
    return Path(override) if override else Path.home() / ".claude" / "projects"


def encode_path(path):
    return re.sub(r"[^A-Za-z0-9]", "-", str(path))


def session_id(root):
    pinned = os.environ.get("AUDIT_SESSION_ID")
    if pinned:
        return pinned
    proj = projects_dir() / encode_path(root)
    files = list(proj.glob("*.jsonl")) if proj.is_dir() else []
    if files:
        files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
        return files[0].stem
    return "local-" + datetime.now().strftime("%Y%m%d")


def session_dir(root):
    d = base_dir(root) / session_id(root)
    d.mkdir(parents=True, exist_ok=True)
    return d


def is_on(root):
    return (base_dir(root) / "ENABLED").is_file()


def parse_value(raw):
    return int(raw) if re.fullmatch(r"-?(0|[1-9][0-9]*)", raw) else raw


def cmd_on(root, args):
    base = base_dir(root)
    base.mkdir(parents=True, exist_ok=True)
    (base / ".gitignore").write_text("*\n")
    (base / "ENABLED").write_text(now() + "\n")
    print("audit logging ON: " + str(base))
    return 0


def cmd_off(root, args):
    (base_dir(root) / "ENABLED").unlink(missing_ok=True)
    print("audit logging OFF (collected data kept)")
    return 0


def cmd_enabled(root, args):
    return 0 if is_on(root) else 1


def cmd_session(root, args):
    print(session_dir(root))
    return 0


def cmd_event(root, args):
    if not args:
        sys.exit("usage: audit.py event KIND [key=value ...]")
    if not is_on(root):
        return 0
    record = {"ts": now(), "kind": args[0]}
    for pair in args[1:]:
        if "=" not in pair:
            sys.exit("audit: bad field %r, expected key=value" % pair)
        key, value = pair.split("=", 1)
        record[key] = parse_value(value)
    with open(session_dir(root) / "events.jsonl", "a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")
    return 0


def cmd_copy_ledger(root, args):
    if len(args) != 1:
        sys.exit("usage: audit.py copy-ledger WORKSPACE")
    if not is_on(root):
        return 0
    ledger = Path(args[0]) / "progress.md"
    if ledger.is_file():
        shutil.copyfile(ledger, session_dir(root) / "ledger.md")
    return 0


COMMANDS = {
    "on": cmd_on,
    "off": cmd_off,
    "enabled": cmd_enabled,
    "session": cmd_session,
    "event": cmd_event,
    "copy-ledger": cmd_copy_ledger,
}


def main(argv):
    if not argv or argv[0] not in COMMANDS:
        sys.exit(__doc__)
    return COMMANDS[argv[0]](repo_root(), argv[1:])


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
