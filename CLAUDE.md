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

**Domain-agnostic core**: Core skills (in `plugin/`) MUST NOT name-drop domain-specific tools, dependencies, or skills in their body. Domain-specific skills live in companion plugins (e.g., `plugin-ios/`) that register via `metadata.platform_review` frontmatter and declare their own deps in the companion's own `deps-manifest.yaml`. Core dispatches to platform skills via the discovery contract in `docs/extensibility.md`. Core deps live only in `plugin/resources/deps-manifest.yaml` with `suggest_in` entries. Exceptions: (a) `## MCP Integration` sections may name cross-domain tools (Linear, claude-mem) available in all domains; (b) multi-language marker-file lists inside **Domain Detection** blocks may enumerate platform markers like `*.xcodeproj`, `Cargo.toml`, `Package.swift`, `package.json` — as long as the list spans multiple languages and is used only for detection, not for naming a companion skill/tool.

**Scripts mirror manifest**: `install-deps.sh` and `update-deps.sh` have hardcoded arrays — they do NOT parse `deps-manifest.yaml`. Any dep change must update both scripts AND the manifest.

**Version bump**: After feature work, update version in `plugin.json` and add a release entry to `docs/CHANGELOG.md`. After merge, sync `marketplace.json` AND Luscii/claude-marketplace. Three places must match for core (`plugin/.claude-plugin/plugin.json`, `circle` entry in `marketplace.json`, Luscii); four when the companion is touched (`plugin-ios/.claude-plugin/plugin.json` mirrors its `marketplace.json` entry).

**Workflow order**: arch → security (P0 blocks impl) → impl (simplicity assessment first) → qa (coherence check + REJECT loops to impl) → commit → push → PR → code-review. Never suggest `/circle:code-review` before a PR exists.

**TDD**: On by default. `impl` uses `/circle:tdd` for red-green-refactor. `qa` verifies via commit history. Disable: `tdd.enabled: false` in config.yaml. Enforcement: `hard` (blocks) or `soft` (warns).

**Model routing**: Fork-context skills pin a specific Claude model ID in frontmatter `metadata.model` (e.g., `claude-opus-4-6`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001`) for cost predictability and stable behavior across Anthropic releases. Orchestrators pass the `model` parameter to Task tool. Override per-project in `config.yaml` under `agents.<name>.model` (accepts both alias and full ID). Same-context skills inherit the session model.

**Cross-provider note**: family aliases (`opus`/`sonnet`/`haiku`) resolve to **different versions on different providers** — latest on Anthropic API; the previous-major on Bedrock/Vertex unless overridden via `ANTHROPIC_DEFAULT_OPUS_MODEL` (or `_SONNET_`, `_HAIKU_`). The plugin's pinned IDs avoid this divergence; Bedrock/Vertex users must confirm the pinned IDs are available on their provider, or override via `agents.<name>.model`.

**Pinned models — current** (as of v2.1.0):
- Opus: `claude-opus-4-6` → arch, security, impl
- Sonnet: `claude-sonnet-4-6` → scope, refine, ux, qa, validate-prd, code-review.agent_a, code-review.platform_review
- Haiku: `claude-haiku-4-5-20251001` → facilitate, code-review.agent_b

Maintainers: monitor [Anthropic deprecation page](https://docs.claude.com/en/docs/about-claude/model-deprecations) and bump pins when a model is retired. The 12 pin sites are: 9 fork-skill frontmatters + 3 entries in `plugin/skills/code-review/SKILL.md` `metadata.model_routing`. Both `plugin/skills/greenfield/SKILL.md` routing tables (Role table + Role Sequence Detail + the JSON `model_routing` example) must stay in sync — see Gotchas.

**Holacracy**: Roles have purposes, not personas. Reference roles, not names. External comms use team voice.

## Gotchas

- **Marketplace frontmatter**: Only `name`, `description`, `allowed-tools`, `compatibility`, `license`, `metadata` allowed as top-level fields. `context`/`agent` go inside `metadata:`
- **marketplace.json vs plugin.json**: Different files, different locations (root `.claude-plugin/` vs `plugin/.claude-plugin/`), different purposes
- **Pinned model drift**: when changing a skill's `metadata.model`, also update the corresponding row in `plugin/skills/greenfield/SKILL.md` (Role table at section "Model & Effort Routing", Role Sequence Detail table, AND the `model_routing` JSON example in the session-state schema). Drift is silent at runtime (skill frontmatter wins) but breaks audit consistency and confuses contributors.
- **`xhigh` effort is Opus 4.7-only**: do NOT declare `effort: xhigh` on any skill — the plugin pins Opus 4.6 (and Sonnet/Haiku versions that don't support `xhigh`). Stick to `low|medium|high`.
