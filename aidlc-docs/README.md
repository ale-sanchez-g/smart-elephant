# AI Delivery Lifecycle (AIDLC) Documentation

This directory contains documentation and artifacts for the AI-driven delivery workflow used in this repository.

## Directory Structure

- **plans/** — Plan templates and approved plan files for features and enhancements
- **requirements/** — Requirement documents and feature specifications
- **story-artifacts/** — User stories and acceptance criteria
- **design-artifacts/** — Architecture diagrams and decision records
- **validation/** — Validation plans and reports
- **prompts.md** — Chronological log of prompts and outputs (append-only)

## Workflow Overview

This repository follows an approval-first AI delivery workflow:

1. **Plan before work**: Every substantive change starts with a plan and must be explicitly approved
2. **Prompts are auditable**: Every prompt used to generate artifacts is logged to `prompts.md`
3. **Small commits and PRs**: Implement changes in small, testable commits
4. **Specialized chat modes**: Use `.github/chatmodes/` for different SDLC phases

## Creating a Plan

1. Copy `plans/initial-plan.md` to a new file describing your work
2. Include: Scope, Deliverables, Acceptance Criteria, Timeline, Owner, and Reviewers
3. Set `status: "Draft"` while iterating
4. Wait for a reviewer to change status to `Approved`
5. Implement only after approval

## Logging Prompts

Append to `prompts.md` after generating artifacts:

```markdown
### [Date] [Short Description]
**Prompt:** [Brief summary of the prompt]
**Generated files:**
- file1.md
- file2.py
```

## Reference

For detailed conventions and workflow, see the main [README.md](../README.md).
