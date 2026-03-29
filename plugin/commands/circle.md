# Circle — Status Dashboard

Show the status of the Circle framework for the current project.

## Process

1. **Detect project name**: `basename "$PWD" | tr '[:upper:]' '[:lower:]'`

2. **Detect domain** by analyzing files in the current directory:
   - **software**: if common project markers exist (e.g., `package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, `pom.xml`, `*.xcodeproj`, `Makefile`, `CMakeLists.txt`, `Gemfile`, `build.gradle`)
   - **general**: default if no software indicator found

3. **Check workflow status**: Read `~/.claude/circle/projects/<project-name>/output/session-state.json` if it exists.
   - If it exists: show current phase, active workflow, completed steps
   - If it doesn't exist: indicate Circle is not yet initialized for this project

4. **Check existing artifacts**: List files in `~/.claude/circle/projects/<project-name>/output/` if the directory exists. Show each role's output files.

5. **Show simple view** (default):

```
Circle — <project-name>
================================
Domain:  <detected>
Status:  <initialized/not initialized>
Phase:   <current phase from session-state or "Not started">

What's done:
  <List completed steps, e.g. "Requirements (Scope Clarifier)", "Architecture (Architecture Owner)">
  <Or "Nothing yet — run /circle:init to get started">

What's next:
  <Next suggested step based on phase>
  <Or "Run /circle:greenfield for the full workflow">

Your circle:
  /circle:scope       — Scope Clarifier (requirements, work items)
  /circle:arch        — Architecture Owner (design, trade-offs)
  /circle:impl        — Implementer (implementation, code review)
  /circle:qa          — Quality Guardian (testing, quality)
  /circle:ux          — Experience Designer (UI/UX design)
  /circle:refine      — Refiner (prioritization, roadmap)
  /circle:facilitate  — Facilitator (cycle planning)
  /circle:security    — Security Guardian (audits, threat modeling)
  /circle:docs        — Documentation Steward

Workflows:
  /circle:greenfield — Full workflow start to finish
  /circle:cycle      — Cycle planning session (Shape Up)

Review:
  /circle:code-review — PR code review
  /circle:triage      — Handle review feedback

Utilities:
  /circle:validate-prd — PRD quality validation (8 checks)
  /circle:tdd          — TDD red-green-refactor enforcer
  /circle:track        — Capture work for assessment tracking
  /circle:init         — Set up Circle for this project
  /circle:skills-discovery — Discover and install external skills (security-gated)
  /circle:shard        — Split large docs for faster processing

Tip: Type /circle detailed for version info and dependency status.
```

6. **If the user requests "detailed" or "full" view**, also show:

Generated artifacts:
```
Generated artifacts:
  scope/       <list of files or empty>
  arch/        <list of files or empty>
  impl/        <list of files or empty>
  qa/          <list of files or empty>
  security/    <list of files or empty>
  ux/          <list of files or empty>
  refine/      <list of files or empty>
  facilitate/  <list of files or empty>
  code-review/ <list of files or empty>
  triage/      <list of files or empty>
  docs/        <list of files or empty>

Output directory: ~/.claude/circle/projects/<project-name>/output/
```

Active workflow details:
```
Active workflow: <greenfield/cycle/none>
Completed steps: <list or N/A>
```

TDD configuration:
```
TDD:
  Enabled:     <true/false from config.yaml, default: true>
  Enforcement: <hard/soft from config.yaml, default: hard>
```

Check dependency versions: Read `~/.claude/plugins/installed_plugins.json` and check system binaries to show current versions.

```
Dependencies:
  Core:
    claude-mem      <version>
    Linear          cloud (managed by Claude)

  Extras:
    bmad-mcp        <version from npm list -g bmad-mcp>
    Notion          <version>

  Domain-Specific (if detected):
    <list installed domain deps from deps-manifest.yaml>

  Local:
    circle  <version from plugin.json>

  Setup:  bash ${CLAUDE_PLUGIN_ROOT}/resources/scripts/install-deps.sh
  Update: bash ${CLAUDE_PLUGIN_ROOT}/resources/scripts/update-deps.sh
```
