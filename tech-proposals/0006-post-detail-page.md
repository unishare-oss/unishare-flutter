---
title: "0006: Post Detail Page"
description: "Proposal for a dedicated post-detail screen that renders full post content, attachments, and social interactions, and serves as the deep-link target for push notifications and shared URLs."
---

# PROP-0006: Post Detail Page

**Status:** PROPOSED  
**Author:** architect  
**Date:** 2026-05-06  
**Spec:** (pending approval)  
**Approved by:** (fill in when accepted)

---

## Problem

The feed screen (PROP-0003) renders a scrollable list of `PostCard` widgets, but tapping a card has no destination. The `PostCard` tap handler is a no-op. Students have no way to read a post's full body, view all attached media, see comments, or like a post — the primary interaction surface of the app is unreachable.

Beyond the tap-from-feed path, the detail screen must function as a **standalone deep-link target**. Push notifications and shared URLs reference a post by its Firestore document ID (e.g., `https://unishare.app/posts/abc123`), and the screen must render correctly when the app is cold-started directly into that route — meaning it cannot depend on feed state being populated in memory.

Two structural concerns compound the data-loading problem:

1. The feed's `postFeedProvider` loads posts in pages. A post the user taps may be on page 1 of the current session or may have been obtained by a completely different session (deep link). Feed data is therefore unreliable as a sole source.
2. `likesCount` on the post document is updated by a Cloud Function, not by the client. A snapshot from the feed may be stale by the time the user opens the detail screen, particularly for popular posts. The detail screen should reflect live counts.

