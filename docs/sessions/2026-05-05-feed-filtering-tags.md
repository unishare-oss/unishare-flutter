# Session: 2026-05-05-feed-filtering-tags

**Date:** 2026-05-05  
**Member:** Sudakarn  
**Agent:** flutter-engineer  
**Task:** Implement SPEC-0005 feed filtering by tags

## Context

PROP-0005 (approved) and SPEC-0005 (DRAFT — two blocking open questions remain) define the full design.
All stub files have been scaffolded under `apps/mobile/lib/features/post_feed/`.

Note: The spec file map lists `lib/features/post/` as the location for all new files, but the repo
already has `lib/features/post_feed/` scaffolded for feed-specific code. All filtering files
were placed in `post_feed/` to match the existing structure. The spec should be updated to
reflect this before moving to APPROVED.

Blocking open questions from SPEC-0005 (must resolve before implementing data layer):
1. Curated tag collection name — confirm against `tools/seed_firestore.js`.
2. `users/{uid}/preferences` as sub-document vs. top-level fields on the user doc.

## Plan

1. Resolve the two open questions (check seed script, check existing `users` Security Rules).
2. Implement domain layer — entities are complete; implement the three use cases (no Firebase imports).
3. Implement data layer — `TagFirestoreDatasource`, `PreferencesFirestoreDatasource`, update `PostFirestoreDatasource` with `array-contains-any` predicate and Hive cache key.
4. Implement `TagRepositoryImpl` and `PreferencesRepositoryImpl`.
5. Extend `PostRepository` interface with `getPostFeed({tagFilter})` and update `PostRepositoryImpl`.
6. Add composite index to `firestore.indexes.json` (`posts | tags CONTAINS, createdAt DESC`).
7. Add Security Rules for `users/{uid}/preferences` and `courses/{courseId}` (read-only).
8. Wire Riverpod providers — `tagListProvider`, `FilterPreferencesNotifier`, updated `FeedNotifier`.
9. Implement `FeedScreen` with filter chip row and `FeedEmptyStateWidget`.
10. Implement `FilterPickerWidget`.
11. Register `FeedScreen` in GoRouter.
12. Run `dart run build_runner build --delete-conflicting-outputs` after each Freezed/Riverpod file.
13. Write unit + widget tests per the SPEC-0005 test plan.
14. Run `flutter analyze` and `dart format .` before committing.

## Notes

Domain entities are already written with full implementations (no TODOs needed).
Data layer datasource stubs have TODO comments explaining what to implement.
Presentation stubs have TODO comments for provider wiring.

Watch out for:
- Hive `typeId` collision — audit existing adapters before assigning IDs to any new Hive models.
- The `array-contains-any` composite index must be deployed (`firebase deploy --only firestore:indexes`)
  before the filtered query will work in Firestore — failing to deploy causes a runtime error.
- `PostRepository` interface is in `lib/features/post/` (not `post_feed/`) — the engineer must extend
  it there and update `PostRepositoryImpl` in the same `post/` module.

## Handoff

**To:** architect (for spec update) or flutter-engineer (for implementation)  
**Done:** All stub files scaffolded; domain entities and use cases written in full; session doc created.  
**Not done:** Data layer, presentation layer, tests, GoRouter wiring, Firestore index/rules deployment.  
**Watch out for:** The two blocking open questions in SPEC-0005 — do not implement data layer until resolved.
