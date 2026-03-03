# Dual Guard Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add anti-overcomplication and big-picture coherence guardrails to bmad-impl and bmad-qa.

**Architecture:** Two additive changes — a Simplicity Assessment step in the Implementer (advisory, before coding) and a Coherence & Scope Drift check in the Quality Guardian (integrated into existing severity system). Plus version bump and docs update.

**Tech Stack:** Pure Markdown edits. No build, no tests, no CI.

---

### Task 1: Add Simplicity Assessment to bmad-impl

**Files:**
- Modify: `plugin/skills/bmad-impl/SKILL.md:84-87` (insert new step between current steps 2 and 3)

**Step 1: Add new step after "Read architecture and requirements"**

Insert after line 84 (`2. **Read architecture and requirements**: Understand what to build and how`) and before line 86 (`3. **Explore the codebase**`). The new step becomes step 3 and all subsequent steps renumber.

```markdown
3. **Simplicity Assessment**: Before writing any code, evaluate the design for overcomplication:

   Read the architecture (`arch/architecture.md`) and PRD (`prioritize/PRD.md`), then assess:

   **a) Scope check**: Does the design contain components, services, or modules not directly required by Must Have user stories? If yes, list them and ask the user:
   > "These components are in the architecture but not traced to MVP user stories: {list}. Proceed with full design, or simplify?"

   **b) Technology check**: Does the design introduce infrastructure (containers, orchestration, message queues, caching layers, managed services) not strictly necessary for an MVP? If yes, propose the simplest alternative:
   > "The architecture specifies {technology}. For MVP, {simpler alternative} would suffice. Proceed with original, or simplify?"

   **c) Dependency check**: Count external dependencies introduced by the design. If more than what's strictly needed for MVP requirements, flag:
   > "The design introduces {N} external dependencies. {list of potentially unnecessary ones} could be deferred post-MVP. Proceed, or simplify?"

   This assessment is **advisory** — the user decides whether to proceed or simplify. If the user chooses to simplify, note the simplifications in the implementation notes.
```

**Step 2: Renumber subsequent steps**

Current steps 3-11 become 4-12. Update all step numbers.

**Step 3: Add simplicity principle**

At the end of `## BMAD Principles` (line 131), add:

```markdown
- Simplicity first: assess design complexity before coding — simpler is better for MVPs
```

**Step 4: Commit**

```bash
git add plugin/skills/bmad-impl/SKILL.md
git commit -m "feat(bmad-impl): add Simplicity Assessment step before coding

Advisory pre-implementation check that evaluates architecture for
overcomplication. Checks scope, technology, and dependency overhead
against MVP requirements. User decides whether to simplify."
```

---

### Task 2: Add Coherence & Scope Drift Check to bmad-qa

**Files:**
- Modify: `plugin/skills/bmad-qa/SKILL.md:265-291` (insert new step after TDD Compliance Check)

**Step 1: Add new step after TDD Compliance Check (step 5)**

Insert after step 5 (TDD Compliance Check, ending around line 289) and before step 6 (Self-Verification, line 291). New step becomes step 6 and subsequent steps renumber.

```markdown
6. **Coherence & Scope Drift Check**:

   Read the PRD (`prioritize/PRD.md`) and architecture (`arch/architecture.md`), then verify against the implemented code:

   **A) Scope Drift Detection:**
   - Map all Must Have user stories from the PRD
   - Scan implemented code for routes, endpoints, services, modules, and configurations
   - For each implemented component, trace it back to a PRD user story
   - Produce a traceability table in the test report:
     ```markdown
     ## Scope Drift Analysis

     | Implemented Component | PRD User Story | Status |
     |---|---|---|
     | /api/users endpoint | US-1: User registration | Traced |
     | /api/analytics endpoint | — | UNTRACED |
     ```
   - Components marked UNTRACED = scope drift → P1

   **B) Big Picture Coherence:**
   - Verify implemented features use consistent patterns (error handling, authentication, data flow, naming conventions)
   - Check that integration points declared in the architecture are actually implemented
   - Check for circular dependencies or undeclared coupling between components
   - Produce a coherence section in the test report:
     ```markdown
     ## Coherence Analysis

     | Check | Status | Details |
     |---|---|---|
     | Consistent error handling | PASS/FAIL | {details} |
     | Consistent auth pattern | PASS/FAIL | {details} |
     | Integration points implemented | PASS/FAIL | {missing points} |
     | No circular dependencies | PASS/FAIL | {cycles found} |
     ```

   **C) Severity:**
   - Scope drift (feature not in PRD) → P1
   - Pattern inconsistency between components → P2
   - Missing declared integration point → P1
   - Circular dependency → P0
```

**Step 2: Renumber subsequent steps**

