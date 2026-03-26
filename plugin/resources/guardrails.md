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

### Protocol

1. Extract the list of checkable items from the upstream artifact (FR-*, work items, components, acceptance criteria — depending on your role's "Check For" column above).
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
