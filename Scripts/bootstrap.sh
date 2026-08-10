#!/bin/bash
#
# bootstrap.sh — turn this template into a new project.
#
# Renames the app, the Xcode project, the schemes, and the bundle identifier
# in one pass, so starting project #2 is a single command instead of an
# afternoon of find-and-replace.
#
#   ./Scripts/bootstrap.sh --name MyApp --bundle-prefix com.acme
#
# Optional:
#   --display-name "My App"    Home-screen name (defaults to --name)
#   --scheme myapp             Deep-link URL scheme (defaults to lowercased name)
#   --team ABCDE12345          Apple Developer Team ID
#   --dry-run                  Print what would change, change nothing
#
# Run it on a clean checkout, then delete it — a project only bootstraps once.

set -euo pipefail

cd "$(dirname "$0")/.." || exit 1

OLD_NAME="AppTemplate"
OLD_PREFIX="com.patrick"

NEW_NAME=""
NEW_PREFIX=""
DISPLAY_NAME=""
URL_SCHEME=""
TEAM_ID=""
DRY_RUN=false

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'

usage() {
    sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --name)          NEW_NAME="${2:-}"; shift 2 ;;
        --bundle-prefix) NEW_PREFIX="${2:-}"; shift 2 ;;
        --display-name)  DISPLAY_NAME="${2:-}"; shift 2 ;;
        --scheme)        URL_SCHEME="${2:-}"; shift 2 ;;
        --team)          TEAM_ID="${2:-}"; shift 2 ;;
        --dry-run)       DRY_RUN=true; shift ;;
        -h|--help)       usage 0 ;;
        *) echo "${RED}Unknown option: $1${RESET}"; usage 1 ;;
    esac
done

# ─── Validate ────────────────────────────────────────────────────────────────

[ -n "$NEW_NAME" ]   || { echo "${RED}--name is required${RESET}"; usage 1; }
[ -n "$NEW_PREFIX" ] || { echo "${RED}--bundle-prefix is required${RESET}"; usage 1; }

# The name becomes a Swift module name, so it must be a valid identifier.
if ! echo "$NEW_NAME" | grep -qE '^[A-Za-z][A-Za-z0-9]*$'; then
    echo "${RED}--name must be alphanumeric and start with a letter (it becomes the Swift module name).${RESET}"
    exit 1
fi

if ! echo "$NEW_PREFIX" | grep -qE '^[a-zA-Z0-9.-]+$'; then
    echo "${RED}--bundle-prefix must be reverse-DNS, e.g. com.acme${RESET}"
    exit 1
fi

DISPLAY_NAME="${DISPLAY_NAME:-$NEW_NAME}"
URL_SCHEME="${URL_SCHEME:-$(echo "$NEW_NAME" | tr '[:upper:]' '[:lower:]')}"

if [ "$NEW_NAME" = "$OLD_NAME" ]; then
    echo "${RED}--name matches the template name; nothing to do.${RESET}"
    exit 1
fi

# ─── Confirm ─────────────────────────────────────────────────────────────────

echo ""
echo "${BOLD}Bootstrapping new project${RESET}"
echo "  Module / target   $OLD_NAME  →  ${GREEN}$NEW_NAME${RESET}"
echo "  Bundle prefix     $OLD_PREFIX  →  ${GREEN}$NEW_PREFIX${RESET}"
echo "  Bundle ID         ${GREEN}$NEW_PREFIX.$NEW_NAME${RESET} ${DIM}(+ .dev / .staging)${RESET}"
echo "  Display name      ${GREEN}$DISPLAY_NAME${RESET}"
echo "  URL scheme        ${GREEN}$URL_SCHEME://${RESET}"
[ -n "$TEAM_ID" ] && echo "  Team ID           ${GREEN}$TEAM_ID${RESET}"
$DRY_RUN && echo "  ${BOLD}(dry run — no files will be modified)${RESET}"
echo ""

if ! $DRY_RUN; then
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        echo "${RED}Working tree is dirty.${RESET} Commit or stash first — this script rewrites many files."
        exit 1
    fi
    printf "Proceed? [y/N] "
    read -r reply
    case "$reply" in [yY]*) ;; *) echo "Aborted."; exit 0 ;; esac
    echo ""
fi

run() {
    if $DRY_RUN; then
        echo "  ${DIM}would run:${RESET} $*"
    else
        "$@"
    fi
}

# ─── 1. Rewrite file contents ────────────────────────────────────────────────
#
# Order matters: replace the prefix first, because "com.patrick.AppTemplate"
# contains the app name and we do not want to rewrite it twice.

echo "→ Rewriting file contents"

targets=$(git ls-files -- \
    '*.swift' '*.xcconfig' '*.plist' '*.pbxproj' '*.xcscheme' \
    '*.md' '*.yml' '*.yaml' '*.xcprivacy' '*.json' '*.entitlements' 2>/dev/null || true)

