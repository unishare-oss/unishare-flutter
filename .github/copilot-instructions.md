# Copilot Instructions — Unishare Flutter

Unishare Flutter is a cross-platform mobile app (iOS, Android, Web) for academic content sharing. Firebase-native, no NestJS API dependency.

## Architecture: Strict Clean Architecture

Every feature lives under `apps/mobile/lib/features/<name>/` with three layers:

```
data/
  datasources/   ← Firebase/Firestore calls and DTOs only
  models/        ← Freezed models with JSON serialization
  repositories/  ← implements domain interfaces
domain/
  entities/      ← pure Dart classes, NO framework imports
  repositories/  ← abstract interfaces
  usecases/      ← single-responsibility use case classes
presentation/
  providers/     ← Riverpod providers (@riverpod codegen)
  screens/       ← GoRouter screen widgets
  widgets/       ← feature-scoped reusable widgets
```

**Hard rules:**
- The `domain/` layer must have zero Flutter or Firebase imports. Pure Dart only.
- `data/` may import Firebase packages. `presentation/` may import Flutter packages.
- Cross-layer imports must only go inward (presentation → domain ← data).
- Use cases are single-responsibility — one public `call` method, no side effects beyond the stated purpose.

## Code Conventions

- **No unbounded `ListView`** — always use `ListView.builder` or `SliverList`.
- **All remote images** must go through `CachedNetworkImage`. Never `Image.network`.
- **No plaintext secrets** in Dart source — use `--dart-define` or `firebase_remote_config`.
- **Every new screen** (`screens/`) must have a corresponding widget test.
- **State management**: `flutter_riverpod` + `riverpod_generator` only. No `setState` in feature screens.
- **Navigation**: `go_router` only. No `Navigator.push` in feature code.
- **Models**: `freezed` + `json_serializable`. No manual `copyWith` or `toJson`.
- **Logging**: always use `AppLogger` (Crashlytics wrapper in `core/logging/`). Never `print` or `debugPrint` in production paths.
- **Offline**: Hive for local persistence. Never write raw files or use `SharedPreferences` for structured data.
- **Error handling**: validate only at system boundaries (user input, Firestore responses). Trust internal domain logic.

## Code Suggestions

When suggesting new code, follow these patterns:

**New screen:**
```dart
class FooScreen extends ConsumerWidget {
  const FooScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { ... }
}
```

**New Riverpod provider:**
```dart
@riverpod
Future<Foo> foo(FooRef ref) async { ... }
```
Never suggest `Provider((ref) => ...)` — always use `@riverpod` codegen.

**New use case:**
```dart
class GetFooUseCase {
  const GetFooUseCase(this._repository);
  final FooRepository _repository;

  Future<Foo> call(String id) => _repository.getFoo(id);
}
```

**Firestore reads:**
- One-shot: `.get()`
- Real-time (only when always needed): `.snapshots()`

**Navigation:**
```dart
context.go('/route');      // replace stack
context.push('/route');    // push onto stack
```
Never `Navigator.of(context).push(...)`.

## Generated Files — Never Suggest Edits

Do not suggest changes to:
- `**/*.g.dart` — Riverpod/JSON codegen
- `**/*.freezed.dart` — Freezed model codegen
- `**/generated_plugin_registrant.*`
- `apps/mobile/android/app/build/**`
- `apps/mobile/ios/Pods/**`

If a generated file has a bug, the fix goes in the source file, then `dart run build_runner build`.

## Stack Reference

| Concern | Package |
|---|---|
| State | `flutter_riverpod` + `riverpod_generator` |
| Navigation | `go_router` |
| Auth | `firebase_auth`, `google_sign_in`, `local_auth` |
| Database | `cloud_firestore` |
| Storage | `firebase_storage` |
| Offline | `hive_flutter` |
| Logging | `firebase_crashlytics` (via `AppLogger`) |
| Feature flags | `firebase_remote_config` |
| Images | `cached_network_image` |
| Secrets | `flutter_secure_storage` |
| Models | `freezed` + `json_serializable` |
| Typography | `google_fonts` (Space Grotesk + Fira Code) |

## PR Review Checklist

Flag the PR if any of these are missing or violated:

- [ ] `flutter analyze` passes (no errors or warnings)
- [ ] `dart format .` has been run (no formatting diffs)
- [ ] Domain layer has zero Flutter/Firebase imports
- [ ] No unbounded `ListView` (must be `ListView.builder` or `SliverList`)
- [ ] Remote images use `CachedNetworkImage`
- [ ] No hardcoded secrets or API keys in Dart source
- [ ] Every new screen has at least one widget test
- [ ] Generated files (`*.g.dart`, `*.freezed.dart`) are not manually edited
- [ ] New Riverpod providers use `@riverpod` codegen, not manual `Provider()`
- [ ] New Firestore queries use `.get()` for one-shot reads, `.snapshots()` only for real-time listeners that are always needed
- [ ] No `print` or `debugPrint` in production paths — use `AppLogger`

## Planning Workflow

Non-trivial features follow: Tech Proposal → Tech Spec → Implementation → Review.

- Proposals live in `tech-proposals/NNNN-slug.md`
- Specs live in `tech-specs/NNNN-slug.md`
- ADRs live in `docs/decisions/NNNN-slug.md`

If a PR introduces a new feature spanning more than 2 files, check whether a corresponding spec exists in `tech-specs/`. Flag if there is no approved spec behind the implementation.
