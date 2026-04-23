# Platform-Review Extensibility Contract

Any Claude Code plugin may register as a platform-review target for Circle's
`code-review` skill by adding this frontmatter to a SKILL.md:

```yaml
---
name: <platform>-review
metadata:
  platform_review: true          # marks this skill as a platform dispatch target
  platform_markers:              # globs that indicate this skill applies to the diff
    - "<glob1>"
    - "<glob2>"
---
```

When a user runs `/circle:code-review <PR>`, the core `code-review` skill:

1. Scans the available-skills list surfaced by the harness for skills with
   `metadata.platform_review: true`.
2. For each matching skill, reads its `metadata.platform_markers` glob list.
3. Matches each glob against the paths in `gh pr diff --name-only`.
4. The first skill whose markers hit becomes the dispatch target. If multiple
   skills match, the tie is broken alphabetically by the **surfaced skill id**
   (e.g., `circle-ios:ios-review`), not by the SKILL frontmatter `name`. The
   report logs the collision using that id.
5. The target is invoked via the Skill tool in parallel with Agents A and B,
   receiving: PR number, diff content, repo-root `CLAUDE.md`.

If no platform skill matches, the core runs Agents A + B only — no regression
on non-platform projects.

## Return contract

The dispatched skill must return findings as a JSON array using the same shape
core's own Agents A and B produce, so they flow through the same confidence
filter without translation:

```json
[
  {
    "category": "<string>",
    "file": "<path>",
    "lines": "<start>-<end>",
    "description": "<what's wrong>",
    "source": "<citation — Apple doc, framework, spec, etc.>",
    "confidence": <0-100>
  }
]
```

Field notes:

- `lines` is a range string (e.g., `"148-156"`), not an int — covers single-line
  findings too (`"150-150"`).
- `confidence` is the 0-100 scale used across Circle code review. Core applies
  the same confidence threshold to dispatched findings as to its own agents
  (90 normally, 75 for foundational files).
- `description` is the short human-readable finding text — core quotes it
  verbatim in the posted review comment.

Core merges these findings into the unified review report, labelled with the
dispatched skill's name so reviewers can see who contributed what.

## Example — `android-review`

```yaml
---
name: android-review
description: Android/Kotlin platform review
allowed-tools: Read, Grep, Glob, Bash(gh pr diff:*), Bash(gh pr view:*)
metadata:
  platform_review: true
  platform_markers:
    - "**/build.gradle"
    - "**/build.gradle.kts"
    - "**/*.kt"
  context: fork
---
```

That is the entire contract. No core changes needed to add new platforms.

## Trust model

> ⚠️ Platform-review plugins receive your PR diff and `CLAUDE.md` on every
> `/circle:code-review` invocation. Install only platform-review plugins you
> trust, the same way you'd evaluate any MCP server or Claude Code plugin.
>
> A malicious plugin with `metadata.platform_review: true` could exfiltrate
> code through any network-capable tool it declares. This is the same trust
> surface as any installed plugin — but worth naming explicitly because the
> auto-dispatch makes it invisible at invocation time.
>
> Providers of the dispatched skill may retain prompt data per their own
> retention policy. Check before installing a platform plugin whose model
> runs on an unfamiliar provider.

## Lint and collision

- If the frontmatter YAML is malformed, the core skips that skill during
  discovery and logs a warning.
- If multiple platform skills match the same diff, the alphabetical-first wins
  and the report explicitly names both so the user can choose which to keep
  installed.

## Privacy and data handling

The dispatched skill runs with its own `allowed-tools` — core does not pass
its tool surface through. The dispatched skill cannot read or write files
outside what its own frontmatter allows.

## Follow-ups (not in v2.0)

- A `metadata.platform_review_priority` integer key for deterministic tie-breaking.
- A `/circle:qa lint` check (Check 10) to validate platform plugins' frontmatter.
- A `retain_diff: false` declaration for privacy-conscious skills.
