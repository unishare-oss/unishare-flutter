# /new-spec

Write a Tech Spec from an approved Tech Proposal. Run this after `/new-proposal` is approved.

## Usage

```
/new-spec <NNNN-slug>
```

Example: `/new-spec 0003-post-feed`

## When to use

After the corresponding Tech Proposal has status `ACCEPTED`. Never write a spec without an approved proposal.

## Steps

1. **Read the approved proposal** at `tech-proposals/<NNNN-slug>.md` to extract the chosen option, goals, and non-goals.

2. **Ask the user these questions** using `AskUserQuestion` before writing anything — collect all answers in one call:
   - Are there any Firestore collections or fields that must be reused from existing features?
   - Are there screens or flows from a Figma design, or should the architect define the UI structure from scratch?
   - Any edge cases or error states you want explicitly handled (e.g. offline, empty state, permission denied)?
   - Are there open questions from the proposal that have since been resolved?

3. **Invoke the `architect` subagent** with the proposal content and user answers as context to write the spec at `tech-specs/<NNNN-slug>.md` using the stencil at `docs/stencils/tech-spec.md`. The architect must:
   - Reference the proposal in the frontmatter (`proposal: PROP-NNNN`)
   - Provide the full Clean Architecture file map (every file to create or modify)
   - Define all public Dart interfaces (entities, repository abstracts, use case signatures)
   - Include Firestore schema if applicable
   - Write a complete test plan (unit + widget tests, one row per file)
   - Set `status: DRAFT` initially

4. **After the architect writes the draft**, ask the user: "Does the file map and interface design look right, or are there layers/files missing?" Apply any corrections before finalizing.

5. **Print a review checklist** before the spec moves to `APPROVED`:

   - [ ] References the approved proposal
   - [ ] File map is complete — every layer covered (data / domain / presentation)
   - [ ] All public interfaces defined in Dart (no pseudocode)
   - [ ] Firestore schema documented (if applicable)
   - [ ] Test plan has one entry per screen and per use case
   - [ ] Out of scope section filled in
   - [ ] Open questions resolved or explicitly deferred

6. **Remind**: once the spec is approved, run `/new-feature <name>` to scaffold the folder structure, then hand the spec to the `flutter-engineer` subagent to implement.
