# Circle Plugin

Universal Agent Skills plugin for Claude Code and Codex. The shared runtime lives entirely in `plugins/circle/`; there is no provider-specific skill copy.

## Dev

```bash
claude --plugin-dir ./plugins/circle
python3 "$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py" plugins/circle
```

## Layout

```text
.claude-plugin/marketplace.json        # Claude marketplace
.agents/plugins/marketplace.json       # Codex marketplace
plugins/circle/.claude-plugin/plugin.json      # Claude manifest
plugins/circle/.codex-plugin/plugin.json       # Codex manifest
plugins/circle/commands/circle.md              # Claude-only status alias
plugins/circle/resources/                      # Shared resources and templates
plugins/circle/skills/*/SKILL.md               # Shared Agent Skills
plugin-ios/                            # Claude-only iOS companion
```

## Rules

**Agent Skills standard**: Every core `SKILL.md` uses only `name` and `description` frontmatter. Instructions, resource paths, invocation language, and delegation must remain host-neutral.

**Single source**: Never recreate `plugins/circle/`. Both marketplaces point to `plugins/circle/`.

**Zero footprint**: All outputs go to `~/.circle/projects/<project>/`. Never write Circle artifacts to the user's repository.

**Domain-agnostic core**: Core skills must not depend on domain-specific tools. Companion plugins register platform-review skills through `metadata.platform_review` and own their dependencies.

**Optional integrations**: Never install or connect an integration without explicit user confirmation. Shared skills may suggest the host plugin manager but must not contain provider-specific install commands.

**Version alignment**: Keep both plugin manifests and the versioned Claude marketplace entry aligned. The Codex marketplace entry must continue to point to `./plugins/circle`.

**Workflow order**: arch → security → impl → qa → commit → push → PR → pr-review. Security P0 blocks implementation; QA rejection returns to implementation.

**TDD**: Enabled by default. Disable with `tdd.enabled: false` in `~/.circle/projects/<project>/config.yaml`.

**Holacracy**: Roles have purposes, not personas. Reference roles, not names. External communication uses the team voice.