if $DRY_RUN; then
    count=$(echo "$targets" | grep -c . || true)
    echo "  ${DIM}would rewrite $count tracked file(s)${RESET}"
else
    echo "$targets" | while IFS= read -r file; do
        [ -f "$file" ] || continue
        # LC_ALL=C keeps sed from choking on non-ASCII bytes in these files.
        LC_ALL=C sed -i '' \
            -e "s|${OLD_PREFIX}|${NEW_PREFIX}|g" \
            -e "s|${OLD_NAME}|${NEW_NAME}|g" \
            "$file"
    done
fi

# ─── 2. Apply the human-facing names ─────────────────────────────────────────
#
# These are values bootstrap chooses, not straight renames, so they are set
# explicitly after the bulk pass.

echo "→ Setting display name and URL scheme"

if ! $DRY_RUN; then
    LC_ALL=C sed -i '' \
        -e "s|^APP_DISPLAY_NAME = .*|APP_DISPLAY_NAME = ${DISPLAY_NAME}|" \
        -e "s|^APP_URL_SCHEME = .*|APP_URL_SCHEME = ${URL_SCHEME}|" \
        Config/Shared.xcconfig

    LC_ALL=C sed -i '' \
        -e "s|^APP_DISPLAY_NAME = .*|APP_DISPLAY_NAME = ${DISPLAY_NAME} Dev|" \
        -e "s|^APP_URL_SCHEME = .*|APP_URL_SCHEME = ${URL_SCHEME}-dev|" \
        Config/Development.xcconfig

    LC_ALL=C sed -i '' \
        -e "s|^APP_DISPLAY_NAME = .*|APP_DISPLAY_NAME = ${DISPLAY_NAME} QA|" \
        -e "s|^APP_URL_SCHEME = .*|APP_URL_SCHEME = ${URL_SCHEME}-staging|" \
        Config/Staging.xcconfig

    LC_ALL=C sed -i '' \
        -e "s|^APP_DISPLAY_NAME = .*|APP_DISPLAY_NAME = ${DISPLAY_NAME}|" \
        -e "s|^APP_URL_SCHEME = .*|APP_URL_SCHEME = ${URL_SCHEME}|" \
        Config/Production.xcconfig
fi

if [ -n "$TEAM_ID" ]; then
    echo "→ Setting development team"
    if ! $DRY_RUN; then
        LC_ALL=C sed -i '' "s|DEVELOPMENT_TEAM = [A-Z0-9]*;|DEVELOPMENT_TEAM = ${TEAM_ID};|g" \
            "${NEW_NAME}.xcodeproj/project.pbxproj" 2>/dev/null \
            || LC_ALL=C sed -i '' "s|DEVELOPMENT_TEAM = [A-Z0-9]*;|DEVELOPMENT_TEAM = ${TEAM_ID};|g" \
                "${OLD_NAME}.xcodeproj/project.pbxproj"
    fi
fi

# ─── 3. Rename paths ─────────────────────────────────────────────────────────
#
# Deepest paths first, so renaming a parent never invalidates a queued child.

echo "→ Renaming files and directories"

find . -depth -name "*${OLD_NAME}*" -not -path "./.git/*" | while IFS= read -r path; do
    newpath="$(dirname "$path")/$(basename "$path" | sed "s|${OLD_NAME}|${NEW_NAME}|g")"
    if $DRY_RUN; then
        echo "  ${DIM}$path → $newpath${RESET}"
    else
        git mv "$path" "$newpath" 2>/dev/null || mv "$path" "$newpath"
    fi
done

# ─── 4. Reset version history ────────────────────────────────────────────────

echo "→ Resetting version to 1.0.0 (build 1)"
if ! $DRY_RUN; then
    LC_ALL=C sed -i '' \
        -e "s|^MARKETING_VERSION = .*|MARKETING_VERSION = 1.0.0|" \
        -e "s|^CURRENT_PROJECT_VERSION = .*|CURRENT_PROJECT_VERSION = 1|" \
        Config/Shared.xcconfig
fi

# ─── Done ────────────────────────────────────────────────────────────────────

echo ""
if $DRY_RUN; then
    echo "${BOLD}Dry run complete.${RESET} Re-run without --dry-run to apply."
    exit 0
fi

echo "${GREEN}${BOLD}Done.${RESET} ${NEW_NAME} is ready."
echo ""
echo "Next steps:"
echo "  1. Point Config/Development.xcconfig and Config/Production.xcconfig at your API."
echo "  2. Replace the Item model and its repository with your first real resource."
echo "  3. Review AppTemplate/PrivacyInfo.xcprivacy against what your backend stores."
echo "  4. Delete Scripts/bootstrap.sh — a project only bootstraps once."
echo "  5. Verify:  xcodebuild -scheme Development -destination 'generic/platform=iOS Simulator' build"
echo ""
