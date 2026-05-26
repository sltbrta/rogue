# Project Conventions

These conventions are the repo-local quick reference. The rule files under
`~/.claude/rules/` remain the source of truth.

## Modularity

Per `~/.claude/rules/code-modularity-standards.md`, keep source code small
enough to review and debug without scrolling through unrelated concerns.

| Unit | Hard cap | Production target |
|---|---:|---:|
| File | 500 lines | 300 lines |
| Class | 300 lines | 200 lines |
| Function or method | 80 lines | 40 lines |
| Complexity | 15 | 10 |
| Function parameters | 6 | 4 |

When a file approaches the cap, split along responsibility boundaries. Do not
add new logic to an oversized file unless the PR also decomposes it or carries a
specific allow-list justification.

## One Function Per File

Per `~/.claude/rules/one-function-per-file.md`, new Python modules default to
one exported function per file. Folder hierarchy carries the semantic grouping:

```text
runtime/search/
  channels/
    bm25/
      search.py
      score.py
  ranking/
    fuse.py
```

Keep tiny local helpers in the caller file when they are private and used by a
single function. Move helpers to their own file when they have multiple callers
or their own tests. Class shells may keep `__init__`, dunders, tiny accessors,
and one-line delegates.

## Function-First Composition

Per `~/.claude/rules/function-first-composition.md`, stateless logic belongs in
pure module functions. Classes are for explicit state, resource lifecycle,
domain entities, builders, and state machines. If a class method does not need
instance state, make it a function. If it does need state, keep the class thin
and pass explicit state to a function that performs the work.

## Testing Pyramid

Per `~/.claude/rules/testing-pyramid.md`, test shape should usually be:

- 70-80% unit tests for pure logic and edge cases.
- 15-25% integration tests for real component wiring.
- 5-10% E2E tests for critical user paths.

Language defaults:

| Stack | Unit | Integration | E2E |
|---|---|---|---|
| Python | `pytest` | `pytest` + testcontainers | Playwright |
| TypeScript | Vitest | Vitest + testcontainers or MSW | Playwright |
| Rust | `cargo test` | `tests/` + `tokio::test` | Playwright or CLI smoke |
| Swift | XCTest / Swift Testing | XCTest with real fixtures | XCUITest |

Every bug fix gets a regression test that would have failed before the fix.
Every user-facing feature gets at least one integration or smoke path.

## Feature Flags

Per `~/.claude/rules/feature-flags.md`, incomplete code can merge only when the
user-reachable surface stays safe. Release and experiment flags default off,
include a removal condition in the PR body, and test both on and off paths.
Feature flags are not authorization checks.

## Naming

- Files and directories: `kebab-case` for TS/JS packages and docs, `snake_case`
  for Python modules, idiomatic names for language-specific ecosystems.
- Python functions and variables: `snake_case`.
- JavaScript and TypeScript values: `camelCase`.
- Types, classes, React components, and Swift types: `PascalCase`.
- Constants: `SCREAMING_SNAKE_CASE` when they are global and immutable.
- Test names describe behavior, not implementation details.

Prefer names that make the caller read like a sentence. Avoid generic buckets
such as `utils`, `helpers`, or `common` unless the package already has that
convention and the module stays focused.

## Commit Messages

Use Conventional Commits:

```text
feat: add quality workflow scaffold
fix: reject missing owner id
docs: document migration checklist
refactor: split search scoring
test: cover empty registry lookup
chore: update tooling pins
```

The subject says what changed. The body explains why the change exists, what
tradeoffs matter, and which rules or specs it implements. Use footers for
issue, PR, or handover references when useful.

Do NOT add `Co-Authored-By` trailers, `🤖 Generated with Claude Code`
footers, or any per-commit / per-PR attribution. Attribution goes in the
repo's top-level README only — one line. See `~/.claude/CLAUDE.md` §
"Attribution — repo-level only".

## Trunk-Based Development

Per `~/.claude/rules/trunk-based-development.md`, branches are short-lived and
PRs stay small. Use feature flags for incomplete work, split large changes into
reviewable slices, and avoid long-lived integration branches.

## Code Ownership

Per `~/.claude/rules/code-ownership.md`, CODEOWNERS is policy only when branch
protection enforces review. Keep ownership patterns current and validate them
with `.github/workflows/codeowners-check.yml`.

## Monorepos

Per `~/.claude/rules/monorepo-strategy.md`, root tooling owns shared quality
configuration for `packages/*` and `apps/*`. Cross-package refactors should land
atomically in one PR, with affected-package checks where the project has them.
