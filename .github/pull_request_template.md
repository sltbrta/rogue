## Summary

<!-- 1-3 bullets: what changed + why. Be concise. -->

## DONE gate (per `~/.claude/rules/truth-seeking-discipline.md`)

- [ ] **User-reachable surface** — a user can invoke this feature without reading source
- [ ] **Integration test** — exercises the full end-user path (not just unit-level)
- [ ] **Marketing-vs-capability** — every README / docs / spec claim added/updated is verifiable
- [ ] **Stub disclosure** — disabled/stubbed portions marked "coming soon" at the surface itself

If any answer is "no" → downgrade ROADMAP status marker (🚧 / 🎨 instead of ✅).

## Integration proof (per `~/.claude/rules/integration-checks-mandatory.md`)

```
# Call-site grep (production code, not tests):
$ grep -rn "<NewSymbol>(" <prod-dirs> --include="*.py" | grep -v test
<paste matches OR "N/A — bug fix, no new exports">

# End-to-end exercise:
- One of: pytest <test path> / CLI command / MCP tool / bench job
- <fill in>
```

## Test plan

- [ ] All new tests pass
- [ ] Existing regression tests pass
- [ ] (If applicable) bench / smoke / manual UI walk completed
