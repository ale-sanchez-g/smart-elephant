# smart-elephant

This repository uses an approval-first AI delivery workflow to keep work auditable, reviewable and reproducible.

## Key Ideas

- **Plan before work**: Every substantive change starts with a plan stored under `aidlc-docs/plans/` and must be explicitly approved by a human reviewer before implementation.
- **Prompts are auditable**: Every prompt the assistant uses to generate artifacts must be logged to `aidlc-docs/prompts.md` with a short summary and the list of files produced.
- **Small commits and PRs**: After approval, implement changes in small, testable commits and open a PR that references the plan file.
- **Agentic primitives**: Use specialized chat modes in [.github/chatmodes/](.github/chatmodes/) for different phases of the software delivery lifecycle.

## Chat Modes & Agentic Primitives

This repository includes specialized chat modes for different delivery phases:

### Setup Phase
- [1. setup.chatmode.md](.github/chatmodes/1.%20setup.chatmode.md) - Initialize AI delivery workflow and repository structure

### Inception Phase
- [2.1 inception.stories.chatmode.md](.github/chatmodes/2.1%20inception.stories.chatmode.md) - Generate user stories from product requirements
- [2.2 inception.units.chatmode.md](.github/chatmodes/2.2%20inception.units.chatmode.md) - Implement software units from component designs
- [2.3 inception.architecture.chatmode.md](.github/chatmodes/2.3%20inception.architecture.chatmode.md) - Design architecture and deployment planning

### Construction Phase
- [3.1 constrcution.domain.chatmode.md](.github/chatmodes/3.1%20constrcution.domain.chatmode.md) - Domain-driven component model design
- [3.2 constrcution.code.chatmode.md](.github/chatmodes/3.2%20constrcution.code.chatmode.md) - Code generation and deployment automation
- [3.3 constrcution.build.chatmode.md](.github/chatmodes/3.3%20constrcution.build.chatmode.md) - Build REST APIs and Infrastructure as Code

## Quickstart — How to Work with the Assistant

### 1. Seeded Files
This repo creates the `aidlc-docs/` folder with templates and placeholders:
- `aidlc-docs/README.md` — workflow and conventions
- `aidlc-docs/plans/initial-plan.md` — plan template (use this when proposing work)
- `aidlc-docs/prompts.md` — append-only log for prompts and generated outputs

### 2. Create a Plan
- Copy `aidlc-docs/plans/initial-plan.md` to a new file describing Scope, Deliverables, Acceptance Criteria, Timeline, Owner and Reviewers.
- Set `status: "Draft"` while iterating. Add at least one human reviewer.

### 3. Obtain Approval
- Wait for a reviewer to change `status` to `Approved` in the plan file or leave an approving comment in a PR. 
- **Do NOT proceed until approved.**

### 4. Implementation
- After approval, perform small, self-contained commits that implement the plan.
- Open a Pull Request that references the plan filename and lists the minimal test/run steps.
- Add the prompt(s) that produced the changes to `aidlc-docs/prompts.md` with the produced file paths.

### 5. Review & Merge
- Require at least one human reviewer on the PR. 
- Merge only after tests/lint pass and reviewers approve.

## Greenfield Project Flow

For new projects starting from scratch, follow this sequence:

### Phase 1: Setup & Requirements
1. **Initialize workflow**: Use [1. setup.chatmode.md](.github/chatmodes/1.%20setup.chatmode.md) to set up the repository structure and AI delivery workflow.
2. **Create user stories**: Use [2.1 inception.stories.chatmode.md](.github/chatmodes/2.1%20inception.stories.chatmode.md) to generate user stories from high-level product requirements.
   - Input: Product description or vision document
   - Output: `aidlc-docs/story-artifacts/mvp_user_stories.md`
   - Approval gate: Review and approve user stories before proceeding

### Phase 2: Design & Architecture
3. **Domain modeling**: Use [3.1 constrcution.domain.chatmode.md](.github/chatmodes/3.1%20constrcution.domain.chatmode.md) to create component models.
   - Input: User stories from step 2
   - Output: `design/<domain>_component_model.md`
   - Approval gate: Review domain model before implementation

