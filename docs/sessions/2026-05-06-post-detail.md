# Session: 2026-05-06-post-detail

**Date:** 2026-05-06  
**Member:** khinnadiko  
**Agent:** flutter-engineer  
**Task:** Implement Post Detail Page (SPEC-0006)

## Context

SPEC-0006 is APPROVED. Stub files have been scaffolded into `apps/mobile/lib/features/post/`. The feature extends the existing `post` feature folder — no new top-level feature directory.

Key decisions from the spec:
- Data strategy: hybrid seed-then-stream (`postDetailProvider` as `AsyncNotifier` family)
- Route `/posts/:postId` declared outside `StatefulShellRoute` (no navbar)
- `PostCard.onTap` calls `context.push('/posts/${post.id}', extra: post)`
- Likes use a separate `LikeRepository`; `likesCount` is Cloud Function–managed
- Comments: flat list, `posts/{postId}/comments` subcollection, `createdAt ASC` index
- Attachments: heterogeneous — image / pdf / video; `mediaTypes: string[]` parallel to `mediaUrls`
- Guests: read-only; like button disabled, comment input hidden

Spec: `tech-specs/0006-post-detail-page.md`

## Plan

1. Extend `Post` entity — add `mediaTypes: List<String>` field
2. Extend `PostRepository` interface — add `Stream<Post> watchPost(String postId)`
3. Implement `PostFirestoreDatasource.watchPost` and update `createPost` to write `mediaTypes`
4. Implement `PostRepositoryImpl.watchPost`
5. Implement `CommentFirestoreDatasource` (watchComments + addComment)
6. Implement `CommentRepositoryImpl` and `LikeRepositoryImpl`
7. Register new providers in `post_repository_provider.dart`
8. Implement `postDetailProvider` (AsyncNotifier family — seed + stream)
9. Implement `commentsProvider` and `userLikeStatusProvider`
10. Add `/posts/:postId` GoRoute to `router.dart` (outside StatefulShellRoute)
11. Implement `PostDetailScreen`, `CommentTile`, `LikeButton`, `AttachmentCarousel`
12. Wire `PostCard.onTap` in the feed feature
13. Run `dart run build_runner build --delete-conflicting-outputs`
14. Run `flutter analyze` and `dart format .`
15. Write widget + unit tests per SPEC-0006 test plan

## Notes

- PDF viewer package must be team-approved before `AttachmentCarousel` PDF slot is implemented. Use a placeholder until resolved.
- `PostStorageDatasource` currently validates only jpg/jpeg/png/webp/pdf. Video upload is out of scope — do not modify validation; just ensure the carousel renders video slots correctly for posts that already have `mediaTypes: ["video"]`.
- Existing Firestore documents without `mediaTypes` must not crash — default to `const []` and fall back to `"image"` type in the carousel.
- The `_RouterNotifier` guard in `router.dart` — confirm `/posts/someId` is not accidentally redirected before adding the new route.

## Handoff

**To:** architect or qa-engineer (reviewer)  
**Done:** (fill in on completion)  
**Not done:** (fill in on completion)  
**Watch out for:** (fill in on completion)
