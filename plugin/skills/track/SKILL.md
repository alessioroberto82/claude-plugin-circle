---
name: track
description: Capture work done outside Circle skills for assessment tracking. Interactive 3-question flow.
allowed-tools: Read
metadata:
  context: same
---

# Work Tracker

Capture work that doesn't flow through other Circle skills — ad-hoc debugging, mentoring, cross-team collaboration, manual reviews, production incidents, or any other meaningful activity.

## Process

1. **Read the template**: Read `${CLAUDE_PLUGIN_ROOT}/resources/work-summary-template.md` for the output format. If not found, use the format below directly.

2. **Gather details** with 3 focused questions:

   **Q1**: "What did you work on? (deliverable, task, activity — be specific about the project and what you produced or accomplished)"

   Wait for the user's response.

   **Q2**: "What decisions did you make or challenges did you navigate? (technical choices, trade-offs, blockers resolved)"

   Wait for the user's response.

   **Q3**: "What was the outcome? (result achieved, status change, impact on team or project)"

   Wait for the user's response.

3. **Compose and output** a Work Summary block using the template:

   ```
   ### Work Summary
   - **Role**: manual-track | **Project**: {project from user's answer}
   - **Deliverable**: {from Q1}
   - **Key decisions**: {from Q2}
   - **Approach**: {inferred from Q1 + Q2}
   - **Outcome**: {from Q3}
   - **Initiative**: {inferred — what was self-directed or proactive in the user's answers}
   ```

   Make each field concrete and specific. Rephrase the user's answers into dense, factual statements. Do not pad with filler.

4. **Confirm**: "Captured. claude-mem will index this in the current session."

## Notes

- Keep it fast — the whole interaction should feel like 30 seconds, not a form
- If the user provides all details in one message, skip remaining questions and go straight to the Work Summary
- This skill produces no file output — the value is the structured text that claude-mem's session hooks capture automatically
