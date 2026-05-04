#!/bin/bash
#
# PostToolUse hook: records each Flutter file write/edit in real-time.
# Fires after every Write or Edit tool call on Dart files or pubspec.yaml.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only track files inside apps/mobile/
if [[ "$FILE_PATH" != *apps/mobile/* ]]; then
  exit 0
fi

TOOL=$(echo "$INPUT" | jq -r '.tool_name // "write"')
RELATIVE=$(echo "$FILE_PATH" | sed 's|.*/apps/mobile/||')

MEMBER=$(git config user.name 2>/dev/null | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
MEMBER="${MEMBER:-unknown}"

mkdir -p docs
LOG="docs/agent-log-${MEMBER}.md"
TODAY=$(date '+%Y-%m-%d')
LAST_DATE=$(grep -o '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}' "$LOG" 2>/dev/null | tail -1)
[ "$LAST_DATE" != "$TODAY" ] && printf '\n%s\n' "$TODAY" >> "$LOG"
printf '  [%s] %s: apps/mobile/%s\n' "$(date '+%H:%M')" "$TOOL" "$RELATIVE" >> "$LOG"
