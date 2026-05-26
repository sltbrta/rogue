# Rulesets — relaxed by default

This template ships `merge-checks-org.json` with **NO `required_status_checks` block** by design.

Per `~/.claude/rules/greptile-pr-gate.md` HARD RULE 2026-05-24 (pm), repos start with a **relaxed Ruleset** that only enforces:

- `deletion` — no deleting `main`
- `non_fast_forward` — no force-push to `main`
- `pull_request` — requires PR (1 approval, dismiss-stale, conversation-resolution)

## Why no required status checks?

Hardcoding context names like `"CodeRabbit"` / `"Greptile Review"` / `"Copilot Pull Request Reviewer"` risks permanently blocking merges if the actual bot-emitted names differ. Each bot's slug varies per install + version + repo.

Discipline-side, you still wrap up ALL findings before merging (per `~/.claude/rules/iteration-discipline.md` catch-once-fix-everything). The Ruleset isn't the enforcement; the orchestrator's discipline is.

## How to add required status checks AFTER first PR

1. Open the first PR as draft → mark ready → bots auto-fire.
2. `gh pr checks <N>` shows the EXACT context names emitted by each bot for this repo.
3. Settings → Rules → Rulesets → "Merge Checks" → edit → add a `required_status_checks` rule with the observed names.
4. Save. Future PRs gate on those checks.
