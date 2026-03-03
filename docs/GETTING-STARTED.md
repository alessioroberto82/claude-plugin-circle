# Getting Started with BMAD

BMAD is a circle of AI roles that help you build software — from initial idea through to working code. Each role has a clear purpose and accountability, following holacracy principles.

You talk to them using simple commands in Claude Code. No programming knowledge required.

## Who is this for?

BMAD is designed for everyone involved in building a product:

- **Product Managers** — define what to build, prioritize features, create roadmaps
- **Business Analysts** — gather requirements, write user stories, clarify scope
- **Designers** — create UI/UX designs, map user journeys, build wireframes
- **Scrum Masters** — plan sprints, coordinate the team, track progress
- **Developers** — implement features, review code, run tests
- **Documentation writers** — generate docs from templates, keep things consistent

You don't need to be technical to use BMAD. If you can type a sentence and press Enter, you can work with the circle.

## Meet the circle

| Role | What it does |
|------|-------------|
| **Scope Clarifier** | Helps you define what you're building and why |
| **Prioritizer** | Prioritizes features and creates a product plan |
| **Experience Designer** | Designs the user experience and interface |
| **Architecture Owner** | Plans how the software will be structured |
| **Implementer** | Writes and reviews the actual code |
| **Quality Guardian** | Makes sure everything works correctly |
| **Facilitator** | Organizes the work into sprints |
| **Security Guardian** | Audits security, models threats, checks compliance |
| **Documentation Steward** | Creates project documentation |

## Your first conversation

The easiest way to start is by talking to the **Scope Clarifier**. It will ask you questions about what you want to build and help you think through the details.

1. Open Claude Code
2. Type this and press Enter:

```
/bmad:bmad-scope
```

3. The Scope Clarifier will ask you about your project. Just answer in plain language — describe what you want to build, who it's for, and what problem it solves.

4. When done, it will save a requirements document and suggest which role to invoke next.

That's it. Each role works the same way: type the command, have a conversation, get results.

## Quick paths by role

### If you're a Product Manager

Start with the Scope Clarifier to gather requirements, then invoke the Prioritizer to create a product requirements document (PRD) and prioritize features:

```
/bmad:bmad-scope
```
then
```
/bmad:bmad-prioritize
```

### If you're a Designer

After requirements are gathered, invoke the Experience Designer:

```
/bmad:bmad-ux
```

### If you're a Scrum Master

Use the Facilitator to run sprint planning, or use the sprint ceremony workflow:

```
/bmad:bmad-facilitate
```
or
```
/bmad:bmad-sprint
```

### If you're a Developer

After the architecture is designed, invoke the Implementer to start building:

```
/bmad:bmad-impl
```

### If you want the full workflow

The greenfield command runs the entire process from start to finish, with you making decisions at each step:

```
/bmad:bmad-greenfield
```

This walks through: Scope Clarifier (requirements) → Prioritizer (product plan) → PRD Validator (quality check) → Experience Designer (design) → Architecture Owner (architecture) → Security Guardian (security audit) → Facilitator (sprint planning) → Implementer (simplicity assessment + implementation with TDD) → Quality Guardian (testing + TDD compliance + coherence & scope drift check). You can skip optional steps.

## Available commands

Every command starts with `/bmad:`. Just type it and press Enter.

| Command | What it does |
|---------|-------------|
| `/bmad:bmad-scope` | Gather requirements and clarify scope |
| `/bmad:bmad-prioritize` | Create a product plan and prioritize features |
| `/bmad:bmad-ux` | Design user experience and interface |
| `/bmad:bmad-arch` | Plan software architecture |
| `/bmad:bmad-impl` | Implement code |
| `/bmad:bmad-qa` | Test and validate quality |
| `/bmad:bmad-facilitate` | Plan sprints and coordinate |
| `/bmad:bmad-security` | Audit security and model threats |
| `/bmad:bmad-docs` | Generate documentation |
| `/bmad:bmad-greenfield` | Run the full workflow start to finish |
| `/bmad:bmad-sprint` | Run a sprint planning session |
| `/bmad:bmad-code-review` | Review a pull request |
| `/bmad:bmad-triage` | Handle review feedback on a pull request |
| `/bmad:bmad-validate-prd` | Validate PRD quality before architecture design |
| `/bmad:bmad-tdd` | Enforce test-driven development (red-green-refactor cycle) |
| `/bmad:bmad-shard` | Split large documents into smaller pieces (saves time and cost) |
| `/bmad:bmad-init` | Set up BMAD for your current project (run once) |
| `/bmad:bmad` | See project status and what's been done |

## Where does everything go?

BMAD keeps all its work in a folder on your computer, completely separate from your project files. Nothing gets added to your codebase unless you explicitly ask the Implementer to write code.

All outputs are saved to: `~/.claude/bmad/projects/<your-project>/output/`

Each role saves their work in their own subfolder (e.g., `scope/`, `arch/`, `impl/`).

## Tips

- **You can invoke any role at any time.** There's no strict order — use whoever makes sense for what you need right now.
- **Roles access context within a session.** If the Scope Clarifier creates requirements, the Prioritizer can read them when you invoke it to create a product plan.
- **You can customize how roles behave** per project. See the [Customization Guide](CUSTOMIZATION.md) for details.
- **All dependencies are optional.** BMAD works out of the box. Extra integrations (like Linear for issue tracking) add functionality but aren't required.

## Next steps

- Run `/bmad:bmad-init` to set up BMAD for your project
- Start with `/bmad:bmad-scope` to define what you're building
- Check status anytime with `/bmad:bmad`
- Read the [Customization Guide](CUSTOMIZATION.md) when you want to tailor the workflow
