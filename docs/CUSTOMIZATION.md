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
| **Knowledge Pack** | Project-aware roles | `docs/bmad/` in your repo | Create Markdown files |
| **Per-project config** | Role overrides, templates | `~/.claude/circle/projects/<project>/config.yaml` | Create YAML file |
| **Role behavior** | Role definitions | `plugin/skills/<name>/SKILL.md` | Edit SKILL.md |
| **Templates** | Document templates | `plugin/resources/templates/` | Drop .md file |
| **New role** | Add a circle member | `plugin/skills/<name>/SKILL.md` | Create directory + file |
| **Code review** | PR review with CLAUDE.md compliance | `/circle:code-review <PR>` | Invoke on any open PR |

---

## 1. Project Knowledge Packs

A Knowledge Pack makes Circle understand your project. It's a set of Markdown files committed to your repo that every Circle role can access. CLAUDE.md handles coding standards; the Knowledge Pack handles everything else — domain, architecture, build, integrations.

### Step 1: Create knowledge files

Create `docs/bmad/` (or `Docs/bmad/`) in your repo with these files:

| File | What to include | Target size |
|---|---|---|
| `project.md` | Product name, team, stakeholders, multi-region context, business rules | ~80 lines |
| `domain.md` | Domain vocabulary, data types, terminology glossary, canonical names | ~120 lines |
| `architecture.md` | Layer diagram, DI patterns, navigation, state management, migration boundaries | ~150 lines |
| `build.md` | Build commands, CI pipelines, test commands, release process, environments | ~80 lines |
| `integrations.md` | SDKs, health platforms, analytics, auth, feature flags, project management | ~100 lines |

Each file starts with a metadata comment for staleness tracking:

```markdown
<!-- bmad-knowledge | last-reviewed: 2026-03-04 | owner: @yourhandle -->
# Your Title

Content organized with ## headers...
```

For cross-platform projects sharing domain vocabulary, add a sync marker:

```markdown
<!-- shared-origin: my-domain | sync-with: other-repo/docs/bmad/domain.md -->
```

### Step 2: Create config template

Add `docs/bmad/config.yaml` to your repo. This maps knowledge files to Circle roles:

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
      - docs/bmad/project.md
      - docs/bmad/domain.md

  arch:
    context_files:
      - docs/bmad/project.md
      - docs/bmad/domain.md
      - docs/bmad/architecture.md
      - docs/bmad/integrations.md
    extra_instructions: |
      Use domain-specific skills for architecture decisions.

  impl:
    context_files:
      - docs/bmad/project.md
      - docs/bmad/domain.md
      - docs/bmad/architecture.md
      - docs/bmad/build.md
      - docs/bmad/integrations.md
    extra_instructions: |
      Run build verification before committing.

  qa:
    context_files:
      - docs/bmad/project.md
      - docs/bmad/domain.md
      - docs/bmad/architecture.md
      - docs/bmad/build.md

  code-review:
    context_files:
      - docs/bmad/project.md
      - docs/bmad/architecture.md
      - docs/bmad/build.md

  ux:
    context_files:
      - docs/bmad/project.md
      - docs/bmad/domain.md

  security:
    context_files:
      - docs/bmad/project.md
      - docs/bmad/architecture.md
      - docs/bmad/integrations.md
```

### Step 3: Activate

Run `/circle:init`. It detects the config template at `docs/bmad/config.yaml` and copies it to `~/.claude/circle/projects/<project>/config.yaml`. Every Circle role now loads project knowledge automatically.

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
# What kind of project this is (software or general)
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

## 7. Model Routing

Circle assigns a default Claude model to each fork-context role based on task complexity. Opus handles deep reasoning (architecture, security, implementation), Sonnet handles structured work (scope, prioritization, QA), and Haiku handles lightweight coordination.

### Default Assignments

| Role | Default Model | Rationale |
|------|--------------|-----------|
| Scope Clarifier | sonnet | Structured requirements gathering |
| Prioritizer | sonnet | Feature prioritization |
| Experience Designer | sonnet | UX design patterns |
| Architecture Owner | opus | Deep trade-off reasoning |
| Security Guardian | opus | Adversarial threat modeling |
| Facilitator | haiku | Lightweight coordination |
| Implementer | opus | Code generation quality |
| Quality Guardian | sonnet | Criteria-based validation |

Code review agents (spawned by `code-review` via Task tool) also default to **sonnet**. Configure via `code_review.agent_a_model` and `code_review.agent_b_model` in config.yaml. Note: `code-review` itself is same-context and inherits the session model — only its spawned agents are configurable.

### Override via config.yaml

```yaml
agents:
  arch:
    model: opus       # deep reasoning tasks
  scope:
    model: sonnet     # structured tasks
  facilitate:
    model: haiku      # lightweight tasks

# Code review agent models
code_review:
  agent_a_model: sonnet
  agent_b_model: sonnet
```

### How It Works

- **Fork-context skills** (`context: fork`) specify `model:` in frontmatter metadata. Orchestrators pass this to the Task tool's `model` parameter.
- **Same-context skills** (`context: same`) inherit the session model and cannot be overridden.
- **Config overrides** take precedence over frontmatter defaults.

### Cost Implications

Model routing lets you optimize cost without sacrificing quality where it matters. Approximate relative cost per token: Opus (5x), Sonnet (1x), Haiku (0.2x).

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
