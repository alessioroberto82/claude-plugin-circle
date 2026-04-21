# circle

Holacracy-based development workflow plugin for Claude Code with distributed roles, quality gates, and Shape Up planning.

## Overview

Circle is a pure Markdown plugin for Claude Code that provides a circle of AI roles to help build software — from initial idea through to working code. The core plugin `circle` ships 18 skills: 9 holacracy roles (Scope Clarifier, Architecture Owner, Implementer, Quality Guardian, Experience Designer, Refiner, Facilitator, Security Guardian, Documentation Steward) and 9 utilities (init, greenfield orchestrator, cycle planning, TDD, context sharding, code review, triage, PRD validation, skills discovery).

The core is domain-agnostic: platform-specific review capabilities are packaged as companion plugins that register via a frontmatter extensibility contract. The companion plugin `circle-ios` ships alongside core in this repository and supplies iOS/Swift review via the same monorepo marketplace listing. See [`docs/extensibility.md`](docs/extensibility.md) for the contract.

Each role has a clear purpose, domain, and accountability following holacracy principles — authority is distributed and roles act within their domain without asking permission. Circle works for product people, designers, analysts, developers, and documentation writers. No programming knowledge is required to get started.

The plugin follows a zero-footprint principle: it never adds files to the user's project repository. All outputs are stored in `~/.claude/circle/projects/<project>/`.

## Stack & Infrastructure

| Layer | Technology | Details |
|---|---|---|
| Format | Pure Markdown | Skills are SKILL.md files with YAML frontmatter |
| Shell scripts | Bash | `install-deps.sh`, `update-deps.sh` for dependency management |
| Plugin system | Claude Code Plugin | Manifest in `plugin/.claude-plugin/plugin.json` |
| Marketplace | Claude Marketplace | Listing in `.claude-plugin/marketplace.json` |
| Version control | Git | GitHub-hosted at `alessioroberto82/claude-plugin-circle` |
| CI/CD | None | No build step, no tests, no CI pipeline |

## Structure

```
├── .claude-plugin/        — Marketplace listing for both plugins (marketplace.json)
├── plugin/                — Core plugin source (namespace: circle)
│   ├── .claude-plugin/    — Plugin manifest (plugin.json)
│   ├── commands/          — /circle dashboard command
│   ├── resources/         — Shared resources
│   │   ├── soul.md        — Team principles (loaded by every role)
│   │   ├── guardrails.md  — Guardrail definitions
│   │   ├── deps-manifest.yaml — Core dependency registry (source of truth)
│   │   ├── work-summary-template.md — Assessment-aware work summary
│   │   ├── scripts/       — install-deps.sh, update-deps.sh
│   │   └── templates/     — Output templates (docs/, software/, business/, personal/)
│   └── skills/            — 18 skills (one SKILL.md per directory)
│       ├── arch/          — Architecture Owner
│       ├── code-review/   — Multi-agent PR review with platform-review dispatch
│       ├── cycle/         — Cycle planning ceremony
│       ├── docs/          — Documentation Steward
│       ├── facilitate/    — Facilitator
│       ├── greenfield/    — Full workflow orchestrator
│       ├── impl/          — Implementer
│       ├── init/          — Project initialization
│       ├── refine/        — Refiner
│       ├── qa/            — Quality Guardian
│       ├── scope/         — Scope Clarifier
│       ├── security/      — Security Guardian
│       ├── shard/         — Context sharding
│       ├── skills-discovery/ — Third-party skill install with security gate
│       ├── tdd/           — TDD Guardian
│       ├── triage/        — PR comment triage
│       ├── ux/            — Experience Designer
│       └── validate-prd/  — PRD Validator
├── plugin-ios/            — Companion plugin source (namespace: circle-ios)
│   ├── .claude-plugin/    — Companion manifest (plugin.json)
│   ├── resources/         — Companion-specific resources
│   │   └── deps-manifest.yaml — iOS/Swift dependency registry
│   └── skills/
│       └── ios-review/    — iOS platform review (registers via metadata.platform_review)
├── docs/                  — Documentation
│   ├── CHANGELOG.md       — Release history
│   ├── CUSTOMIZATION.md   — Configuration guide
│   ├── GETTING-STARTED.md — Onboarding guide
│   ├── extensibility.md   — Platform-review extensibility contract
│   ├── adr/               — Architecture Decision Records
│   └── plans/             — Design documents
└── CLAUDE.md              — Project coding standards
```

## Conventions

- **Naming**: Lowercase for skill names — directories, frontmatter, output paths. `circle` as plugin namespace
- **Context model**: `context: fork` for roles (isolated execution), `context: same` for orchestrators/interactive
- **Zero footprint**: All outputs written to `~/.claude/circle/projects/<project>/`, never to the repo
- **Domain-agnostic core**: Skills never name-drop domain-specific tools in SKILL.md body; domain deps live only in `deps-manifest.yaml`
- **Scripts mirror manifest**: `install-deps.sh` and `update-deps.sh` have hardcoded arrays — any dep change must update both scripts AND the manifest
- **Version bump**: For core, three places must match — `plugin/.claude-plugin/plugin.json`, the `circle` entry in `.claude-plugin/marketplace.json`, and `Luscii/claude-marketplace`. The companion adds a fourth — `plugin-ios/.claude-plugin/plugin.json` — and must stay in sync with its `marketplace.json` entry
- **Workflow order**: arch → security → impl → qa → commit → push → PR → code-review
- **Model routing**: Fork-context skills specify default model in frontmatter `metadata.model`; overridable per-project in `config.yaml`
- **Effort routing**: Fork-context skills declare `metadata.effort` (low/medium/high/max); overridable per-project
- **Holacracy**: Roles have purposes, not personas. Reference roles, not names. External comms use team voice

## Direction

[USER]: Where is this project heading? What are the next 2-3 major milestones?
What constraints shape architectural decisions (e.g., budget, team size, compliance)?
What would you explicitly not change about the current approach?

## Decisions

- **Pure Markdown, no build**: The plugin is entirely Markdown files with YAML frontmatter. No compilation, no tests, no CI. [USER]: Why was this approach chosen over a code-based plugin?
- **Holacracy model**: Roles follow holacracy principles — distributed authority, clear accountabilities, no job titles. [USER]: What drove the choice of holacracy over other team models?
- **Zero repo footprint**: All outputs go to `~/.claude/circle/projects/` — the plugin never writes to the user's repository. [USER]: What motivated this constraint?
- **Shape Up planning**: Appetite-based sizing (cappuccino/sandwich/hutspot) and cycle-based planning instead of sprints and story points. [USER]: Why Shape Up over Scrum or Kanban?
- **Fork context for roles**: Each work role runs in isolated context to prevent cross-phase confusion. [USER]: What problems did shared context cause that led to this?
- **Domain-agnostic core with conditional deps**: Core skills are domain-free; domain-specific tools are declared in `deps-manifest.yaml` and auto-detected at init. [USER]: What drove the separation?

[USER]: What other key architectural decisions have been made? Consider: the choice of Claude Code plugin system, the dependency management approach, the Knowledge Pack pattern.
