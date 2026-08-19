# Circle for Codex

## Layout

- `plugin/` is the Claude Code implementation.
- `plugins/circle/` is the Codex implementation.
- `.agents/plugins/marketplace.json` exposes the Codex implementation as `circle@circle`.

The two implementations are deliberately versioned side by side. Do not replace the Codex directory with a raw copy of `plugin/`: Codex uses different manifest fields, skill frontmatter, output paths, and delegation instructions. Byte-identical resources listed in `scripts/sync_shared_resources.py` are canonical in `plugin/resources/` and copied into the Codex package for distribution.

## Install from a local checkout

```bash
codex plugin marketplace add /path/to/claude-plugin-circle
codex plugin add circle@circle
```

Start a new Codex thread after installation so it discovers the updated skills.

## Update Circle for Codex

When a change affects a provider-specific workflow or resource, port the equivalent behavior manually. Shared resources are synchronized automatically. Then run:

```bash
python3 scripts/sync_shared_resources.py
python3 scripts/sync_shared_resources.py --check
python3 "$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py" plugins/circle
python3 "$HOME/.codex/skills/.system/plugin-creator/scripts/update_plugin_cachebuster.py" plugins/circle
codex plugin add circle@circle
```

The cachebuster preserves the semantic version and lets Codex reload the locally updated plugin. Keep the public version aligned with the Claude Code release when the two implementations have equivalent user-visible behavior.
