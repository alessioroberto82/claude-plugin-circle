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
| arch | `scope/requirements.md` or `refine/PRD.md` | Each FR-*/work item addressed in architecture |
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
