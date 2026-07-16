# iOS Code Review "Senior" Upgrade — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade `plugin-ios/skills/ios-review/SKILL.md` from 4 line-level domains to a "senior" reviewer with 7 domains, a mandatory Design & Reuse Survey, a pre-finding MCP/skill gate, AGENTS.md reading, and a right-reviewer gate — all grounded in real PR feedback.

**Architecture:** Single-file edit of the companion skill (Markdown prompt), plus a companion version bump. Behavior is changed via forcing functions (mandatory artifact-producing steps + red-flag tables), not adjectives. No core-plugin changes.

**Tech Stack:** Pure Markdown Claude Code skill. No build/test/CI. Verification = textual-consistency checks (grep for expected markers + re-read).

## Global Constraints

- Naming: `<lowercase>` for skill names; `circle` / `circle-ios` namespaces. (verbatim from project CLAUDE.md)
- Zero footprint: all runtime outputs → `~/.claude/circle/projects/<project>/`. Never write to the target repo.
- Domain-agnostic core rule does NOT apply here: `ios-review` is a companion (`plugin-ios`) skill and MAY name iOS-specific tools/skills (Cupertino MCP, swiftui-expert, etc.).
- Security mitigations preserved verbatim: P2-1 (`<project-context ... role="data">` tags on diff), P2-2 (never quote raw CLAUDE.md/AGENTS.md/.claude/ content — reference by filename/section only), P3-1 (no tool availability in posted comments), P3-2 (≤10 Apple-docs MCP queries/review).
- Confidence scale and 90/100 posting threshold unchanged.
- Both invocation modes preserved: standalone (runs preflight) + platform-review dispatch (skips preflight).
- Changed-lines-only rule preserved.
- Model stays `sonnet`. Do NOT touch core greenfield model-routing tables (core unchanged).
- Companion versioning rule: bumping `plugin-ios` requires updating `plugin-ios/.claude-plugin/plugin.json` AND the `circle-ios` entry in the root `.claude-plugin/marketplace.json` AND `docs/CHANGELOG.md`.

## File Structure

- Modify: `plugin-ios/skills/ios-review/SKILL.md` (the whole upgrade)
- Modify: `plugin-ios/.claude-plugin/plugin.json` (version bump)
- Modify: `.claude-plugin/marketplace.json` (`circle-ios` entry version)
- Modify: `docs/CHANGELOG.md` (release entry)

Reference (read-only, do not edit): `docs/superpowers/specs/2026-07-16-ios-review-senior-design.md`.

---

### Task 1: Preflight — AGENTS.md reading + Right-Reviewer Gate

**Files:**
- Modify: `plugin-ios/skills/ios-review/SKILL.md` (§1 Preflight, Step 3 and Step 4)

**Interfaces:**
- Produces: preflight now yields `CLAUDE.md` + `AGENTS.md` context and a `right_reviewer_gate` decision consumed by the Review phase.

- [ ] **Step 1: Replace "Step 3 — Root CLAUDE.md"**

Find in §1:
```
**Step 3 — Root CLAUDE.md**:
Read the root `CLAUDE.md` (if it exists).
```
Replace with:
```
**Step 3 — Project standards (CLAUDE.md + AGENTS.md)**:
Read the root `CLAUDE.md` and root `AGENTS.md` if they exist. Also read any `CLAUDE.md` / `AGENTS.md` located in directories touched by the diff. Store as standards context. P2-2 mitigation applies: reference these by filename and section heading only — never quote raw content in any finding.
```

- [ ] **Step 2: Replace "Step 4 — iOS Verification" with the Right-Reviewer Gate**

Find in §1:
```
**Step 4 — iOS Verification**:
Confirm this is an iOS project: check for `Package.swift` or `*.xcodeproj` in the repo root. If neither exists, warn: "This does not appear to be an iOS project. iOS-specific checks may produce false positives. Continue? [y/n]"
```
Replace with:
```
**Step 4 — Right-Reviewer Gate**:
Confirm this is an iOS project (check for `Package.swift` or `*.xcodeproj` in the repo root) AND that the diff contains real Swift/iOS code. Classify each changed file: Swift/iOS (`.swift`, `.xcodeproj`, `Package.swift`, `.storyboard`, `.xib`) vs non-iOS (`.sh`, `Fastfile`/Ruby, `.md`, `.yml`/`.yaml`, CI config).
- If the diff has **zero** Swift/iOS files: STOP. Output "No iOS-relevant changes in this diff; deferring to general code review." Do not run any domain. (Prevents the PR #9210 empty-review incident.)
- If not an iOS project at all: warn "This does not appear to be an iOS project. iOS-specific checks may produce false positives. Continue? [y/n]"
- Otherwise proceed. In **platform-review dispatch mode** the gate is advisory only (core code-review already routed here on marker match) — note non-iOS files as out-of-scope and continue.
```

