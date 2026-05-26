# Contributing

Every PR in this repo follows the disciplines below. They are the source of
truth in `~/.claude/rules/`; this file is a quick reference.

## 1. The per-PR floor

Per `~/.claude/rules/iteration-discipline.md`, a PR ships only when all seven
items hold:

1. It does not break anything: tests are green at HEAD and existing behavior is intact.
2. It does what it is supposed to do: acceptance commands are runnable and match expected output.
3. The bot reviewer is clean at HEAD: no unresolved findings from the active reviewer set.
4. The orchestrator's own role-4 review is clean: findings are fixed or dismissed with reasoning.
5. Per-PR runnable gates are green: `verify-pr.sh`, `check-done.sh`, or project equivalents pass.
6. The quality stack is clean: linter, type checker, security scanner, formatter, and complexity checks pass.
7. New behavior has failing-then-passing test evidence.

If any item is not true, keep the PR in draft or mark the status as pending.

## 2. Draft-first workflow

Open every non-trivial PR as draft per `~/.claude/rules/greptile-pr-gate.md`.
Run an internal subagent or CLI review on the draft diff, apply findings, then
mark the PR ready so CodeRabbit, Greptile, and Copilot can review the stable
state. Do not use bot reviews as the first debugging pass.

## 3. PR checklist

- [ ] Tests and acceptance commands pass from a clean checkout.
- [ ] CodeRabbit or active bot reviewer has no unresolved findings.
- [ ] The orchestrator/self-review pass is clean.
- [ ] `verify-pr.sh` / claim verifier passes, when the project has one.
- [ ] `check-done.sh` / DONE gate passes, when the project has one.
- [ ] Quality toolchain passes: lint, type, format, security, complexity.
- [ ] Docs, roadmap, and status markers match the actual shipped surface.

## 4. No silent hook bypass

Per `~/.claude/rules/never-bypass-hooks-silently.md`, do not use `--no-verify`,
`CLAUDE_HOOKS_BYPASS=1`, `CLAUDE_HOOKS_SKIP=...`, or a local hook override
without explicit Sammy authorization in the same turn. If a hook fails, fix the
underlying issue or document the blocker.

Run `./scripts/setup-hooks.sh` after cloning so this repo uses
`~/.claude/git-hooks`.

## 5. Catch once, fix everything caught

Per `~/.claude/rules/iteration-discipline.md`, every reviewer finding already on
the table gets resolved regardless of severity. Do not loop indefinitely to
find more issues. Fix the known set, document any justified dismissal, then move
forward when the floor is green.

## 6. Modularity gates

Per `~/.claude/rules/code-modularity-standards.md`:

- Files stay at or below 500 lines.
- Classes stay at or below 300 lines.
- Functions and methods stay at or below 80 lines.
- Cyclomatic or cognitive complexity stays at or below 15.
- Public functions avoid more than 6 parameters.

Use one-function-per-file decomposition from
`~/.claude/rules/one-function-per-file.md` for new Python structure unless a
documented exception applies.

## 7. Testing pyramid

Per `~/.claude/rules/testing-pyramid.md`, bias toward 70-80% unit tests,
15-25% integration tests, and 5-10% E2E tests. Every user-facing feature needs
at least one integration or smoke path that exercises the real user surface.

## 8. Function-first composition

Per `~/.claude/rules/function-first-composition.md`, stateless logic goes in
pure module functions. Classes manage state and lifecycle only, and methods
delegate to functions where practical. Document exceptions in the PR.

## 9. Where to read more

- `~/.claude/rules/quality-toolchain-pre-merge.md`
- `~/.claude/rules/code-modularity-standards.md`
- `~/.claude/rules/one-function-per-file.md`
- `~/.claude/rules/function-first-composition.md`
- `~/.claude/rules/testing-pyramid.md`
- `~/.claude/rules/hermetic-builds.md`
- `~/.claude/rules/trunk-based-development.md`
- `~/.claude/rules/feature-flags.md`
- `~/.claude/rules/code-ownership.md`
- `~/.claude/rules/monorepo-strategy.md`
- `~/.claude/rules/greptile-pr-gate.md`
- `~/.claude/rules/parallel-phase-cadence.md`
- `~/.claude/rules/never-bypass-hooks-silently.md`
- `~/.claude/rules/iteration-discipline.md`
- `~/.claude/rules/post-merge-cleanup.md`
