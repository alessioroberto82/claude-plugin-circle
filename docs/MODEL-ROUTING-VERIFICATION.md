# Model Routing Verification Protocol

**Purpose**: confirm that the pinned model IDs declared in each Circle skill's frontmatter are actually applied at runtime when Claude Code dispatches a fork-context skill.

**When to run**: once, after installing or upgrading Circle to v2.1.0 or later, OR after bumping any pinned model ID.

**Why this exists**: the parent session's status line shows the parent model (e.g. `opus 4.7 + xhigh`) and does NOT reflect the model used by sub-agents dispatched via the Task tool. Without this protocol there is no observable signal that per-skill routing works.

---

## Privacy

Do **NOT** paste raw `/cost` output into this CHANGELOG, GitHub issues, or any public artifact. `/cost` may include account-scoped totals, session IDs, or timestamps that you do not want to publish.

When recording results, write only the minimum needed:

> Test X: pass — observed `claude-<family>-<version>`

Strip totals, timestamps, account/session IDs.

---

## Setup

1. Fresh Claude Code session, Circle 2.1.0 (or later) installed via marketplace.
2. Any working directory — a scratch repo is fine. The verification does not modify the repo.
3. Confirm the parent session model is **different** from each pinned model below — otherwise you cannot tell whether the per-skill routing is taking effect or you are just seeing the parent's model leak through. Easiest: use a fresh session with the Anthropic API default (Opus 4.7).

**Effort signal**: `/cost` exposes thinking/reasoning tokens per model row. A skill pinned to `effort: low` (e.g. `facilitate`) should burn substantially fewer thinking tokens than the parent session (which typically runs at `xhigh` on Opus 4.7). If a `low`-effort skill shows high thinking-token volume relative to its output, effort routing is NOT applying — file under "fail" alongside any model-routing failures.

---

## Test A — Sonnet pin verification

**Skill under test**: `/circle:scope` — pinned to `claude-sonnet-4-6`.

1. Run `/circle:scope brief test feature for verification` and let it complete.
2. Run `/cost`.
3. **Pass criterion**: a row for `claude-sonnet-4-6` appears in `/cost` with non-zero token usage.
4. **Fail criterion**: only `claude-opus-4-7` (or whatever the parent session model is) appears, with no `claude-sonnet-4-6` row → routing is broken; apply ADR-004 fallback (see `output/arch/architecture.md`).

Record result: `Test A: <pass|fail> — observed <model id>`

---

## Test B — Opus 4.6 pin verification

**Skill under test**: `/circle:arch` — pinned to `claude-opus-4-6`.

1. With requirements in place (e.g. from Test A), run `/circle:arch`.
2. Run `/cost`.
3. **Pass criterion**: a row for `claude-opus-4-6` (NOT 4.7) appears with non-zero usage.
4. **Fail criterion**: only `claude-opus-4-7` appears, or the dispatch errors with "model not found" → routing is broken or the pinned ID is rejected by the Task tool. Fallback per ADR-004.

Record result: `Test B: <pass|fail> — observed <model id>`

---

## Test C — Haiku pin verification

**Skill under test**: `/circle:facilitate` — pinned to `claude-haiku-4-5-20251001`.

1. Run `/circle:facilitate plan a one-day cycle for verification`.
2. Run `/cost`.
3. **Pass criterion**: a row for `claude-haiku-4-5-20251001` appears with non-zero usage.
4. **Fail criterion**: only the parent model appears.

Record result: `Test C: <pass|fail> — observed <model id>`

---

## Test D — code-review multi-agent pin verification

**Skill under test**: `/circle:code-review` — dispatches three sub-agents, each with a different pinned model:
- `agent_a` → `claude-sonnet-4-6`
- `agent_b` → `claude-haiku-4-5-20251001`
- `platform_review` → `claude-sonnet-4-6`

1. On any open PR (or use a tiny test PR), run `/circle:code-review`.
2. Run `/cost`.
3. **Pass criterion**: BOTH `claude-sonnet-4-6` AND `claude-haiku-4-5-20251001` rows appear with non-zero usage. (`platform_review` runs only if a platform-review skill matches the diff — its absence is not a failure.)
4. **Fail criterion**: only one of the two models appears, or the parent model dominates with no Sonnet/Haiku rows → multi-agent routing is broken.

Record result: `Test D: <pass|fail> — observed <models>`

---

## Test E — Smoke load (all remaining fork skills)

**Skills under test**: `/circle:refine`, `/circle:ux`, `/circle:qa`, `/circle:validate-prd`, `/circle:security`, `/circle:impl`. These are not exercised in Tests A-D but share the same pin pattern, so a typo in any of their frontmatters would fail at dispatch.

1. For each of the six skills, invoke it with a minimal prompt (e.g. `/circle:refine status` or `/circle:qa lint`). The goal is **load + dispatch**, not full execution — kill the skill (`Ctrl-C` or `exit`) once it has clearly started.
2. **Pass criterion**: each skill dispatches without an error like `model not found` or `invalid model identifier`. A skill that prompts for input or starts producing output has dispatched successfully.
3. **Fail criterion**: any skill returns a "model not found" error → typo in that skill's pinned ID. Read the skill's frontmatter, fix, retry.

Record result: `Test E: <pass|fail> — skills failing: <list or "none">`

---

## Acceptance

All five tests **pass** → record verification in `docs/CHANGELOG.md` under the v2.1.0 entry, replacing the placeholder line:

```
> Verification result (2026-MM-DD): Test A/B/C/D/E = pass.
```

If any test **fails** → do NOT tag v2.1.0. Apply the appropriate fallback:
- Test A or B fail with "model not found" passed to Task tool → apply ADR-004 fallback (modify `greenfield/SKILL.md` to pass family aliases at dispatch time, keep pin in skill frontmatter for direct invocation).
- Test E fails on a specific skill → typo in that skill's frontmatter; fix and re-run only that test.
- Other failure modes → open an issue and triage before release.

---

## After Anthropic deprecates a pinned model

When Anthropic announces deprecation of `claude-opus-4-6`, `claude-sonnet-4-6`, or `claude-haiku-4-5-20251001`:

1. Bump the relevant pin in 12 sites (9 fork-skill frontmatters + 3 entries in `plugin/skills/code-review/SKILL.md`).
2. Update `plugin/skills/greenfield/SKILL.md` (3 tables) and `CLAUDE.md` "Pinned models — current".
3. Re-run **this entire protocol** before tagging the new minor.
4. Record the new verification line in CHANGELOG under the new release.
