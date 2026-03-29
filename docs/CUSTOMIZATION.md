# Circle — Customization Guide

This guide explains how to customize Circle for your team and projects. You can change everything from team principles to individual role behavior.

## Quick Customization

If you just want to tweak how Circle works for your project, here are the most common changes:

| What you want to do | How |
|---|---|
| **Make Circle understand your project** | **Create a Knowledge Pack (see Section 1 below)** |
| Give a role extra instructions for your project | Create a config file (see Section 2 below) |
| Change the team's working principles | Edit `plugin/resources/soul.md` — plain text, takes effect immediately |
| Add a document template for the Documentation Steward | Drop a `.md` file in `plugin/resources/templates/docs/` |
| Add a new role to the circle | Create a folder and skill file (see Section 3 below) |

## Customization Layers

| Layer | What | Where | Friction |
|---|---|---|---|
| **Soul** | Team principles | `plugin/resources/soul.md` | Edit file, instant effect |
| **Knowledge Pack** | Project-aware roles | `docs/circle/` in your repo | Create Markdown files |
| **Per-project config** | Role overrides, templates | `~/.claude/circle/projects/<project>/config.yaml` | Create YAML file |
| **Role behavior** | Role definitions | `plugin/skills/<name>/SKILL.md` | Edit SKILL.md |
| **Templates** | Document templates | `plugin/resources/templates/` | Drop .md file |
| **New role** | Add a circle member | `plugin/skills/<name>/SKILL.md` | Create directory + file |
| **Code review** | PR review with CLAUDE.md compliance | `/circle:code-review <PR>` | Invoke on any open PR |

---

## 1. Project Knowledge Packs

A Knowledge Pack makes Circle understand your project. It's a set of Markdown files committed to your repo that every Circle role can access. CLAUDE.md handles coding standards; the Knowledge Pack handles everything else — domain, architecture, build, integrations.

### Step 1: Create knowledge files

Create `docs/circle/` (or `Docs/circle/`) in your repo with these files:

| File | What to include | Target size |
|---|---|---|
| `project.md` | Product name, team, stakeholders, multi-region context, business rules | ~80 lines |
| `domain.md` | Domain vocabulary, data types, terminology glossary, canonical names | ~120 lines |
| `architecture.md` | Layer diagram, DI patterns, navigation, state management, migration boundaries | ~150 lines |
| `build.md` | Build commands, CI pipelines, test commands, release process, environments | ~80 lines |
| `integrations.md` | SDKs, health platforms, analytics, auth, feature flags, project management | ~100 lines |

Each file starts with a metadata comment for staleness tracking:

```markdown
<!-- circle-knowledge | last-reviewed: 2026-03-04 | owner: @yourhandle -->
# Your Title

Content organized with ## headers...
```

For cross-platform projects sharing domain vocabulary, add a sync marker:

```markdown
<!-- shared-origin: my-domain | sync-with: other-repo/docs/circle/domain.md -->
```

### Step 2: Create config template

Add `docs/circle/config.yaml` to your repo. This maps knowledge files to Circle roles:

```yaml
project:
  name: my-project
  domain: software

reading_order:
  - CLAUDE.md
  - soul.md

agents:
  scope:
    context_files:
      - docs/circle/project.md
      - docs/circle/domain.md

  arch:
    context_files:
      - docs/circle/project.md
      - docs/circle/domain.md
      - docs/circle/architecture.md
      - docs/circle/integrations.md
    extra_instructions: |
      Use domain-specific skills for architecture decisions.

  impl:
    context_files:
      - docs/circle/project.md
      - docs/circle/domain.md
      - docs/circle/architecture.md
      - docs/circle/build.md
      - docs/circle/integrations.md
    extra_instructions: |
      Run build verification before committing.

  qa:
    context_files:
      - docs/circle/project.md
      - docs/circle/domain.md
      - docs/circle/architecture.md
      - docs/circle/build.md

  code-review:
    context_files:
      - docs/circle/project.md
      - docs/circle/architecture.md
      - docs/circle/build.md

  ux:
    context_files:
      - docs/circle/project.md
      - docs/circle/domain.md

  security:
    context_files:
      - docs/circle/project.md
      - docs/circle/architecture.md
      - docs/circle/integrations.md
```

