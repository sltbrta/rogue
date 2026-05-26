# Migration Checklist

Use this when porting an existing repo onto this template. The goal is a small,
reviewable migration that wires the quality stack without erasing project-
specific behavior.

## Why Migrate

- Consistent pre-commit, CI, and review workflow across repos.
- File-size and modularity gates are present from day one.
- CODEOWNERS and 3-bot review setup are documented.
- Hook setup is explicit through `./scripts/setup-hooks.sh`.
- New contributors inherit the same conventions and quality floor.

## Phase 1 - Audit Existing State

- [ ] Record current default branch SHA.
- [ ] List existing CI workflows and required status checks.
- [ ] Run the file-size gate or equivalent `wc -l` audit.
- [ ] Capture current lint, format, type, and security scanner output.
- [ ] Capture current test commands and coverage, if available.
- [ ] Identify existing `package.json`, `pyproject.toml`, lockfiles, and tool pins.
- [ ] Identify CODEOWNERS location and whether branch protection enforces it.

Do not hide existing failures. Either fix them in the migration PR or record a
temporary baseline with a concrete drain plan.

## Phase 2 - Add Template Files

- [ ] Copy in missing quality configs: `biome.json`, `tsconfig.base.json`,
      `pyproject.toml`, `.pre-commit-config.yaml`, and `.editorconfig`.
- [ ] Merge with existing `package.json` or `pyproject.toml`; do not overwrite
      project scripts, dependencies, package names, or publish settings.
- [ ] Add `.nvmrc` and `.python-version` only after confirming the project can
      run on those pins or documenting a scoped override.
- [ ] Add `.prettierignore` and list only Biome-owned paths.
- [ ] Add `scripts/setup-hooks.sh` and run it locally.
- [ ] Add `scripts/check-file-size.sh` and route the workflow through it.

## Phase 3 - Refactor Against Modularity

- [ ] Fix files over 500 lines or add justified entries to `.file-size-allow-list`.
- [ ] Split functions over 80 lines where a clean boundary exists.
- [ ] Reduce complexity over 15 with early returns and helper extraction.
- [ ] Apply one-function-per-file for new Python structure.
- [ ] Avoid broad rewrites unrelated to the migration.

Legitimate allow-list entries are rare: generated code, data tables, format-
required snapshots, composer shells, or irreducible single functions.

## Phase 4 - Wire Branch Protection And 3-Bot Review

- [ ] Install CodeRabbit, Greptile, and GitHub Copilot Code Review.
- [ ] Open an initial draft PR to populate actual status check names.
- [ ] Configure the `Merge Checks` ruleset from `BOOTSTRAP.md`.
- [ ] Validate CODEOWNERS with `.github/workflows/codeowners-check.yml`.
- [ ] Confirm ready-for-review triggers the bot review set.

## Phase 5 - First Migration PR

- [ ] Keep the first PR focused on tooling and docs.
- [ ] Run the acceptance checks in the PR body.
- [ ] Mark any non-green gate as pending with the exact blocker.
- [ ] Fix all reviewer findings already surfaced.
- [ ] Merge only after the repo is in a reproducible state.

## Anti-Patterns

- Bulk-copying every template file over project-specific configuration.
- Skipping modularity refactors with "do it later" and no tracked baseline.
- Bypassing hooks during migration.
- Claiming hermetic builds before lockfiles and toolchain pins are enforced.
- Enabling required status checks before the checks have run once.
- Letting Prettier and Biome own the same paths.
