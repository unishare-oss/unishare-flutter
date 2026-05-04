# Session: 2026-05-03-post-integration

**Date:** 2026-05-03
**Member:** Slade
**Agent:** flutter-engineer
**Task:** Implement post integration feature (SPEC-0004)

## Context

PROP-0004 (ACCEPTED) and SPEC-0004 (APPROVED) are complete. ADR-0003 records the package decisions.
Folder structure and stub files have been scaffolded. The engineer picks up from here.

Key references:
- Spec: `tech-specs/0004-post-integration.md`
- Proposal: `tech-proposals/0004-post-integration.md`
- ADR: `docs/decisions/0003-post-integration-packages.md`

Domain entities needed:
- `PostDraft` (offline draft with `uploadedUrls` map for idempotent retry)
- `Post` (published feed post, matches PROP-0003 Firestore schema)

Firestore collections involved:
- `posts/{postId}` — single write target, direct client write (no Cloud Functions)

Firebase Storage paths:
- `posts/{uid}/{uuid}-{filename}` — scoped per user, enforced by Storage Rules

Screens required:
- `CreatePostScreen` — title (required), body, tags, media picker, submit

New packages to add to `pubspec.yaml`:
- `connectivity_plus` — connectivity stream for draft queue sync
- `file_picker` — JPEG, PNG, WebP, PDF selection (per ADR-0003)

Platform permission entries required:
- `Info.plist`: `NSPhotoLibraryUsageDescription`
- `AndroidManifest.xml`: `READ_EXTERNAL_STORAGE`

## Plan

1. Add `connectivity_plus` and `file_picker` to `pubspec.yaml`; add platform permissions
2. Implement `PostDraft.copyWith` and `PostDraftModel` Hive adapter (verify `typeId: 1` is free)
3. Implement `PostStorageDatasource` — upload file, return download URL
4. Implement `PostFirestoreDatasource` — write single document to `posts/{postId}`
5. Implement `PostRepositoryImpl` — 6-step upload sequencing algorithm from spec
6. Implement `CreatePost` and `SyncDraftQueue` use cases
7. Implement `CreatePostNotifier` and `DraftQueueNotifier` Riverpod providers
8. Implement `CreatePostScreen`, `MediaAttachmentPicker`, `DraftQueueIndicator` widgets
9. Register `/posts/create` route in GoRouter; confirm existing redirect covers it
10. Call `initPostDraftBox()` in `main.dart` after `Hive.initFlutter()`
11. Update `firestore.rules` and `storage.rules` per spec
12. Add `posts | authorId ASC, createdAt ASC` composite index to `firestore.indexes.json`
13. Run `dart run build_runner build --delete-conflicting-outputs`
14. Write all tests per the test plan; run `flutter analyze` and `dart format .`

## Notes

<!-- Running notes during the session — discoveries, blockers, pivots. -->

## Handoff

**To:** architect or qa-engineer (reviewer)
**Done:**
**Not done:**
**Watch out for:**
- `typeId: 1` must be verified free before `PostDraftModel` is registered
- Confirm `_RouterNotifier.redirect` in `router.dart` covers `/posts/create` before closing PR
- `post_repository.dart` may already exist from PROP-0003 feed work — do not break `watchFeed`
