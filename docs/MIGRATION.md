# Migration from BMAD-Setup to BMAD Plugin

This guide covers migrating from the original BMAD-Setup (global slash commands + shell script injection) to the BMAD plugin.

## What Changes

| Before (BMAD-Setup) | After (Plugin) |
|---|---|
| `~/.claude/commands/bmad.md` | Plugin skill: `/bmad:bmad-greenfield` |
| `~/.claude/commands/generate-docs.md` | Plugin skill: `/bmad:bmad-docs` |
| `~/.claude/commands/bmad-init.md` | Plugin skill: `/bmad:bmad-init` |
| `~/.claude/commands/bmad-remove.md` | Not needed (zero footprint by default) |
| `~/Documents/BMAD-Setup/soul.md` | `plugin/resources/soul.md` |
| `~/Documents/BMAD-Setup/bmad-section-template.md` | Distributed across 17 SKILL.md files |
| Single conversation role-playing | Real role isolation (`context: fork`) via 17 SKILL.md files |
| No state persistence | `session-state.json` with pause/resume |
| No quality gates | P0 blocks + QA reject gates |
| No token management | Context sharding via `/bmad:bmad-shard` |

## What Changes (v2 — Holacracy Alignment)

If you were using the previous plugin version with named agents (Mary, Winston, etc.), commands and output directories have been renamed:

| Old Command | New Command | Role |
|---|---|---|
| `/bmad:bmad-mary` | `/bmad:bmad-scope` | Scope Clarifier |
| `/bmad:bmad-john` | `/bmad:bmad-prioritize` | Prioritizer |
| `/bmad:bmad-sally` | `/bmad:bmad-ux` | Experience Designer |
| `/bmad:bmad-winston` | `/bmad:bmad-arch` | Architecture Owner |
| `/bmad:bmad-amelia` | `/bmad:bmad-impl` | Implementer |
| `/bmad:bmad-murat` | `/bmad:bmad-qa` | Quality Guardian |
| `/bmad:bmad-bob` | `/bmad:bmad-facilitate` | Facilitator |
| `/bmad:bmad-doris` | `/bmad:bmad-docs` | Documentation Steward |

Output directories have also changed:

| Old Directory | New Directory |
|---|---|
| `output/mary/` | `output/scope/` |
| `output/john/` | `output/prioritize/` |
| `output/sally/` | `output/ux/` |
| `output/winston/` | `output/arch/` |
| `output/amelia/` | `output/impl/` |
| `output/murat/` | `output/qa/` |
| `output/bob/` | `output/facilitate/` |
| `output/doris/` | `output/docs/` |

Config keys have also changed (e.g., `bmad-winston` → `bmad-arch`, `bmad-amelia` → `bmad-impl`). Update your `config.yaml` accordingly.

## What Stays the Same

- Output location: `~/.claude/bmad/projects/<project>/output/`
- Soul principles (now with holacracy section)
- MCP integrations (Linear, claude-mem, and domain-specific servers)
- Zero project footprint
- Session state format

## Migration Steps

### Step 1: Install the Plugin

```bash
# For development/testing
claude --plugin-dir /path/to/claude-plugin-bmad/plugin

# For permanent installation
claude plugin marketplace add /path/to/claude-plugin-bmad
claude plugin install bmad@bmad
```

### Step 2: Remove Old Slash Commands

```bash
rm ~/.claude/commands/bmad.md
rm ~/.claude/commands/bmad-init.md
rm ~/.claude/commands/bmad-remove.md
rm ~/.claude/commands/generate-docs.md
```

### Step 3: Remove BMAD Injection from Projects

For any project where you ran the old `/bmad-init`:

```bash
# In the project directory, remove BMAD markers from CLAUDE.md
cd /path/to/project
# The old bmad-remove command, or manually edit CLAUDE.md
# to remove content between <!-- BMAD-INJECT-START --> and <!-- BMAD-INJECT-END -->
```

