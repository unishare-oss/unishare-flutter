# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## Project Overview

**Unishare Flutter** is a cross-platform mobile app (iOS, Android, Web) for academic content sharing — Firebase-native, no dependency on the NestJS API.

## Repo Structure

```
.
├── CLAUDE.md
├── .claude/
│   ├── settings.json
│   ├── agents/          ← architect, flutter-engineer, qa-engineer, security-reviewer
│   ├── hooks/           ← automated logging and git guardrails
│   └── skills/
├── apps/
│   └── mobile/          ← Flutter app (run all flutter commands from here)
│       ├── lib/
│       ├── test/
│       ├── integration_test/
│       ├── android/
│       └── ios/
├── packages/            ← shared Dart packages (design system, auth, networking)
├── tools/               ← repo scripts (codegen, localization, release)
├── tech-proposals/      ← Tech Proposals (auto-rendered on docs site)
├── tech-specs/          ← Tech Specs (auto-rendered on docs site)
├── docs/
│   ├── decisions/       ← Architecture Decision Records (auto-rendered on docs site)
│   ├── sessions/        ← per-session agent scratchpads
│   ├── agent-runs/      ← structured reviewer audit reports
│   └── agent-log.md     ← automated session log
└── .github/workflows/
```

## Commands

All Flutter commands run from `apps/mobile/`:

```bash
cd apps/mobile

flutter pub get                    # Install dependencies
flutter run                        # Run on connected device/emulator
flutter run -d chrome              # Run on web
flutter build apk                  # Build Android APK
flutter build web                  # Build for web
flutter test                       # Run unit + widget tests
flutter test --coverage            # Run tests with coverage report
flutter test integration_test/     # Run integration tests
flutter analyze                    # Static analysis
dart format .                      # Format all Dart files
flutter pub run build_runner build # Generate Riverpod/Freezed code
flutter pub run build_runner watch # Watch mode for code gen
flutterfire configure              # Link to Firebase project
```

Firebase commands run from the **repo root** (where `firebase.json` lives):

```bash
# Deploy Firestore security rules
firebase deploy --only firestore:rules

# Deploy Firestore indexes
firebase deploy --only firestore:indexes

# Deploy both rules and indexes together
firebase deploy --only firestore
```

Seed reference data (universities, departments, courses) — one-time per environment:

```bash
# 1. Get a service account key:
#    Firebase Console → Project Settings → Service accounts → Generate new private key
#    Save as tools/service-account.json (gitignored)

# 2. Install seed dependencies
cd tools && pnpm install

# 3. Run the seed
node seed_firestore.js service-account.json
```

## Architecture

Strict Clean Architecture — the Domain layer must have **zero Flutter or Firebase imports**.

```
apps/mobile/lib/
  features/<name>/
    data/
      datasources/     ← Firebase/Firestore calls, DTOs
      models/          ← Freezed models with JSON serialization
      repositories/    ← implements domain interfaces
    domain/
      entities/        ← pure Dart classes, no framework imports
      repositories/    ← abstract interfaces
      usecases/        ← single-responsibility use case classes
    presentation/
      providers/       ← Riverpod providers (@riverpod code gen)
      screens/         ← GoRouter screen widgets
      widgets/         ← feature-scoped reusable widgets
  shared/
    widgets/           ← app-wide reusable components
    theme/             ← ThemeData, typography, color tokens
  core/
    firebase/          ← Firebase initialization
    storage/           ← Hive setup and helpers
    logging/           ← AppLogger (Crashlytics wrapper)

apps/mobile/test/
  unit/
  widget/
  goldens/

apps/mobile/integration_test/
```

## Stack

| Concern | Package |
|---|---|
| State | `flutter_riverpod` + `riverpod_generator` |
| Navigation | `go_router` |
| Auth | `firebase_auth`, `google_sign_in`, `local_auth` |
| Database | `cloud_firestore` |
| Storage | `firebase_storage` |
| Offline | `hive_flutter` |
| Logging | `firebase_crashlytics` |
| Feature flags | `firebase_remote_config` |
| Images | `cached_network_image` |
| Secrets | `flutter_secure_storage` |
| Models | `freezed` + `json_serializable` |
| Typography | `google_fonts` (Space Grotesk + Fira Code) |

## Agents

Role-scoped agents live in `.claude/agents/`. Always specify which agent is active at the start of a session.

- **architect** — system design, Firestore schema, and PR review only. Cannot write feature code.
- **flutter-engineer** — implements features in Data and Presentation layers. Does not approve own PRs.
- **qa-engineer** — owns test matrix, CI/CD, and accessibility sweeps. Does not write feature code.
- **security-reviewer** — audits auth flows, Firestore rules, and secrets. Read-only reviewer.

The agent that writes code must NOT be the agent that approves it.

## Planning Workflow

Every non-trivial feature follows this pipeline before any code is written:

### 1. Tech Proposal (`tech-proposals/NNNN-slug.md`)
The **architect** writes a proposal using the stencil at `docs/stencils/tech-proposal.md` (rendered at <https://unishare-oss.github.io/unishare-flutter/stencils/tech-proposal/>). Covers: problem, proposed solution, alternatives considered, and open questions. The team approves before moving on.

> Skip for changes touching ≤ 2 files with no architectural impact.

### 2. Tech Spec (`tech-specs/NNNN-slug.md`)
The **architect** expands the approved proposal into a full spec using `docs/stencils/tech-spec.md`. Covers: Clean Architecture layer breakdown, Firestore schema, Riverpod providers, acceptance criteria, and test plan.

### 3. Implementation
The **flutter-engineer** implements strictly following the approved spec. No scope creep beyond what the spec describes.

### 4. Review
Submit for review to **architect** or **qa-engineer** — never the same agent that wrote the code. Reviewer checks implementation against the spec.

---

For any task spanning more than 2 files or touching architecture, use Plan Mode first.

## Do Not Edit

Never edit these files — they are generated by build tools:

- `**/*.g.dart` — Riverpod/JSON codegen output (`build_runner`)
- `**/*.freezed.dart` — Freezed model codegen output
- `**/generated_plugin_registrant.*` — Flutter plugin registry
- `apps/mobile/android/app/build/**` — Android build artifacts
- `apps/mobile/ios/Pods/**` — CocoaPods dependencies

To regenerate: `dart run build_runner build --delete-conflicting-outputs`

## Conventions

- Domain layer: zero Flutter or Firebase imports — pure Dart only
- No unbounded `ListView` — always `ListView.builder` or `SliverList`
- All remote images through `CachedNetworkImage`
- No plaintext secrets in Dart source — use `--dart-define` or `firebase_remote_config`
- `google-services.json` and `GoogleService-Info.plist` are gitignored
- Run `flutter analyze` and `dart format .` before every commit
- Every screen must have a widget test

## Docs Folder Conventions

Each folder serves a distinct purpose:

| Folder | Written by | Format | Purpose |
|--------|-----------|--------|---------|
| `tech-proposals/` | Architect | `NNNN-slug.md` | Tech Proposals — problem + solution + alternatives, approved before spec |
| `tech-specs/` | Architect | `NNNN-slug.md` | Tech Specs — full layer design, schema, acceptance criteria |
| `docs/sessions/` | Any agent | `YYYY-MM-DD-task-slug.md` | Session scratchpad for context passing between agents |
| `docs/agent-runs/` | Reviewer agents | `YYYY-MM-DD-<role>-<task>.md` | Structured audit reports (security, QA, architect reviews) |
| `docs/decisions/` | Architect | `NNNN-slug.md` | Architecture Decision Records (ADRs) |
| `docs/agent-log-<member>.md` | Stop hook | append-only | Per-member chronological session log |

**Proposals** (`tech-proposals/`) — use the stencil at `docs/stencils/tech-proposal.md`. Must be approved before a spec is written. Auto-rendered on the docs site when pushed to `main`.

**Specs** (`tech-specs/`) — use the stencil at `docs/stencils/tech-spec.md`. Must reference the approved proposal. Implementation only begins once the spec is approved. Auto-rendered on the docs site when pushed to `main`.

**Sessions** (`docs/sessions/`) — create one per work session using `_template.md`. Fill in context, plan, and handoff. The next agent reads this before starting.

**Agent runs** (`docs/agent-runs/`) — every reviewer agent writes its final report here (role + timestamp + session-id header). This is the audit trail: for every line of code you can show what agent proposed it and which reviewer cleared it.

**Decisions** (`docs/decisions/`) — the **architect agent must automatically write and commit an ADR immediately after any non-trivial design decision is made**, without waiting to be asked. Use the stencil at `docs/stencils/adr.md`. Number sequentially (0001, 0002, …). Status values: `PROPOSED` → `ACCEPTED` → `SUPERSEDED by #NNNN`. The ADR is committed directly to `main` — the docs site updates automatically.

## Agent Logging (mandatory for every session)

At the start of every session, before doing any work, ask the user for their name if not known, then immediately append to `docs/agent-log-<member>.md` (where `<member>` is the git user name lowercased with spaces replaced by hyphens, e.g. `docs/agent-log-jane-doe.md`):

```
---
Date: YYYY-MM-DD HH:MM
Member: [member name]
Agent: [architect | flutter-engineer | qa-engineer | security-reviewer]
Task: [one-line description of what this session will accomplish]
Prompt: [the exact task or instruction the member gave]
```

At the end of the session, append the outcome block:

```
Outcome: [what was completed]
Decisions: [non-obvious choices made and why]
Handoff: [what the next agent or reviewer needs to know]
Review: [PENDING | APPROVED by <name> | CHANGES REQUESTED by <name>]
```

The Stop hook will automatically append the changed file list after this block.

### Rules

- Log every session, even if no files were changed (planning, review-only sessions)
- If switching agent roles mid-session, close the current entry and open a new one
- The agent that writes code must not be the agent listed under Review: APPROVED
- For Plan Mode sessions, paste the full task breakdown under the Prompt field
