# Circle — Customization Guide

This guide explains how to customize Circle for your team and projects. You can change everything from team principles to individual role behavior.

## Quick Customization

If you just want to tweak how Circle works for your project, here are the most common changes:

| What you want to do | How |
|---|---|
| **Make Circle understand your project** | **Create a Knowledge Pack (see Section 1 below)** |
| Give a role extra instructions for your project | Create a config file (see Section 2 below) |
| Change the team's working principles | Edit `plugins/circle/resources/soul.md` — plain text, takes effect immediately |
| Add a document template for the Documentation Steward | Drop a `.md` file in `plugins/circle/resources/templates/docs/` |
| Add a new role to the circle | Create a folder and skill file (see Section 3 below) |

## Customization Layers

| Layer | What | Where | Friction |
|---|---|---|---|
| **Soul** | Team principles | `plugins/circle/resources/soul.md` | Edit file, instant effect |
| **Knowledge Pack** | Project-aware roles | `docs/circle/` in your repo | Create Markdown files |
| **Per-project config** | Role overrides, templates | `~/.circle/projects/<project>/config.yaml` | Create YAML file |
| **Role behavior** | Role definitions | `plugins/circle/skills/<name>/SKILL.md` | Edit SKILL.md |
| **Templates** | Document templates | `plugins/circle/resources/templates/` | Drop .md file |
| **New role** | Add a circle member | `plugins/circle/skills/<name>/SKILL.md` | Create directory + file |
| **PR review** | PR review with CLAUDE.md compliance | `/circle:pr-review <PR>` | Invoke on any open PR |

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

  pr-review:
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

Run `/circle:init`. It detects the config template at `docs/circle/config.yaml` and copies it to `~/.circle/projects/<project>/config.yaml`. Every Circle role now loads project knowledge automatically.

New team members: clone the repo → `/circle:init` → done.

### Design principles

- **Complement, don't duplicate**: CLAUDE.md owns coding standards. Knowledge Pack owns domain, architecture, build, integrations. Never overlap.
- **Shard by concern, not by role**: 5 files by topic. Roles compose what they need via config. One vocabulary change propagates to all roles.
- **Budget tokens**: Keep each file under 500 lines (~2000 tokens). The heaviest role (Implementer) loads ~5000 tokens of knowledge pack — about 2.5% of the context window.
- **Dual purpose**: Knowledge files serve as both AI context and human-readable project documentation.

---

## 2. Per-Project Configuration

This is a settings file that tells Circle roles how to behave differently for a specific project. You can create it manually or use a Knowledge Pack config template (see above).

Create `~/.circle/projects/<project-name>/config.yaml`:

```yaml
# What kind of project this is (software, business, personal, or general)
# Detection: software (Package.swift, package.json, etc.), business (business-plan.md,
# market-analysis.md, strategy.md), personal (goals.md, journal.md, habits/)
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

# Handoff digest (Phase 2 — token reduction)
# When true, each role writes a compact handoff-digest.md at handoff and
# downstream roles read it as their primary input (escalating to the full
# document on demand). guardrails builds its Traceability table from the
# digest too. Default false = roles read full upstream docs as before.
# Currently wired on the scope→arch hop only.
handoff:
  digest: false           # Set to true to enable digest handoff
```

See `plugins/circle/resources/templates/config-example.yaml` for a full example with all available options.

---

## 3. Adding a New Role

1. Create the directory: `plugins/circle/skills/<name>/`
2. Create `SKILL.md` with this template:

```yaml
---
name: <name>
description: "<Role Name> — <One-line purpose>. <When to use>."
---

# <Role Name>

You energize the **<Role Name>** role in the Circle.

## Soul
Read and embody the principles in `../../resources/soul.md`.

## Your Role
<2-3 sentences about the role's purpose and accountabilities>

## Domain Detection
<Standard domain detection block>

## Input Prerequisites
<What files to read, error if missing>

## Process
1. <Step-by-step execution>
2. <Save output to ~/.circle/projects/{project}/output/<name>/>

## Handoff
> **<Role Name> — Complete.**
> Output saved to: <path>
> Next suggested role: <recommendation>
```

3. Done. Claude Code and Codex discover the skill through the universal plugin.
4. Optionally add to `greenfield/SKILL.md` workflow sequence.

---

## 4. Adding a New Template

1. Drop a `.md` file in the appropriate directory:
   - `plugins/circle/resources/templates/docs/` — for the Documentation Steward
   - `plugins/circle/resources/templates/software/` — for roles (PRD, architecture, etc.)

2. Use `{placeholder}` patterns for dynamic content.

3. The Documentation Steward will automatically discover and list new templates in the docs/ directory.

---

## 5. Modifying the Soul

Edit `plugins/circle/resources/soul.md`. Changes take effect on the next skill invocation.

The Soul is loaded by every role and sets the behavioral foundation. It includes both team principles and holacracy alignment guidelines. Keep it concise and principle-based.

---

## 6. Adding to the Greenfield Workflow

To add a new role to the greenfield orchestrator:

1. Edit `plugins/circle/skills/greenfield/SKILL.md`
2. Add the role to the workflow sequence
3. Add to the "Role Sequence Detail" table
4. Add checkpoint handling in the execution phase

---

## 7. Host Execution

Circle uses the model, tools, permissions, and delegation mechanism provided by the current host session. Skills must not require Claude- or Codex-specific model routing.

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

## For Developers: MCP Integration

> This section is for developers who want to connect Circle roles to external services via MCP (Model Context Protocol).

Roles can use integrations exposed by the current host but degrade gracefully when they are unavailable. To configure:

- **Linear**: Connect the Linear plugin or MCP integration in the current host
- **Notion**: Connect the Notion plugin or MCP integration in the current host
- **Domain-specific tools**: Install the appropriate companion plugin; shared core skills never install them automatically

Per-project Linear mapping in `config.yaml`:
```yaml
linear:
  team: "My Team"
  project: "My Project"
```
