---
name: init
description: Initialize Circle framework for the current project. Creates output directories in home folder (zero project footprint). Checks and installs optional dependencies. Run once per project.
allowed-tools: Read, Grep, Glob, Bash
metadata:
  context: same
  agent: general-purpose
---

# Circle Init

Initialize the Circle-METHOD framework for the current project. All outputs are stored externally in the home directory — nothing is added to the project repository.

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
- `extras` — always shown, marked as optional

Platform-specific deps (iOS, Android, Rust, …) are owned by their companion plugins (e.g., `circle-ios`). Install the companion plugin to get its own dependency prompts — the core `init` skill only handles core + extras.

Check for project-level overrides in `~/.claude/circle/projects/$PROJECT_NAME/config.yaml` under the `dependencies:` key. If a dep is marked `skip`, exclude it. If marked `include`, add it.

**Display dependency status table:**
```
Circle Dependencies
==================

  Core (recommended for all teams):
    [ok]      claude-mem      Cross-session semantic memory
    [manual]  Linear          Enable in Claude Code settings

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

  Extras:
    [3] Notion          — Notion integration                [SKIP]
    [4] bmad-mcp        — BMAD MCP server                   [SKIP]

Enter numbers to toggle, or 'done':
```

After selection, save preferences to `~/.claude/circle/projects/$PROJECT_NAME/config.yaml` under the `dependencies:` key. Then install selected deps.

If all dependencies are already installed, skip the choice prompt and show:
```
All dependencies installed. Proceeding with initialization.
```

### 1. Detect project name

Derive from current directory: `basename "$PWD" | tr '[:upper:]' '[:lower:]'`

### 2. Detect domain

Analyze files in the current directory:
- **software**: if common project markers exist (e.g., `package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, `pom.xml`, `*.xcodeproj`, `Makefile`, `CMakeLists.txt`, `Gemfile`, `build.gradle`)
- **business**: if `business-plan.md`, `market-analysis.md`, or `strategy.md` exists
- **personal**: if `goals.md`, `journal.md`, or `habits/` folder exists
- **general**: default if no domain indicator found

### 3. Create output structure

Zero footprint — all in home directory:
```bash
PROJECT_NAME=$(basename "$PWD" | tr '[:upper:]' '[:lower:]')
BASE=~/.claude/circle/projects/$PROJECT_NAME

mkdir -p $BASE/output/{scope,arch,impl,qa,security,ux,refine,facilitate,docs,code-review,triage}
mkdir -p $BASE/output/sessions
mkdir -p $BASE/shards/{requirements,architecture,tasks}
mkdir -p $BASE/shards/sessions
mkdir -p $BASE/workspace
```

### 4. Create or migrate session state

Check if `~/.claude/circle/projects/$PROJECT_NAME/output/session-state.json` already exists.

**If it does NOT exist** — create a fresh v2 file:
```json
{
  "version": 2,
  "project": "<project-name>",
  "domain": "<detected-domain>",
  "updated": "<ISO-8601 timestamp>",
  "sessions": {}
}
```

**If it exists** — check the `version` field:
- If `version` is `2`: already migrated, skip.
- If `version` is absent or `1`: run **v1 → v2 migration**:

**Migration algorithm** (must be idempotent):
1. Copy the file to `session-state.v1-backup.json` (safety net)
2. Read the existing `workflow` object from root
3. If `workflow.type` is `"none"` or the `workflow` object is empty:
   - Write v2 with empty `sessions: {}`
4. Else (active or completed workflow exists):
   - Generate session ID: `{project}-001`
   - Create a session entry by moving `workflow` fields into it
   - Add `type` from `workflow.type`, `created` from root `created`, `updated` from root `updated`
   - Move root `artifacts` array into the session entry
5. Set `version: 2` at root
6. Remove root fields: `phase`, `workflow`, `artifacts`, `created`
7. Write back to `session-state.json`

**If the file is not valid JSON**: warn the user and offer to back up and create a fresh v2 file.

### 5. Check for project config

- If `~/.claude/circle/projects/$PROJECT_NAME/config.yaml` exists, report it
- If not, search for a config template in the repo:
  - Check: `docs/circle/config.yaml`, `Docs/circle/config.yaml`, `.circle/config.yaml`
  - If found: copy it to `~/.claude/circle/projects/$PROJECT_NAME/config.yaml` and report:
    ```
    Found project Circle config template at <path>. Copied to ~/.claude/circle/projects/<project>/config.yaml
    ```
  - If not found: suggest: "Create `~/.claude/circle/projects/$PROJECT_NAME/config.yaml` for project-specific customization."

### 6. Confirm

```
Circle initialized for: <project-name>
Domain: <detected-domain>
Output: ~/.claude/circle/projects/<project-name>/output/

Dependencies:
  <summary of installed/missing from deps-manifest.yaml check>
  Install missing: bash <plugin-root>/resources/scripts/install-deps.sh
  Update all:      bash <plugin-root>/resources/scripts/update-deps.sh

Available roles:
  /circle:scope       - Scope Clarifier (requirements, work items)
  /circle:arch        - Architecture Owner (design, ADRs, trade-offs)
  /circle:impl        - Implementer (implementation, code review)
  /circle:qa          - Quality Guardian (test strategy, QA)
  /circle:ux          - Experience Designer (UI/UX design)
  /circle:refine      - Refiner (prioritization, roadmap)
  /circle:facilitate  - Facilitator (cycle planning, coordination)
  /circle:security    - Security Guardian (audits, threat modeling)
  /circle:docs        - Documentation Steward (doc generation)

Review:
  /circle:code-review - Multi-agent PR code review with CLAUDE.md compliance
  /circle:triage      - Triage PR review comments

Orchestrators:
  /circle:greenfield - Full workflow (analysis → QA)
  /circle:cycle      - Cycle planning ceremony (Shape Up)

Utilities:
  /circle:validate-prd - Validate PRD quality (8 checks)
  /circle:tdd          - TDD red-green-refactor cycle
  /circle:shard        - Split large documents into shards
  /circle:init         - Project initialization (already done)

Start with: /circle:scope to gather requirements, or /circle:greenfield for the full workflow.
```
