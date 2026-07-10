# Digest Handoff (PR-A) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire a compact handoff-digest mechanism on the single scope→arch hop, fully behind config flag `handoff.digest` (default OFF), so downstream reads a small digest instead of the full upstream doc — with identical behavior when the flag is off.

**Architecture:** `scope` writes `scope/handoff-digest.md` at handoff (flag-guarded). `arch` reads that digest first and escalates to the full doc on demand (flag-guarded). `guardrails.md` self-verification builds its Traceability table from the digest, falling back to the full doc if the digest is absent (flag-guarded). A new resource template defines the digest schema. All edits are prompt/Markdown — no code.

**Tech Stack:** Pure Markdown plugin for Claude Code. No build, no tests, no CI. "Verification" = grep-based structural checks + manual flag-OFF/ON dry-run against `session-state`/`config.yaml` conventions.

## Global Constraints

- **Domain-agnostic core**: no domain-specific tool names in SKILL bodies outside allowed sections (CLAUDE.md).
- **Flag key**: `handoff.digest`, boolean, nested convention (like `tdd.enabled`, `guardrails.self_check`, `parallel.enabled`). Default **OFF** (treat absent/false identically).
- **Flag OFF ⇒ zero behavioral change**: when off, no digest is read or written; the role reads/writes exactly as on current `main`.
- **Additive**: the full upstream document is ALWAYS still written; the digest never replaces it. Greenfield gates (full-doc filenames) are untouched.
- **Graceful degradation**: flag ON but digest missing ⇒ consumer falls back to the full doc, no hard failure.
- **Scope**: scope→arch hop ONLY. Do not touch refine/ux/impl/qa/security/other hops.
- **No version bump / no default flip** in PR-A (that is PR-B).
- **Branch**: `feat/digest-handoff` (already checked out; spec commit `4c61994` present).
- **Digest path**: `~/.claude/circle/projects/{project}/output/scope/handoff-digest.md`.
- **Digest size target**: ~300–600 tokens.

---

### Task 1: Digest schema template resource

**Files:**
- Create: `plugin/resources/handoff-digest-template.md`

**Interfaces:**
- Produces: the digest schema consumed by Task 2 (producer) and referenced by Tasks 3–4 (consumers). Sections (exact headings): `## Verifiable items`, `## Key decisions`, `## Interface for next role`, `## Escalation hints`. Header line format: `# Handoff Digest — {role} → {next role}` and a `**Source doc**: {path}   **Domain**: {domain}` line.

- [ ] **Step 1: Create the template file**

Create `plugin/resources/handoff-digest-template.md` with exactly:

```markdown
# Handoff Digest Template

Output this compact digest at handoff **only when** `handoff.digest: true` in the
project `config.yaml`. Write it alongside (never instead of) the full document.
Target ~300–600 tokens. Fill every section from THIS session's work; do not invent.

```
# Handoff Digest — {role} → {next role}
**Source doc**: {relative path to the full document}   **Domain**: {software|business|personal|general}

## Verifiable items
| ID | Item | One-line essence |
|----|------|------------------|
| FR-1 | {short label} | {one line} |

## Key decisions
- {decision} — {one-line why}

## Interface for next role
- {what the next role needs to begin without opening the full doc}

## Escalation hints
- For detail on {topic}, see §{section} of the source doc
```

## Guidance
- **Verifiable items**: one row per checkable item the downstream role and
  guardrails must trace (FR-*, NFR, work items, components, acceptance criteria —
  whatever your role produces). This list IS the guardrails checklist.
- **Key decisions**: only choices that constrain the downstream role (e.g. explicit
  out-of-scope items, a chosen constraint). Skip narration.
- **Interface for next role**: the minimal contract to start work.
- **Escalation hints**: map topics to source-doc sections so escalation is cheap.
```

- [ ] **Step 2: Verify structure**

