# smart-elephant

This repository uses an approval-first AI delivery workflow to keep work auditable, reviewable and reproducible.

Key ideas

- Plan before work: every substantive change starts with a plan stored under `aidlc-docs/plans/` and must be explicitly approved by a human reviewer before implementation.
- Prompts are auditable: every prompt the assistant uses to generate artifacts must be logged to `aidlc-docs/prompts.md` with a short summary and the list of files produced.
- Small commits and PRs: after approval, implement changes in small, testable commits and open a PR that references the plan file.

Quickstart — how to work with the assistant

1. Seeded files: this repo already contains the `aidlc-docs/` folder with templates and placeholders. See:
	- `aidlc-docs/README.md` — workflow and conventions
	- `aidlc-docs/plans/initial-plan.md` — plan template (use this when proposing work)
	- `aidlc-docs/prompts.md` — append-only log for prompts and generated outputs

2. Create a plan
	- Copy `aidlc-docs/plans/initial-plan.md` to a new file describing Scope, Deliverables, Acceptance Criteria, Timeline, Owner and Reviewers.
	- Set `status: "Draft"` while iterating. Add at least one human reviewer.

3. Obtain approval
	- Wait for a reviewer to change `status` to `Approved` in the plan file or leave an approving comment in a PR. Do NOT proceed until approved.

4. Implementation
	- After approval, perform small, self-contained commits that implement the plan.
	- Open a Pull Request that references the plan filename and lists the minimal test/run steps.
	- Add the prompt(s) that produced the changes to `aidlc-docs/prompts.md` with the produced file paths.

5. Review & merge
	- Require at least one human reviewer on the PR. Merge only after tests/lint pass and reviewers approve.

Example session flow

1. Contributor creates `aidlc-docs/plans/feature-x.md` (status: Draft) and asks reviewers for feedback.
2. Reviewer approves the plan (status: Approved).
3. Assistant or contributor implements changes in a branch and opens PR referencing `feature-x.md`.
4. Assistant appends the prompt and output files to `aidlc-docs/prompts.md`.
5. Human reviewers review the PR and merge when ready.

Files & locations to know

- `aidlc-docs/README.md` — conventions and how-to
- `aidlc-docs/plans/` — plan templates and plan files
- `aidlc-docs/prompts.md` — chronological log of prompts and outputs
- `aidlc-docs/requirements/`, `aidlc-docs/story-artifacts/`, `aidlc-docs/design-artifacts/` — artifact folders (placeholders present)

Recommended next steps (optional)

- Add a GitHub Action that enforces: if code changes are present then a plan exists and is `Approved`, and that `aidlc-docs/prompts.md` includes the relevant prompt entries.
- Add a PR template that requires a link to the plan and a short test checklist.

Reference

This workflow is inspired by the AI delivery guidance: https://prod.d13rzhkk8cj2z0.amplifyapp.com/

If you want, I can:
- Create a sample plan for a concrete feature and open a draft PR for review.
- Implement the suggested GitHub Action and PR template.
