# Changelog

## v1.4.0 — Multi-Session Workflow Tracking

### Session Registry (schema v2)

`session-state.json` evolves from a single `workflow` object to a `sessions` map supporting multiple concurrent workflows. Each session is keyed by a Linear issue ID (e.g., `ENG-42`) or an auto-generated project counter (`{project}-001`).

- **Schema v2** — `version: 2` field, `sessions` map replaces root `workflow`
- **Artifact isolation** — each session writes to `output/sessions/{id}/{role}/`, preventing cross-session overwrites
- **Session lifecycle** — completed sessions generate a summary, then auto-clean artifacts and registry entry
- **Resume selection** — when multiple sessions are active, `resume` presents a numbered menu; single session auto-selects
- **Multi-session status** — `status` shows a summary table of all active sessions of the requested type
- **v1 migration** — legacy `session-state.json` is auto-migrated on `init` or orchestrator startup (backup created)
- **Session-scoped sharding** — `shard` writes metadata and files to `shards/sessions/{id}/` within orchestrated sessions

### Security Hardening

- **Session ID validation** — Linear IDs validated against `/^[A-Z]{1,10}-\d{1,5}$/`; auto-generated IDs use validated `project` field
- **Path-safety guards** — all session IDs rejected if containing `/`, `\`, or `..`
- **Orphaned session detection** — `resume` verifies artifact directory exists before loading
- **Cleanup safeguards** — recursive delete validates target path is under expected directory

### Skills Changed

| Skill | Change |
|-------|--------|
| `greenfield` | Major — session creation, scoped paths, resume/status selection, cleanup, defensive migration |
| `cycle` | Major — session creation, scoped paths, resume/status selection, cleanup |
| `init` | Medium — v2 schema creation, v1→v2 migration with backup |
| `shard` | Medium — session-scoped sharding paths and metadata |

## v1.3.0 — Holacracy Terminology Alignment

**BREAKING**: Agile/Scrum terminology replaced with Holacracy-aligned vocabulary across all skills. Users with existing `shards/stories/` directories must re-run `/circle:shard` to regenerate under `shards/tasks/`.

### Terminology changes
- `STORY-xxx` → `TASK-xxx` (shard prefix)
- `shards/stories/` → `shards/tasks/` (directory)
- `user story` → `work item` (concept)
- `epic` → `initiative` (grouping)
- `story points` removed (Agile-specific metric)
- `"As a user, I want to..."` → purpose-driven format: `"Enable {actor} to {action} for {outcome}"`
- PRD template: `## User Stories` → `## Work Items`, `### Epic` → `### Initiative`, `US-x.x` → `WI-x.x`

### Files changed
- 10 skill files updated (shard, greenfield, validate-prd, impl, qa, tdd, init, cycle, scope, prioritize)
- `resources/guardrails.md` — upstream artifact mapping
- `resources/templates/software/PRD.md` — PRD template
- `resources/templates/config-example.yaml` — parallel config comments
- `commands/circle.md` — dashboard description

## v1.2.0 — Effort Routing & Parallel Implementation

### Effort Routing

Per-role effort level configuration alongside existing model routing. Each fork-context role declares a default effort level (`low`, `medium`, `high`, `max`) in its frontmatter metadata. Greenfield displays effort in step headers and persists it in session-state.json.

- **9 fork-context skills updated** — scope, prioritize, validate-prd, ux, arch, security, facilitate, impl, qa now declare `metadata.effort`
- **Greenfield model routing table** — expanded to show default effort per role
- **session-state.json** — new `effort_routing` map alongside `model_routing`
- **config.yaml** — `agents.<name>.effort` override per project
- **Precedence**: config.yaml > session-state.json > skill frontmatter default

### Worktree Parallel Implementation

When work items are sharded, greenfield can implement independent tasks in parallel using git worktrees. The orchestrator builds a dependency DAG from task shards, groups independent tasks into execution waves, and launches up to 3 concurrent impl agents in isolated worktrees.

- **Dependency graph** — parses `Dependencies` from task shards, filters to task-to-task deps only
- **Wave execution** — independent tasks grouped into parallel batches (max `parallel.max_agents`)
- **Automatic merge** — `git merge --no-ff` per completed worktree, preserving per-task commit history
- **Conflict handling** — merge conflicts pause the workflow with clear resolution instructions
- **config.yaml** — `parallel.enabled` (default: true) and `parallel.max_agents` (default: 3)
- **Graceful fallback** — no shards or parallel disabled → sequential impl as before

## v1.1.0 — Work Tracking

### Assessment-Aware Work Tracking

All Circle skills now produce enriched Work Summary blocks at handoff, automatically captured by claude-mem's session hooks. Designed to feed `/assessment-daily` in luscii-matrix with rich observations for the Expert/Core & Master self-assessment framework.

- **New skill: `/circle:track`** — Interactive 3-question capture for work outside Circle skills (debugging, mentoring, cross-team collaboration)
- **New resource: `work-summary-template.md`** — Structured template with 6 fields aligned to assessment dimensions (Mastery, Autonomy, Impact, Ownership)
- **12 skills enriched** — arch, impl, qa, scope, prioritize, security, ux, docs, code-review, cycle, facilitate, triage now output Work Summary blocks before handoff
- Graceful degradation: template missing → skip silently; claude-mem unavailable → text still visible in session

## v1.0.0 — Circle

