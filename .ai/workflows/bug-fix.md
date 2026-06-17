# Workflow: Bug Fix Process

Standard operating procedure for identifying, tracking, resolving, and testing software bugs.

---

## 🧭 Flow Map
`Issue Reported → Reproduce Locally → Create Test Case (Red) → Implement Fix (Green) → PR Review → Deploy & Validate`

---

## 🛠️ Step-by-Step Procedure

### 1. Verification & Reproduction
* Verify the reported issue from logs, screenshots, or transaction hashes.
* Attempt to reproduce the bug in a local development environment.
* Document exact steps, browser details, inputs, and database states.

### 2. Isolate & Write Failing Test
* Write a failing unit or integration test (`red test`) that reproduces the bug under the reported inputs.
* Confirm that the test fails predictably.

### 3. Implement the Fix
* Code the minimal, cleanest correction that resolves the root issue.
* Avoid editing unrelated logic or changing APIs.
* Verify that the failing test now passes (`green test`), and that the rest of the test suite remains successful.

### 4. Code Review & PR
* Create a pull request naming the branch `fix/[bug-description]`.
* Reference the issue ID in the PR body. Include the test script and logs verifying successful execution.

### 5. Deploy & Verify
* Release the fix to staging.
* Perform manual smoke tests. If resolved, merge the PR to `main` for production deploy.
