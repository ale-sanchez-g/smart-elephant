# aidlc-docs — AI Delivery Documents

This folder contains all artifacts created by the AI-driven delivery workflow. Keep the structure stable so automated processes and reviewers can find plans, prompts and artifacts.

Structure

- `plans/` — Approval-first plans. Every plan must use the plan template and include an Approval section.
- `requirements/` — Requirements, feature change docs, and spec files.
- `story-artifacts/` — User stories and acceptance criteria.
- `design-artifacts/` — Architecture diagrams, ADRs, and design docs.
- `prompts.md` — Chronological log of prompts used during sessions and the files produced.

How to use

1. Before the assistant modifies code or creates major artifacts, create a plan in `plans/` and obtain human approval.
2. Reference the plan filename in PRs and in the `prompts.md` entries for traceability.
3. Keep `prompts.md` append-only so prompts and outputs remain auditable.

Reference

See the AI delivery example site for workflow inspiration: https://prod.d13rzhkk8cj2z0.amplifyapp.com/