### BMAD → Circle

The plugin has been renamed from "BMAD" to "Circle" — aligning the name with holacracy's core concept. All commands change from `/bmad:bmad-*` to `/circle:*`.

- **Plugin name**: `bmad` → `circle`
- **Skill names**: `bmad-scope` → `scope`, `bmad-arch` → `arch`, etc. (prefix removed)
- **Commands**: `/bmad:bmad-scope` → `/circle:scope`, etc.
- **Output path**: `~/.claude/bmad/` → `~/.claude/circle/`
- **Config keys**: `agents.bmad-scope` → `agents.scope`
- **Repo**: `claude-plugin-bmad` → `claude-plugin-circle`

### Breaking Changes

- All user commands changed
- Output directory moved (no automatic migration)
- Config keys changed (re-create config.yaml)
- Run `/circle:init` after upgrading

## v0.11.0 — Shape Up Workflow

### Shape Up Replaces Scrum

BMAD's workflow now follows Shape Up methodology instead of Scrum. Appetite-based sizing replaces story points. Cycles replace sprints. Pitches replace backlog items.

- **New skill: `bmad-cycle`** — Interactive 4-step cycle planning ceremony (shaping review → appetite sizing → cycle commitment → quality notes). Replaces `bmad-sprint`.
- **Appetite sizing**: ☕ Cappuccino (1 person, ≤2 weeks), 🥪 Sandwich (few people, ≤1 cycle), 🍲 Hutspot (many people, >1 cycle)
- **Pitch-based PRD**: `bmad-prioritize` now generates pitches with problem, appetite, solution sketch, rabbit holes, and no-gos
- **`bmad-facilitate` rewritten**: Produces cycle plans with bets and appetite instead of sprint plans with story points
- **`bmad-greenfield` updated**: References cycle planning instead of sprint planning
- **Removed: `bmad-sprint`** — Use `bmad-cycle` instead

### Breaking Changes

- `/bmad:bmad-sprint` no longer exists — use `/bmad:bmad-cycle`
- Cycle plan output moved from `facilitate/sprint-plan-*.md` to `facilitate/cycle-plan-*.md`
- PRD template no longer includes "Release Plan" section — replaced by "Pitches" section

## v0.10.0 — Project Knowledge Packs

### Knowledge Packs

BMAD roles can now understand your project deeply — not just coding standards (CLAUDE.md), but domain vocabulary, architecture patterns, build pipelines, and integrations. Create a set of Markdown files in `docs/bmad/` in your repo, and every role loads the relevant slices automatically.

- **5 knowledge files**: `project.md`, `domain.md`, `architecture.md`, `build.md`, `integrations.md`
- **Role-aware injection**: each role loads only what it needs via `config.yaml` `context_files` mapping
- **Team distribution**: config template lives in the repo; `bmad-init` auto-detects and copies it
- **Complement, don't duplicate**: Knowledge Pack owns domain/architecture/build/integrations; CLAUDE.md owns coding standards

### bmad-init Config Template Detection

`/bmad:bmad-init` now searches for a config template at `docs/bmad/config.yaml` (or `Docs/bmad/`, `.bmad/`) in the repo. If found, it copies it to `~/.claude/bmad/projects/<project>/config.yaml` automatically. New team members: clone → `/bmad:bmad-init` → project-aware BMAD.

See [Customization Guide — Section 1](CUSTOMIZATION.md) for the full Knowledge Pack setup guide.

## v0.9.0 — Anti-Overcomplication & Coherence

### Simplicity Assessment (bmad-impl)

The Implementer now evaluates the architecture for overcomplication before writing code. It checks for unnecessary infrastructure, excessive dependencies, and components not traced to MVP user stories. This is an advisory check — the developer decides whether to simplify.

- **Enabled by default** — no config needed
- **Advisory only** — does not block implementation
- **Simplification decisions** are recorded in implementation notes

### Coherence & Scope Drift Check (bmad-qa)

The Quality Guardian now verifies big-picture coherence and detects scope drift during verification. It traces implemented components back to PRD user stories and checks for consistent patterns, missing integration points, and circular dependencies.

- **Enabled by default** — integrated into existing verification mode
- **Uses existing severity system**: scope drift = P1, circular dependency = P0
- **No new config options** — works with existing quality gate behavior

## v0.8.0 — Guardrails Enhancement

### Self-Verification Protocol

Fork-context roles (bmad-arch, bmad-impl, bmad-qa) now verify their output against upstream artifacts before handoff. Each role appends a **Traceability** section to its output document showing coverage of upstream requirements.

- **Enabled by default** — no action required
- **Disable per-project**: add `guardrails.self_check: false` to your `config.yaml`
- **Graceful degradation**: if upstream artifacts don't exist, self-verification is silently skipped

### validate-prd Default Changed

The greenfield workflow now defaults PRD Validation to **enabled** (previously disabled). When starting a new greenfield workflow, PRD Validation will be suggested as default-on.

- **No action required** — you can still opt out during greenfield setup
- **Existing configs preserved**: if your `config.yaml` has `validate_prd: false`, it takes precedence

### New Config Option

```yaml
# Add to your config.yaml if you want to disable self-verification
guardrails:
  self_check: false
```

### New Resource File

`plugin/resources/guardrails.md` — defines the self-verification protocol. Roles read this at runtime alongside `soul.md`.
