# /new-feature

Scaffold a new feature following Clean Architecture. Run this before writing any code.

## Usage

```
/new-feature <feature-name>
```

Example: `/new-feature post-feed`

## What this does

Creates the full folder structure and empty stub files for a new feature module,
then opens a session scratchpad so the architect and engineer have a shared starting point.

## Steps

1. **Confirm the feature name** — convert to snake_case if needed (e.g. `post-feed` → `post_feed`)

2. **Create the folder structure** under `apps/mobile/lib/features/<name>/`:

```
<name>/
  data/
    datasources/   ← empty, add Firebase calls here
    models/        ← empty, add Freezed models here
    repositories/  ← empty, implement domain interfaces here
  domain/
    entities/      ← empty, add pure Dart entities here
    repositories/  ← empty, add abstract interfaces here
    usecases/      ← empty, add use case classes here
  presentation/
    providers/     ← empty, add @riverpod providers here
    screens/       ← empty, add GoRouter screens here
    widgets/       ← empty, add feature widgets here
```

3. **Create a session scratchpad** at `docs/sessions/YYYY-MM-DD-<name>.md` from the template in
   `docs/sessions/_template.md`. Fill in:
   - Task: "Implement <name> feature"
   - Plan: list the domain entities needed, the Firestore collections involved, and the screens required

4. **Print a checklist** the engineer must complete before submitting for review:

   - [ ] Domain entities defined (zero Flutter/Firebase imports)
   - [ ] Repository interfaces defined in `domain/repositories/`
   - [ ] Firestore data source implemented in `data/datasources/`
   - [ ] Freezed models with `fromJson`/`toJson` in `data/models/`
   - [ ] Repository implementation in `data/repositories/`
   - [ ] Use cases in `domain/usecases/` (one class, one public method each)
   - [ ] Riverpod providers in `presentation/providers/` (code gen — `@riverpod`)
   - [ ] Screens registered in GoRouter
   - [ ] Widget test for every screen
   - [ ] `flutter analyze` passes, `dart format .` clean

5. **Remind**: run `dart run build_runner build --delete-conflicting-outputs` after adding Freezed models
   or Riverpod providers.
