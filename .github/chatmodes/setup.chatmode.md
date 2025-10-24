---
description: Instructions for setting up Chat Mode in your repository with an AI delivery workflow.
tools: ['search', 'runCommands', 'runTasks', 'todos']
---

# Setup Chat Mode — AI Delivery Workflow

This chatmode file establishes a lightweight AI delivery workflow and the repository conventions the assistant (and contributors) must follow.

Core rules (strict):

- All project artifacts created during sessions must live under `aidlc-docs/` using the subfolders described below.
- Before writing code or making substantive edits, the assistant must create a plan markdown file in `aidlc-docs/plans/` and wait for explicit approval from a human reviewer.
- All prompts used to generate artifacts, plus the outputs' file references, must be logged (appended) to `aidlc-docs/prompts.md`.
- Use the templates in `aidlc-docs/` (README, plan template) when producing new documents.

Why: this enforces an approval-first, review-driven AI delivery process that keeps artifacts auditable and reproducible. See the AI delivery reference for ideas and examples: https://prod.d13rzhkk8cj2z0.amplifyapp.com/

Folder conventions (required):

- `aidlc-docs/` — root for all AI-generated delivery artifacts and prompts.
	- `plans/` — plans and sprint-level approvals. Every plan must use the plan template and include an "Approval" section.
	- `requirements/` — requirement docs, change requests, feature specs.
	- `story-artifacts/` — user stories, acceptance criteria, and related artifacts.
	- `design-artifacts/` — architecture diagrams, component designs, decision records.
	- `prompts.md` — chronological list of prompts and the produced file paths.

Plan-before-work contract (agent must follow):

1. Create a plan file in `aidlc-docs/plans/` describing goal, scope, deliverables, acceptance criteria, timeline, owners, reviewers, and proposed changes.
2. Wait for the user's explicit approval in a comment or PR. Do not modify code or create additional artifacts until the plan is approved.
3. After approval, perform steps in small, self-contained commits. Add short PR descriptions and list changed files.
4. Log each prompt and its output file(s) to `aidlc-docs/prompts.md` with timestamp and a one-line summary.

Plan template guidance (high-level): include these fields in every plan — Title, Objective, Scope (in/out), Deliverables, Acceptance Criteria, Steps, Timeline, Owner, Reviewers, Risks, and Approval status.

Acceptance and review gates:

- Plans must include at least one human reviewer and explicit Accept/Reject vote (or a signed-off comment).
- Pull requests for implementation should reference the plan filename and include succinct test/run steps.

Minimal CI/PR suggestions (optional):

- Add simple checks in CI: verify required `aidlc-docs` files exist (plan present and prompts appended), run tests/lint for changed code, and require PR review before merge.

Operational notes for human maintainers:

- The assistant will create the `aidlc-docs/` structure and seed templates when first invoked. If you prefer a different structure, update this file and the assistant will follow the new convention.
- All prompts and generated artifacts are stored in the repository for auditability and reproducibility.

Confirm your understanding of this enhanced workflow here by replying with a single line: "I understand and will follow the AI delivery workflow." After confirmation, the assistant may create the folders and seed templates.
