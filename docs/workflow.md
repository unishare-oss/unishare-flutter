# Feature Implementation Workflow

This is the end-to-end process for implementing any non-trivial feature in Unishare. Follow it in order — do not skip steps.

> **Skip the proposal and spec only if your change touches ≤ 2 files with zero architectural impact.**

---

## Overview

```
/new-proposal  →  /new-spec  →  /new-feature  →  implement  →  /pr-review
```

---

## Step 1 — Write a Tech Proposal

**Command:** `/new-proposal <feature-name>`

**Example:** `/new-proposal notifications`

Claude will ask you a few questions before writing anything:

- What problem does this solve and who is affected?
- Any constraints the solution must meet?
- Do you have a preferred approach, or should the architect explore freely?
- Any approaches to rule out?

The `architect` agent then writes `tech-proposals/NNNN-slug.md` covering the problem, options, trade-offs, and a recommendation.

**Your job:** Read the draft, correct anything wrong, then get team sign-off. Once approved, change `status` to `ACCEPTED`.

> Do not proceed to Step 2 until the proposal is `ACCEPTED`.

---

## Step 2 — Write a Tech Spec

**Command:** `/new-spec <NNNN-slug>`

**Example:** `/new-spec 0004-notifications`

Claude will ask you:

- Any existing Firestore collections to reuse?
- Is there a Figma design, or should the architect define the UI structure?
- Edge cases to explicitly handle (offline, empty state, permission denied)?
- Any open questions from the proposal that have since been resolved?

The `architect` agent then writes `tech-specs/NNNN-slug.md` with the full Clean Architecture file map, Dart interfaces, Firestore schema, and test plan.

**Your job:** Check that the file map is complete and the interfaces look right. Once approved, change `status` to `APPROVED`.

> Do not write any code until the spec is `APPROVED`.

---

## Step 3 — Scaffold the Feature

**Command:** `/new-feature <feature-name>`

**Example:** `/new-feature notifications`

This creates the full folder structure under `apps/mobile/lib/features/<name>/`:

```
<name>/
  data/
    datasources/
    models/
    repositories/
  domain/
    entities/
    repositories/
    usecases/
  presentation/
    providers/
    screens/
    widgets/
```

It also creates a session scratchpad at `docs/sessions/YYYY-MM-DD-<name>.md` for context passing between agents.

---

## Step 4 — Implement

Hand the approved spec and the session scratchpad (`docs/sessions/YYYY-MM-DD-<name>.md`) to the `flutter-engineer` agent — the scratchpad has the entity list, Firestore collections, and screens already mapped out from step 3. Before writing any code, the engineer will ask you about open UI decisions:

- Where should primary actions live? (FAB, app bar, inline, bottom bar)
- What do empty states look like?
- What happens on error? (snackbar, banner, full error screen)
- Do loading states need skeletons or spinners?
- Do destructive actions need a confirmation dialog?

The engineer implements strictly from the approved spec — no scope beyond what the spec describes.

**Implementation checklist** (must be complete before review):

- [ ] Domain entities defined — zero Flutter/Firebase imports
- [ ] Repository interfaces in `domain/repositories/`
- [ ] Firestore data source in `data/datasources/`
- [ ] Freezed models with `fromJson`/`toJson` in `data/models/`
- [ ] Repository implementation in `data/repositories/`
- [ ] Use cases in `domain/usecases/` — one class, one public method each
- [ ] Riverpod providers in `presentation/providers/` using `@riverpod`
- [ ] Screens registered in GoRouter
- [ ] Widget test for every screen
- [ ] `flutter analyze` passes, `dart format .` clean
- [ ] Run `dart run build_runner build --delete-conflicting-outputs` after adding Freezed models or Riverpod providers

---

## Step 5 — Review

**Command:** `/pr-review <branch-name>`

**Example:** `/pr-review feat/notifications`

> The engineer who wrote the code must NOT run this on their own PR.

This fans out to three reviewer agents in parallel:

| Agent               | Checks                                              |
| ------------------- | --------------------------------------------------- |
| `architect`         | Layer boundaries, domain purity, schema consistency |
| `qa-engineer`       | Coverage gaps, accessibility, performance           |
| `security-reviewer` | Auth flows, Firestore rules, secret handling        |

Each agent writes a report to `docs/agent-runs/`. The merged verdict is one of:

- **APPROVED** — all three passed, zero blocking findings
- **CHANGES REQUESTED** — blocking findings listed with required fixes
- **BLOCKED** — critical security finding or broken architecture invariant

---

## Debugging

If you hit a bug at any point:

**Command:** `/debug <description>`

**Example:** `/debug Feed screen crashes when scrolling past 20 posts`

The debug workflow follows: reproduce → form hypotheses → fix root cause → write regression test. It never suppresses exceptions or deletes failing tests to make CI green.

---

## Agent Roles

| Agent               | Can do                                   | Cannot do          |
| ------------------- | ---------------------------------------- | ------------------ |
| `architect`         | Write proposals, specs, ADRs, PR reviews | Write feature code |
| `flutter-engineer`  | Implement features, write tests          | Approve own PRs    |
| `qa-engineer`       | Test matrix, CI/CD, accessibility sweeps | Write feature code |
| `security-reviewer` | Audit auth, Firestore rules, secrets     | Approve own audits |

The agent that writes code is never the agent that approves it.

---

## Where Things Live

| What                          | Where                              |
| ----------------------------- | ---------------------------------- |
| Tech Proposals                | `tech-proposals/NNNN-slug.md`      |
| Tech Specs                    | `tech-specs/NNNN-slug.md`          |
| Architecture Decisions (ADRs) | `docs/decisions/NNNN-slug.md`      |
| Session scratchpads           | `docs/sessions/YYYY-MM-DD-task.md` |
| Review reports                | `docs/agent-runs/`                 |
| Session log                   | `docs/agent-log.md`                |
| Stencils                      | `docs/stencils/`                   |
