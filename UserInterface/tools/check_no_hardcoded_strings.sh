#!/usr/bin/env bash
# Fails when a Dart source file contains a hardcoded capitalized string
# literal inside Text(...). Run from the UserInterface directory or any
# parent — the script resolves paths relative to its own location.
#
# Add `// i18n-ignore` to a line to suppress the check for that line.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ui_dir="$(cd "$script_dir/.." && pwd)"

search_paths=(
  "$ui_dir/dispatcher/lib"
  "$ui_dir/responder/lib"
  "$ui_dir/team_admin/lib"
  "$ui_dir/shared_auth/lib"
)

existing=()
for p in "${search_paths[@]}"; do
  if [[ -d "$p" ]]; then
    existing+=("$p")
  fi
done

if [[ ${#existing[@]} -eq 0 ]]; then
  echo "check_no_hardcoded_strings: no Dart source directories found"
  exit 0
fi

# Capitalized string literal inside Text(...). Covers ~90% of user-facing prose.
pattern="Text\(\s*['\"][A-Z]"

raw_matches="$(grep \
  --recursive \
  --line-number \
  --extended-regexp \
  --include='*.dart' \
  --exclude='*.g.dart' \
  --exclude='*.freezed.dart' \
  --exclude-dir='l10n' \
  --exclude-dir='generated' \
  "$pattern" \
  "${existing[@]}" 2>/dev/null || true)"

if [[ -z "$raw_matches" ]]; then
  exit 0
fi

filtered="$(echo "$raw_matches" | grep --invert-match 'i18n-ignore' || true)"

if [[ -z "$filtered" ]]; then
  exit 0
fi

echo "Hardcoded user-facing strings found. Move them to ARB or annotate the line with '// i18n-ignore':" >&2
echo "$filtered" >&2
exit 1
