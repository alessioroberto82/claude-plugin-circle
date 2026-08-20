# Circle for Codex

Circle uses one universal Agent Skills implementation in `plugins/circle/`. Claude Code and Codex have separate manifests in that directory, but share every core skill and resource.

## Install from a local checkout

```bash
codex plugin marketplace add /path/to/claude-plugin-circle
codex plugin add circle@circle
```

Start a new Codex thread after installation so it discovers the updated skills.

## Validate and reload during development

```bash
python3 "$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py" plugins/circle
python3 "$HOME/.codex/skills/.system/plugin-creator/scripts/update_plugin_cachebuster.py" plugins/circle
codex plugin add circle@circle
```

The cachebuster preserves the semantic version while letting Codex reload local changes. Keep both plugin manifests and the versioned Claude marketplace entry on the same public version.
