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

**Model routing (two layers)**: (1) Fork-context skills pin a specific Claude model ID in frontmatter `metadata.model` (e.g., `claude-opus-4-6`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001`) — Claude Code resolves these when launching the skill. (2) Orchestrators pass the `model` **alias** (`opus`/`sonnet`/`haiku`) to the Task tool — full model IDs are not in the Task tool enum and are silently discarded. The mapping rule (substring match: contains `"opus"`→`"opus"`, `"sonnet"`→`"sonnet"`, `"haiku"`→`"haiku"`; precedence: opus > sonnet > haiku) is applied at every dispatch site. Override per-project in `config.yaml` under `agents.<name>.model` (must use alias; full IDs also work via the mapping rule but aliases are preferred). Same-context skills inherit the session model. **Effort** is NOT supported as a Task tool parameter (upstream: [anthropics/claude-code#14321](https://github.com/anthropics/claude-code/issues/14321)); it is retained in routing tables and step banners for display only.

**Cross-provider note**: family aliases (`opus`/`sonnet`/`haiku`) resolve to **different versions on different providers** — latest on Anthropic API; the previous-major on Bedrock/Vertex unless overridden via `ANTHROPIC_DEFAULT_OPUS_MODEL` (or `_SONNET_`, `_HAIKU_`). This concern applies to the **frontmatter layer** (fork-context skills); the Task tool alias always resolves on the active provider. Bedrock/Vertex users must confirm the pinned frontmatter IDs are available on their provider, or override via `agents.<name>.model`.

**Pinned models — current** (as of v2.1.0):
- Opus: `claude-opus-4-6` → arch, security, impl
- Sonnet: `claude-sonnet-4-6` → scope, refine, ux, qa, validate-prd, code-review.agent_a, code-review.platform_review
- Haiku: `claude-haiku-4-5-20251001` → facilitate, code-review.agent_b

Maintainers: monitor [Anthropic deprecation page](https://docs.claude.com/en/docs/about-claude/model-deprecations) and bump pins when a model is retired. The 12 pin sites are: 9 fork-skill frontmatters + 3 entries in `plugin/skills/code-review/SKILL.md` `metadata.model_routing`. Both `plugin/skills/greenfield/SKILL.md` routing tables (Role table + Role Sequence Detail + the JSON `model_routing` example) must stay in sync — see Gotchas. Note: the 9 fork-skill frontmatters use full IDs (correct); the Task tool dispatch in greenfield and code-review uses aliases (`opus`/`sonnet`/`haiku`). These are different layers — see "Model routing (two layers)" above.

**Holacracy**: Roles have purposes, not personas. Reference roles, not names. External comms use team voice.

## Gotchas

- **Marketplace frontmatter**: Only `name`, `description`, `allowed-tools`, `compatibility`, `license`, `metadata` allowed as top-level fields. `context`/`agent` go inside `metadata:`
- **marketplace.json vs plugin.json**: Different files, different locations (root `.claude-plugin/` vs `plugin/.claude-plugin/`), different purposes
- **Pinned model drift**: when changing a skill's `metadata.model`, also update the corresponding row in `plugin/skills/greenfield/SKILL.md` (Role table at section "Model & Effort Routing", Role Sequence Detail table, AND the `model_routing` JSON example in the session-state schema). Drift is silent at runtime (skill frontmatter wins) but breaks audit consistency and confuses contributors. Note: greenfield routing tables now have two columns (Frontmatter model + Task tool alias) — both must be updated.
- **Task tool model alias**: Orchestrators must pass `"opus"`, `"sonnet"`, or `"haiku"` — not full model IDs — when invoking the Task tool. Full IDs are silently discarded. The mapping rule (substring match) handles both alias and full-ID inputs at dispatch time.
- **Effort not supported at Task tool level**: The Task tool has no `effort` parameter. Do NOT pass `effort:` to Task tool invocations. Effort values in routing tables and step banners are advisory (display only). Upstream tracking: [anthropics/claude-code#14321](https://github.com/anthropics/claude-code/issues/14321).
- **`xhigh` effort is Opus 4.7-only**: do NOT declare `effort: xhigh` on any skill — the plugin pins Opus 4.6 (and Sonnet/Haiku versions that don't support `xhigh`). Stick to `low|medium|high`.
