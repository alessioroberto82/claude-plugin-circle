# circle

Holacracy-based Agent Skills plugin for Claude Code and Codex with distributed roles, quality gates, and Shape Up planning.

## Overview

Circle is a pure Markdown plugin that provides a circle of AI roles to help build software — from initial idea through to working code. The core plugin ships 20 shared Agent Skills: 9 holacracy roles and 11 utilities, including the status dashboard.

The core is domain-agnostic: platform-specific review capabilities are packaged as companion plugins that register via a frontmatter extensibility contract. The companion plugin `circle-ios` ships alongside core in this repository and supplies iOS/Swift review via the same monorepo marketplace listing. See [`plugins/circle/resources/extensibility.md`](plugins/circle/resources/extensibility.md) for the contract.

Each role has a clear purpose, domain, and accountability following holacracy principles — authority is distributed and roles act within their domain without asking permission. Circle works for product people, designers, analysts, developers, and documentation writers. No programming knowledge is required to get started.

The plugin follows a zero-footprint principle: it never adds files to the user's project repository. All outputs are stored in `~/.circle/projects/<project>/`.

## Stack & Infrastructure

| Layer | Technology | Details |
|---|---|---|
| Format | Pure Markdown | Skills are SKILL.md files with YAML frontmatter |
| Plugin system | Claude Code and Codex | Manifests in `plugins/circle/.claude-plugin/` and `plugins/circle/.codex-plugin/` |
| Marketplace | Claude and Codex | Listings in `.claude-plugin/` and `.agents/plugins/` |
| Version control | Git | GitHub-hosted at `alessioroberto82/claude-plugin-circle` |
| CI/CD | None | No build step, no tests, no CI pipeline |

## Structure

```
├── .claude-plugin/        — Claude marketplace
├── .agents/plugins/       — Codex marketplace
├── plugins/circle/                — Core plugin source (namespace: circle)
│   ├── .claude-plugin/    — Claude manifest
│   ├── .codex-plugin/     — Codex manifest
│   ├── commands/          — Claude-only /circle alias
│   ├── resources/         — Shared resources
│   │   ├── soul.md        — Team principles (loaded by every role)
│   │   ├── guardrails.md  — Guardrail definitions
│   │   ├── deps-manifest.yaml — Core dependency registry (source of truth)
│   │   ├── work-summary-template.md — Assessment-aware work summary
│   │   └── templates/     — Output templates (docs/, software/, business/, personal/)
│   └── skills/            — 20 shared Agent Skills
│       ├── arch/          — Architecture Owner
│       ├── pr-review/     — Multi-agent PR review with platform-review dispatch
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
│       ├── status/        — Project status dashboard
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
- **Agent Skills standard**: Shared skills use only `name` and `description` frontmatter and host-neutral instructions
- **Single source**: Both plugin manifests use `plugins/circle/`; no provider-specific skill copy
- **Zero footprint**: All outputs written to `~/.circle/projects/<project>/`, never to the repo
- **Domain-agnostic core**: Skills never name-drop domain-specific tools in SKILL.md body; domain deps live only in `deps-manifest.yaml`
- **Version bump**: Both core manifests and the versioned Claude marketplace entry must match; the Codex marketplace must point to `./plugins/circle`
- **Workflow order**: arch → security → impl → qa → commit → push → PR → pr-review
- **Host execution**: Skills use the current host model, permissions, tools, and delegation mechanism
- **Holacracy**: Roles have purposes, not personas. Reference roles, not names. External comms use team voice

## Direction

[USER]: Where is this project heading? What are the next 2-3 major milestones?
What constraints shape architectural decisions (e.g., budget, team size, compliance)?
What would you explicitly not change about the current approach?

## Decisions

- **Pure Markdown, no build**: The plugin is entirely Markdown files with YAML frontmatter. No compilation, no tests, no CI. [USER]: Why was this approach chosen over a code-based plugin?
- **Holacracy model**: Roles follow holacracy principles — distributed authority, clear accountabilities, no job titles. [USER]: What drove the choice of holacracy over other team models?
- **Zero repo footprint**: All outputs go to `~/.circle/projects/` — the plugin never writes to the user's repository. [USER]: What motivated this constraint?
- **Shape Up planning**: Appetite-based sizing (cappuccino/sandwich/hutspot) and cycle-based planning instead of sprints and story points. [USER]: Why Shape Up over Scrum or Kanban?
- **Host-neutral skills**: Workflow semantics are shared; execution details belong to the current host rather than duplicated skill trees.
- **Domain-agnostic core with conditional deps**: Core skills are domain-free; domain-specific tools are declared in `deps-manifest.yaml` and auto-detected at init. [USER]: What drove the separation?

[USER]: What other key architectural decisions have been made? Consider: the choice of Claude Code plugin system, the dependency management approach, the Knowledge Pack pattern.