Run: `grep -E "^(## Verifiable items|## Key decisions|## Interface for next role|## Escalation hints)$" plugin/resources/handoff-digest-template.md | wc -l`
Expected: `4`

- [ ] **Step 3: Commit**

```bash
git add plugin/resources/handoff-digest-template.md
git commit -m "feat(resources): add handoff-digest template (Phase 2 PR-A)"
```

---

### Task 2: scope produces the digest at handoff (flag-guarded)

**Files:**
- Modify: `plugin/skills/scope/SKILL.md` (Process section — insert a new step after "Save output", before "MCP Integration"; renumber following steps)

**Interfaces:**
- Consumes: template from Task 1 at `${CLAUDE_PLUGIN_ROOT}/resources/handoff-digest-template.md`.
- Produces: `scope/handoff-digest.md` (read by Tasks 3 and 4). Written only when `handoff.digest: true`.

- [ ] **Step 1: Insert the digest-production step**

In `plugin/skills/scope/SKILL.md`, replace the block starting at "5. **Save output**" through "6. **MCP Integration**" — old text:

```
5. **Save output** to: `~/.claude/circle/projects/$PROJECT_NAME/output/scope/{filename}`

6. **MCP Integration** (if available):
```

with:

```
5. **Save output** to: `~/.claude/circle/projects/$PROJECT_NAME/output/scope/{filename}`

6. **Write handoff digest** (only if enabled): Read `~/.claude/circle/projects/$PROJECT_NAME/config.yaml`. If `handoff.digest` is not `true`, skip this step entirely (default). Otherwise, read `${CLAUDE_PLUGIN_ROOT}/resources/handoff-digest-template.md` and write a filled digest to `~/.claude/circle/projects/$PROJECT_NAME/output/scope/handoff-digest.md`:
   - **Verifiable items**: one row per FR-* and NFR in the requirements doc, each with a one-line essence.
   - **Key decisions**: scope choices that constrain downstream (e.g. explicit Out-of-Scope items).
   - **Interface for next role**: what the Architecture Owner needs to begin.
   - **Escalation hints**: map topics to sections of the source doc (`{filename}`).
   Keep it ~300–600 tokens. The full document from step 5 is always still written — the digest is additive.

7. **MCP Integration** (if available):
```

- [ ] **Step 2: Renumber the remaining steps**

In the same file, apply these exact replacements (Work Summary and Handoff shift by one):

Replace `7. **Work Summary**:` with `8. **Work Summary**:`
Replace `8. **Handoff**:` with `9. **Handoff**:`

- [ ] **Step 3: Verify guard wording and numbering**

Run: `grep -nE "handoff\.digest|Write handoff digest|^8\. \*\*Work Summary|^9\. \*\*Handoff" plugin/skills/scope/SKILL.md`
Expected: 3 matches — the guard mention inside step 6, the step-6 title, `8. **Work Summary**`, `9. **Handoff**` (grep reports each line; confirm no duplicate step numbers remain).

Run: `grep -c "handoff-digest.md" plugin/skills/scope/SKILL.md`
Expected: `1`

- [ ] **Step 4: Verify flag-OFF parity (dry read)**

Read the modified step 6. Confirm the first sentence makes the digest path conditional on `handoff.digest` being `true` and says to skip otherwise. This is the flag-OFF guarantee.

- [ ] **Step 5: Commit**

```bash
git add plugin/skills/scope/SKILL.md
git commit -m "feat(scope): produce handoff digest at handoff when handoff.digest enabled"
```

---

### Task 3: arch reads digest-first with escalation (flag-guarded)

**Files:**
- Modify: `plugin/skills/arch/SKILL.md` (Input Prerequisites section)

**Interfaces:**
- Consumes: `scope/handoff-digest.md` from Task 2.
- Produces: the escalation rule text (referenced conceptually by verification; no downstream code dependency).

- [ ] **Step 1: Add the digest-first block to Input Prerequisites**

In `plugin/skills/arch/SKILL.md`, find the Input Prerequisites list. Replace this exact block:

