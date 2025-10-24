# prompts.md — session prompts and outputs

This file is append-only. For every prompt the assistant uses to generate artifacts, append a short entry with these fields:

- Date: YYYY-MM-DD HH:MM UTC
- Role: (assistant|user|system)
- Intent: one-line description of why the prompt was run
- Prompt (summary or full prompt)
- Output files: list of repo paths written or modified

Example entry

---
Date: 2025-10-24 15:20 UTC
Role: assistant
Intent: Seed repository with AI delivery docs and plan template
Prompt: "Create aidlc-docs structure and initial plan template following AI delivery workflow"
Output files:
- `aidlc-docs/README.md`
- `aidlc-docs/plans/initial-plan.md`
---

Keep entries minimal but precise. If a prompt produced multiple files, list them all.