### Step 3: Activate

Run `/circle:init`. It detects the config template at `docs/circle/config.yaml` and copies it to `~/.claude/circle/projects/<project>/config.yaml`. Every Circle role now loads project knowledge automatically.

New team members: clone the repo → `/circle:init` → done.

### Design principles

- **Complement, don't duplicate**: CLAUDE.md owns coding standards. Knowledge Pack owns domain, architecture, build, integrations. Never overlap.
- **Shard by concern, not by role**: 5 files by topic. Roles compose what they need via config. One vocabulary change propagates to all roles.
- **Budget tokens**: Keep each file under 500 lines (~2000 tokens). The heaviest role (Implementer) loads ~5000 tokens of knowledge pack — about 2.5% of the context window.
- **Dual purpose**: Knowledge files serve as both AI context and human-readable project documentation.

---

## 2. Per-Project Configuration

This is a settings file that tells Circle roles how to behave differently for a specific project. You can create it manually or use a Knowledge Pack config template (see above).

Create `~/.claude/circle/projects/<project-name>/config.yaml`:

```yaml
# What kind of project this is (software, business, personal, or general)
domain: software

# Which optional steps to include in the full workflow
# Note: security is always mandatory and cannot be disabled
greenfield_defaults:
  ux: true           # Include UX design phase
  facilitate: false   # Skip sprint planning

# Instructions for specific roles
agents:
  arch:
    context_files:
      - docs/ARCHITECTURE.md
    extra_instructions: |
      This project uses a layered architecture with dependency injection.

  impl:
    extra_instructions: |
      Follow project coding standards and existing conventions.

# TDD (Test-Driven Development)
# Enabled by default. The Implementer enforces red-green-refactor via /circle:tdd.
# The Quality Guardian verifies TDD compliance in commit history.
tdd:
  enabled: true           # Set to false to disable TDD workflow
  enforcement: hard       # hard = QA blocks on violation; soft = QA warns only
```

See `plugin/resources/templates/config-example.yaml` for a full example with all available options.

---

## 3. Adding a New Role

1. Create the directory: `plugin/skills/<name>/`
2. Create `SKILL.md` with this template:

```yaml
---
name: <name>
description: "<Role Name> — <One-line purpose>. <When to use>."
allowed-tools: Read, Grep, Glob, Bash
metadata:
  context: fork            # fork = isolated subagent | same = main conversation
  agent: general-purpose   # Explore, Plan, qa, or general-purpose
  model: sonnet            # opus, sonnet, or haiku
  effort: medium           # low, medium, high, or max
---

# <Role Name>

You energize the **<Role Name>** role in the Circle.

## Soul
Read and embody the principles in `${CLAUDE_PLUGIN_ROOT}/resources/soul.md`.

## Your Role
<2-3 sentences about the role's purpose and accountabilities>

## Domain Detection
<Standard domain detection block>

## Input Prerequisites
<What files to read, error if missing>

## Process
1. <Step-by-step execution>
2. <Save output to ~/.claude/circle/projects/{project}/output/<name>/>

## Handoff
> **<Role Name> — Complete.**
> Output saved to: <path>
> Next suggested role: <recommendation>
```

3. Done. Claude Code auto-discovers the skill.
4. Optionally add to `greenfield/SKILL.md` workflow sequence.

---

## 4. Adding a New Template

1. Drop a `.md` file in the appropriate directory:
   - `plugin/resources/templates/docs/` — for the Documentation Steward
   - `plugin/resources/templates/software/` — for roles (PRD, architecture, etc.)

2. Use `{placeholder}` patterns for dynamic content.

3. The Documentation Steward will automatically discover and list new templates in the docs/ directory.

