# circle-ios

Platform-review companion for [claude-plugin-circle](https://github.com/alessioroberto82/claude-plugin-circle). Auto-activates under `/circle:code-review` when iOS markers (`Package.swift`, `*.xcodeproj`, `*.swift`) are detected, or runs standalone via `/circle-ios:ios-review <PR>`.

## Install

```bash
claude plugin marketplace add alessioroberto82/claude-plugin-circle
claude plugin install circle-ios@circle
```

Run `/circle:init` in your iOS project — it detects Package.swift / *.xcodeproj and suggests installing the optional dependencies below.

## Dependencies

All optional. The skill degrades gracefully when missing.

- **Cupertino MCP** — Apple documentation lookup (`brew tap mihaelamj/tap && brew install cupertino`)
- **SwiftUI Expert** — SwiftUI patterns and best practices
- **Swift LSP** — Swift language server
- **Swift Concurrency** — async/await, actors, Sendable
- **Swift Testing Expert** — Swift Testing framework (`#expect`, `#require`)

See `resources/deps-manifest.yaml` for full install commands.

## How dispatch works

The core `circle` plugin's `/circle:code-review` skill scans installed plugins for `metadata.platform_review: true` in their frontmatter. This skill declares it, along with `platform_markers` (Swift file globs). When any of those globs match a file in the PR diff, this skill is invoked in parallel with the core reviewers. See `docs/extensibility.md` in the core repo for the full contract.

## License

MIT.
