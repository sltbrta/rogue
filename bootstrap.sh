#!/usr/bin/env bash
# bootstrap.sh — one-command setup for a new repo created from this template.
#
# Usage:
#   ./bootstrap.sh <owner>/<repo>
#
# Idempotent: safe to re-run. Skips steps that are already complete.
#
# Pre-reqs:
#   - gh CLI authed with admin scope on the target repo
#   - Repo already created from template
#   - CR + Greptile + Copilot apps installed on the repo OR org (manual one-time step)
#   - package.json still carries REPLACE-ME-AT-BOOTSTRAP until the project names itself

set -euo pipefail

REPO="${1:-}"
if [ -z "$REPO" ]; then
  echo "Usage: $0 <owner>/<repo>"
  exit 1
fi

OWNER="${REPO%/*}"
NAME="${REPO#*/}"

echo "=== Bootstrap: $REPO ==="

# ── Verify gh auth + repo exists ──
echo "→ checking repo exists..."
if ! gh repo view "$REPO" >/dev/null 2>&1; then
  echo "ERROR: $REPO not found or no perms"
  exit 1
fi

# ── Default branch ──
DEFAULT_BRANCH=$(gh repo view "$REPO" --json defaultBranchRef --jq '.defaultBranchRef.name')
echo "→ default branch: $DEFAULT_BRANCH"

# ── Check if Ruleset already exists ──
RULESET_EXISTS=$(gh api "repos/$REPO/rulesets" 2>/dev/null | python3 -c "
import json, sys
try:
  data = json.load(sys.stdin)
  for r in data if isinstance(data, list) else []:
    if r.get('name') == 'Merge Checks':
      print('yes'); break
except: pass
" || echo "no")

if [ "$RULESET_EXISTS" = "yes" ]; then
  echo "→ 'Merge Checks' ruleset already exists; skipping creation"
else
  echo "→ creating 'Merge Checks' ruleset (relaxed — no required status checks)..."
  # Per ~/.claude/rules/greptile-pr-gate.md HARD RULE 2026-05-24 (pm):
  # Repos ship with a RELAXED Ruleset: no required_status_checks block.
  # Rationale: hardcoding "CodeRabbit" / "Greptile Review" / "Copilot Pull Request Reviewer"
  # context names will permanently block merges if the actual bot context names differ
  # (each bot emits its own slug; names vary per install + version). After the first PR
  # on the new repo runs the bots, AUDIT the actual status-check names in 'gh pr checks <N>'
  # and add them manually via Settings → Rules → Rulesets → "Merge Checks" → edit.
  cat > /tmp/ruleset-$$.json <<EOF
{
  "name": "Merge Checks",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["~DEFAULT_BRANCH"],
      "exclude": []
    }
  },
  "rules": [
    {"type": "deletion"},
    {"type": "non_fast_forward"},
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": true
      }
    }
  ]
}
EOF
  gh api -X POST "repos/$REPO/rulesets" --input /tmp/ruleset-$$.json >/dev/null
  rm /tmp/ruleset-$$.json
  echo "  ✓ ruleset created (no required status checks — add after first PR populates context names)"
fi

# ── GitHub apps verification (manual) ──
echo "→ Verify bot installations manually:"
echo "    https://github.com/$REPO/settings/installations"
echo "  Required: CodeRabbit, Greptile, GitHub Copilot Code Review"

# ── Per-project memory pointer ──
# Derive slug from $HOME-based path so it works on any developer's machine.
REPO_PATH="$HOME/Developer/${OWNER}/${NAME}"
PROJ_SLUG="$(echo "$REPO_PATH" | sed 's|/|-|g' | sed 's|^-||')"
MEM_DIR="$HOME/.claude/projects/$PROJ_SLUG/memory"
if [ ! -d "$MEM_DIR" ]; then
  mkdir -p "$MEM_DIR"
  cat > "$MEM_DIR/MEMORY.md" <<EOF
# Per-project memory index for $REPO

(Auto-created by bootstrap.sh. Add memory entries as work progresses.)
EOF
  echo "  ✓ per-project memory pointer at $MEM_DIR/MEMORY.md"
else
  echo "  → per-project memory already exists at $MEM_DIR"
fi

echo ""
echo "=== Bootstrap complete ==="
echo ""
echo "Next steps (manual):"
echo "  1. Install CR + Greptile + Copilot apps at https://github.com/$REPO/settings/installations (if not already)"
echo "  2. Replace REPLACE-ME-AT-BOOTSTRAP in package.json if this repo uses Node tooling"
echo "  3. Open a trivial first PR as DRAFT to populate bot status check names"
echo "  4. gh pr ready <num> → bot reviews fire on draft→ready transition"
echo "  5. Verify all 3 bot checks appear in 'gh pr checks <num>'"
echo "  6. Add the OBSERVED context names to the Ruleset via Settings → Rules → Rulesets → Merge Checks"
echo "  7. If Greptile check missing: dashboard → enable 'Create GitHub status check' for this repo"
