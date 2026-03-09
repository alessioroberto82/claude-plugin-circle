# BMAD

A circle of AI roles that helps you build software — from initial idea through to working code. Each role has a clear purpose, domain, and accountability. You talk to them in plain language, and they handle the rest.

Every role in this circle operates under the same set of principles — written by our founder Joris to capture the Luscii soul. Growth over ego. Iteration over perfection. Impact over activity. No gold-plating. No fear-driven engineering. These aren't slogans — they shape how every role thinks, prioritizes, and communicates with you.

BMAD follows holacracy: roles have purposes and accountabilities, not job titles or personas. Authority is distributed — each role acts within its domain without asking permission.

BMAD works for everyone on the team: product people, designers, analysts, developers, and documentation writers. No programming knowledge required to get started.

**New to BMAD?** Start with the [Getting Started Guide](docs/GETTING-STARTED.md) — it walks you through your first conversation with no technical setup.

## The Circle

| Command | Role | Accountability |
|---|---|---|
| `/bmad:bmad-scope` | Scope Clarifier | Gathers requirements, writes user stories, clarifies what you're building |
| `/bmad:bmad-arch` | Architecture Owner | Plans how software is structured, documents design decisions (ADRs) |
| `/bmad:bmad-impl` | Implementer | Writes code, reviews implementations |
| `/bmad:bmad-qa` | Quality Guardian | Plans testing strategy, validates quality |
| `/bmad:bmad-ux` | Experience Designer | Designs user interfaces and user journeys |
| `/bmad:bmad-prioritize` | Prioritizer | Prioritizes features, creates product plans (PRDs) |
| `/bmad:bmad-facilitate` | Facilitator | Plans cycles, coordinates the team |
| `/bmad:bmad-security` | Security Guardian | Audits security, models threats, checks compliance |
| `/bmad:bmad-docs` | Documentation Steward | Generates docs from templates |

> **ADR** = Architecture Decision Record — a short document explaining why a technical decision was made.
> **PRD** = Product Requirements Document — describes what a product should do and why.

## Review

| Command | What it does |
|---|---|
| `/bmad:bmad-code-review` | Reviews a pull request using 2 parallel agents with confidence scoring, checking against your project's CLAUDE.md conventions |
| `/bmad:bmad-triage` | Triages incoming PR review comments — decides which to accept, reject, or clarify, then implements fixes |

## Orchestrators

These run multi-step workflows, guiding you through each phase with decision points along the way.

| Command | What it does |
|---|---|
| `/bmad:bmad-greenfield` | Runs the full workflow: Scope Clarifier (requirements) → Prioritizer (product plan) → PRD Validator (quality check) → Experience Designer (design) → Architecture Owner (architecture) → Security review → Facilitator (cycle plan) → Implementer (code) → Quality Guardian (tests). You can skip optional steps. |
| `/bmad:bmad-cycle` | Interactive cycle planning ceremony — 4-step Shape Up process from shaping review to cycle commitment |

