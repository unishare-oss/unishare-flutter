# /pr-review

Orchestrated PR review — runs all reviewer agents in the correct order and collects sign-offs.

## Usage

```
/pr-review <PR number or branch name>
```

Example: `/pr-review 42` or `/pr-review feat/post-feed`

## What this does

Fans out to three reviewer agents in parallel, waits for all reports, then produces a merged verdict.
The engineer who wrote the code must NOT be the one running this command on their own PR.

## Steps

1. **Fetch the diff** — run `git diff main...<branch>` (or fetch the PR diff if a PR number is given).
   Summarise: files changed, lines added/removed, features touched.

2. **Fan out in parallel** — invoke all three reviewers with the diff as context:

   - `@security-reviewer` — threat model + secret scan + Firestore rules audit
   - `@qa-engineer` — coverage gap + accessibility sweep + performance check
   - `@architect` — layer boundary violations + domain purity + schema consistency

3. **Wait for all three reports** — each agent writes its report to `docs/agent-runs/`.

4. **Merge the verdicts**:

   | Agent | Verdict | Blocking findings |
   |-------|---------|-------------------|
   | security-reviewer | | |
   | qa-engineer | | |
   | architect | | |

5. **Overall verdict**:
   - **APPROVED** — all three passed, zero blocking findings
   - **CHANGES REQUESTED** — list every blocking finding with the owning agent and required fix
   - **BLOCKED** — any Critical security finding or broken architecture invariant

6. **Post the merged report** to the PR description (or print it for the human to paste).

## Rules

- Never approve a PR that touches auth, crypto, or PII without a security-reviewer APPROVED
- Never approve a PR with a new unbounded `ListView` or uncached image
- Architecture violations (domain layer importing Flutter/Firebase) are always blocking