### Step 4: Rename Output Directories (v2 migration)

If you have existing outputs from the named-agent version:

```bash
PROJECT=~/.claude/bmad/projects/<project-name>/output
mv $PROJECT/mary $PROJECT/scope 2>/dev/null
mv $PROJECT/john $PROJECT/prioritize 2>/dev/null
mv $PROJECT/sally $PROJECT/ux 2>/dev/null
mv $PROJECT/winston $PROJECT/arch 2>/dev/null
mv $PROJECT/amelia $PROJECT/impl 2>/dev/null
mv $PROJECT/murat $PROJECT/qa 2>/dev/null
mv $PROJECT/bob $PROJECT/facilitate 2>/dev/null
mv $PROJECT/doris $PROJECT/docs 2>/dev/null
```

### Step 5: Update Per-Project Config

If you have a `config.yaml`, update the agent keys:

```yaml
# Before
agents:
  bmad-winston:
    extra_instructions: ...
  bmad-amelia:
    extra_instructions: ...

# After
agents:
  bmad-arch:
    extra_instructions: ...
  bmad-impl:
    extra_instructions: ...
```

Also update greenfield defaults:

```yaml
# Before
greenfield_defaults:
  sally: true
  bob: false

# After
greenfield_defaults:
  ux: true
  facilitate: false
```

### Step 6: Archive BMAD-Setup

The old `~/Documents/BMAD-Setup/` directory is no longer needed. You can archive it:

```bash
mv ~/Documents/BMAD-Setup ~/Documents/BMAD-Setup-archived
```

## Command Mapping

| Old Command | New Command |
|---|---|
| `/bmad <task>` | `/bmad:bmad-greenfield` (full workflow) or invoke roles directly |
| `/bmad-init` | `/bmad:bmad-init` |
| `/bmad-remove` | Not needed |
| `/generate-docs` | `/bmad:bmad-docs` |
| `/bmad:bmad-mary` | `/bmad:bmad-scope` |
| `/bmad:bmad-winston` | `/bmad:bmad-arch` |
| `/bmad:bmad-amelia` | `/bmad:bmad-impl` |
| `/bmad:bmad-murat` | `/bmad:bmad-qa` |
| `/bmad:bmad-sally` | `/bmad:bmad-ux` |
| `/bmad:bmad-john` | `/bmad:bmad-prioritize` |
| `/bmad:bmad-bob` | `/bmad:bmad-facilitate` |
| `/bmad:bmad-doris` | `/bmad:bmad-docs` |
| N/A | `/bmad:bmad-security` (security audit) |
| N/A | `/bmad:bmad-code-review` (multi-agent PR review) |
| N/A | `/bmad:bmad-triage` (review comment handler) |
| N/A | `/bmad:bmad-sprint` (sprint ceremony) |
| N/A | `/bmad:bmad-shard` (context sharding) |
| N/A | `/bmad:bmad-validate-prd` (PRD validation) |
| N/A | `/bmad:bmad-tdd` (TDD enforcement) |
| N/A | `/bmad:bmad` (status dashboard) |

## What Changes (v0.8.0 — Guardrails Enhancement)

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

## Key Improvements After Migration

1. **Real isolation**: Each role runs in its own context — no context pollution between phases
2. **Pause/resume**: Stop mid-workflow, close your laptop, resume tomorrow
3. **Quality gates**: P0 security findings block implementation; QA rejects loop back
4. **Token efficiency**: Shard large documents, load only what's needed
5. **Team adoption**: `claude plugin install` — no more copying files and editing paths
6. **Extensibility**: Add a role = create a directory with SKILL.md. Done.
7. **Holacracy alignment**: Roles have purposes and accountabilities, not personas
8. **TDD by default**: Red-green-refactor cycle enforced by the Implementer, verified by the Quality Guardian

## What Changes (v0.9.0 — Anti-Overcomplication & Coherence)

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