> **Shape Up**: BMAD uses [Shape Up](https://basecamp.com/shapeup) for work planning — appetite-based sizing (☕ cappuccino, 🥪 sandwich, 🍲 hutspot) instead of story points, and 4-week cycles instead of sprints.

## Utilities

| Command | What it does |
|---|---|
| `/bmad:bmad-init` | Sets up BMAD for your current project. Run this once per project. Checks for optional tools and offers to install them. |
| `/bmad:bmad-validate-prd` | Validates PRD quality against 8 structured checks. Use after creating a PRD, before architecture design |
| `/bmad:bmad-tdd` | Enforces strict red-green-refactor TDD cycle. Write a failing test, make it pass, refactor. Used standalone or as sub-workflow of the Implementer |
| `/bmad:bmad-shard` | Splits large documents into smaller pieces (called "shards") so roles can work with just the part they need — reduces token usage by ~90% |
| `/bmad:bmad` | Shows project status: what phase you're in, what's been done, and what roles are available |

> **Token** = the unit of text that AI models process. Fewer tokens means faster responses and lower cost.
> **Context sharding** = breaking a large document into focused pieces so each role loads only what it needs.

## Setup

```bash
# Load BMAD for the current session (development/testing)
claude --plugin-dir /path/to/claude-plugin-bmad/plugin

# Or install permanently via the marketplace
claude plugin marketplace add /path/to/claude-plugin-bmad
claude plugin install bmad@bmad
```

Then in any project:

```bash
/bmad:bmad-init          # Set up BMAD for this project
/bmad:bmad-scope         # Start by defining requirements
/bmad:bmad-greenfield    # Or run the full workflow
```

## Dependencies

All dependencies are **optional** — roles work without them and adapt when tools aren't available. `/bmad:bmad-init` detects what's installed and offers setup options.

| Dependency | Type | Group | What it adds |
|---|---|---|---|
| Linear | Cloud MCP | Core | Issue tracking and cycle management for all roles |
| claude-mem | Plugin | Core | Memory that persists across sessions for all roles |
| Notion | Plugin | Extras | The Documentation Steward can publish docs to Notion |
| bmad-mcp | npm | Extras | Additional workflow tools for Greenfield orchestrator |

**Domain-Specific (iOS):**

| Dependency | Type | What it adds |
|---|---|---|
| Cupertino | Brew MCP | Apple documentation and Human Interface Guidelines |
| SwiftUI Expert | Plugin | SwiftUI best practices and patterns |
| Swift LSP | Plugin | Code intelligence for Swift files |

Domain-specific dependencies are auto-detected by `bmad-init` based on project marker files (e.g., `Package.swift` for iOS). See `deps-manifest.yaml` for conditions.

> **MCP** = Model Context Protocol — a way for Claude to connect to external services. Think of it as a plugin for the plugin.

```bash
# First-time setup (interactive — walks you through what to install)
bash plugin/resources/scripts/install-deps.sh

# Check what's installed
bash plugin/resources/scripts/install-deps.sh --check-only

# Update everything
bash plugin/resources/scripts/update-deps.sh
```

The dependency manifest is at `plugin/resources/deps-manifest.yaml`. Per-project overrides go in `config.yaml` under the `dependencies:` key.

## Project Knowledge Packs

**Make BMAD understand your project.** A Knowledge Pack is a set of focused Markdown files in your repo that give every BMAD role deep awareness of your project — its architecture, domain vocabulary, build system, and integrations. CLAUDE.md handles coding standards; the Knowledge Pack handles everything else.

```
your-repo/
└── docs/bmad/           # or Docs/bmad/
    ├── project.md       # Product identity, team, multi-region context
    ├── domain.md        # Domain vocabulary, data models, terminology glossary
    ├── architecture.md  # Layers, DI patterns, navigation, migration boundaries
    ├── build.md         # Build commands, CI pipelines, release process
    ├── integrations.md  # SDKs, APIs, analytics, auth, feature flags
    └── config.yaml      # Template — bmad-init copies to ~/.claude/bmad/projects/
```

### How it works

1. **Knowledge files live in your repo** — committed, versioned, available to the whole team
2. **`config.yaml` maps files to roles** — each role loads only the slices relevant to its accountability
3. **`/bmad:bmad-init` auto-detects the config template** and copies it to `~/.claude/bmad/projects/<project>/`

A new team member clones the repo, runs `/bmad:bmad-init`, and BMAD immediately knows the project. No manual setup.

### Role-aware injection

Not every role needs every file. The config maps knowledge by concern:

| Role | Loads |
|---|---|
| Scope Clarifier, Prioritizer | project + domain |
| Architecture Owner | project + domain + architecture + integrations |
| Implementer | project + domain + architecture + build + integrations |
| Quality Guardian | project + domain + architecture + build |
| Code Review | project + architecture + build |
| Security Guardian | project + architecture + integrations |

### Getting started

1. Create `docs/bmad/` in your repo with the 5 knowledge files
2. Add a `config.yaml` template with `agents.<role>.context_files` mappings
3. Run `/bmad:bmad-init` — it detects and activates the config
4. Every BMAD role now produces project-aware output

See [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) for the full Knowledge Pack configuration guide.

---

## Architecture

### Zero Footprint

BMAD never adds files to your project repository. All outputs are stored in a separate directory on your machine:

```
~/.claude/bmad/projects/<project>/
├── output/
│   ├── scope/        # Requirements
│   ├── arch/         # Architecture, ADRs
│   ├── impl/         # Implementation notes
│   ├── code-review/  # PR review reports
│   ├── triage/       # Triage learnings
│   ├── qa/           # Test plans, reports
│   ├── security/     # Security audits
│   ├── ux/           # UX designs
│   ├── prioritize/   # PRDs
│   ├── facilitate/   # Cycle plans
│   └── docs/         # Generated docs
├── shards/           # Context shards
│   ├── requirements/
│   ├── architecture/
│   └── stories/
├── workspace/        # Temporary working files
└── config.yaml       # Per-project overrides
```

### Role Isolation

Each work role runs in its own isolated context — it starts fresh every time with no leftover state from previous runs. This prevents confusion between phases. Orchestrators and interactive workflows run in your main conversation so they can have multi-turn discussions with you.

### Quality Gates

Built-in safety checks prevent the workflow from advancing when something isn't right:

- **PRD Validation Gate**: If PRD validation fails, the workflow loops back to the Prioritizer for fixes before architecture begins
- **Security Block**: The greenfield orchestrator won't move to implementation if critical security issues are found
- **QA Reject Gate**: If the Quality Guardian rejects the implementation, the workflow sends it back to the Implementer for fixes
- **TDD Compliance**: The Quality Guardian verifies commit history follows the `test(red):` → `feat(green):` → `refactor:` pattern. Hard enforcement blocks merge; soft enforcement warns only
- **Simplicity Assessment**: Before coding, the Implementer evaluates the architecture for overcomplication — flagging unnecessary infrastructure, excessive dependencies, and components not traced to MVP stories. Advisory check; the developer decides whether to simplify
- **Coherence & Scope Drift**: The Quality Guardian verifies that implemented features are traced to PRD requirements (scope drift detection) and that the system works as an integrated whole (consistent patterns, no circular dependencies)
- **Completeness Check**: The orchestrator verifies output files exist before moving to the next step

### Context Sharding

Large documents (like a PRD or architecture spec) can be split into small, focused pieces called "shards":

```bash
/bmad:bmad-shard                    # Split documents into shards
/bmad:bmad-impl STORY-001          # Implement one story at a time
```

Each invocation loads only the relevant shard (~300 tokens instead of ~5,000), making roles faster and cheaper to run.

### MCP Integration

Roles connect to external services through MCP (Model Context Protocol) when available. If a service isn't set up, roles simply skip those features — nothing breaks.

| MCP Server | Used By | What it provides |
|---|---|---|
| Linear | All roles | Issue tracking, cycle management |
| claude-mem | All roles | Memory that persists across Claude Code sessions |
| Domain-specific tools | Roles with domain detection | Platform documentation and framework APIs (e.g., Cupertino for iOS) |

## Customization

See [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) for the full guide.

### Per-Project Config

Create `~/.claude/bmad/projects/<project>/config.yaml` to change how roles behave for a specific project:

```yaml
agents:
  bmad-arch:
    context_files:
      - docs/ARCHITECTURE.md
    extra_instructions: |
      This project uses a layered architecture with dependency injection.

  bmad-impl:
    extra_instructions: |
      Follow project coding standards and existing conventions.
```

### Adding Roles

Drop a `SKILL.md` in `plugin/skills/bmad-<name>/`. Auto-discovered.

### Adding Templates

Drop a `.md` in `plugin/resources/templates/docs/` or `software/`.

## Workflows

### New Feature
```
Scope Clarifier → Prioritizer → [PRD Validator] → [Experience Designer] → Architecture Owner → [Security] → [Facilitator] → Implementer (with TDD) → Quality Guardian
```
Steps in brackets are optional.

### Bug Fix
```
Implementer (analyze) → Architecture Owner (review) → Implementer (fix) → Quality Guardian (verify)
```

### Code Review
```
Implementer (implement) → Quality Guardian (test) → Code Review (multi-agent PR review) → Triage (handle feedback) → merge
```

## Soul

The team principles live in `plugin/resources/soul.md` — every role reads them on every invocation. To understand the culture behind BMAD, start there.

## Changelog

See [docs/CHANGELOG.md](docs/CHANGELOG.md).