---

## 5. Modifying the Soul

Edit `plugin/resources/soul.md`. Changes take effect on the next skill invocation.

The Soul is loaded by every role and sets the behavioral foundation. It includes both team principles and holacracy alignment guidelines. Keep it concise and principle-based.

---

## 6. Adding to the Greenfield Workflow

To add a new role to the greenfield orchestrator:

1. Edit `plugin/skills/greenfield/SKILL.md`
2. Add the role to the workflow sequence
3. Add to the "Role Sequence Detail" table
4. Add checkpoint handling in the execution phase

---

## 7. Model & Effort Routing

Circle assigns a default Claude model and effort level to each fork-context role based on task complexity. Model controls which Claude model runs; effort controls reasoning depth within that model.

### Default Assignments

| Role | Default Model | Default Effort | Rationale |
|------|--------------|----------------|-----------|
| Scope Clarifier | sonnet | medium | Structured requirements gathering |
| Refiner | sonnet | medium | Feature prioritization |
| Experience Designer | sonnet | medium | UX design patterns |
| Architecture Owner | opus | high | Deep trade-off reasoning |
| Security Guardian | opus | high | Adversarial threat modeling |
| Facilitator | haiku | low | Lightweight coordination |
| Implementer | opus | high | Code generation quality |
| PRD Validator | sonnet | low | Checklist-based validation |
| Quality Guardian | sonnet | medium | Criteria-based validation |

Code review agents (spawned by `code-review` via Task tool) also default to **sonnet**. Configure via `code_review.agent_a_model` and `code_review.agent_b_model` in config.yaml. Note: `code-review` itself is same-context and inherits the session model — only its spawned agents are configurable.

### Override via config.yaml

```yaml
agents:
  arch:
    model: opus       # deep reasoning tasks
    effort: high      # high reasoning depth
  scope:
    model: sonnet     # structured tasks
    effort: medium    # moderate reasoning depth
  facilitate:
    model: haiku      # lightweight tasks
    effort: low       # minimal reasoning depth

# Code review agent models
code_review:
  agent_a_model: sonnet
  agent_b_model: sonnet
```

### Effort Levels

| Level | Use for |
|-------|---------|
| `low` | Checklist validation, lightweight coordination, boilerplate |
| `medium` | Structured gathering, prioritization, criteria-based QA |
| `high` | Architecture design, security modeling, code generation |
| `max` | Complex multi-system reasoning (use sparingly) |

**Precedence**: config.yaml > session-state.json > skill frontmatter default

### How It Works

- **Fork-context skills** (`context: fork`) specify `model:` and `effort:` in frontmatter metadata. Orchestrators pass these when presenting role invocations.
- **Same-context skills** (`context: same`) inherit the session model and cannot be overridden.
- **Config overrides** take precedence over frontmatter defaults for both model and effort.

### Cost Implications

Model and effort routing let you optimize cost without sacrificing quality where it matters. Approximate relative cost per token: Opus (5x), Sonnet (1x), Haiku (0.2x). Higher effort levels increase token usage within a session.

---

## 8. Parallel Implementation

When work items are sharded (via `/circle:shard`), greenfield can implement independent tasks in parallel using git worktrees. This reduces wall-clock time for multi-task features.

### How It Works

1. Greenfield detects `shards/tasks/` with ≥2 task files
2. Parses `Dependencies` from each task shard
3. Builds a dependency graph (task-to-task deps only)
4. Groups independent tasks into parallel waves (max 3 concurrent)
5. Launches impl agents in isolated worktrees
6. Merges completed worktrees into the feature branch via `git merge --no-ff`
7. Pauses on merge conflicts for manual resolution

### Configuration

```yaml
parallel:
  enabled: true       # default: true (disable to force sequential impl)
  max_agents: 3       # default: 3, max concurrent worktree agents
```

### When It Activates

Parallel impl runs only when:
- `shards/tasks/` exists with ≥2 task files
- `parallel.enabled` is not `false` in config.yaml

