#!/usr/bin/env bash
# s29-002-tag-move.sh — Tag discipline for v1.0.1 + v0.3.0 (STORY-S29-002, Issue #1014)
#
# Per docs/sprints/sprint-29/00-plan.md §Wave 1 (owner directive #1):
#   - Move v1.0.1 → template HEAD  43592c24c838247e4ef0125de571c43dd42149ea
#   - Add   v0.3.0 → launcher HEAD  b0d820da6b9cced6ae224e7db97d9cd31bece00b
#
# HUMAN-ONLY EXECUTION
# --------------------
# Force-push + cross-repo tag manipulation are owner-territory per RETRO-018 W6
# (cross-agent push authority NOT in doctrine; branch/tag owners handle own push).
# This script verifies state and prints the EXACT git commands; it does NOT push.
# Owner runs the printed commands from local clones of each sister repo.
#
# Usage:
#   bash scripts/s29-002-tag-move.sh verify       # verify SHA resolution + current tag state
#   bash scripts/s29-002-tag-move.sh commands     # print git commands owner will run (NO push)
#   bash scripts/s29-002-tag-move.sh all          # verify + commands (default)
#
# No-arg invocation → exit 2 with usage (TC2).
#
# Doctrinal contract (sister d-test: scripts/tests/d1014-s29-002-tag-move.sh, 5 TCs):
#   TC1: argv routing: verify|commands|all → distinct behavior
#   TC2: missing argv → exit 2 + usage to stderr
#   TC3: bash -n syntactically valid
#   TC4: SHA literals embedded match Issue #1014 plan.md spec
#   TC5: commands section contains no force-push-with-lease flag (force-push = owner-only,
#        we print plain `git push origin SHA:refs/tags/X` which owner executes manually)
#
# Refs:
#   - Issue #1014 (STORY-S29-002)
#   - docs/sprints/sprint-29/00-plan.md §Wave 1 owner directive #1
#   - RETRO-018 W6 — cross-agent push authority NOT in doctrine
#   - ADR-0055 §1 — Cadence Rule 1 atomic (this script + sister d-test same commit)

set -euo pipefail

TEMPLATE_REPO="atilcan65/dev-studio-template"
LAUNCHER_REPO="atilcan65/dev-studio-launcher"

TEMPLATE_TARGET_SHA="43592c24c838247e4ef0125de571c43dd42149ea"
LAUNCHER_TARGET_SHA="b0d820da6b9cced6ae224e7db97d9cd31bece00b"

usage() {
    cat >&2 <<EOF
Usage: $0 <verify|commands|all>
  verify   — check target SHAs resolve + report current v1.0.1/v0.3.0 tag state
  commands — print exact git commands owner runs (NO push executed by this script)
  all      — verify + commands (default if no arg)

HUMAN-ONLY: this script verifies + prints. Force-push + cross-repo tag moves
are owner-territory per RETRO-018 W6. Owner runs the printed commands.
EOF
    exit 2
}

cmd="${1:-}"
if [ -z "$cmd" ]; then
    usage
fi
case "$cmd" in
    verify|commands|all) ;;
    -h|--help) usage ;;
    *) usage ;;
esac

verify_state() {
    echo "=== Target SHA verification ==="
    local t_sha l_sha
    t_sha=$(gh api "repos/$TEMPLATE_REPO/commits/$TEMPLATE_TARGET_SHA" --jq .sha 2>/dev/null || echo "UNRESOLVABLE")
    l_sha=$(gh api "repos/$LAUNCHER_REPO/commits/$LAUNCHER_TARGET_SHA" --jq .sha 2>/dev/null || echo "UNRESOLVABLE")
    echo "  template target ($TEMPLATE_REPO): $t_sha"
    echo "  launcher target ($LAUNCHER_REPO): $l_sha"
    if [ "$t_sha" != "$TEMPLATE_TARGET_SHA" ] || [ "$l_sha" != "$LAUNCHER_TARGET_SHA" ]; then
        echo "ERROR: target SHA mismatch — re-verify plan.md spec before running" >&2
        return 1
    fi

    echo ""
    echo "=== Current tag state ==="
    echo -n "  $TEMPLATE_REPO v1.0.1 → "
    local current_v101
    current_v101=$(gh api "repos/$TEMPLATE_REPO/git/refs/tags/v1.0.1" --jq .object.sha 2>/dev/null || echo "NOT_FOUND")
    echo "$current_v101"
    if [ "$current_v101" = "$TEMPLATE_TARGET_SHA" ]; then
        echo "    (already at target — no move needed)"
    fi

    echo -n "  $LAUNCHER_REPO v0.3.0 → "
    local current_v030
    current_v030=$(gh api "repos/$LAUNCHER_REPO/git/refs/tags/v0.3.0" --jq .object.sha 2>/dev/null || echo "NOT_FOUND")
    echo "$current_v030"
    if [ "$current_v030" = "$NOT_FOUND_RESULT" ]; then
        echo "    (does not exist yet — needs create)"
    fi
}

print_commands() {
    cat <<EOF
=== Commands for owner (run from local clones; NOT executed by this script) ===

# ---- Step 1: Move v1.0.1 → template HEAD ----
# From local clone of $TEMPLATE_REPO:
cd path/to/dev-studio-template
git fetch --tags
git tag -d v1.0.1
git push origin :refs/tags/v1.0.1
git push origin $TEMPLATE_TARGET_SHA:refs/tags/v1.0.1
git tag -v v1.0.1   # verify GPG signature if applicable

# ---- Step 2: Add v0.3.0 → launcher HEAD ----
# From local clone of $LAUNCHER_REPO:
cd path/to/dev-studio-launcher
git fetch --tags
git push origin $LAUNCHER_TARGET_SHA:refs/tags/v0.3.0
git tag -v v0.3.0   # verify GPG signature if applicable

# ---- Step 3: Post-verify ----
gh api repos/$TEMPLATE_REPO/git/refs/tags/v1.0.1 --jq .object.sha   # expect $TEMPLATE_TARGET_SHA
gh api repos/$LAUNCHER_REPO/git/refs/tags/v0.3.0 --jq .object.sha    # expect $LAUNCHER_TARGET_SHA

# ---- Step 4: Close Issue #1014 ----
gh issue close 1014 -c "Tag move complete: v1.0.1 → $TEMPLATE_TARGET_SHA, v0.3.0 created at $LAUNCHER_TARGET_SHA"

EOF
}

NOT_FOUND_RESULT="NOT_FOUND"

case "$cmd" in
    verify)
        verify_state
        ;;
    commands)
        print_commands
        ;;
    all)
        verify_state
        echo ""
        print_commands
        ;;
esac