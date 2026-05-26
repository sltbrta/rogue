#!/usr/bin/env bash
# scripts/setup-hooks.sh - wire ~/.claude/git-hooks for this repo.
#
# Per ~/.claude/rules/known-hooks.md + ~/.claude/rules/never-bypass-hooks-silently.md.
# Idempotent: safe to re-run.

set -euo pipefail

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: not inside a git repo"
  exit 1
fi

HOOK_PATH="$HOME/.claude/git-hooks"

if [ ! -d "$HOOK_PATH" ]; then
  echo "ERROR: $HOOK_PATH does not exist."
  echo "Install dotclaude first: https://github.com/sltbrta/dotclaude"
  exit 1
fi

HOOKS_DIR="$(git rev-parse --git-dir)/hooks"
LOCAL_OVERRIDES=""
if [ -d "$HOOKS_DIR" ]; then
  for hook in "$HOOKS_DIR"/*; do
    [ -e "$hook" ] || continue
    case "$hook" in
      *.sample) continue ;;
    esac
    LOCAL_OVERRIDES="${LOCAL_OVERRIDES}${hook##*/}"$'\n'
  done
fi

if [ -n "$LOCAL_OVERRIDES" ]; then
  # Per git-config(1): when core.hooksPath is set, Git does NOT execute hooks
  # from .git/hooks — only from the configured hooksPath. So these files are
  # INERT once we set core.hooksPath below. The warning still matters because
  # tools like husky / simple-git-hooks not only DROP files in .git/hooks but
  # ALSO call `git config --local core.hooksPath .husky` (etc), which DOES
  # override the global path. We re-check core.hooksPath explicitly below.
  echo "WARN: local .git/hooks/ contains non-sample files (will be inert once"
  echo "      core.hooksPath is set, but their presence may indicate a tool"
  echo "      like husky has also reconfigured the hookspath — verify below):"
  while IFS= read -r hook; do
    [ -n "$hook" ] && printf '  %s\n' "$hook"
  done <<<"$LOCAL_OVERRIDES"
  echo ""
fi

CURRENT=$(git config --local core.hooksPath 2>/dev/null || echo "")
if [ -n "$CURRENT" ] && [ "$CURRENT" != "$HOOK_PATH" ]; then
  echo "ERROR: local core.hooksPath is already set to a DIFFERENT path:"
  echo "  current:  $CURRENT"
  echo "  desired:  $HOOK_PATH"
  echo ""
  echo "This is likely set by husky / simple-git-hooks / similar tool."
  echo "Decide whether to keep the existing config or override:"
  echo "  - To override: git config --local --unset core.hooksPath ; ./scripts/setup-hooks.sh"
  echo "  - To keep current: do nothing (this script is a no-op for you)"
  exit 1
fi

if [ "$CURRENT" = "$HOOK_PATH" ]; then
  echo "core.hooksPath already set to $HOOK_PATH"
else
  git config --local core.hooksPath "$HOOK_PATH"
  echo "set local core.hooksPath = $HOOK_PATH"
fi

if [ ! -x "$HOOK_PATH/pre-push" ]; then
  echo "ERROR: $HOOK_PATH/pre-push missing or not executable."
  echo "       Hooks NOT active. Install dotclaude correctly first."
  exit 1
fi

echo "pre-push hook present at $HOOK_PATH/pre-push"
echo ""
echo "Done. Hooks active. Test by attempting a no-op push: git push --dry-run"
