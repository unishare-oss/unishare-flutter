# Contributing to Unishare Flutter

## Workflow

All work follows the agent-driven planning workflow defined in `CLAUDE.md`. Before writing any code:

1. **Architect** designs the layer structure and Firestore schema
2. Plan is presented and approved
3. **Flutter Engineer** implements the approved plan
4. **Architect or QA Engineer** reviews — never the same agent that wrote the code

For tasks spanning more than 2 files or touching architecture, use Plan Mode first.

## Branching

```
main              ← stable, always green
feat/<name>       ← feature branches (from main)
fix/<name>        ← bug fixes
chore/<name>      ← tooling, deps, CI
```

Branch from `main`. Open a PR back to `main`. Squash-merge on approval.

## Commit style

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add theme switcher screen
fix: prevent crash when Hive box not open
refactor: remove duplicate border token from AppColors
test: add lerp mid-point test for AppColors
chore: upgrade flutter to 3.24
docs: add ADR for single-slot theming
```

## Running the app

All Flutter commands run from `apps/mobile/`:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome
flutter test
flutter analyze
dart format .
```

## Architecture rules

- **Domain layer**: zero Flutter or Firebase imports — pure Dart only
- No unbounded `ListView` — always `ListView.builder` or `SliverList`
- All remote images through `CachedNetworkImage`
- No plaintext secrets — use `--dart-define` or `firebase_remote_config`
- Every screen must have a widget test

## Code generation

Never edit `*.g.dart` or `*.freezed.dart` files directly. Regenerate with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## PR checklist

See `.github/PULL_REQUEST_TEMPLATE.md` — the checklist is enforced on every PR.

## Agent logging

Every session must be logged in `docs/agent-log.md` per the format in `CLAUDE.md`. The agent that writes code must not be the agent listed under `Review: APPROVED`.
