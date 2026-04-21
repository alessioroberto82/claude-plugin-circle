# Circle Plugin

Pure Markdown plugin for Claude Code. 18 skills (9 holacracy roles + 9 utilities). No build, no tests, no CI.

## Dev

```bash
claude --plugin-dir ./plugin
```

## Layout

```
.claude-plugin/marketplace.json        # Marketplace listing (root, outside plugin/)
plugin/.claude-plugin/plugin.json      # Plugin manifest (name, version)
plugin/commands/circle.md              # /circle dashboard
plugin/resources/soul.md               # Shared principles — every role loads this
plugin/resources/deps-manifest.yaml    # Dependency registry (source of truth)
plugin/resources/scripts/              # install-deps.sh, update-deps.sh
plugin/resources/templates/{docs,software,business,personal}/ # Output templates
plugin/skills/*/SKILL.md               # 18 skills (see ls)
docs/                                  # CHANGELOG.md, CUSTOMIZATION.md, GETTING-STARTED.md
```

## Rules

**Naming**: `<lowercase>` for skill names — dirs, frontmatter, output paths. `circle` as plugin namespace.

**Context model**: `context: fork` for roles, `context: same` for orchestrators/interactive.

**Zero footprint**: All outputs → `~/.claude/circle/projects/<project>/`. Never write to the repo.

**Domain-agnostic core**: Core skills (in `plugin/`) MUST NOT name-drop domain-specific tools, platforms, or frameworks in their body. Domain-specific skills live in companion plugins (e.g., `plugin-ios/`) that register via `metadata.platform_review` frontmatter and declare their own deps in the companion's own `deps-manifest.yaml`. Core dispatches to platform skills via the discovery contract in `docs/extensibility.md`. Core deps live only in `plugin/resources/deps-manifest.yaml` with `suggest_in` entries. Exception: `## MCP Integration` sections may name cross-domain tools (Linear, claude-mem) available in all domains.

**Scripts mirror manifest**: `install-deps.sh` and `update-deps.sh` have hardcoded arrays — they do NOT parse `deps-manifest.yaml`. Any dep change must update both scripts AND the manifest.

**Version bump**: After feature work, update version in `plugin.json` and add a release entry to `docs/CHANGELOG.md`. After merge, sync `marketplace.json` AND Luscii/claude-marketplace. Three places must match.

**Workflow order**: arch → security (P0 blocks impl) → impl (simplicity assessment first) → qa (coherence check + REJECT loops to impl) → commit → push → PR → code-review. Never suggest `/circle:code-review` before a PR exists.

**TDD**: On by default. `impl` uses `/circle:tdd` for red-green-refactor. `qa` verifies via commit history. Disable: `tdd.enabled: false` in config.yaml. Enforcement: `hard` (blocks) or `soft` (warns).

**Model routing**: Fork-context skills specify a default model (opus/sonnet/haiku) in frontmatter `metadata.model`. Orchestrators pass the `model` parameter to Task tool. Override per-project in `config.yaml` under `agents.<name>.model`. Same-context skills inherit the session model.

**Holacracy**: Roles have purposes, not personas. Reference roles, not names. External comms use team voice.

## Gotchas

- **Marketplace frontmatter**: Only `name`, `description`, `allowed-tools`, `compatibility`, `license`, `metadata` allowed as top-level fields. `context`/`agent` go inside `metadata:`
- **marketplace.json vs plugin.json**: Different files, different locations (root `.claude-plugin/` vs `plugin/.claude-plugin/`), different purposes
- **Do not neutralize**: `deps-manifest.yaml`, `init`, `triage` contain domain-specific content by design