4. **Architecture design**: Use [2.3 inception.architecture.chatmode.md](.github/chatmodes/2.3%20inception.architecture.chatmode.md) to define deployment architecture.
   - Input: Component models, user stories, cloud platform constraints
   - Output: `design/auth_unit.md`, `design/api_gateway_unit.md`, etc.
   - Approval gate: Review architecture decisions and cloud resource plans

### Phase 3: Implementation
5. **Implement software units**: Use [2.2 inception.units.chatmode.md](.github/chatmodes/2.2%20inception.units.chatmode.md) to generate implementation code.
   - Input: Component design specifications
   - Output: Implementation files in `BACKEND/`, `vocabMapper/`, etc.
   - Approval gate: Review implementation plan before code generation

6. **Build REST APIs**: Use [3.3 constrcution.build.chatmode.md](.github/chatmodes/3.3%20constrcution.build.chatmode.md) to create API layer.
   - Input: Service definitions, API framework preference
   - Output: `api/routes/`, `api/controllers/`, OpenAPI specs
   - Approval gate: Review API design and contracts

7. **Generate deployment code**: Use [3.2 constrcution.code.chatmode.md](.github/chatmodes/3.2%20constrcution.code.chatmode.md) for IaC and deployment.
   - Input: Component models, architecture specs, backend code
   - Output: `DEPLOYMENT/terraform/`, deployment scripts, runbooks
   - Approval gate: Review infrastructure and cost estimates

### Example Greenfield Session
```
Developer: "I want to build a multi-tenant SaaS application for document management"

Step 1: Use inception.stories → generates user stories
Step 2: Approve user stories → proceed
Step 3: Use constrcution.domain → generates domain models
Step 4: Approve domain models → proceed
Step 5: Use inception.architecture → generates architecture plans
Step 6: Approve architecture → proceed
Step 7: Use inception.units → generates implementation code
Step 8: Use constrcution.build → generates REST APIs
Step 9: Use constrcution.code → generates deployment infrastructure
```

## Brownfield Project Flow

For existing projects requiring enhancements or refactoring:

### Phase 1: Analysis & Planning
1. **Analyze existing codebase**: Review current implementation, identify areas for enhancement.
2. **Create enhancement user stories**: Use [2.1 inception.stories.chatmode.md](.github/chatmodes/2.1%20inception.stories.chatmode.md) for new features.
   - Input: Feature description + existing system context
   - Output: User stories with acceptance criteria
   - Approval gate: Validate stories don't conflict with existing functionality

### Phase 2: Incremental Design
3. **Update domain models**: Use [3.1 constrcution.domain.chatmode.md](.github/chatmodes/3.1%20constrcution.domain.chatmode.md) to extend existing models.
   - Input: User stories + existing component models
   - Output: Updated component models showing new/changed components
   - Approval gate: Review impact on existing system boundaries

4. **Architecture evolution**: Use [2.3 inception.architecture.chatmode.md](.github/chatmodes/2.3%20inception.architecture.chatmode.md) for infrastructure changes.
   - Input: Existing architecture + new requirements
   - Output: Architecture evolution plan with migration strategy
   - Approval gate: Review changes to deployed resources and migration risks

### Phase 3: Incremental Implementation
5. **Implement new units**: Use [2.2 inception.units.chatmode.md](.github/chatmodes/2.2%20inception.units.chatmode.md) for new components.
   - Input: New component designs + integration points with existing code
   - Output: New implementation files with integration adapters
   - Approval gate: Review integration approach and backward compatibility

6. **Extend or refactor APIs**: Use [3.3 constrcution.build.chatmode.md](.github/chatmodes/3.3%20constrcution.build.chatmode.md) for API changes.
   - Input: Existing API code + new endpoint requirements
   - Output: New/updated routes, versioning strategy, migration guide
   - Approval gate: Review API versioning and breaking change strategy

