# Governance Protocol

This protocol defines how the Circle evolves dynamically. When a role detects a gap in the circle, it follows this protocol to propose new roles — always with human approval.

## Tension Format

When you detect a task outside your scope that no existing Circle role covers, formulate a tension:

```
TENSION DETECTED
================
Gap: [What task or responsibility is missing from the circle]
Suggested Role: <name>
Purpose: [What this role would do in the circle]
Accountabilities:
  - [Responsibility 1]
  - [Responsibility 2]
  - [Responsibility 3]
Domain: software | business | personal | general
```

## Existing Roles Reference

Before proposing a new role, verify the gap is real. These roles already exist:
- **arch**: Architecture design, ADRs, system design
- **code-review**: Multi-agent PR review with context
- **cycle**: Cycle planning ceremony (Shape Up)
- **docs**: Documentation generation from templates
- **facilitate**: Cycle planning, coordination, blockers
- **greenfield**: Full workflow orchestration
- **impl**: Code implementation, action execution
- **init**: Project initialization
- **qa**: Testing strategy, quality validation
- **refine**: Requirements refinement, PRDs, priorities
- **scope**: Vision, scope, briefs
- **security**: Threat modeling, compliance, audits
- **shard**: Document sharding for context management
- **tdd**: TDD red-green-refactor enforcement
- **triage**: PR review comment handling
- **ux**: UI/UX design, wireframes, journeys
- **validate-prd**: PRD quality validation

If an existing role covers the task, suggest invoking that role instead of creating a new one.

## Proposal Flow

1. **Present the tension** to the user using the format above
2. **Offer options**: Approve / Reject / Modify
   - **Approve**: Create the temporary role immediately
   - **Reject**: Continue your current work, no role created
   - **Modify**: User adjusts name, purpose, or accountabilities before creation
3. **If approved**: Create the temporary role in the current session context

## Temporary Role Format

When creating a temporary role after approval, establish it in the conversation with:

```
TEMPORARY ROLE CREATED
======================
Name: <name>
Purpose: [Purpose as approved by user]
Accountabilities:
  - [As approved]
Principles: Follow soul.md (Growth Over Ego, Iteration Over Perfection, Impact Over Activity, Distributed Authority)

This role is active for the current session only.
```

The temporary role:
- Can be invoked by orchestrators as if it were a permanent role
- Follows the same Circle principles from soul.md
- Has no SKILL.md on filesystem (exists only in conversation context)
- Ceases to exist when the session ends

## Promotion Rules

**Usage tracking**: Each time a temporary role is invoked, increment its `uses` counter in the conversation context (stored in `temporary_roles` within the session state). This count persists for the duration of the session.

When the count reaches **2 or more uses**:

1. **Suggest promotion**: "The temporary role <name> has been used N times this session. Would you like to make it permanent?"
2. **If confirmed**: Generate a SKILL.md using the role template at `${CLAUDE_PLUGIN_ROOT}/resources/templates/software/role-template.md`
   - Create directory: `~/.claude/circle/projects/{project}/skills/<name>/`
   - Write `~/.claude/circle/projects/{project}/skills/<name>/SKILL.md` with all standard blocks (frontmatter, soul.md, domain detection, config, process, tension sensing)
   - Use `${CLAUDE_PLUGIN_ROOT}/` for all resource paths (never hardcode absolute paths)
   - Instruct the user to copy the file to `plugin/skills/<name>/` in the repo if they want to persist it in version control
   - Set `promoted: true` in the session state entry for this role
3. **If rejected**: Do not suggest again in this session

## Governance Principles

- **Human-in-the-loop**: Never create a role without explicit user approval
- **Minimal disruption**: Tension sensing should not interrupt normal work flow for minor gaps
- **Single responsibility**: Each proposed role should have a clear, distinct purpose
- **Circle coherence**: New roles should complement, not overlap with, existing roles