Otherwise, greenfield falls back to sequential implementation silently.

---

## 9. Multi-Domain Support

Circle automatically detects the project domain and adapts role behavior, questions, and output templates.

### Supported Domains

| Domain | Detected by | Template directory |
|--------|------------|-------------------|
| **software** | `package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, `pom.xml`, `*.xcodeproj`, `Makefile`, etc. | `templates/software/` |
| **business** | `business-plan.md`, `market-analysis.md`, `strategy.md` | `templates/business/` |
| **personal** | `goals.md`, `journal.md`, `habits/` folder | `templates/personal/` |
| **general** | Default if no indicators found | — |

### Domain-Specific Role Behavior

These roles adapt their process based on detected domain:

| Role | Business behavior | Personal behavior |
|------|------------------|------------------|
| **Scope** | Market analysis questions, business brief | Goals/aspirations questions, personal brief |
| **Refine** | Business requirements document | Action plan |
| **Security** | Compliance report | Privacy audit |
| **Facilitate** | Quarterly planning | Weekly planning |
| **Arch** | Operational architecture | Systems design |
| **QA** | Validation plan | Progress plan |

### Override Domain

Set domain explicitly in config.yaml:

```yaml
domain: business  # software, business, personal, or general
```

---

## 10. Governance Protocol

Circle supports dynamic role creation through a structured governance protocol based on holacracy's tension-driven governance.

### How It Works

1. **Tension detection** — During work, agent roles detect tasks that fall outside any existing role's scope
2. **Proposal** — The role formulates a tension and proposes a temporary role to the user
3. **Approval** — The user approves or rejects the proposal
4. **Creation** — If approved, a temporary role is created in the conversation context
5. **Promotion** — Temporary roles used 2+ times can be promoted to permanent skills

### Governance Resources

| Resource | Purpose |
|----------|---------|
| `resources/governance-protocol.md` | Tension format, proposal flow, temporary role format, promotion rules |
| `resources/templates/software/role-template.md` | Template for generating new Circle-standard role skills |

### Configuration

The governance protocol is always active in agent roles (via Tension Sensing) and orchestrators (via Temporary Roles). No configuration needed.

---

## 11. Skills Discovery

Discover and install external skills from the marketplace with a mandatory security gate.

```
/circle:skills-discovery
```

The security gate classifies each skill as PASS, WARN, or BLOCK based on patterns defined in `resources/skill-security-criteria.md`. BLOCK verdicts reject installation; WARN requires explicit user confirmation.

---

## For Developers: Context Model Reference

> This section is for developers who are modifying or creating roles. You can skip this if you're just using Circle.

| Context | When to Use | Effect |
|---|---|---|
| `fork` | Work roles (analysis, design, implementation) | Isolated subagent, clean context, no bleed between runs |
| `same` | Orchestrators, interactive workflows, utilities | Runs in main conversation, supports multi-turn dialogue |

---

## For Developers: Agent Type Reference

> This section is for developers building custom roles.

| Agent Type | When to Use |
|---|---|
| `Explore` | Discovery, analysis, codebase exploration |
| `Plan` | Architecture, design, planning |
| `qa` | Testing, validation, quality checks |
| `general-purpose` | Implementation, coordination, anything else |

---

## For Developers: MCP Integration

> This section is for developers who want to connect Circle roles to external services via MCP (Model Context Protocol).

Roles reference MCP tools (Linear, claude-mem, and domain-specific servers) but degrade gracefully if unavailable. To configure:

- **Linear**: Set up Linear MCP server in Claude Code settings
- **claude-mem**: Install claude-mem plugin for cross-session memory
- **Domain-specific tools**: Configured via `deps-manifest.yaml` groups (e.g., Cupertino for iOS, installed automatically by `init` when domain markers are detected)

Per-project Linear mapping in `config.yaml`:
```yaml
linear:
  team: "My Team"
  project: "My Project"
```
