#!/bin/bash
#
# Stop hook: appends git file changes to the current session entry in docs/agent-log-<member>.md.
# Only runs when Flutter source files are affected.

FLUTTER_STATUS=$(git status --short -- apps/mobile/lib/ apps/mobile/test/ apps/mobile/integration_test/ apps/mobile/pubspec.yaml 2>/dev/null)

if [ -z "$FLUTTER_STATUS" ]; then
  exit 0
fi

# Derive member name from git config, fall back to 'unknown'
MEMBER=$(git config user.name 2>/dev/null | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
MEMBER="${MEMBER:-unknown}"

LOG="docs/agent-log-${MEMBER}.md"
mkdir -p docs

# Warn if Claude forgot to write a session header
LAST_SECTION=$(awk '/^---/{found=NR} END{print NR-found}' "$LOG" 2>/dev/null)
if [ -z "$LAST_SECTION" ] || [ "$LAST_SECTION" -lt 2 ]; then
  printf '\n[WARNING: session header was not written — member/agent/task unknown]\n' >> "$LOG"
fi

{
  printf 'Files:\n'
  while IFS= read -r line; do
    status="${line:0:2}"
    file="${line:3}"
    case "${status// /}" in
      M)  printf '  ~ %s\n' "$file" ;;
      A)  printf '  + %s\n' "$file" ;;
      D)  printf '  - %s\n' "$file" ;;
      R)  printf '  > %s\n' "$file" ;;
      ??) printf '  ? %s (untracked)\n' "$file" ;;
      *)  printf '  %s %s\n' "$status" "$file" ;;
    esac
  done <<< "$FLUTTER_STATUS"
  STAT=$(git diff --stat HEAD -- apps/mobile/lib/ apps/mobile/test/ apps/mobile/integration_test/ apps/mobile/pubspec.yaml 2>/dev/null | tail -1)
  [ -n "$STAT" ] && printf 'Summary: %s\n' "$STAT"
  printf '\n'
} >> "$LOG"
