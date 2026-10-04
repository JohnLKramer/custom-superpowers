#!/usr/bin/env bash
# Tests for audit logging: scripts/audit.py (switch, session dir, events,
# ledger copy) and scripts/harvest.py (usage.json from a transcript).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
AUDIT_SCRIPTS="$REPO_ROOT/skills/auditing-superpowers/scripts"
AUDIT="$AUDIT_SCRIPTS/audit.py"
HARVEST="$AUDIT_SCRIPTS/harvest.py"

FAILURES=0
TEST_ROOT=""

pass() { echo "  [PASS] $1"; }
fail() {
    echo "  [FAIL] $1"
    FAILURES=$((FAILURES + 1))
}

cleanup() {
    if [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]]; then
        rm -rf "$TEST_ROOT"
    fi
}

# check_json FILE PYEXPR DESCRIPTION — PYEXPR sees the parsed file as `d`.
check_json() {
    if python3 - "$1" "$2" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
sys.exit(0 if eval(sys.argv[2]) else 1)
PY
    then pass "$3"; else fail "$3"; fi
}

main() {
    echo "=== Test: audit logging ==="

    TEST_ROOT="$(mktemp -d)"
    trap cleanup EXIT

    git init -q -b main "$TEST_ROOT/repo"
    local repo
    repo="$(cd "$TEST_ROOT/repo" && git rev-parse --show-toplevel)"
    export AUDIT_SESSION_ID="sess-1"
    export AUDIT_PROJECTS_DIR="$TEST_ROOT/projects"
    local base="$repo/.superpowers/audit"

    # --- off by default ---
    local rc=0
    (cd "$repo" && python3 "$AUDIT" enabled) || rc=$?
    if [[ "$rc" -eq 1 ]]; then pass "enabled exits 1 when audit was never turned on"; else fail "enabled exits 1 when off (got $rc)"; fi

    (cd "$repo" && python3 "$AUDIT" event dispatch role=implementer)
    if [[ ! -e "$base" ]]; then pass "event is a silent no-op while off and creates nothing"; else fail "event created files while off"; fi

    # --- outside a git repo ---
    local nogit="$TEST_ROOT/nogit"
    mkdir -p "$nogit"
    local err
    rc=0
    err="$(cd "$nogit" && python3 "$AUDIT" on 2>&1)" || rc=$?
    if [[ "$rc" -eq 1 && "$err" == *"not inside a git repository"* && ! -e "$nogit/.superpowers" ]]; then
        pass "outside a git repo: clear error, nothing written"
    else
        fail "outside a git repo should error cleanly (rc=$rc, err=$err)"
    fi

    # --- on ---
    (cd "$repo" && python3 "$AUDIT" on >/dev/null)
    if [[ -f "$base/ENABLED" && "$(cat "$base/.gitignore")" == "*" ]]; then
        pass "on writes ENABLED and a self-ignoring .gitignore"
    else
        fail "on should write ENABLED and .gitignore containing *"
    fi
    (cd "$repo" && python3 "$AUDIT" enabled) && pass "enabled exits 0 after on" || fail "enabled exits 0 after on"

    if [[ -z "$(cd "$repo" && git status --porcelain)" ]]; then
        pass "audit directory stays out of git status"
    else
        fail "audit directory shows in git status: $(cd "$repo" && git status --porcelain)"
    fi

    # --- events ---
    local sdir
    sdir="$(cd "$repo" && python3 "$AUDIT" session)"
    if [[ "$sdir" == "$base/sess-1" && -d "$sdir" ]]; then pass "session prints and creates the session directory"; else fail "session dir wrong: $sdir"; fi

    (cd "$repo" && python3 "$AUDIT" event dispatch role=implementer task=3 'summary=said "hi" — naïve café')
    (cd "$repo" && python3 "$AUDIT" event brainstorm-done path=docs/x.md)
    local lines
    lines="$(wc -l < "$sdir/events.jsonl" | tr -d ' ')"
    if [[ "$lines" == "2" ]]; then pass "event appends one line per call"; else fail "expected 2 event lines, got $lines"; fi
    python3 - "$sdir/events.jsonl" <<'PY' && pass "event lines are valid JSON with typed ints and quoted text intact" || fail "event line content wrong"
import json, sys
first, second = [json.loads(l) for l in open(sys.argv[1])]
assert first["kind"] == "dispatch" and first["task"] == 3 and first["role"] == "implementer"
assert first["summary"] == 'said "hi" — naïve café'
assert second["kind"] == "brainstorm-done" and "ts" in second
PY

    (cd "$repo" && python3 "$AUDIT" event dispatch code=0123 note=² big=--5 task=3)
    python3 - "$sdir/events.jsonl" <<'PY' && pass "leading zeros and non-ASCII digits stay strings; plain ints stay ints" || fail "parse_value typing wrong"
import json, sys
last = [json.loads(l) for l in open(sys.argv[1])][-1]
assert last["code"] == "0123" and last["note"] == "²" and last["big"] == "--5" and last["task"] == 3
PY
    sed -i.bak '$d' "$sdir/events.jsonl" && rm -f "$sdir/events.jsonl.bak"

    # --- ledger copy ---
    mkdir -p "$repo/ws"
    printf '# SDD ledger — plan: p.md\nTask 1: complete\n' > "$repo/ws/progress.md"
    (cd "$repo" && python3 "$AUDIT" copy-ledger ws >/dev/null)
    if [[ "$(head -1 "$sdir/ledger.md")" == "# SDD ledger — plan: p.md" ]]; then
        pass "copy-ledger copies progress.md to ledger.md"
    else
        fail "copy-ledger did not copy the ledger"
    fi

    # --- session id from newest transcript ---
    unset AUDIT_SESSION_ID
    local enc
    enc="$(printf '%s' "$repo" | sed 's|[^A-Za-z0-9]|-|g')"
    mkdir -p "$AUDIT_PROJECTS_DIR/$enc"
    : > "$AUDIT_PROJECTS_DIR/$enc/old-session.jsonl"
    : > "$AUDIT_PROJECTS_DIR/$enc/new-session.jsonl"
    touch -t 202001010000 "$AUDIT_PROJECTS_DIR/$enc/old-session.jsonl"
    local picked
    picked="$(cd "$repo" && python3 "$AUDIT" session)"
    if [[ "$picked" == "$base/new-session" ]]; then pass "session id defaults to the newest transcript"; else fail "wrong session dir: $picked"; fi
    export AUDIT_SESSION_ID="sess-1"

    # --- off keeps data ---
    (cd "$repo" && python3 "$AUDIT" off >/dev/null)
    if [[ ! -e "$base/ENABLED" && -f "$sdir/events.jsonl" && -f "$sdir/ledger.md" ]]; then
        pass "off removes ENABLED and keeps collected data"
    else
        fail "off should remove only ENABLED"
    fi

    harvest_tests "$repo" "$base"

    echo ""
    if [[ "$FAILURES" -ne 0 ]]; then
        echo "FAILED: $FAILURES assertion(s)."
        exit 1
    fi
    echo "PASS"
}

