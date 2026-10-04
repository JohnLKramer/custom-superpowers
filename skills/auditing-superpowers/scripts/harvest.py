#!/usr/bin/env python3
"""Fill usage.json for this audit session from a Claude Code transcript.

Usage: harvest.py [--transcript PATH]

Sums main-session usage per model (each assistant message once, even when the
transcript repeats its line) and lists every subagent result with its resolved
model, token total, usage, duration and tool count. A dispatch is joined to the
session's events.jsonl entry whose agent_id matches. Fields the transcript
lacks stay missing; nothing is defaulted to zero. Does nothing when audit is
off. Reads the transcript one line at a time and skips lines over 8 MB.
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import audit  # noqa: E402

MAX_LINE = 8_000_000
USAGE_FIELDS = (
    "input_tokens",
    "output_tokens",
    "cache_read_input_tokens",
    "cache_creation_input_tokens",
)
DISPATCH_FIELDS = (
    "agentId",
    "agentType",
    "resolvedModel",
    "totalTokens",
    "totalDurationMs",
    "totalToolUseCount",
    "usage",
)


def harvest(transcript, events):
    seen = set()
    per_model = {}
    dispatches = []
    dispatch_keys = set()
    skipped = 0
    by_agent = {}
    for index, event in enumerate(events):
        if event.get("agent_id") is not None:
            by_agent.setdefault(str(event["agent_id"]), index)

    with open(transcript, encoding="utf-8", errors="replace") as f:
        for line in f:
            if len(line) > MAX_LINE:
                skipped += 1
                continue
            try:
                rec = json.loads(line)
            except ValueError:
                skipped += 1
                continue
            msg = rec.get("message")
            if (
                rec.get("type") == "assistant"
                and isinstance(msg, dict)
                and isinstance(msg.get("usage"), dict)
            ):
                mid = msg.get("id")
                if mid is not None:
                    if mid in seen:
                        continue
                    seen.add(mid)
                bucket = per_model.setdefault(msg.get("model") or "unknown", {"messages": 0})
                bucket["messages"] += 1
                for field in USAGE_FIELDS:
                    value = msg["usage"].get(field)
                    if isinstance(value, int):
                        bucket[field] = bucket.get(field, 0) + value
            result = rec.get("toolUseResult")
            if isinstance(result, dict) and "agentId" in result:
                entry = {k: result[k] for k in DISPATCH_FIELDS if k in result}
                if "timestamp" in rec:
                    entry["timestamp"] = rec["timestamp"]
                key = json.dumps(entry, sort_keys=True)
                if key in dispatch_keys:
                    continue
                dispatch_keys.add(key)
                if str(entry["agentId"]) in by_agent:
                    entry["event_index"] = by_agent[str(entry["agentId"])]
                dispatches.append(entry)

    return {
        "transcript": str(transcript),
        "skipped_lines": skipped,
        "main": per_model,
        "dispatches": dispatches,
    }


def read_events(path):
    if not path.is_file():
        return []
    events = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            try:
                events.append(json.loads(line))
            except ValueError:
                events.append({})
    return events


def main(argv):
    root = audit.repo_root()
    if not audit.is_on(root):
        return 0
    if argv[:1] == ["--transcript"] and len(argv) == 2:
        transcript = Path(argv[1])
    elif not argv:
        transcript = (
            audit.projects_dir()
            / audit.encode_path(root)
            / (audit.session_id(root) + ".jsonl")
        )
    else:
        sys.exit("usage: harvest.py [--transcript PATH]")
    if not transcript.is_file():
        print("no transcript found; usage.json not written")
        return 0
    sdir = audit.session_dir(root)
    result = harvest(transcript, read_events(sdir / "events.jsonl"))
    out = sdir / "usage.json"
    out.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("harvested: " + str(out))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
