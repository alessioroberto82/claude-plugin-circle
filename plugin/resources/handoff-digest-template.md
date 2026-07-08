# Handoff Digest Template

Output this compact digest at handoff **only when** `handoff.digest: true` in the project `config.yaml`. Write it alongside (never instead of) the full document. Target ~300–600 tokens. Fill every section from THIS session's work; do not invent.

```
# Handoff Digest — {role} → {next role}
**Source doc**: {relative path to the full document}   **Domain**: {software|business|personal|general}

## Verifiable items
| ID | Item | One-line essence |
|----|------|------------------|
| FR-1 | {short label} | {one line} |

## Key decisions
- {decision} — {one-line why}

## Interface for next role
- {what the next role needs to begin without opening the full doc}

## Escalation hints
- For detail on {topic}, see §{section} of the source doc
```

## Guidance
- **Verifiable items**: one row per checkable item the downstream role and guardrails must trace (FR-*, NFR, work items, components, acceptance criteria — whatever your role produces). This list IS the guardrails checklist.
- **Key decisions**: only choices that constrain the downstream role (e.g. explicit out-of-scope items, a chosen constraint). Skip narration.
- **Interface for next role**: the minimal contract to start work.
- **Escalation hints**: map topics to source-doc sections so escalation is cheap.
