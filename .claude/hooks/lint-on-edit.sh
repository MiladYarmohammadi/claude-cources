#!/bin/bash
# PostToolUse hook (Edit|Write): lint what Claude just changed and feed
# failures back to the model via exit code 2.
#   *.yml / *.yaml       -> yamllint (repo .yamllint config; chart templates
#                           are excluded there because they contain Go tpl)
#   anything in charts/  -> helm lint --strict charts/app
# Tools that aren't installed are skipped silently.
set -u

file=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null) || exit 0
[ -n "$file" ] && [ -f "$file" ] || exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0

status=0

case "$file" in
  *.yml|*.yaml)
    if command -v yamllint >/dev/null 2>&1; then
      out=$(yamllint -c .yamllint "$file" 2>&1) || {
        echo "yamllint failed for $file:" >&2
        echo "$out" >&2
        status=2
      }
    fi
    ;;
esac

case "$file" in
  */charts/app/*)
    if command -v helm >/dev/null 2>&1; then
      out=$(helm lint --strict charts/app 2>&1) || {
        echo "helm lint --strict charts/app failed:" >&2
        echo "$out" >&2
        status=2
      }
    fi
    ;;
esac

exit $status