```
Read requirements from `~/.claude/circle/projects/{project}/output/`:
- Check for: `scope/requirements.md`
- Also check: `refine/PRD.md` (if Refiner has refined requirements)
- If none found: "Requirements missing. Run `/circle:scope` first to gather requirements."
```

with:

```
Read requirements from `~/.claude/circle/projects/{project}/output/`:
- **Digest-first (only if enabled)**: read `~/.claude/circle/projects/{project}/config.yaml`. If `handoff.digest` is `true` AND `scope/handoff-digest.md` exists, read the digest as your PRIMARY input instead of the full doc. **Escalation rule**: if a decision depends on a detail not present in the digest, open the source doc named in the digest (use its Escalation hints to jump to the right section) before proceeding — do not guess. If the flag is off or the digest is absent, fall back to the full doc below (default behavior).
- Check for: `scope/requirements.md`
- Also check: `refine/PRD.md` (if Refiner has refined requirements)
- If none found: "Requirements missing. Run `/circle:scope` first to gather requirements."
```

- [ ] **Step 2: Verify guard + escalation wording**

Run: `grep -nE "Digest-first|handoff\.digest|Escalation rule|do not guess" plugin/skills/arch/SKILL.md`
Expected: at least the 4 phrases present on the inserted lines.

Run: `grep -c "handoff-digest.md" plugin/skills/arch/SKILL.md`
Expected: `1`

- [ ] **Step 3: Verify flag-OFF + fallback parity (dry read)**

Read the inserted bullet. Confirm it (a) gates on `handoff.digest` being `true`, (b) also requires the digest file to exist, (c) explicitly falls back to the full doc otherwise. This guarantees identical behavior when off and graceful degradation when on-but-missing.

- [ ] **Step 4: Commit**

```bash
git add plugin/skills/arch/SKILL.md
git commit -m "feat(arch): read scope handoff digest first with on-demand escalation"
```

---

### Task 4: guardrails builds traceability from the digest (flag-guarded, with fallback)

**Files:**
- Modify: `plugin/resources/guardrails.md` (Upstream Artifact Mapping note + Protocol step 1)

**Interfaces:**
- Consumes: `scope/handoff-digest.md` `## Verifiable items` section (Task 1 schema, produced by Task 2).
- Note: only the arch row of the mapping is in scope for PR-A; other rows keep current behavior.

- [ ] **Step 1: Add a digest note under the Upstream Artifact Mapping table**

In `plugin/resources/guardrails.md`, find this exact line (immediately after the mapping table):

```
Read the upstream artifact from `~/.claude/circle/projects/{project}/output/`. If the first path doesn't exist, try the alternative (e.g., PRD.md if requirements.md is missing).
```

Replace it with:

```
Read the upstream artifact from `~/.claude/circle/projects/{project}/output/`. If the first path doesn't exist, try the alternative (e.g., PRD.md if requirements.md is missing).

**Digest source (only if enabled)**: if `handoff.digest` is `true` in `config.yaml` AND the upstream role wrote a `handoff-digest.md`, take your checklist from that digest's `## Verifiable items` section instead of re-reading the full upstream doc. If the flag is off or no digest exists, use the full artifact as described above (default behavior). For PR-A this applies to the `arch` role reading `scope/handoff-digest.md`; other roles keep reading the full artifact.
```

- [ ] **Step 2: Point Protocol step 1 at the digest when present**

In the same file, replace this exact line:

```
1. Extract the list of checkable items from the upstream artifact (FR-*, work items, components, acceptance criteria — depending on your role's "Check For" column above).
```

with:

```
1. Extract the list of checkable items (FR-*, work items, components, acceptance criteria — per your role's "Check For" column). Source them from the upstream `handoff-digest.md` `## Verifiable items` section when the digest path above applies; otherwise from the full upstream artifact.
```

- [ ] **Step 3: Verify wording**

Run: `grep -nE "Digest source|handoff\.digest|Verifiable items" plugin/resources/guardrails.md`
Expected: the note + step-1 reference present (≥3 matches).

- [ ] **Step 4: Verify flag-OFF parity (dry read)**

Read both edited spots. Confirm each states the digest path is taken only when `handoff.digest` is `true` AND a digest exists, and that the full-doc path remains the default/fallback. Confirm the note scopes PR-A to arch←scope.

- [ ] **Step 5: Commit**

```bash
git add plugin/resources/guardrails.md
git commit -m "feat(guardrails): build traceability from handoff digest with full-doc fallback"
```

---

### Task 5: Document the `handoff.digest` flag

**Files:**
- Modify: `docs/CUSTOMIZATION.md` (config / per-project settings section)

**Interfaces:**
- Consumes: nothing. Produces: user-facing documentation of the flag.

- [ ] **Step 1: Locate the config-options section**

Run: `grep -nE "guardrails|self_check|tdd\.enabled|parallel|config\.yaml" docs/CUSTOMIZATION.md | head`
Expected: shows where per-project `config.yaml` options are documented. Choose the block that lists boolean feature flags (near `guardrails.self_check` / `tdd.enabled`).

- [ ] **Step 2: Add the flag documentation**

Immediately after the existing `guardrails.self_check` (or nearest feature-flag) entry, insert:

```markdown
### `handoff.digest` (default: `false`)

When `true`, each role writes a compact `handoff-digest.md` at handoff and downstream roles read that digest as their primary input (escalating to the full document on demand). The `guardrails` self-verification builds its Traceability table from the digest too. When `false` (default), roles read the full upstream documents exactly as before — no digest is written or read. Currently wired on the scope→arch hop only.

```yaml
handoff:
  digest: true
```
```

(If no feature-flag block exists, add a new `## Config: handoff.digest` section following the file's existing heading style.)

- [ ] **Step 3: Verify**

Run: `grep -nE "handoff\.digest|handoff:|digest: true" docs/CUSTOMIZATION.md`
Expected: the heading + the YAML example present.

- [ ] **Step 4: Commit**

```bash
git add docs/CUSTOMIZATION.md
git commit -m "docs(customization): document handoff.digest config flag"
```

---

## Post-implementation validation (spec §5 — not a code task)

Do this after all tasks land, before writing PR-B:

1. **Flag-OFF parity**: with no `handoff.digest` in `config.yaml`, run a scope→arch dry run (or re-read the three edited files) and confirm no digest read/write path is taken — behavior matches current `main`.
2. **Flag-ON happy path**: set `handoff.digest: true`, run `/circle:scope` then `/circle:arch` on a scratch feature. Confirm: `scope/handoff-digest.md` is created and well-formed (4 schema sections); arch's output still addresses every FR; guardrails' Traceability table is populated from the digest.
3. **Flag-ON missing digest**: with flag on but `scope/handoff-digest.md` deleted, confirm arch and guardrails fall back to the full doc without error.
4. **Token measurement**: use the transcript analyzer (`~/.claude/projects/.../*.jsonl`, `attributionSkill`+`usage`) to compare the `arch` fork's fresh (cache_creation) tokens OFF vs ON on the same input. Record the delta — this decides whether PR-B (extend + flip default) proceeds.
5. **qa lint**: run `/circle:qa lint`; confirm all 8 checks still pass.

## Self-Review notes

- **Spec coverage**: §1 template → Task 1; §1 producer + §4 flag → Task 2; §2 digest-first + escalation → Task 3; §3 guardrails unification → Task 4; §4 config doc → Task 5; §5 pilot/measurement → Post-implementation validation. All spec sections mapped.
- **Type/name consistency**: digest filename `handoff-digest.md`, flag `handoff.digest`, and section headings (`## Verifiable items`, etc.) are used identically across Tasks 1–5.
- **No version bump** in any task (PR-A constraint honored).