The UI must reproduce the Figma design exactly (https://www.figma.com/design/gIUtcwNTmPi17dOuuv5oDB/Unishare?node-id=0-1). The Figma introduces components — comments list, like button affordance, attachment carousel — that may not exist yet in the shared design system and must be audited before implementation begins.

---

## Proposed Solution

Use **Option C — Hybrid: optimistic display from feed data, then stream live updates from Firestore**.

### GoRouter route

Declare `/posts/:postId` as a top-level route **outside** the `StatefulShellRoute` shell (following the same pattern established in PROP-0005 for New Post steps and Post Details). This means the navbar is automatically absent, and the route is reachable from both the feed tap and a cold-start deep link with no conditional logic.

```
/posts/:postId   →   PostDetailScreen(postId: postId)
```

The `PostCard` tap handler calls `context.push('/posts/${post.id}', extra: post)`. GoRouter's `extra` carries the already-loaded `Post` entity for the warm-start case. For the cold-start case (deep link, push notification), `extra` is `null` — the screen falls back to fetching by ID.

### Clean Architecture layers

| Layer | Addition |
|---|---|
| `domain/entities/Comment` | Pure Dart entity: `id`, `authorId`, `authorName`, `authorAvatar`, `body`, `createdAt` |
| `domain/repositories/PostRepository` | New method: `Stream<Post> watchPost(String postId)` |
| `domain/repositories/CommentRepository` | New interface: `Stream<List<Comment>> watchComments(String postId)`, `Future<void> addComment(String postId, String body)` |
| `domain/usecases/WatchPost` | Wraps `PostRepository.watchPost` |
| `domain/usecases/WatchComments` | Wraps `CommentRepository.watchComments` |
| `domain/usecases/AddComment` | Validates body non-empty, delegates to `CommentRepository` |
| `domain/usecases/ToggleLike` | Writes/removes `posts/{postId}/likes/{userId}`, server-side `likesCount` is managed by Cloud Function |
| `data/datasources/PostFirestoreDataSource` | Add `watchPost(String postId)` — `snapshots()` stream on `posts/{postId}` |
| `data/datasources/CommentFirestoreDataSource` | Stream on `posts/{postId}/comments` ordered by `createdAt` ascending |
| `data/models/CommentDto` | Freezed + `fromJson`/`toJson` |
| `data/repositories/CommentRepositoryImpl` | Maps `CommentDto` → `Comment` entity |
| `presentation/providers/postDetailProvider` | `@riverpod`, accepts `postId`; exposes `AsyncValue<Post>` |
| `presentation/providers/commentsProvider` | `@riverpod`, accepts `postId`; exposes `AsyncValue<List<Comment>>` |
| `presentation/screens/PostDetailScreen` | Full-screen layout per Figma |
| `presentation/widgets/CommentTile` | Single comment row |
| `presentation/widgets/AttachmentCarousel` | Horizontal media strip using `CachedNetworkImage` |
| `presentation/widgets/LikeButton` | Stateless button; receives `isLiked` + `count` + `onTap` |

### Data loading strategy (hybrid)

`postDetailProvider` is a family provider keyed on `postId`. On construction:

1. If GoRouter `extra` carries a `Post` object, the provider emits it immediately as the initial value (zero-latency render).
2. Simultaneously, `WatchPost(postId)` opens a Firestore `snapshots()` stream. When the first snapshot arrives it supersedes the seed value, and subsequent snapshots update live (e.g., `likesCount` incremented by Cloud Function).

For the cold-start / deep-link case, there is no seed from `extra`, so the provider starts in `AsyncValue.loading()` and populates once the first Firestore snapshot arrives. The screen shows a skeleton loader during this window.

This design satisfies both the warm-start (instant render from feed cache) and cold-start (fetch by ID) cases without branching logic in the presentation layer — the provider handles the difference internally.

### Comments subcollection

Comments are stored in `posts/{postId}/comments/{commentId}` — a new subcollection not present in PROP-0003's schema. The detail screen opens a real-time stream (`watchComments`) and appends new comments as they arrive. Adding a comment writes directly to this subcollection; `commentsCount` denormalization on the post document is deferred (see Open Questions).

### Like interaction

`ToggleLike` checks `posts/{postId}/likes/{currentUserId}` for existence. If absent, it creates the document; if present, it deletes it. `likesCount` on the post is maintained exclusively by a Cloud Function — the client never writes it directly. The `LikeButton` widget performs an optimistic local toggle on tap and reconciles with the live stream when the Cloud Function updates `likesCount`.

### Figma compliance

The implementation must reproduce the Figma layout exactly. Before the flutter-engineer begins, the architect must audit the Figma node (`node-id=0-1`) and enumerate every UI component on the Post Detail screen. Any component not already present in `apps/mobile/lib/shared/widgets/` or the design system (`packages/`) must be listed in the tech spec as a new widget to build. No Material defaults should be used for components that Figma specifies with custom tokens.

---

## Alternatives Considered

### A — Pass Post via GoRouter `extra`, no Firestore fetch

The `PostCard` tap passes the full `Post` entity in GoRouter `extra`. The detail screen reads this object and renders it directly — no network call on open. The existing `postFeedProvider` is the sole data source.

**Pros:**
- Instant render with zero additional Firestore reads.
- No new domain use case or repository method needed for data loading.
- Simplest possible implementation.

**Cons:**
- Breaks on cold start. Deep links and push notifications provide only a `postId` in the URL path — `extra` is `null`. The screen has no fallback, so cold-start users see an error or blank screen.
- Data goes stale immediately. `likesCount`, `commentsCount` (if added), and `body` edits are frozen at the moment the feed loaded. A post with 200 likes shows the cached 150 from the feed snapshot.
- Comments are entirely unavailable — there is no `comments` field on the `Post` entity; comments live in a subcollection that the feed never fetches.
- Tightly couples the detail screen's data contract to the feed's load order, making the detail screen non-standalone.

**Effort:** XS (implementation) but produces a product that is broken for deep-link users.

**Rejected:** Cannot satisfy the deep-link requirement, which is a hard constraint. Data staleness is also unacceptable for social interaction counts.

---

### B — Always fetch post fresh from Firestore by ID

Ignore `extra` entirely. Every time the detail screen opens, `postDetailProvider` issues a one-shot `get()` call on `posts/{postId}`. Comments are fetched separately.

**Pros:**
- Uniform code path for warm-start and cold-start — no conditional branching on `extra`.
- Data is fresh at open time regardless of how the screen was reached.
- Simpler provider implementation than the hybrid stream approach.

**Cons:**
- Visible loading spinner on every tap from the feed, even when the post data is already in memory. On a slow connection this creates a noticeable and unnecessary delay — the user just tapped a card they could already read in the feed.
- A one-shot `get()` does not update after open. `likesCount` incremented by a Cloud Function while the user is reading the post is not reflected. The user must leave and re-enter to see updated counts.
- No real-time comments — new comments posted by others while the user reads do not appear without a manual refresh.
- Firestore billing: one extra document read per detail screen open, even for posts already in Firestore's local cache from the feed query.

**Effort:** S. Straightforward `FutureProvider.family` implementation.

**Rejected:** The unnecessary loading spinner on feed taps degrades UX for the most common path. Lack of live updates makes social interactions (likes, comments) feel unresponsive. The hybrid approach adds only marginal complexity for substantially better UX.

---

### C — Hybrid: optimistic display from feed data, then stream live updates (recommended)

Described fully in Proposed Solution above.

**Pros:**
- Instant render on feed tap (seed from `extra`) with no spinner for the common path.
- Correct cold-start behavior (falls back to Firestore fetch when `extra` is absent).
- Live updates via `snapshots()` stream keep `likesCount` and post content current throughout the session.
- Real-time comments via subcollection stream — new comments appear without refresh.
- Single provider interface for both cases — presentation layer is unaware of whether data came from `extra` or Firestore.

**Cons:**
- Slightly more complex provider implementation: the provider must accept an optional seed value and merge it with an incoming stream.
- Opens a persistent Firestore listener per active detail screen, which consumes one Firestore connection slot. This is negligible at current scale but worth monitoring.
- `extra` carries a Dart object, which is not serializable by GoRouter's URL-based state restoration. If the OS kills the app and restores it to the detail screen, `extra` will be null and the screen will fall back to the Firestore fetch path — this is correct behavior but must be documented and tested.

**Effort:** M. The stream-seeding pattern in Riverpod requires a `StreamProvider.family` with a custom build step or an `AsyncNotifier` that combines seed + stream.

**Recommended.** The warm-start path is the dominant user flow (tapping from feed), so eliminating its loading spinner is the highest-impact UX win. The cold-start fallback is architecturally clean and correct. Real-time updates are table stakes for a social feature.

---

## Open Questions

1. **Figma audit: new components** — The Figma design at `node-id=0-1` must be inspected before the tech spec is written. Which UI components on the Post Detail screen (comment input bar, attachment carousel, like button, author chip, tag list) are already in the shared design system versus net-new widgets? The tech spec cannot be written without this inventory.

2. **Comments subcollection schema** — Does the `comments` subcollection need a `likesCount` or nested reply structure (threaded comments), or is it a flat list for v1? The answer changes the Firestore schema and domain entity design.

3. **`commentsCount` denormalization** — Should the `posts/{postId}` document carry a `commentsCount` field (updated by Cloud Function) for display on `PostCard` in the feed, or is the count shown only on the detail screen (where the full subcollection is streamed)? If needed on the feed card, a Cloud Function trigger on `comments` subcollection writes must be added.

4. **Like state for the current user** — The `LikeButton` must know whether the current user has already liked the post. The `posts/{postId}/likes/{userId}` document must be checked on screen open. Does this happen inside `WatchPost` (Firestore rules permitting a sub-read from the use case), or does `postDetailProvider` issue a separate existence check and pass `isLiked` as a field alongside the `Post`? A `userLikeStatusProvider` family keyed on `postId` may be the cleanest separation.

5. **Deep-link URL scheme** — Push notifications from FCM and shared URLs must resolve to `/posts/:postId`. Is the path `/posts/:postId` the canonical deep-link path, or does the backend/notification service use a different scheme (e.g., `/p/:postId`, `unishare://post/:postId`)? The GoRouter route must match exactly.

6. **Comment input and auth gate** — Can unauthenticated (guest-mode) users view the detail screen read-only, with the comment input and like button disabled? Or does the detail route require authentication (redirect to `/welcome` if no session)? The current `_RouterNotifier` must be extended or the detail screen must handle this locally.

7. **Attachment rendering** — `mediaUrls` on the post document is a `string[]`. Are all entries image URLs, or can they include PDF or video links? The `AttachmentCarousel` widget design depends on whether it must handle heterogeneous media types or can assume images-only for v1.

---

## Acceptance Criteria

- Tapping a `PostCard` in the feed navigates to `/posts/:postId` and renders the full post without a loading spinner (warm-start path).
- Cold-starting the app via a deep link to `/posts/:postId` renders a skeleton loader, then the full post once the Firestore snapshot arrives.
- The detail screen's visual layout matches the Figma design exactly — pixel-level fidelity is required for all components specified in the design.
- `likesCount` displayed on the detail screen updates in real time when the Cloud Function increments it (no manual refresh required).
- The like button reflects the current user's like state on open and toggles correctly; optimistic local toggle is reconciled when the stream updates.
- Comments load from `posts/{postId}/comments` in ascending `createdAt` order and new comments from other users appear without refresh while the screen is open.
- Submitting a comment writes to the `comments` subcollection and appears in the list within one Firestore round-trip.
- The navbar (PROP-0005 shell) is absent from the Post Detail screen — the route is declared outside `StatefulShellRoute`.
- Android back button and iOS swipe-back return the user to the previous screen (feed or notification inbox) correctly.
- All new domain entities, repository interfaces, and use cases are pure Dart — zero Flutter or Firebase imports.
- `flutter analyze` reports zero issues on all new code.
- Every new screen and widget has a corresponding widget test; the cold-start path has a unit test for `postDetailProvider` behavior when `extra` is null.