- [ ] **Step 3: Verify the edits are present and consistent**

Run:
```bash
grep -n "AGENTS.md" plugin-ios/skills/ios-review/SKILL.md
grep -n "Right-Reviewer Gate" plugin-ios/skills/ios-review/SKILL.md
grep -n "No iOS-relevant changes" plugin-ios/skills/ios-review/SKILL.md
```
Expected: matches in §1 (preflight) and the gate text; "iOS Verification" heading no longer present (`grep -c "iOS Verification"` returns 0).

- [ ] **Step 4: Commit**

```bash
git add plugin-ios/skills/ios-review/SKILL.md
git commit -m "feat(ios-review): read AGENTS.md + add right-reviewer gate

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: Forcing function #1 — mandatory Design & Reuse Survey

**Files:**
- Modify: `plugin-ios/skills/ios-review/SKILL.md` (insert a new step between §3 Dependency Availability Detection and §4 Review; renumber Review→§5 onward OR insert as §3.5 to avoid renumbering churn)

**Interfaces:**
- Produces: a saved `Design & Reuse Survey` artifact and per-symbol REUSE/DUPLICATES/BYPASSES verdicts consumed by Domain 5 (Task 4).

- [ ] **Step 1: Insert the Survey step**

Insert immediately before `### 4. Review` a new section:
```
### 3.5 Design & Reuse Survey (mandatory — blocks findings if skipped)

Before emitting ANY finding, produce and save this artifact. This is a forcing function: no Survey → no findings.

```
## Design & Reuse Survey
- What this change does (1 line):
- Equivalent logic already in the codebase? Grep for calculators/providers/helpers/use-cases on the same concept (e.g. `grep -rn "Calculator\|Provider\|Mapper\|UseCase"` scoped to the touched feature dir).
    → per-symbol verdict: REUSE-OK / DUPLICATES <file:line> / BYPASSES-GATE <gate-symbol>
- Introduces metadata/config that promises behavior the code does not implement? (consistency)
- Reuses a builder/section/type meant for a different case? (wrong filtering / wrong branch)
```

Rules:
- Every `DUPLICATES` or `BYPASSES-GATE` verdict MUST name the existing symbol with a `file:line` you verified via Grep/Read. A verdict without a verified reference is not allowed — downgrade it to REUSE-OK or omit it.
- Save the Survey into the review output file (§6), not into posted comments.
```

- [ ] **Step 2: Verify insertion and ordering**

Run:
```bash
grep -n "Design & Reuse Survey" plugin-ios/skills/ios-review/SKILL.md
awk '/### 3.5 Design & Reuse Survey/{s=NR} /### 4. Review/{r=NR} END{print "survey@"s" review@"r}' plugin-ios/skills/ios-review/SKILL.md
```
Expected: survey line number < review line number (Survey precedes Review).

- [ ] **Step 3: Commit**

