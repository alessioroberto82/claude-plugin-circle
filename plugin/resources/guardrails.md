# Guardrails

## Self-Verification Protocol

Before handoff, verify your output covers upstream requirements. This closes the feedback loop between roles and catches gaps before they compound downstream.

### When to Run
- **Default**: enabled for all fork-context roles
- **Skip if**: project config has `guardrails.self_check: false`
- **Skip if**: upstream artifact does not exist (graceful degradation — do not block the role)

### Upstream Artifact Mapping

| Your Role | Read This | Check For |
|---|---|---|
| arch | `scope/requirements.md` or `refine/PRD.md` (or `scope/handoff-digest.md` if `handoff.digest` enabled) | Each FR-*/work item addressed in architecture |
| impl | `arch/architecture.md` | Each component/module implemented |
| qa | `scope/requirements.md` or `refine/PRD.md` | Each acceptance criterion has a test |
| refine | `scope/requirements.md` | Each FR-* has a work item |
| ux | `refine/PRD.md` | Each work item has UX coverage |
| security | `arch/architecture.md` | Each component has threat analysis |

Read the upstream artifact from `~/.claude/circle/projects/{project}/output/`. If the first path doesn't exist, try the alternative (e.g., PRD.md if requirements.md is missing).

**Digest source (only if enabled)**: if `handoff.digest` is `true` in `config.yaml` AND the upstream role wrote a `handoff-digest.md`, take your checklist from that digest's `## Verifiable items` section instead of re-reading the full upstream doc. If the flag is off or no digest exists, use the full artifact as described above (default behavior). For PR-A this applies to the `arch` role reading `scope/handoff-digest.md`; other roles keep reading the full artifact.

### Protocol

1. Extract the list of checkable items (FR-*, work items, components, acceptance criteria — per your role's "Check For" column). Source them from the upstream `handoff-digest.md` `## Verifiable items` section when the digest path above applies; otherwise from the full upstream artifact.
2. For each item, assess coverage in your output:
   - ✅ **Covered** — explicitly addressed
   - ⚠️ **Partial** — mentioned but incomplete
   - ❌ **Missing** — not addressed
3. Append a `## Traceability` section to your output document:

   | Upstream Item | Status | Notes |
   |---|---|---|
   | {item} | ✅/⚠️/❌ | {brief note} |

4. Update your handoff message:
   - If all ✅: no change needed
   - If any ⚠️: append `Note: {N} items partially covered. See Traceability section.`
   - If any ❌: append `⚠️ {N} upstream items not covered. See Traceability section.`

## Standards Compliance Protocol

Project coding standards are LAW — they are the primary baseline for design and implementation and override Circle defaults, skills, and existing (legacy) patterns. This protocol makes standards ingestion and compliance MANDATORY for the fork-context roles that design or write code (`arch`, `impl`). It is DISTINCT from the Self-Verification Protocol above: that one checks upstream *requirement* coverage; this one checks *coding-standard* compliance.

### When to Run
- **Mandatory** for `arch` and `impl`. Recommended for `qa` and `triage` fixes.
- **Skip if**: project config has `guardrails.standards_check: false`.
- **Graceful degradation**: if NO standards sources are found (see Step 1), say so explicitly in the handoff — do not silently skip the protocol.

### Step 1 — Standards Ingestion (MANDATORY)
Read the following, in order, and treat them as the authoritative baseline:
1. Root `CLAUDE.md`. If it is only an import shim (e.g. a line like `@AGENTS.md`), follow the import and read the target file.
2. Root `AGENTS.md` (if present).
3. `Glob(".claude/rules/*.md")` — load every rule file whose YAML frontmatter `paths:` globs match the files in scope (for `impl`: the files being changed; for `arch`: the feature's target area). When in doubt, load them all.
4. Nested `CLAUDE.md` / `AGENTS.md` in any directory touched by the work, tagged with their scope.
5. Any other `.claude/**/*.md` project-standards docs.

A standard may carry a scope tag — `Overall codebase` (applies to all touched code) vs `New code` (applies only to added/modified lines). Respect the tag. If the project defines `global_rules` in `config.yaml`, treat each entry as a MANDATORY rule with absolute precedence (see the role's Input Prerequisites).

### Step 2 — Compliance Table (MANDATORY output)
Append a `## Standards Compliance` section to your output document (`architecture.md` for `arch`; the implementation notes for `impl`):

| Standard (source § heading) | Status | Evidence |
|---|---|---|
| `.claude/rules/architecture.md` § Use Dependency Injection | ✅/⚠️/❌ | `file:line` — how it complies, or where/how it violates |

- ✅ **Compliant** — explicitly satisfied, with `file:line` evidence.
- ⚠️ **Partial / at-risk** — satisfied loosely, or not verifiable.
- ❌ **Violated** — cite the exact rule text and the offending `file:line`.

Every row MUST cite a specific source (rule file + heading). A claim without a citation is not evidence of compliance. A compiling build or a passing test is NOT sufficient evidence that a standard is met.

### Step 3 — Compound Rules
A single standard heading may carry several independent sub-requirements — bullet points, numbered clauses, or "and" conditions. Check the work against EACH sub-requirement separately. Compliance with one bullet does NOT excuse a violation of another bullet under the same heading. Examples (✅/❌ samples) are ILLUSTRATIVE — they show one instance, not the full boundary of the rule.

### Step 4 — Gate
- All ✅: proceed to handoff.
- Any ⚠️ or ❌: surface it as an explicit tension at your role's checkpoint — state the violated standard, the preferred-layer alternative, and its cost. Do NOT declare the work "done" or hand off while an undisclosed ⚠️/❌ remains. This is bounded: raise the tension and propose the next action; do not unilaterally rewrite beyond the task.
