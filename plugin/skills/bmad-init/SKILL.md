---
name: bmad-init
description: Initialize BMAD framework for the current project. Creates output directories in home folder (zero project footprint). Checks and installs optional dependencies. Run once per project.
allowed-tools: Read, Grep, Glob, Bash
metadata:
  context: same
  agent: general-purpose
---

# BMAD Init

Initialize the BMAD-METHOD framework for the current project. All outputs are stored externally in the home directory — nothing is added to the project repository.

## Process

### 0. Check dependencies

Read the dependency manifest at `${CLAUDE_PLUGIN_ROOT}/resources/deps-manifest.yaml`.

For each dependency, run the appropriate check:
- **plugin** type: `claude plugin list 2>/dev/null | grep -q <name>`
- **npm** type: `npm list -g <name> 2>/dev/null | grep -q <name>`
- **mcp-brew** type: `command -v <binary>`
- **mcp-cloud** type: no automated check (mark as "manual")

Auto-detect relevant groups:
- `core` — always relevant
- `ios` — relevant if domain is software AND (`Package.swift` or `*.xcodeproj` exists)
- `extras` — always shown, marked as optional

Check for project-level overrides in `~/.claude/bmad/projects/$PROJECT_NAME/config.yaml` under the `dependencies:` key. If a dep is marked `skip`, exclude it. If marked `include`, add it.

**Display dependency status table:**
```
BMAD Dependencies
==================

  Core (recommended for all teams):
    [ok]      claude-mem      Cross-session semantic memory
    [manual]  Linear          Enable in Claude Code settings

  iOS / Swift development:
    [--]      Cupertino       Apple documentation MCP server
    [ok]      SwiftUI Expert  SwiftUI design patterns
    [--]      Swift LSP       Swift language server

  Additional tools:
    [--]      Notion          Notion workspace integration
    [--]      bmad-mcp        BMAD MCP server

  2 installed, 4 missing, 1 manual
```

If dependencies are missing, offer the user these choices:

```
How would you like to proceed?

  1) Auto-install all missing dependencies
     Runs the install script automatically.

  2) Guided setup (choose one by one)
     For each missing dependency, shows what it does,
     which roles use it, and asks whether to install.

  3) Skip dependency setup
     Continue without installing. Roles degrade gracefully.
     Run later: bash ${CLAUDE_PLUGIN_ROOT}/resources/scripts/install-deps.sh

  4) Customize dependency choices
     Toggle individual dependencies on/off.
     Saves preferences to your project config.
```

**Option 1 (Auto-install)**:
Run:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/resources/scripts/install-deps.sh" --all
```

**Option 2 (Guided setup)**:
For each missing dependency, show:
```
--- <name> (<description>) ---
Used by: <role list>
Command: <install_command>

Install? [y/N]:
```
Run install_command if user confirms. For cloud MCP deps, show the manual instructions.

**Option 3 (Skip)**:
Print the install script path for later use and continue.

**Option 4 (Customize)**:
Show all dependencies across all groups. Let the user toggle each on/off:
```
Toggle dependencies (enter numbers, comma-separated):

  Core:
    [1] claude-mem      — Cross-session memory              [INSTALL]
    [2] Linear          — Issue tracking                    [MANUAL]

  iOS / Swift:
    [3] Cupertino       — Apple docs MCP                    [INSTALL]
    [4] SwiftUI Expert  — SwiftUI patterns                  [INSTALL]
    [5] Swift LSP       — Swift language server             [SKIP]

  Extras:
    [6] Notion          — Notion integration                [SKIP]
    [7] bmad-mcp        — BMAD MCP server                   [SKIP]

Enter numbers to toggle, or 'done':
```

After selection, save preferences to `~/.claude/bmad/projects/$PROJECT_NAME/config.yaml` under the `dependencies:` key. Then install selected deps.

If all dependencies are already installed, skip the choice prompt and show:
```
All dependencies installed. Proceeding with initialization.
```

### 1. Detect project name

Derive from current directory: `basename "$PWD" | tr '[:upper:]' '[:lower:]'`

### 2. Detect domain

Analyze files in the current directory:
- **software**: if common project markers exist (e.g., `package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, `pom.xml`, `*.xcodeproj`, `Makefile`, `CMakeLists.txt`, `Gemfile`, `build.gradle`)
- **general**: default if no software indicator found

### 3. Create output structure

Zero footprint — all in home directory:
```bash
PROJECT_NAME=$(basename "$PWD" | tr '[:upper:]' '[:lower:]')
BASE=~/.claude/bmad/projects/$PROJECT_NAME

mkdir -p $BASE/output/{scope,arch,impl,qa,security,ux,prioritize,facilitate,docs,code-review,triage}
mkdir -p $BASE/shards/{requirements,architecture,stories}
mkdir -p $BASE/workspace
```

### 4. Create session state

Write to `~/.claude/bmad/projects/$PROJECT_NAME/output/session-state.json`:
```json
{
  "project": "<project-name>",
  "domain": "<detected-domain>",
  "phase": "analysis",
  "created": "<ISO-8601 timestamp>",
  "updated": "<ISO-8601 timestamp>",
  "artifacts": [],
  "workflow": {
    "type": "none",
    "current_step": null,
    "completed_steps": [],
    "checkpoints": []
  }
}
```

### 5. Check for project config

- If `~/.claude/bmad/projects/$PROJECT_NAME/config.yaml` exists, report it
- If not, suggest: "Create `~/.claude/bmad/projects/$PROJECT_NAME/config.yaml` for project-specific customization."

### 6. Confirm

```
BMAD initialized for: <project-name>
Domain: <detected-domain>
Output: ~/.claude/bmad/projects/<project-name>/output/

Dependencies:
  <summary of installed/missing from deps-manifest.yaml check>
  Install missing: bash <plugin-root>/resources/scripts/install-deps.sh
  Update all:      bash <plugin-root>/resources/scripts/update-deps.sh

Available roles:
  /bmad:bmad-scope       - Scope Clarifier (requirements, user stories)
  /bmad:bmad-arch        - Architecture Owner (design, ADRs, trade-offs)
  /bmad:bmad-impl        - Implementer (implementation, code review)
  /bmad:bmad-qa          - Quality Guardian (test strategy, QA)
  /bmad:bmad-ux          - Experience Designer (UI/UX design)
  /bmad:bmad-prioritize  - Prioritizer (prioritization, roadmap)
  /bmad:bmad-facilitate  - Facilitator (sprint planning, coordination)
  /bmad:bmad-security    - Security Guardian (audits, threat modeling)
  /bmad:bmad-docs        - Documentation Steward (doc generation)

Review:
  /bmad:bmad-code-review - Multi-agent PR code review with CLAUDE.md compliance
  /bmad:bmad-triage      - Triage PR review comments

Orchestrators:
  /bmad:bmad-greenfield - Full workflow (analysis → QA)
  /bmad:bmad-sprint     - Sprint planning ceremony

Utilities:
  /bmad:bmad-validate-prd - Validate PRD quality (8 checks)
  /bmad:bmad-tdd          - TDD red-green-refactor cycle
  /bmad:bmad-shard        - Split large documents into shards
  /bmad:bmad-init         - Project initialization (already done)

Start with: /bmad:bmad-scope to gather requirements, or /bmad:bmad-greenfield for the full workflow.
```
