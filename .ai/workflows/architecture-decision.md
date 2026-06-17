# Workflow: Architecture Decision Process

Procedure for proposing, discussing, and documenting critical technical and architectural decisions.

---

## 🎯 Purpose
To ensure all significant engineering decisions (e.g. database selections, smart contract upgrades, library additions) are evaluated, debated, approved by the team, and historically logged.

---

## 🛠️ Step-by-Step Procedure

### 1. Identify Need for ADR
An Architecture Decision Record (ADR) is required if:
* You are introducing a new framework or core library.
* You are modifying database schemas or relationships.
* You are changing contract interfaces, upgrade patterns, or access architectures.
* You are introducing external messaging channels or off-ramps (e.g., swapping gateways).

### 2. Propose ADR Using Template
* Copy [.ai/templates/adr-template.md](file:///c:/Users/user/Desktop/bikkofarms-platform/.ai/templates/adr-template.md) to `.ai/decisions/`.
* Name the file sequentially: `[NNNN]-[short-slug].md` (e.g., `0002-migrate-to-drizzle-orm.md`).
* State Context, Alternatives considered, Proposed design, Consequences, and Risks. Set Status to `Proposed`.

### 3. Share & Gather Feedback
* Open a pull request containing only the ADR file.
* Share the PR link in team channels for comments.
* Answer questions and refine proposal details based on feedback.

### 4. Approval Gate
* The Senior Full Stack Engineer or Tech Lead must review and approve.
* Once agreed upon, update the status field in the ADR to `Accepted` (or `Rejected` if team decided otherwise).
* Merge the PR to register the ADR in repository history.
