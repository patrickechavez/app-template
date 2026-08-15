#!/bin/bash
#
#  rename.sh
#  AppTemplate
#
#  Renames the template to a new app. Run once, from the repository root, on a
#  clean working tree:
#
#      Scripts/rename.sh MyApp com.acmecorp
#      Scripts/rename.sh MyApp com.acmecorp "My App"
#
#  Every change lands in the working tree, so `git checkout . && git clean -fd`
#  puts everything back. That recovery is why a clean tree is required.
#

set -euo pipefail

readonly OLD_NAME="AppTemplate"
readonly OLD_DISPLAY="App Template"
readonly OLD_PREFIX="com.patrick"

# The deep link scheme is lowercase, so it needs its own substitution — two
# apps sharing `apptemplate://` would fight over every incoming link.
readonly OLD_SCHEME="apptemplate"

usage() {
    cat <<'EOF'
usage: Scripts/rename.sh <AppName> <BundlePrefix> [DisplayName]

  AppName       becomes the target, folder and Swift type. Letters and digits,
                starting with a letter. No spaces or hyphens.
  BundlePrefix  reverse-DNS, at least two components, lowercase.
  DisplayName   home screen name. Defaults to AppName.

examples:
  Scripts/rename.sh MyApp com.acmecorp
  Scripts/rename.sh MyApp com.acmecorp "My App"
EOF
    exit 1
}

[ $# -eq 2 ] || [ $# -eq 3 ] || usage

readonly NEW_NAME="$1"
readonly NEW_PREFIX="$2"
readonly NEW_DISPLAY="${3:-$1}"
readonly NEW_SCHEME="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"

fail() {
    echo "error: $1" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Validate everything before writing anything.
# ---------------------------------------------------------------------------

[[ "$NEW_NAME" =~ ^[A-Za-z][A-Za-z0-9]*$ ]] ||
    fail "AppName '${NEW_NAME}' must be letters and digits, starting with a letter."

[[ "$NEW_PREFIX" =~ ^[a-z0-9]+(\.[a-z0-9]+)+$ ]] ||
    fail "BundlePrefix '${NEW_PREFIX}' must be lowercase reverse-DNS, e.g. com.acmecorp"

[ -d "${OLD_NAME}.xcodeproj" ] ||
    fail "${OLD_NAME}.xcodeproj not found. Run this from the repository root, and only once."

git rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
    fail "not a git repository. This script relies on git to be undoable."

[ -z "$(git status --porcelain)" ] ||
    fail "working tree has uncommitted changes.
Commit or stash first — this script rewrites files in place."

# ---------------------------------------------------------------------------
# Rename files and folders.
# ---------------------------------------------------------------------------

git mv "${OLD_NAME}.xcodeproj" "${NEW_NAME}.xcodeproj"
git mv "${OLD_NAME}" "${NEW_NAME}"
git mv "${NEW_NAME}/App/${OLD_NAME}App.swift" "${NEW_NAME}/App/${NEW_NAME}App.swift"

echo "renamed  ${OLD_NAME}.xcodeproj → ${NEW_NAME}.xcodeproj"
echo "renamed  ${OLD_NAME}/ → ${NEW_NAME}/"
echo "renamed  ${NEW_NAME}/App/${OLD_NAME}App.swift → ${NEW_NAME}/App/${NEW_NAME}App.swift"

# ---------------------------------------------------------------------------
# Rewrite file contents.
#
# The list comes from git's index rather than `find`, which excludes .git,
# DerivedData and everything else gitignored without having to name them.
# ---------------------------------------------------------------------------

should_skip() {
    case "$1" in
        .claude/*|docs/superpowers/*|Scripts/rename.sh) return 0 ;;
        *) return 1 ;;
    esac
}

count=0

while IFS= read -r -d '' file; do
    should_skip "$file" && continue

    case "$file" in
        *.swift|*.xcconfig|*.pbxproj|*.xcscheme|*.plist|README.md) ;;
        *) continue ;;
    esac

    grep -qF -e "$OLD_NAME" -e "$OLD_DISPLAY" -e "$OLD_PREFIX" -e "$OLD_SCHEME" "$file" || continue

    sed -i '' \
        -e "s|${OLD_DISPLAY}|${NEW_DISPLAY}|g" \
        -e "s|${OLD_NAME}|${NEW_NAME}|g" \
        -e "s|${OLD_PREFIX}|${NEW_PREFIX}|g" \
        -e "s|${OLD_SCHEME}|${NEW_SCHEME}|g" \
        "$file"

    count=$((count + 1))
done < <(git ls-files -z)

echo "rewrote  ${count} files"
echo
echo "Done. Review with \`git diff\`, then commit."
echo "To undo: git checkout . && git clean -fd"
