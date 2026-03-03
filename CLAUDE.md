# BMAD Plugin

Pure Markdown plugin for Claude Code. 17 skills (9 holacracy roles + 8 utilities). No build, no tests, no CI.

## Dev

```bash
claude --plugin-dir ./plugin
```

## Layout

```
.claude-plugin/marketplace.json        # Marketplace listing (root, outside plugin/)
plugin/.claude-plugin/plugin.json      # Plugin manifest (name, version)
plugin/commands/bmad.md                # /bmad dashboard
plugin/resources/soul.md               # Shared principles — every role loads this
plugin/resources/deps-manifest.yaml    # Dependency registry (source of truth)
plugin/resources/scripts/              # install-deps.sh, update-deps.sh
plugin/resources/templates/{docs,software}/ # Output templates
plugin/skills/bmad-*/SKILL.md          # 17 skills (see ls)
docs/                                  # CUSTOMIZATION.md, GETTING-STARTED.md, MIGRATION.md
```

## Rules

**Naming**: `bmad-<lowercase>` everywhere — dirs, frontmatter, output paths.

**Context model**: `context: fork` for roles, `context: same` for orchestrators/interactive.

**Zero footprint**: All outputs → `~/.claude/bmad/projects/<project>/`. Never write to the repo.

**Domain-agnostic core**: Never name-drop domain-specific tools (Cupertino, SwiftUI Expert) in SKILL.md body. Domain deps live only in `deps-manifest.yaml` with `suggest_in` entries. Exception: `## MCP Integration` sections may name cross-domain tools (Linear, claude-mem).

**Scripts mirror manifest**: `install-deps.sh` and `update-deps.sh` have hardcoded arrays — they do NOT parse `deps-manifest.yaml`. Any dep change must update both scripts AND the manifest.

**Version bump**: After feature work, update version in `plugin.json`. After merge, sync `marketplace.json` AND Luscii/claude-marketplace. Three places must match.

**Workflow order**: arch → security (P0 blocks impl) → impl (simplicity assessment first) → qa (coherence check + REJECT loops to impl) → commit → push → PR → code-review. Never suggest `/bmad-code-review` before a PR exists.

**TDD**: On by default. `bmad-impl` uses `/bmad-tdd` for red-green-refactor. `bmad-qa` verifies via commit history. Disable: `tdd.enabled: false` in config.yaml. Enforcement: `hard` (blocks) or `soft` (warns).

**Model routing**: Fork-context skills specify a default model (opus/sonnet/haiku) in frontmatter `metadata.model`. Orchestrators pass the `model` parameter to Task tool. Override per-project in `config.yaml` under `agents.<name>.model`. Same-context skills inherit the session model.

**Holacracy**: Roles have purposes, not personas. Reference roles, not names. External comms use team voice.

## Gotchas

- **Marketplace frontmatter**: Only `name`, `description`, `allowed-tools`, `compatibility`, `license`, `metadata` allowed as top-level fields. `context`/`agent` go inside `metadata:`
- **marketplace.json vs plugin.json**: Different files, different locations (root `.claude-plugin/` vs `plugin/.claude-plugin/`), different purposes
- **Do not neutralize**: `deps-manifest.yaml`, `bmad-init`, `bmad-triage` contain domain-specific content by design
- **MIGRATION.md**: Contains intentional persona names (Mary, Winston) for migration mapping
