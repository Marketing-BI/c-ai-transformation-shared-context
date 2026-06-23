#!/usr/bin/env bash
# SessionStart hook: inject this plugin's always-on rules as additional context.
set -euo pipefail
RULES_DIR="${CLAUDE_PLUGIN_ROOT}/rules"
[ -d "$RULES_DIR" ] || exit 0
content="$(cat "$RULES_DIR"/*.md 2>/dev/null || true)"
[ -n "$content" ] || exit 0
if command -v jq >/dev/null 2>&1; then
  jq -n --arg c "$content" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
elif command -v python3 >/dev/null 2>&1; then
  python3 -c 'import json,sys;print(json.dumps({"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":sys.stdin.read()}}))' <<<"$content"
else
  exit 0   # emit nothing rather than malformed JSON
fi
