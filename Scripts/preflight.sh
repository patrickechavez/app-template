#!/bin/bash
#
# preflight.sh — refuses to let placeholder values reach production.
#
# Run before any Staging/Production archive. CI runs it on every push, so a
# forgotten sample URL or a debug logging flag fails the pipeline instead of
# shipping.
#
#   ./Scripts/preflight.sh
#
# Exit code 0 = safe to ship. Non-zero = one or more checks failed.

set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

RED=$'\033[0;31m'; YELLOW=$'\033[0;33m'; GREEN=$'\033[0;32m'; DIM=$'\033[2m'; RESET=$'\033[0m'

failures=0
warnings=0

fail()  { echo "${RED}✗ FAIL${RESET}  $1"; [ $# -gt 1 ] && echo "        ${DIM}$2${RESET}"; failures=$((failures + 1)); }
warn()  { echo "${YELLOW}!  WARN${RESET}  $1"; [ $# -gt 1 ] && echo "        ${DIM}$2${RESET}"; warnings=$((warnings + 1)); }
pass()  { echo "${GREEN}✓ PASS${RESET}  $1"; }

echo ""
echo "Preflight checks"
echo "────────────────────────────────────────────────────────"

# ─── 0. Has this template been turned into a real project yet? ───────────────
#
# The template ships with placeholder values on purpose, so a fresh clone
# builds and runs without a backend. Those placeholders are only *failures*
# once someone has bootstrapped the project into a real app — otherwise the
# template's own CI could never be green.
IS_TEMPLATE=false
if grep -qE '^APP_NAME\s*=\s*AppTemplate$' Config/Shared.xcconfig \
   && grep -qE '^APP_BUNDLE_PREFIX\s*=\s*com\.patrick$' Config/Shared.xcconfig; then
    IS_TEMPLATE=true
    echo "${DIM}Un-bootstrapped template detected — placeholder checks report as warnings.${RESET}"
    echo ""
fi

# `placeholder` fails for real projects and warns for the bare template.
placeholder() { if $IS_TEMPLATE; then warn "$@"; else fail "$@"; fi; }

# ─── 1. Production must not point at the sample API ──────────────────────────
prod_url=$(grep -E '^API_BASE_URL' Config/Production.xcconfig | head -1)
if echo "$prod_url" | grep -q "dummyjson"; then
    placeholder "Production API_BASE_URL is still the sample API" \
                "Edit Config/Production.xcconfig — it currently points at dummyjson.com"
else
    pass "Production API_BASE_URL is set"
fi

staging_url=$(grep -E '^API_BASE_URL' Config/Staging.xcconfig | head -1)
if echo "$staging_url" | grep -q "dummyjson"; then
    warn "Staging API_BASE_URL is still the sample API" \
         "Fine while prototyping; fix before handing builds to QA."
else
    pass "Staging API_BASE_URL is set"
fi

# ─── 2. Request logging must be off outside Development ──────────────────────
for env in Staging Production; do
    if grep -qE '^API_LOGGING_ENABLED\s*=\s*YES' "Config/$env.xcconfig"; then
        fail "API_LOGGING_ENABLED is YES in $env" \
             "Request logs contain bearer tokens. Set it to NO in Config/$env.xcconfig."
    else
        pass "Request logging disabled in $env"
    fi
done

# ─── 3. Bundle identifier must not be the template default ───────────────────
if $IS_TEMPLATE; then
    warn "Project has not been bootstrapped yet" \
         "Run ./Scripts/bootstrap.sh --name MyApp --bundle-prefix com.acme"
else
    pass "Project identity has been customised"
fi

# ─── 4. Privacy manifest must exist and be valid ─────────────────────────────
if [ ! -f AppTemplate/PrivacyInfo.xcprivacy ]; then
    fail "PrivacyInfo.xcprivacy is missing" \
         "App Store submission requires it."
elif ! plutil -lint AppTemplate/PrivacyInfo.xcprivacy >/dev/null 2>&1; then
    fail "PrivacyInfo.xcprivacy is not valid plist XML"
else
    pass "Privacy manifest present and valid"
fi

if ! plutil -lint Config/Info.plist >/dev/null 2>&1; then
    fail "Config/Info.plist is not valid plist XML"
else
    pass "Info.plist valid"
fi

# ─── Source scanning ─────────────────────────────────────────────────────────
#
# Comment lines are stripped before matching. Without this, the doc comment on
# AppLogger that *explains why print() is banned* trips the print() check —
# a rule that flags its own documentation trains people to ignore it.
scan_sources() {
    grep -rn --include="*.swift" -E "$1" AppTemplate 2>/dev/null \
        | grep -vE '^[^:]+:[0-9]+:[[:space:]]*(//|/\*|\*)' \
        || true
}

# ─── 5. No print() in shipping code ──────────────────────────────────────────
# Logging goes through AppLogger so it is structured, redacted, and stripped
# from release builds.
print_hits=$(scan_sources '(^|[^A-Za-z0-9_.])print\(' | wc -l | tr -d ' ')
if [ "$print_hits" -gt 0 ]; then
    fail "$print_hits call(s) to print() in AppTemplate/" "Use AppLogger instead:"
    scan_sources '(^|[^A-Za-z0-9_.])print\(' | sed 's/^/        /'
else
    pass "No print() calls in app sources"
fi

# ─── 6. No hardcoded base URLs ───────────────────────────────────────────────
url_hits=$(scan_sources 'URL\(string:[[:space:]]*"https?://' | wc -l | tr -d ' ')
if [ "$url_hits" -gt 0 ]; then
    fail "$url_hits hardcoded URL(s) in AppTemplate/" \
         "Base URLs belong in Config/*.xcconfig, read via APIConfig."
    scan_sources 'URL\(string:[[:space:]]*"https?://' | sed 's/^/        /'
else
    pass "No hardcoded base URLs"
fi

# ─── 7. Secrets must not be committed ────────────────────────────────────────
if git ls-files --error-unmatch Config/Secrets.xcconfig >/dev/null 2>&1; then
    fail "Config/Secrets.xcconfig is tracked by git" \
         "Remove it from the index: git rm --cached Config/Secrets.xcconfig"
else
    pass "No secrets file tracked in git"
fi

echo "────────────────────────────────────────────────────────"
if [ "$failures" -gt 0 ]; then
    echo "${RED}$failures check(s) failed${RESET}, $warnings warning(s)."
    echo ""
    exit 1
fi
echo "${GREEN}All checks passed${RESET}${warnings:+ ($warnings warning(s))}."
echo ""
exit 0
