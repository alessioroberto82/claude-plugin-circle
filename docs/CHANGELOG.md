# Changelog

## v0.10.0 — Project Knowledge Packs

### Knowledge Packs

BMAD roles can now understand your project deeply — not just coding standards (CLAUDE.md), but domain vocabulary, architecture patterns, build pipelines, and integrations. Create a set of Markdown files in `docs/bmad/` in your repo, and every role loads the relevant slices automatically.

- **5 knowledge files**: `project.md`, `domain.md`, `architecture.md`, `build.md`, `integrations.md`
- **Role-aware injection**: each role loads only what it needs via `config.yaml` `context_files` mapping
- **Team distribution**: config template lives in the repo; `bmad-init` auto-detects and copies it
- **Complement, don't duplicate**: Knowledge Pack owns domain/architecture/build/integrations; CLAUDE.md owns coding standards

### bmad-init Config Template Detection

`/bmad:bmad-init` now searches for a config template at `docs/bmad/config.yaml` (or `Docs/bmad/`, `.bmad/`) in the repo. If found, it copies it to `~/.claude/bmad/projects/<project>/config.yaml` automatically. New team members: clone → `/bmad:bmad-init` → project-aware BMAD.

See [Customization Guide — Section 1](CUSTOMIZATION.md) for the full Knowledge Pack setup guide.

## v0.9.0 — Anti-Overcomplication & Coherence

### Simplicity Assessment (bmad-impl)

The Implementer now evaluates the architecture for overcomplication before writing code. It checks for unnecessary infrastructure, excessive dependencies, and components not traced to MVP user stories. This is an advisory check — the developer decides whether to simplify.

- **Enabled by default** — no config needed
- **Advisory only** — does not block implementation
- **Simplification decisions** are recorded in implementation notes

### Coherence & Scope Drift Check (bmad-qa)

The Quality Guardian now verifies big-picture coherence and detects scope drift during verification. It traces implemented components back to PRD user stories and checks for consistent patterns, missing integration points, and circular dependencies.

- **Enabled by default** — integrated into existing verification mode
- **Uses existing severity system**: scope drift = P1, circular dependency = P0
- **No new config options** — works with existing quality gate behavior

## v0.8.0 — Guardrails Enhancement

### Self-Verification Protocol

Fork-context roles (bmad-arch, bmad-impl, bmad-qa) now verify their output against upstream artifacts before handoff. Each role appends a **Traceability** section to its output document showing coverage of upstream requirements.

- **Enabled by default** — no action required
- **Disable per-project**: add `guardrails.self_check: false` to your `config.yaml`
- **Graceful degradation**: if upstream artifacts don't exist, self-verification is silently skipped

### validate-prd Default Changed

The greenfield workflow now defaults PRD Validation to **enabled** (previously disabled). When starting a new greenfield workflow, PRD Validation will be suggested as default-on.

- **No action required** — you can still opt out during greenfield setup
- **Existing configs preserved**: if your `config.yaml` has `validate_prd: false`, it takes precedence

### New Config Option

```yaml
# Add to your config.yaml if you want to disable self-verification
guardrails:
  self_check: false
```

### New Resource File

`plugin/resources/guardrails.md` — defines the self-verification protocol. Roles read this at runtime alongside `soul.md`.
