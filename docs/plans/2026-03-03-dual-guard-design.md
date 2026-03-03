# Dual Guard: Anti-Overcomplication & Big-Picture Coherence (v0.9.0)

**Date**: 2026-03-03
**Status**: Approved
**Motivation**: User feedback — agents overcomplicate at larger scope, lose big picture, leave things unfinished/misconfigured.

## Problem

1. Agents suggest overly complex solutions for MVPs (e.g., Docker Compose when a single script suffices)
2. Individual features delivered well but system lacks coherence
3. Hard for developers to figure out what broke — overwhelming for MVPs

## Solution: Dual Guard (Downstream)

Two complementary checks in Implementer and QA, both additive and non-breaking.

### Guard 1: Simplicity Assessment (bmad-impl)

New step between "Read architecture" and "Explore codebase". Advisory, not blocking.

The Implementer asks 3 questions before writing code:

1. **Scope check**: Does the design contain components/services not directly required by MVP (Must Have) user stories? If yes, list them and ask user whether to proceed or simplify.
2. **Technology check**: Does the design introduce infrastructure (containers, message queues, caching layers) not strictly necessary for MVP? If yes, propose the simplest alternative.
3. **Dependency check**: How many external dependencies does the design introduce? Is there a solution with fewer dependencies that still satisfies MVP requirements?

If red flags found: present a brief report with simplification suggestions. User decides: proceed with original design or simplify.

### Guard 2: Coherence & Scope Drift Check (bmad-qa)

New step in Verification Mode, after TDD Compliance Check.

**A) Scope Drift Detection:**
- Map PRD Must Have user stories
- Scan implemented code for functionality not traced to PRD
- Untraced components = scope drift → P1

**B) Big Picture Coherence:**
- Verify components work as integrated system, not isolated features
- Check: consistent patterns across features (error handling, auth, data flow)
- Check: declared integration points actually implemented
- Check: no circular dependencies or undeclared coupling

**C) Severity mapping:**
- Scope drift (feature not in PRD) → P1
- Pattern inconsistency across components → P2
- Missing integration point → P1
- Circular dependency → P0

## Files to Modify

| File | Change |
|---|---|
| `plugin/skills/bmad-impl/SKILL.md` | New step "Simplicity Assessment" |
| `plugin/skills/bmad-qa/SKILL.md` | New step "Coherence & Scope Drift Check" |
| `plugin/.claude-plugin/plugin.json` | Version → 0.9.0 |
| `.claude-plugin/marketplace.json` | Version → 0.9.0 |
| `CLAUDE.md` | Add guardrail mention in workflow order |
| `docs/GETTING-STARTED.md` | Document new checks |
| `README.md` | Update feature list |
| `docs/MIGRATION.md` | v0.9.0 migration notes |

## What Does NOT Change

- No new files or skills
- No changes to greenfield workflow or existing gates
- No changes to soul.md or guardrails.md
- No changes upstream (arch, prioritize, scope)
- Simplicity Assessment is advisory (no config toggle needed)
- Coherence check uses existing severity system (P0/P1/P2)