harvest_tests() {
    local repo="$1" base="$2"
    local sdir="$base/sess-1"
    rm -f "$sdir/events.jsonl"
    (cd "$repo" && python3 "$AUDIT" on >/dev/null)

    # A dispatch event the harvest can join on agent_id.
    (cd "$repo" && python3 "$AUDIT" event dispatch role=implementer agent_id=agentA)
    # An all-digit agent_id is stored as an int; the join compares as strings.
    (cd "$repo" && python3 "$AUDIT" event dispatch role=fix agent_id=123456789)

    local transcript="$TEST_ROOT/transcript.jsonl"
    python3 - "$transcript" <<'PY'
import json, sys
lines = []
def asst(mid, model, usage):
    return {"type": "assistant", "message": {"id": mid, "model": model, "usage": usage}}
u1 = {"input_tokens": 2, "output_tokens": 100, "cache_read_input_tokens": 1000, "cache_creation_input_tokens": 50}
lines.append(asst("m1", "model-big", u1))
lines.append(asst("m1", "model-big", u1))            # repeated line for the same message
lines.append(asst("m2", "model-big", {"input_tokens": 3, "output_tokens": 10}))  # missing cache fields
lines.append(asst("m3", "model-small", {"input_tokens": 1, "output_tokens": 5}))
lines.append({"type": "user", "timestamp": "2026-10-03T10:00:00Z",
              "toolUseResult": {"agentId": "agentA", "agentType": "general-purpose",
                                "resolvedModel": "model-small", "totalTokens": 72513,
                                "totalDurationMs": 193118, "totalToolUseCount": 27,
                                "usage": {"input_tokens": 2, "output_tokens": 65,
                                          "cache_read_input_tokens": 69752,
                                          "cache_creation_input_tokens": 2694}}})
lines.append({"type": "user",
              "toolUseResult": {"agentId": "123456789", "totalTokens": 7}})
lines.append({"type": "user",
              "toolUseResult": {"agentId": "agentB", "totalTokens": 900}})  # sparse result
with open(sys.argv[1], "w") as f:
    for l in lines:
        f.write(json.dumps(l) + "\n")
    f.write("this line is not json\n")
PY

    (cd "$repo" && python3 "$HARVEST" --transcript "$transcript" >/dev/null)
    local usage="$sdir/usage.json"

    check_json "$usage" 'd["main"]["model-big"]["messages"] == 2 and d["main"]["model-big"]["output_tokens"] == 110' \
        "repeated assistant message lines are counted once"
    check_json "$usage" 'd["main"]["model-big"]["input_tokens"] == 5 and d["main"]["model-big"]["cache_read_input_tokens"] == 1000' \
        "usage fields are summed per model"
    check_json "$usage" '"cache_read_input_tokens" not in d["main"]["model-small"]' \
        "a usage field the transcript lacks stays missing, not zero"
    check_json "$usage" 'd["skipped_lines"] == 1' "an unparseable line is skipped and counted"
    check_json "$usage" 'd["dispatches"][0]["resolvedModel"] == "model-small" and d["dispatches"][0]["totalTokens"] == 72513 and d["dispatches"][0]["event_index"] == 0' \
        "a subagent result is listed and joined to its dispatch event by agent_id"
    check_json "$usage" 'd["dispatches"][0]["usage"]["cache_read_input_tokens"] == 69752' \
        "a subagent result keeps its per-dispatch usage"
    check_json "$usage" 'd["dispatches"][1]["event_index"] == 1' \
        "an all-digit agent_id still joins to its transcript agentId"
    check_json "$usage" '"resolvedModel" not in d["dispatches"][2] and "totalDurationMs" not in d["dispatches"][2] and "event_index" not in d["dispatches"][2]' \
        "a sparse subagent result keeps only the fields it had and stays unmatched"

    # --- no transcript: other harness ---
    rm -f "$usage"
    local out rc=0
    out="$(cd "$repo" && python3 "$HARVEST" --transcript "$TEST_ROOT/nope.jsonl")" || rc=$?
    if [[ "$rc" -eq 0 && "$out" == *"no transcript found"* && ! -e "$usage" ]]; then
        pass "a missing transcript is reported and writes nothing"
    else
        fail "missing transcript should exit 0 without usage.json (rc=$rc, out=$out)"
    fi

    # --- audit off: silent no-op ---
    (cd "$repo" && python3 "$AUDIT" off >/dev/null)
    out="$(cd "$repo" && python3 "$HARVEST" --transcript "$transcript")"
    if [[ -z "$out" && ! -e "$usage" ]]; then pass "harvest is a silent no-op while audit is off"; else fail "harvest ran while off: $out"; fi
}

main "$@"
