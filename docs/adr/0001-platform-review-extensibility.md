# ADR-0001 — Platform-review extensibility via companion plugins

- **Status**: Accepted (2026-04-20)
- **Refs**: #34

## Context

Version 1.8.0 added an `ios-review` skill plus an iOS-specific Agent C in
`code-review`, auto-dispatched when `Package.swift` or `*.xcodeproj` markers
were detected. This violated the plugin's documented domain-agnostic core
principle in four concrete places (allowed-tools, Step 5c detection, Agent C
prompt, `code_review.agent_c.*` config keys).

Extending the same pattern to Android, Rust, Go, etc., would either require
copying the Agent C mechanism N times or accepting that the core is no longer
platform-neutral. Issue #34 opens the design conversation before that happens.

## Decision

**C2 — companion plugin with generic discovery contract.**

Core `code-review` publishes a contract: platform-review skills declare themselves
via SKILL.md frontmatter (`metadata.platform_review: true` and `metadata.platform_markers: [<globs>]`).
At dispatch time, core scans the available-skills list, matches markers against
the PR diff, and invokes the first matching skill via the Skill tool in parallel
with Agents A and B.

`ios-review` moves to a new companion plugin `circle-ios`, shipped from the same
monorepo as `circle` with a shared `marketplace.json` listing both. Core v2.0.0
ships in the same release as companion v1.0.0.

## Alternatives considered

- **C1 — hard split, no core hooks**: rejected. Regresses the auto-dispatch UX
  from v1.8.0 without principle gain that C2 doesn't also deliver.
- **C3 — core preflight suggestion**: rejected. Keeps detection logic in core,
  which is a softer version of the same principle violation.
- **A — single `platform-review` skill with internal routing**: rejected.
  Centralises platform knowledge in one skill that becomes a router; extensibility
  becomes "edit the router".
- **B — fold into `code-review` via runtime MCP discovery**: rejected. Overloads
  `code-review`, and Q4 (below) confirms `suggest_in` isn't a runtime mechanism,
  so B would need a new one anyway — at which point C2 is strictly cleaner.
- **D — temporary role via governance-protocol**: rejected. Wrong mechanism;
  governance-protocol is for recurring/team tensions, not platform extensibility.

## Answered questions (from issue #34)

- **Q1 — standalone value of `/circle:ios-review 42`?** Kept. Becomes `/circle-ios:ios-review 42`.
- **Q2 — Android / Rust / Go realistic?** Yes, 6–18 months. C2 makes them drop-in.
- **Q3 — marketplace plugin-to-plugin deps?** Not formally supported. C2 sidesteps
  by not depending — each plugin is independent; discovery is LLM-visible via the
  harness skill list.
- **Q4 — `suggest_in` runtime dispatch?** No. `suggest_in` stays documentary. A
  new frontmatter convention is the runtime mechanism.

## Consequences

**Positive**:
- Core passes a mechanical lint: zero iOS strings in `plugin/skills/code-review/SKILL.md`.
- Adding a new platform is a new companion plugin, not a core change.
- Auto-dispatch UX preserved.

**Negative (with mitigations)**:
- LLM-level discovery is a fragile surface — mitigated by graceful fallback to
  Agents A + B on any dispatch failure.
- Companion plugin authors must follow the frontmatter contract — mitigated by
  documenting it in `docs/extensibility.md` and adding a lint check as follow-up.

## Migration (v1.8.x / v1.9.x → v2.0.0)

One command:

```
claude plugin install circle-ios@circle
```

Plus rename `code_review.agent_c.*` config keys to `code_review.platform_review.*`.
`/circle:ios-review` is now `/circle-ios:ios-review` when invoked directly.
Auto-dispatch from `/circle:code-review` is unchanged (triggers on the same files).

See `docs/CHANGELOG.md` → v2.0.0 → `### BREAKING` for the full list.

## Extensibility contract

See `docs/extensibility.md`. Summary: one frontmatter key, one glob list, one
SKILL.md — no core changes needed.