Current steps 6-9 become 7-10. Update all step numbers.

**Step 3: Add coherence principle**

At the end of `## BMAD Principles` (line 310), add:

```markdown
- Big picture matters: verify system coherence, not just individual feature correctness
- Scope discipline: flag implemented features not traced to requirements
```

**Step 4: Commit**

```bash
git add plugin/skills/bmad-qa/SKILL.md
git commit -m "feat(bmad-qa): add Coherence & Scope Drift Check

New verification step that detects scope drift (features not in PRD)
and checks big-picture coherence (consistent patterns, integration
points, no circular deps). Uses existing P0/P1/P2 severity system."
```

---

### Task 3: Version bump

**Files:**
- Modify: `plugin/.claude-plugin/plugin.json:3` (version)
- Modify: `.claude-plugin/marketplace.json:12` (version)

**Step 1: Bump plugin.json**

Change line 3 from `"version": "0.8.0"` to `"version": "0.9.0"`.

**Step 2: Bump marketplace.json**

Change line 12 from `"version": "0.8.0"` to `"version": "0.9.0"`.

**Step 3: Update marketplace.json description**

Change line 14 to include the new feature:
```
"description": "17 skills (9 holacracy roles + 8 utilities) with structured workflows, quality gates, self-verification guardrails, anti-overcomplication checks, TDD enforcement, security audits, and full customization"
```

**Step 4: Commit**

```bash
git add plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore: bump version to 0.9.0"
```

---

### Task 4: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md:39` (workflow order rule)

**Step 1: Update workflow order**

Add simplicity assessment and coherence check mentions. Change line 39 from:
```
**Workflow order**: arch → security (P0 blocks impl) → impl → qa (REJECT loops to impl) → commit → push → PR → code-review. Never suggest `/bmad-code-review` before a PR exists.
```
to:
```
**Workflow order**: arch → security (P0 blocks impl) → impl (simplicity assessment first) → qa (coherence check + REJECT loops to impl) → commit → push → PR → code-review. Never suggest `/bmad-code-review` before a PR exists.
```

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(CLAUDE.md): add simplicity and coherence checks to workflow order"
```

---

### Task 5: Update README.md

**Files:**
- Modify: `README.md:148-154` (Quality Gates section)

**Step 1: Add new quality gate descriptions**

After the TDD Compliance bullet (line 153), add:
```markdown
- **Simplicity Assessment**: Before coding, the Implementer evaluates the architecture for overcomplication — flagging unnecessary infrastructure, excessive dependencies, and components not traced to MVP stories. Advisory check; the developer decides whether to simplify
- **Coherence & Scope Drift**: The Quality Guardian verifies that implemented features are traced to PRD requirements (scope drift detection) and that the system works as an integrated whole (consistent patterns, no circular dependencies)
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs(README): add simplicity and coherence checks to quality gates"
```

---

### Task 6: Update docs/GETTING-STARTED.md

**Files:**
- Modify: `docs/GETTING-STARTED.md:101` (greenfield workflow description)

**Step 1: Update greenfield workflow description**

Change line 101 from:
```
This walks through: Scope Clarifier (requirements) → Prioritizer (product plan) → PRD Validator (quality check) → Experience Designer (design) → Architecture Owner (architecture) → Security Guardian (security audit) → Facilitator (sprint planning) → Implementer (implementation with TDD) → Quality Guardian (testing + TDD compliance). You can skip optional steps.
```
to:
```
This walks through: Scope Clarifier (requirements) → Prioritizer (product plan) → PRD Validator (quality check) → Experience Designer (design) → Architecture Owner (architecture) → Security Guardian (security audit) → Facilitator (sprint planning) → Implementer (simplicity assessment + implementation with TDD) → Quality Guardian (testing + TDD compliance + coherence & scope drift check). You can skip optional steps.
```

**Step 2: Commit**

```bash
git add docs/GETTING-STARTED.md
git commit -m "docs(getting-started): mention simplicity assessment and coherence check in workflow"
```

---

### Task 7: Update docs/MIGRATION.md

**Files:**
- Modify: `docs/MIGRATION.md` (append v0.9.0 section at end of file)

**Step 1: Add v0.9.0 migration section**

Append after line 213:

```markdown

## What Changes (v0.9.0 — Anti-Overcomplication & Coherence)

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
```

**Step 2: Commit**

```bash
git add docs/MIGRATION.md
git commit -m "docs(migration): add v0.9.0 section for anti-overcomplication and coherence"
```

---

### Task 8: Final verification

**Step 1: Run plugin lint**

```bash
# Verify plugin consistency after all changes
/bmad:bmad-qa lint
```

**Step 2: Verify version alignment**

```bash
grep '"version"' plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json
# Expected: both show "0.9.0"
```