```bash
git add plugin-ios/skills/ios-review/SKILL.md
git commit -m "feat(ios-review): mandatory Design & Reuse Survey forcing function

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: Forcing function #2 — pre-finding MCP/skill gate + confidence rules

**Files:**
- Modify: `plugin-ios/skills/ios-review/SKILL.md` (§4 Review intro — the "Confidence boosting" block and Rules §4)

**Interfaces:**
- Consumes: MCP availability summary + loaded skills from §2/§3.
- Produces: hard citation gate applied by all domains.

- [ ] **Step 1: Replace the "Confidence boosting" block with a hard gate**

Find the block starting `**Confidence boosting**:` through the paragraph ending `...but the local skill wins on disagreement.` Replace with:
```
**Pre-finding citation gate (mandatory — formalizes project policy #8065):**
Before emitting a finding, it MUST carry a verifiable citation:
- Technical-judgment domains (API / SwiftUI / Concurrency / Testing): a Cupertino MCP result, a loaded domain-skill pattern, or a local project skill. No verifiable citation → cap confidence at 25 (dropped at the 90 threshold).
- Architectural-judgment domains (Reuse & Consistency / Robustness & Silent Failures): the citation is the existing code you read — a verified `file:line`. No verified reference → do not emit.

**Confidence boosting** (applied after the gate passes):
- Backed by a local project skill pattern: +15 (highest — project-specific truth)
- Verified against an Apple docs MCP (Cupertino / apple-docs-mcp / Sosumi): +10
- Backed by a loaded plugin skill pattern: +5
- Model knowledge only: no boost (and, per the gate, capped at 25 in technical domains)

When a finding's topic is covered by a local skill, cite it as `source` (`Local: {skill-name} — {pattern}`); external sources may be secondary evidence, but the local skill wins on disagreement.
```

- [ ] **Step 2: Update Rules §4 to reference the gate**

Find in §Rules:
```
4. Cap confidence at 25 if the cited source cannot be verified against a loaded skill or MCP query.
```
Replace with:
```
4. Apply the pre-finding citation gate (§4): technical-domain findings without a verifiable MCP/skill citation are capped at 25; architectural-domain findings without a verified `file:line` reference are not emitted.
```

- [ ] **Step 3: Verify**

Run:
```bash
grep -n "Pre-finding citation gate" plugin-ios/skills/ios-review/SKILL.md
grep -n "citation gate" plugin-ios/skills/ios-review/SKILL.md
```
Expected: gate defined in §4 and referenced in Rules §4.

- [ ] **Step 4: Commit**

```bash
git add plugin-ios/skills/ios-review/SKILL.md
git commit -m "feat(ios-review): pre-finding MCP/skill citation gate

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: Domains — add teeth to 2/3/4 with red-flag tables

**Files:**
- Modify: `plugin-ios/skills/ios-review/SKILL.md` (§4 Domain 2, Domain 3, Domain 4)

**Interfaces:**
- Consumes: SwiftUI/Concurrency/Testing detection already in each domain.

- [ ] **Step 1: Extend Domain 2 (SwiftUI) with a red-flag table**

Append to Domain 2, before "If SwiftUI Expert skill is loaded...":
```
**Red-flag table (check each against changed lines):**

| Red flag | Why it matters | Source to cite |
|---|---|---|
| Synchronous I/O / DB (e.g. full-history fetch) inside `body` or a computed property read by `body` | Main-thread hazard; jank/hang | Cupertino / swiftui-expert; prefer a `getLatest()`-style bounded query |
| `ObservableObject` + many `@Published` where views observe a subset | Any change reloads all observers | swiftui-expert; suggest `@Observable` + `@State` for per-view observation |
| O(n²) / O(slots×readings) transforms building chart/list data | Scales badly on long histories | flag with the concrete complexity and a single-pass alternative |
```

- [ ] **Step 2: Extend Domain 3 (Concurrency) with a red-flag table**

Append to Domain 3, before "If Swift Concurrency skill is loaded...":
```
**Red-flag table (check each against changed lines):**

| Red flag | Why it matters | Source to cite |
|---|---|---|
| `DispatchSemaphore.wait()` / `DispatchQueue.sync` on `@MainActor` | Deadlock when the awaited work also needs the main actor | swift-concurrency skill |
| Force-unwrap replaced by `?? <default>` that changes semantics | Silent wrong result instead of a safe, provably-non-nil value | flag the semantic change, not the syntax |
| Realm/`@ManagedObject` accessed across threads / in `Task.detached` | Cross-thread crash risk | swift-concurrency skill |
```

- [ ] **Step 3: Extend Domain 4 (Swift Testing) with coverage + build-break checks**

Append to Domain 4, before "If Swift Testing Expert skill is loaded...":
```
**Red-flag table (check each against changed lines):**

| Red flag | Why it matters | Source to cite |
|---|---|---|
| New fallback / error / edge-case path with no accompanying test | Untested branch ships silently | flag the specific untested path |
| Mock/protocol renamed in one file but referenced by old name elsewhere | Compilation break | name the stale reference `file:line` |
| Timing-based waits (`Task.sleep`, fixed delays) used to synchronize tests | Flaky; violates no-arbitrary-delays standard | swift-testing-expert |
```

- [ ] **Step 4: Verify**

Run:
```bash
grep -c "Red-flag table" plugin-ios/skills/ios-review/SKILL.md
```
Expected: ≥ 3 at this point (Domains 2,3,4). More after Task 5.

- [ ] **Step 5: Commit**

```bash
git add plugin-ios/skills/ios-review/SKILL.md
git commit -m "feat(ios-review): red-flag tables + teeth for SwiftUI/concurrency/testing

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 5: New Domains 5/6/7 + Output source table

**Files:**
- Modify: `plugin-ios/skills/ios-review/SKILL.md` (§4 add Domains 5,6,7; §5 Output source table; heading intro "4 domains" → "7 domains")

**Interfaces:**
- Consumes: Design & Reuse Survey (Task 2) feeds Domain 5.

- [ ] **Step 1: Fix the domain count in the §4 intro**

Find: `Analyze the diff across 4 domains.` Replace with: `Analyze the diff across 7 domains.`

- [ ] **Step 2: Append Domain 5**

After Domain 4, add:
```
#### Domain 5: Reuse & Architectural Consistency

Driven by the Design & Reuse Survey (§3.5). Flag:
- **Duplication**: logic re-implemented when an existing symbol does it — cite the existing `file:line` (Survey `DUPLICATES` verdict).
- **Bypassed gate**: a centralized guard/availability check (e.g. an `isXAllowed()` gate) skipped by the new path — cite the gate `file:line` (Survey `BYPASSES-GATE`).
- **Metadata/behavior incoherence**: config/metadata advertises a capability the implementation does not support (e.g. goal metadata declared but the save path returns `false`).
- **Wrong-type reuse**: a builder/section/type reused for a case it filters incorrectly.

Every finding here names a verified `file:line` (architectural-judgment gate, §4).
```

- [ ] **Step 3: Append Domain 6**

```
#### Domain 6: Robustness & Silent Failures

Flag defensive code that hides bugs rather than handling them:
- `guard let … else { return nil/[] }` that swallows a real failure and hides data instead of surfacing it.
- `catch` blocks that discard the error with no logging/propagation.
- Default values (`?? 0`, `?? ""`) that mask an unexpected-nil bug.
- Reintroduced deprecated/insecure APIs (verify deprecation via Apple docs MCP).

Distinguish genuinely-safe fallbacks (provably-non-nil input) from silent wrong-result branches — flag only the latter, and say why the input is NOT provably safe.
```

- [ ] **Step 4: Append Domain 7**

```
#### Domain 7: Accessibility & Project Standards

- **Accessibility**: interactive controls (`Menu`, `Button`, custom tappables) in changed lines missing `accessibilityIdentifier` needed for UI-test automation.
- **Project standards** (checked against CLAUDE.md / AGENTS.md, referenced by section — never quoted): forbidden inline/explanatory comments, Xcode boilerplate file headers, copy-pasted doc-comments referencing the wrong type, and any project-specific rule the standards files define.

Cite the standards file + section for each standards finding (P2-2: name only, no raw quote).
```

- [ ] **Step 5: Add rows to the §5 Output source-format table**

In the source-format table add:
```
| Reuse & Consistency | Reuse: <verdict> — <existing file:line> | Reuse: DUPLICATES BodyCompositionMassCalculator:42 |
| Robustness | Robustness: <pattern> | Robustness: guard-return-nil hides all weight data |
| Accessibility | Accessibility: <pattern> | Accessibility: Menu trigger missing accessibilityIdentifier |
| Standards | Standards: <file §section> | Standards: CLAUDE.md §Comments — inline comment forbidden |
```

- [ ] **Step 6: Verify all 7 domains present**

Run:
```bash
grep -nE "^#### Domain [1-7]:" plugin-ios/skills/ios-review/SKILL.md
grep -c "Red-flag table" plugin-ios/skills/ios-review/SKILL.md
```
Expected: Domains 1–7 all listed; "across 7 domains" present (`grep -c "across 7 domains"` = 1).

- [ ] **Step 7: Commit**

```bash
git add plugin-ios/skills/ios-review/SKILL.md
git commit -m "feat(ios-review): add reuse/robustness/accessibility+standards domains

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 6: Align Identity/Principles text + full-file consistency pass

**Files:**
- Modify: `plugin-ios/skills/ios-review/SKILL.md` (§Your Identity, §Circle Principles — light touch)

**Interfaces:** none (prose alignment only).

- [ ] **Step 1: Extend "Your Identity" to name the new senior behaviors**

Find the "Your Identity" paragraph and append one sentence:
```
Beyond line-level API/state/concurrency checks, you reason about design: you catch logic that duplicates or bypasses existing code, defensive fallbacks that hide bugs, missing accessibility identifiers, and violations of the project's own standards — always citing the existing symbol or standard by reference.
```

- [ ] **Step 2: Full-file consistency read**

Read the whole `SKILL.md`. Confirm: step numbering is monotonic (§1→§7 with §3.5 Survey before §4 Review), no dangling "4 domains", no duplicated headings, security mitigation rules intact, both invocation modes still described.

- [ ] **Step 3: Commit**

```bash
git add plugin-ios/skills/ios-review/SKILL.md
git commit -m "docs(ios-review): align identity prose with new senior domains

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 7: Companion version bump + changelog + marketplace sync

**Files:**
- Modify: `plugin-ios/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json` (the `circle-ios` entry)
- Modify: `docs/CHANGELOG.md`

**Interfaces:** none.

- [ ] **Step 1: Read current companion version**

Run:
```bash
cat plugin-ios/.claude-plugin/plugin.json
grep -n "circle-ios" .claude-plugin/marketplace.json
head -20 docs/CHANGELOG.md
```
Expected: note the current `plugin-ios` version to compute the next minor bump.

- [ ] **Step 2: Bump `plugin-ios/.claude-plugin/plugin.json`**

Increment the `version` field by one minor (e.g. `x.y.z` → `x.(y+1).0`). Match the exact key formatting already in the file.

- [ ] **Step 3: Sync the `circle-ios` entry in `.claude-plugin/marketplace.json`**

Set the `circle-ios` entry `version` to the same value. Confirm the two match:
```bash
python3 -c "import json;a=json.load(open('plugin-ios/.claude-plugin/plugin.json'))['version'];print('plugin.json',a)"
```
and grep the marketplace entry — they must be identical.

- [ ] **Step 4: Add a CHANGELOG entry**

Add a new release section at the top of `docs/CHANGELOG.md` (matching the existing format) summarizing: 7 domains, Design & Reuse Survey, pre-finding citation gate, AGENTS.md reading, right-reviewer gate.

- [ ] **Step 5: Verify version alignment**

Run:
```bash
V=$(python3 -c "import json;print(json.load(open('plugin-ios/.claude-plugin/plugin.json'))['version'])")
echo "companion version: $V"
grep -n "$V" .claude-plugin/marketplace.json docs/CHANGELOG.md
```
Expected: the version string appears in both the marketplace entry and the changelog.

- [ ] **Step 6: Commit**

```bash
git add plugin-ios/.claude-plugin/plugin.json .claude-plugin/marketplace.json docs/CHANGELOG.md
git commit -m "chore(ios-review): bump circle-ios companion version + changelog

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage:**
- Preflight AGENTS.md + mitigation → Task 1 ✓
- Right-Reviewer Gate → Task 1 ✓
- Design & Reuse Survey (forcing fn #1) → Task 2 ✓
- Pre-finding MCP/skill gate (forcing fn #2) → Task 3 ✓
- Domain teeth (B/F) + red-flag tables (forcing fn #3) → Task 4 ✓
- New domains A/C/D+E (5/6/7) → Task 5 ✓
- Output source rows → Task 5 ✓
- Model stays sonnet; core tables untouched → Global Constraints ✓
- Companion versioning (4 places) → Task 7 ✓
- Both modes + changed-lines-only + security mitigations preserved → Tasks 1/3/6 verification ✓

**Placeholder scan:** No TBD/TODO; each edit shows exact find/replace text. ✓

**Type consistency:** Domain numbering 1–7 consistent; "Design & Reuse Survey" named identically in Tasks 2 & 5; "citation gate" named identically in Tasks 3 & 4/5; `getLatest()` / `isXAllowed()` used as illustrative, not as defined interfaces. ✓

**Note:** Post-implementation, run `/circle:qa lint` (plugin internal-consistency check) as a final verification and dogfood on a real iOS PR to confirm the Survey artifact appears.
