# iOS Code Review — "Senior" Upgrade Design

**Date:** 2026-07-16
**Skill:** `plugin-ios/skills/ios-review/SKILL.md` (companion plugin `circle-ios`)
**Status:** Approved (design) — pending implementation plan

## Problem

The current `ios-review` skill reviews iOS PRs across 4 domains (API Validation, SwiftUI, Concurrency, Testing) at the line level. Real PR review feedback on the `omron-foresight-ios` project — from human colleagues (e.g. *ivansatluscii*) and GitHub Copilot — repeatedly flags issues the skill does **not** catch. "Make it more senior" is an adjective; on this plugin, behavior only changes via **forcing functions** (mandatory steps that emit verifiable artifacts + red-flag tables), not personality prose. This design translates "senior" into concrete checks and gates.

## Evidence (recurring PR feedback the skill misses)

| Cluster | Real examples | Current skill |
|---|---|---|
| **A. Reuse / duplication / architectural consistency** | PR #9087: `CompositeIndexDataProvider` duplicates `BodyCompositionMassCalculator` and bypasses `isMassCalculationAllowed()` gate. PR #9859: `buildBodyCompositionSection` reused (wrongly filtered) for skeletal muscle; `HistoryUnitType.skeletalMuscle` advertises goal metadata that `saveGoals()` returns `false` for. | No domain |
| **B. Performance with teeth** | PR #9087 fix: synchronous full-history Realm fetch (`.all?.last`) on main thread during SwiftUI `body` → `getLatest()`. PR #9859: slot bucketing O(slots×readings). PR #9857 (human reviewer): `ObservableObject` + many `@Published` reloads all views → use `@Observable`. | Only "heavy body"; no sync-I/O or complexity check |
| **C. Silent failures / defensive code that hides bugs** | PR #9241: `?? 0.0` replaces a provably-safe force-unwrap → silent wrong result; `guard let … return nil` hides all data; `Semaphore.wait()` on `@MainActor` → deadlock; MD5 reintroduced. | Not covered |
| **D. Accessibility identifiers for UI tests** | PR #9859: `Menu` trigger missing `accessibilityIdentifier` → blocks UI-test automation. | No domain |
| **E. Active project-standards conformance** | PR #9087/#9241: inline comments forbidden, Xcode boilerplate headers; PR #9358: copy-pasted doc-comments referencing wrong type; timing delays in tests. | Reads `CLAUDE.md` passively; does not read `AGENTS.md`; no active check |
| **F. Coverage of new/fallback paths + build-breaking test changes** | PR #9087: fallback path untested; PR #9859/#9241: incomplete mock rename → compilation break. | Only XCTest→Testing style |
| **G. Right-reviewer gate** | PR #9210: iOS review ran on a Fastlane/Bash-only PR → 0 findings; general review then found 2 bugs. | iOS check standalone-only |

Meta-lessons from project memory:
- **#8065**: non-trivial iOS fixes must consult the relevant domain skill / Cupertino MCP *before* concluding. Skill treats this as a confidence bonus, not a gate.
- **feedback_forcing_function_over_adjectives**: change behavior with mandatory artifact-producing steps + red-flag tables, not adjectives.

## Design

### 1. Preflight additions (clusters E, G)
- Read `AGENTS.md` (root and any in diff-touched dirs) alongside `CLAUDE.md`. Keep P2-2 mitigation: reference by filename/section, never quote raw content.
- **Right-Reviewer Gate**: if the diff contains no real Swift/iOS code (only Fastlane/Bash/Markdown/YAML), do **not** run empty domains — emit *"No iOS-relevant changes; deferring to general review"* and stop. Fixes incident #9210.

### 2. Forcing function #1 — mandatory "Design & Reuse Survey" (cluster A)
Before **any** finding, the reviewer fills and saves a structured artifact; skipping it blocks findings:

```
## Design & Reuse Survey
- What this change does (1 line):
- Equivalent logic already in the codebase? → grep calculators/providers/helpers on the same concept
    → per-symbol verdict: REUSE-OK / DUPLICATES <file:line> / BYPASSES-GATE <gate>
- Introduces metadata/config that promises unimplemented behavior? (consistency)
- Reuses a builder/section meant for another type? (wrong filtering)
```
Every `DUPLICATES`/`BYPASSES` verdict must **name the existing symbol with a file:line verified via Grep/Read** — not a suspicion.

### 3. Forcing function #2 — pre-finding MCP/skill gate (formalizes #8065)
A finding in a technical-judgment domain (API/SwiftUI/Concurrency/Testing) **must** cite a Cupertino MCP result, a domain-skill pattern, or a local skill. No verifiable citation → confidence capped at 25 (dropped at the 90 threshold). For the new architectural-judgment domains (Reuse/Silent-failure) the "citation" is the **existing code read** (file:line), not a doc.

### 4. Domains: 4 → 7, each with a red-flag table (forcing function #3)

| Domain | Status | Added red-flags |
|---|---|---|
| 1. API Validation (MCP) | unchanged | — |
| 2. SwiftUI + teeth | extended | sync/Realm I/O in `body`; `ObservableObject` + many `@Published` → global reload (suggest `@Observable`); O(n²) in data sources |
| 3. Concurrency + silent/deadlock | extended | `Semaphore.wait()`/`.sync` on `@MainActor` → deadlock; force-unwrap replaced by `?? default` that changes semantics |
| 4. Swift Testing + coverage | extended | new/fallback paths untested; incomplete mock rename → build break; timing delays |
| 5. **Reuse & Consistency** (A) | NEW | fed by the Survey; duplication, bypassed gates, incoherent metadata |
| 6. **Robustness & Silent Failures** (C) | NEW | `guard let … return nil` hiding data; error-swallowing catch; defaults masking bugs |
| 7. **Accessibility & Standards** (D+E) | NEW | missing `accessibilityIdentifier` on interactive controls; forbidden inline comments/boilerplate headers; copy-paste doc-comments with wrong type — checked against `CLAUDE.md`/`AGENTS.md` |

### 5. Unchanged (do not touch)
- Changed-lines-only rule (already prevents false positives like #9859 where 3/4 Copilot comments were on pre-existing code).
- Local-skill precedence over external sources.
- 10-query MCP cap; P2-1/P2-2/P3-1/P3-2 security mitigations; output/post/handoff formats.
- Two invocation modes (standalone + platform-review dispatch). New steps (Survey, gates, new domains) apply in both modes; standalone still runs preflight, dispatch mode still skips it.

### 6. Decisions
- **Model:** stays `sonnet` (platform-review default). Senior reasoning comes from the Survey + red-flag tables, not the model tier — consistent with forcing-functions-over-adjectives. Per-project `opus` override remains available.
- **Versioning:** touches companion `plugin-ios` → bump `plugin-ios/.claude-plugin/plugin.json`, sync the companion's `marketplace.json` entry, add a CHANGELOG entry. Core is unchanged, so greenfield model-routing tables are NOT touched.

## Non-goals
- No new MCP dependencies; reuse survey uses existing allowed tools (Grep/Glob/Read/Bash).
- No change to core `code-review` skill.
- No change to the confidence scale or the 90/100 posting threshold.

## Acceptance criteria
1. Skill reads `AGENTS.md` when present, with the same mitigations as `CLAUDE.md`.
2. A non-Swift-only diff triggers the Right-Reviewer Gate and stops without empty-domain noise.
3. The Design & Reuse Survey is a mandatory step that blocks findings if skipped; duplication/bypass findings name a verified `file:line`.
4. Findings in technical domains without a verifiable citation are capped at confidence 25.
5. Seven domains present, each with a concrete red-flag list.
6. Companion version + marketplace entry + CHANGELOG updated and consistent.
7. Both invocation modes still function; changed-lines-only and all security mitigations preserved.
