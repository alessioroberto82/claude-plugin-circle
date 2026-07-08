# Design Spec: Digest Handoff Between Circle Roles (Phase 2)

**Date**: 2026-07-08
**Status**: Approved design → ready for implementation plan
**Plugin version target**: 2.5.0 (minor — new opt-in mechanism)
**Prereq**: Phase 1 (boilerplate compression, v2.4.1, PR #46) — merged.

## Context

Circle's fork-context roles (`arch, security, impl, scope, refine, ux, qa, facilitate, validate-prd`) cost 100K–460K *fresh* (cache_creation) tokens per invocation. Profiling of real session transcripts (`~/.claude/projects/-Users-alessioroberto-Projects-claude-plugin-circle/*.jsonl`, fields `attributionSkill` + `usage`) established that the dominant cost is **not** the SKILL.md prose (all static plugin content is <3% of a fork). It is:

1. **Full upstream-doc reloads** — each downstream role reads the entire upstream artifact (`requirements.md`, `PRD.md`, `architecture.md`) as input.
2. **A second full read inside `guardrails.md`** — self-verification re-reads the *same* full upstream doc to extract checkable items and build a Traceability table.
3. (Amplifier) **Prompt-cache expiry** across human-in-the-loop pauses re-bills whatever is loaded.

Today there is **no digest path**: `work-summary-template.md` is output-only (consumed by claude-mem, never read by the next role). This spec introduces a compact **handoff digest** so downstream roles and guardrails read a small structured artifact instead of the full document — attacking costs (1) and (2) directly.

## Goals

- Downstream roles start from a compact digest, loading the full upstream doc **only on demand**.
- Eliminate the guardrails second full-doc read by feeding it the same digest.
- **No quality regression** and **no behavioral change when disabled**.
- Ship behind a config flag (default OFF), validate on one hop, then flip default ON.

## Non-goals

- Removing or shrinking the full upstream documents (they remain canonical, human-facing, and the escalation target).
- Changing greenfield gates or the per-domain output filenames they resolve.
- Replacing the claude-mem Work Summary (separate artifact, separate consumer).

## Decisions (from brainstorming)

1. **Producer**: the role itself, at handoff. It already holds full context in memory → marginal cost ≈ zero, highest fidelity, no extra full-doc read. Written in the same handoff phase as the Traceability section and Work Summary.
2. **Authority model**: digest-first + on-demand escalation. The digest is the primary input; the downstream role opens the full doc only when a decision needs a detail the digest lacks.
3. **Schema**: a fixed structured "handoff contract" whose *Verifiable items* list is exactly what guardrails needs — one artifact, two uses.
4. **Rollout**: config flag `handoff.digest`, default OFF at first merge; validate one hop (scope→arch), then a follow-up PR flips default ON.

## Design

### §1 — The digest artifact and schema

Each fork role, at handoff, writes a compact file **alongside** the full document (which is always still written — the digest is additive):

- Path: `~/.claude/circle/projects/{project}/output/{role}/handoff-digest.md`
  (e.g. `scope/handoff-digest.md` next to `scope/requirements.md`)
- Target size: ~300–600 tokens (vs multiple thousands for the full doc).

Fixed schema:

```markdown
# Handoff Digest — {role} → {next role}
**Source doc**: {relative path to the full document}   **Domain**: {software|business|personal|general}

## Verifiable items
| ID | Item | One-line essence |
|----|------|------------------|
| FR-1 | ... | ... |

## Key decisions
- {decision} — {one-line why}

## Interface for next role
- {what the next role needs to start without opening the full doc}

## Escalation hints
- For detail on {X}, see §{section} of the source doc
```

- **Verifiable items** enumerate the same items guardrails extracts today (FR-*, work items, components, acceptance criteria — depending on the role). This is the pivot that lets one artifact serve both consumers.
- **Key decisions** lists only choices that constrain the downstream role.
- **Interface for next role** is the minimal contract to begin work.
- **Escalation hints** map topics → source-doc sections so escalation is cheap and targeted.

### §2 — Data flow and escalation rule

- A downstream role's *Input Prerequisites* reads the upstream **digest first**, not the full doc.
- Explicit escalation rule added to each consuming role's body:
  > "If a decision depends on a detail not present in the digest, open the source doc named in the digest (use its Escalation hints to jump to the relevant section) before proceeding. Do not guess."
- The full doc remains for: on-demand escalation, greenfield gates (which read full-doc filenames — unchanged), and human readers.

### §3 — Guardrails unification

`guardrails.md` Self-Verification Protocol changes:

- Step 1 becomes: "Read the **Verifiable items** section of the upstream `handoff-digest.md`; use it as the checklist. Open the full source doc only if the digest is missing or incomplete (graceful degradation)."
- The Upstream Artifact Mapping table points at `{upstream-role}/handoff-digest.md` (with the full doc as fallback).
- The Traceability table is built from the digest's item list. This removes the second full-doc read.

### §4 — Config and gating

- New `config.yaml` key: `handoff.digest` (boolean, **default `false`**).
- When `false`: roles read full docs and guardrails re-reads full docs — **identical to current behavior, zero risk**.
- When `true`: producers emit the digest at handoff; consumers read digest-first; guardrails builds traceability from the digest.
- Consistent with existing flags (`tdd.enabled`, `guardrails.self_check`).
- **Graceful degradation**: if `handoff.digest: true` but an upstream digest is absent (e.g. produced before the flag was on), the consumer falls back to the full doc. No hard failure.

### §5 — Pilot scope and measurement

- **This PR (PR-A)**: full mechanism behind the flag (OFF), wired on **one hop only — scope→arch**:
  - `scope` produces `scope/handoff-digest.md` at handoff.
  - `arch` reads the digest-first (guarded by the flag) and applies the escalation rule.
  - `guardrails` builds arch's traceability from scope's digest (guarded by the flag).
  - All other hops unchanged.
- **Validation** (before rollout): run scope→arch on the same input with the flag OFF vs ON. Measure:
  - (a) fresh (cache_creation) tokens of the `arch` fork — via the transcript analyzer written this session.
  - (b) output quality — does arch's architecture still address every FR? Manual comparison of the two arch outputs + traceability completeness.
- **Follow-up PR (PR-B)**, only if validation is green: extend digest production/consumption to all hops and flip `handoff.digest` default to `true`. Version bump accordingly.

## Risks and mitigations

- **Dual source of truth (digest vs full doc)**: mitigated — the digest is generated by the role that owns the doc, in the same handoff, and cites the doc as canonical. The digest never contradicts; it summarizes + points.
- **Quality regression from thinner context**: mitigated — digest-first + explicit escalation rule + full doc always present; validated one hop before broad rollout; default OFF until proven.
- **Savings depend on upstream doc size**: real numbers unknown until the pilot measures them — hence measure-before-extend.

## Files affected (implementation targets)

- `plugin/resources/handoff-digest-template.md` — **new** template (the schema in §1).
- `plugin/skills/scope/SKILL.md` — add digest production at handoff (flag-guarded).
- `plugin/skills/arch/SKILL.md` — Input Prerequisites digest-first + escalation rule (flag-guarded).
- `plugin/resources/guardrails.md` — read digest for the checklist, full doc as fallback (flag-guarded); update Upstream Artifact Mapping.
- `docs/CUSTOMIZATION.md` — document the `handoff.digest` config flag.
- `docs/CHANGELOG.md` + `plugin/.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` — version bump on the rollout PR.

## Verification

1. **Flag OFF = no change**: with `handoff.digest` absent/false, diff scope/arch/guardrails behavior against current `main` — must be identical (no digest read/write path taken).
2. **Flag ON, happy path**: scope writes a well-formed digest; arch consumes it; guardrails builds traceability from it; arch output still covers all FRs.
3. **Flag ON, missing digest**: consumer falls back to full doc without error (graceful degradation).
4. **Token measurement**: analyzer confirms a reduction in arch's fresh tokens, OFF vs ON, on the same input.
5. **qa lint**: `/circle:qa lint` still passes (no gate/registry/domain-detection regressions).