7. **Update deployment**: Use [3.2 constrcution.code.chatmode.md](.github/chatmodes/3.2%20constrcution.code.chatmode.md) for infrastructure updates.
   - Input: Existing IaC + new resource requirements
   - Output: Updated IaC with blue-green deployment strategy
   - Approval gate: Review rollback plan and deployment risks

### Example Brownfield Session
```
Developer: "Add AI-powered search to existing document management system"

Step 1: Analyze existing search implementation in BACKEND/search/
Step 2: Use inception.stories → generates stories for AI search feature
Step 3: Approve stories → proceed
Step 4: Use constrcution.domain → updates domain models with AI components
Step 5: Approve domain changes → proceed
Step 6: Use inception.units → generates AI integration code
Step 7: Use constrcution.build → adds new /api/v2/ai-search endpoints
Step 8: Use constrcution.code → updates infrastructure for ML model hosting
Step 9: Deploy with blue-green strategy, rollback plan ready
```

## Key Differences: Greenfield vs Brownfield

| Aspect | Greenfield | Brownfield |
|--------|-----------|-----------|
| **Starting point** | Product vision | Existing codebase |
| **User stories** | Full system scope | Feature enhancements |
| **Domain modeling** | Create from scratch | Extend existing models |
| **Architecture** | Design entire system | Evolve existing architecture |
| **Implementation** | Generate all code | Integrate with existing code |
| **Deployment** | Provision all resources | Update existing infrastructure |
| **Risk** | Technical feasibility | Backward compatibility |
| **Approval focus** | Architectural patterns | Migration strategy |

## Example Session Flow

### Standard Greenfield Flow
1. Contributor creates `aidlc-docs/plans/feature-x.md` (status: Draft) using a chat mode
2. Chat mode generates plan and waits for approval
3. Reviewer approves the plan (status: Approved)
4. Chat mode implements changes in current branch
5. Chat mode appends prompt and output files to `aidlc-docs/prompts.md`
6. Contributor opens PR referencing `feature-x.md`
7. Human reviewers review the PR and merge when ready

### Standard Brownfield Flow
1. Contributor identifies enhancement need in existing code
2. Uses appropriate chat mode with existing code context
3. Chat mode generates plan showing existing code + proposed changes
4. Reviewer approves plan including migration/rollback strategy
5. Chat mode implements changes with backward compatibility
6. Chat mode updates `aidlc-docs/prompts.md`
7. Contributor opens PR with feature flag or versioning strategy
8. Human reviewers validate no breaking changes, merge when ready

## Files & Locations

- `aidlc-docs/README.md` — conventions and how-to
- `aidlc-docs/plans/` — plan templates and plan files
- `aidlc-docs/prompts.md` — chronological log of prompts and outputs
- `aidlc-docs/requirements/` — requirement documents and feature specs
- `aidlc-docs/story-artifacts/` — user stories and acceptance criteria
- `aidlc-docs/design-artifacts/` — architecture diagrams and decision records
- `aidlc-docs/validation/` — validation plans and reports
- `.github/chatmodes/` — specialized agentic primitives for each delivery phase

## Recommended Next Steps (Optional)

- Add a GitHub Action that enforces: if code changes are present then a plan exists and is `Approved`, and that `aidlc-docs/prompts.md` includes the relevant prompt entries.
- Add a PR template that requires a link to the plan and a short test checklist.
- Configure branch protection rules requiring at least one reviewer approval.
- Set up CI/CD pipeline to validate generated artifacts (linting, security scans, tests).

## Reference

This workflow is inspired by the AI delivery guidance: https://prod.d13rzhkk8cj2z0.amplifyapp.com/

The agentic primitives in this repository implement a complete SDLC workflow with approval gates, validation, and audit trails for AI-assisted development.

## Questions?

If you need help:
- Review the appropriate chat mode file in [.github/chatmodes/](.github/chatmodes/)
- Check `aidlc-docs/README.md` for detailed conventions
- Review `aidlc-docs/prompts.md` to see examples of previous sessions