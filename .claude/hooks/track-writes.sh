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

mkdir -p docs
printf '  [%s] %s: apps/mobile/%s\n' "$(date '+%H:%M')" "$TOOL" "$RELATIVE" >> docs/agent-log.md
