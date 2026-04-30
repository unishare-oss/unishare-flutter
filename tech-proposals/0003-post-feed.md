# Tech Proposal 0001 — Post Feed

**Status:** PROPOSED  
**Author:** architect  
**Date:** 2026-04-30  
**Spec:** (pending approval)

---

## Problem

Unishare needs a way for university students to discover and share academic content — notes, summaries,
past papers, and study guides. Without a feed, users have no surface for browsing new content from peers
or from courses they follow. This is the primary content-discovery mechanism for the app.

---

## Proposed Solution

A reverse-chronological feed backed by a top-level Firestore `posts` collection. The feed is paginated
using cursor-based pagination (`startAfterDocument`) so infinite scroll works efficiently without
offset reads. Each post document is self-contained (denormalized author display name + avatar) to avoid
fan-out reads on render.

### Firestore Schema

```
posts/{postId}
  id:            string   (== document ID)
  authorId:      string   (UID)
  authorName:    string   (denormalized — snapshot at write time)
  authorAvatar:  string   (denormalized URL)
  title:         string
  body:          string
  mediaUrls:     string[]
  tags:          string[]
  likesCount:    int      (maintained by Cloud Function, never written by client)
  createdAt:     Timestamp
  updatedAt:     Timestamp

posts/{postId}/likes/{userId}
  likedAt:       Timestamp
```

`likesCount` on the post document is a counter updated by a Cloud Function triggered on
`likes` subcollection writes — this avoids race conditions from simultaneous client increments.

### Pagination

The feed uses page-number–based pagination. The repository interface takes an explicit `page` index
(0-based) and a fixed `pageSize`:

```dart
// domain/repositories/post_repository.dart
abstract class PostRepository {
  Future<PostFeedPage> getPostFeed({int page = 0, int pageSize = 20});
}

// domain/entities/post_feed_page.dart
class PostFeedPage {
  final List<Post> posts;
  final int page;
  final bool hasMore; // false when posts.length < pageSize
}
```

**Firestore implementation note:** Firestore has no native offset. The data source implements
page-number pagination by caching a `DocumentSnapshot` per page boundary (fetched on the first
load of each page) and using `startAfterDocument` internally. This is transparent to the domain
and presentation layers — they only see page numbers.

```
// page 0: plain limit
posts.orderBy('createdAt', descending: true).limit(pageSize)

// page N: startAfterDocument(cachedCursor[N-1])
posts.orderBy('createdAt', descending: true).startAfterDocument(cursor).limit(pageSize)
```

Page cursors are cached in memory for the session; navigating back to a previous page reuses the
cached snapshot. Jumping to an arbitrary page (e.g., deep-linking to page 10) is not supported —
the user must scroll through preceding pages to build the cursor cache.

### Clean Architecture Layers

| Layer | Responsibility |
|---|---|
| `domain/entities/Post` | Pure Dart; no Firebase types |
| `domain/entities/Author` | Pure Dart snapshot of author fields |
| `domain/repositories/PostRepository` | Abstract interface |
| `domain/usecases/GetPostFeed` | Returns `Stream<List<Post>>` or `Future<PostFeedPage>` |
| `domain/usecases/CreatePost` | Validates and delegates to repository |
| `domain/usecases/DeletePost` | Checks ownership, delegates to repository |
| `data/datasources/PostFirestoreDataSource` | Firestore queries, cursor management |
| `data/models/PostDto` | Freezed + `fromJson`/`toJson` |
| `data/repositories/PostRepositoryImpl` | Maps DTOs → entities |
| `presentation/providers/postFeedProvider` | `@riverpod`, exposes paginated state |
| `presentation/screens/PostFeedScreen` | Infinite scroll list |
| `presentation/screens/PostDetailScreen` | Single post view |
| `presentation/widgets/PostCard` | Feed list item |

---

## Alternatives Considered

### A — Flat array field on a `users` document

Store each user's posts as an array on their profile document. **Rejected**: arrays are bounded at
~1 MB per document; no way to paginate across authors; cross-user feed requires client-side merging.

### B — Algolia / Typesense for feed + search

Use a third-party search index as the feed source. **Rejected for v1**: adds a paid dependency and
operational overhead before we have content volume. Can be layered on top of Firestore later
for full-text search without changing the feed architecture.

### C — `likesCount` incremented by the client

Each client writes `FieldValue.increment(1)` directly on the post document. **Rejected**: concurrent
likes from different users produce correct final counts, but a malicious or buggy client can set
arbitrary values. Cloud Function enforcement is the right boundary.

---

## Open Questions

1. **Author denormalization staleness** — if a user changes their display name or avatar, existing
   posts show the old value. Acceptable for v1? Or do we need a background migration job?

2. **Feed ordering** — pure reverse-chronological is simple but surfaces old high-quality posts poorly.
   Should we reserve a `score` field now (even if unused) to allow ranking later without a schema
   migration?

3. **Offline support** — Firestore offline persistence covers recently viewed documents. Should the
   feed explicitly seed Hive with the first page for fully-offline use, or rely on Firestore's cache?

4. **Media upload flow** — `mediaUrls` are stored as Firebase Storage URLs. Is upload handled inside
   `CreatePost` use case, or is it a prerequisite step the presentation layer completes first before
   calling `CreatePost`?

---

## Acceptance Criteria (for Tech Spec)

- Feed loads first 20 posts ordered by `createdAt` descending
- Scrolling to the end of the list fetches the next page without layout jump
- Liking a post increments the displayed count (optimistic update, reconciled from Firestore)
- Deleting a post is only available to the post author
- All screens have passing widget tests
- `flutter analyze` reports no issues
