# /new-proposal

Write a new Tech Proposal before any design or implementation begins.

## Usage

```
/new-proposal <feature-name>
```

Example: `/new-proposal post-feed`

## When to use

Any change that touches architecture, introduces a new dependency, or where multiple valid approaches exist. Skip only if the change touches ≤ 2 files with zero architectural impact.

## Steps

1. **Determine the next proposal number** — check `tech-proposals/` and increment the highest NNNN by 1.

2. **Convert the feature name** to kebab-case (e.g. `Post Feed` → `post-feed`).

3. **Ask the user these questions** using `AskUserQuestion` before writing anything — collect all answers in one call:
   - What problem does this feature solve, and who is affected?
   - Are there any constraints or requirements the solution must meet (performance, offline support, cost, etc.)?
   - Do you already have a preferred approach in mind, or should the architect explore options freely?
   - Are there any approaches you want to explicitly rule out?

4. **Invoke the `architect` subagent** with the user's answers as context to write the proposal file at `tech-proposals/NNNN-<slug>.md` using the stencil at `docs/stencils/tech-proposal.md`. The architect must:
   - Fill every section: Problem, Goals, Non-goals, Options (at least 2), Recommendation, Open questions
   - Set `status: DRAFT` initially
   - Ground the Problem section in what the user described, not generic filler
   - List at minimum 2 concrete options with pros, cons, and effort estimate
   - If the user ruled out any approaches, document them as rejected options with the reason
   - Include a clear recommendation with justification

5. **After the architect writes the draft**, ask the user: "Does this capture the problem correctly, or should anything be adjusted before it goes to the team for review?" Apply any corrections before moving on.

6. **Print a review checklist** the team must sign off on before the proposal moves to `PROPOSED`:

   - [ ] Problem statement is specific and includes user impact
   - [ ] At least 2 options with pros/cons/effort
   - [ ] Recommendation justified in terms of trade-offs
   - [ ] Open questions listed
   - [ ] No implementation code or file-level details (those belong in the spec)

7. **Remind**: once the team approves the proposal, run `/new-spec <NNNN-slug>` to write the Tech Spec. Do not begin implementation until the spec is also approved.
