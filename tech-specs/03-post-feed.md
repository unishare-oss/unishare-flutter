# Post Feed Tech Spec

**Date:** 2026-04-30
**Status:** Draft
**Proposal:** `tech-proposals/0003-post-feed.md`
**Scope:** Reverse-chronological post feed — display, pagination, like toggle, and post deletion. Post creation and media upload are out of scope for this spec.

---

## Open Questions — Resolved

| # | Question | Decision |
|---|---|---|
| 1 | Author denormalization staleness | Acceptable for v1. No migration job. Document the tradeoff in an ADR. |
| 2 | Reserve `score` field? | Yes — add `score: 0` at write time. Zero cost now, avoids schema migration later. |
| 3 | Offline support | Rely on Firestore's built-in offline cache. No explicit Hive seeding at this phase. |
| 4 | Media upload flow | Upload is a **prerequisite step** owned by the presentation layer. `CreatePost` receives final Storage URLs — it does not perform upload itself. |

---

## Overview

A reverse-chronological feed backed by a top-level `posts` Firestore collection. Posts are paginated using cursor-based pagination (`startAfterDocument`) internally, but the domain and presentation layers see plain page numbers. Each post document is self-contained (denormalized author name + avatar) to avoid fan-out reads on render.

This spec covers: feed display, infinite scroll pagination, optimistic like toggle, and author-only post deletion. The `PostDetailScreen` is scaffolded here but its comments sub-feature is out of scope.

---

## Firestore Schema

```
posts/{postId}
  id:            string      (== document ID)
  authorId:      string      (Firebase UID)
  authorName:    string      (denormalized snapshot at write time)
  authorAvatar:  string      (denormalized Storage URL)
  title:         string
  body:          string
  mediaUrls:     string[]    (Firebase Storage URLs, set by caller before CreatePost)
  tags:          string[]
  score:         int         (reserved for ranking — always 0 for now)
  likesCount:    int         (maintained by Cloud Function, read-only for client)
  createdAt:     Timestamp
  updatedAt:     Timestamp

posts/{postId}/likes/{userId}
  likedAt:       Timestamp
```

**`likesCount` write rule:** the client never writes `likesCount` directly. A Cloud Function triggers on `likes` subcollection writes and atomically updates the counter. The client performs an optimistic local increment for immediate UI feedback and reconciles when the Firestore stream delivers the updated value.

**Indexes required:**
- `posts` collection: `createdAt DESC` (default, covered by Firestore auto-index)
- `posts` collection: `score DESC, createdAt DESC` (reserved — add to `firestore.indexes.json` now even though unused)

---

## Navigation

Routes are defined by `02-navigation-design.md`. This spec adds no new top-level routes.

| Route | Screen | Access |
|---|---|---|
| `/feed` | `PostFeedScreen` — paginated infinite scroll | All (guest = read-only) |
| `/feed/posts/:id` | `PostDetailScreen` — single post, comments entry point | All (guest = read-only) |

---

## Clean Architecture Layers

### Domain (pure Dart — zero Firebase/Flutter imports)

```
features/post_feed/domain/
  entities/
    post.dart                    ← id, authorId, authorName, authorAvatar, title, body,
                                    mediaUrls, tags, likesCount, isLikedByCurrentUser,
                                    createdAt, updatedAt
    post_feed_page.dart          ← posts: List<Post>, page: int, hasMore: bool
  repositories/
    post_repository.dart         ← abstract interface
  usecases/
    get_post_feed.dart           ← Future<PostFeedPage> call({int page, int pageSize})
    toggle_like.dart             ← Future<void> call(String postId, bool liked)
    delete_post.dart             ← Future<void> call(String postId)
```

**`Post` entity shape:**
```dart
class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String title;
  final String body;
  final List<String> mediaUrls;
  final List<String> tags;
  final int likesCount;
  final bool isLikedByCurrentUser;  // resolved by data layer from likes subcollection
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**`PostRepository` interface:**
```dart
abstract class PostRepository {
  Future<PostFeedPage> getPostFeed({int page = 0, int pageSize = 20});
  Future<Post> getPost(String postId);
  Future<void> toggleLike(String postId, bool liked);
  Future<void> deletePost(String postId);
}
```

---

### Data

```
features/post_feed/data/
  datasources/
    post_firestore_datasource.dart   ← Firestore queries, cursor cache, likes reads
  models/
    post_model.dart                  ← Freezed + JSON, extends Post
  repositories/
    post_repository_impl.dart        ← maps PostModel → Post, resolves isLikedByCurrentUser
```

**Cursor cache strategy** (inside `PostFirestoreDataSource`, invisible to domain):
```
page 0  →  posts.orderBy('createdAt', desc).limit(pageSize)
page N  →  posts.orderBy('createdAt', desc).startAfterDocument(cursors[N-1]).limit(pageSize)
```
`cursors` is a `Map<int, DocumentSnapshot>` held in memory. The last document of each page response is stored as the cursor for the next page. Navigating to a page that hasn't been fetched yet requires fetching all preceding pages first (sequential scroll is the only supported access pattern).

**`isLikedByCurrentUser` resolution:** after fetching the post page, the data source performs a single batched `getAll` on `posts/{postId}/likes/{currentUid}` for each post in the page. Unauthenticated (guest) users always get `false`.

---

### Presentation

```
features/post_feed/presentation/
  providers/
    post_feed_provider.dart          ← PostFeedNotifier (AsyncNotifier)
    post_detail_provider.dart        ← postDetailProvider (family, caches single post)
  screens/
    post_feed_screen.dart
    post_detail_screen.dart
  widgets/
    post_card.dart                   ← feed list item with like button
    like_button.dart                 ← optimistic toggle, animates on tap
```

**`PostFeedNotifier`:**
```dart
@riverpod
class PostFeedNotifier extends _$PostFeedNotifier {
  final List<Post> _posts = [];
  int _nextPage = 0;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  Future<List<Post>> build() async {
    _posts.clear();
    _nextPage = 0;
    _hasMore = true;
    return _fetchPage();
  }

  Future<void> fetchNextPage() async { ... }   // guard with _isFetchingMore
  Future<void> toggleLike(String postId, bool liked) async { ... }  // optimistic update
  Future<void> deletePost(String postId) async { ... }
}
```

**Optimistic like flow:**
1. Immediately update `likesCount` and `isLikedByCurrentUser` in the local `_posts` list and call `state = AsyncData(_posts)`.
2. Call `toggleLike` use case.
3. On error: revert the local change and show a snackbar ("Could not update like — try again").

**Infinite scroll trigger:** `PostFeedScreen` attaches a scroll listener to `ScrollController`. When `position.pixels >= position.maxScrollExtent - 200`, it calls `fetchNextPage()` on the notifier.

---

## PostFeedScreen Layout

```
Scaffold
  AppBar(title: 'Feed')
  body:
    RefreshIndicator(                          ← pull-to-refresh calls ref.invalidate
      ListView.builder(
        controller: scrollController,
        itemCount: posts.length + 1,           ← +1 for bottom loader/end indicator
        itemBuilder: (ctx, i) {
          if (i < posts.length) return PostCard(post: posts[i]);
          if (hasMore) return CircularProgressIndicator (centered);
          return Text('You\'re all caught up');
        }
      )
    )
```

No unbounded `ListView` — always `ListView.builder` as per CLAUDE.md.

---

## PostCard Widget

| Element | Detail |
|---|---|
| Author avatar | `CachedNetworkImage`, 36 dp circle, fallback to initials |
| Author name | `bodyMedium`, single line |
| Timestamp | relative ("2h ago") using `DateTime.now()` diff |
| Title | `titleSmall`, max 2 lines, overflow ellipsis |
| Body | `bodySmall`, max 3 lines, overflow ellipsis |
| Tags | `Wrap` of small outlined chips |
| Like button | `LikeButton` widget — heart icon, animated fill on tap |
| Like count | integer next to heart |
| Delete action | `PopupMenuButton` visible only when `post.authorId == currentUser.id` |

Tapping the card navigates to `/feed/posts/:id`.

---

## Error Handling

| Scenario | Behaviour |
|---|---|
| Initial feed load fails (network) | Error state with retry button; `AsyncError` shown via `when` |
| `fetchNextPage` fails | Snackbar "Couldn't load more posts"; `_hasMore` stays `true` so the user can retry by scrolling |
| Like toggle fails | Revert optimistic update; snackbar "Could not update like — try again" |
| Delete fails | Snackbar "Could not delete post — try again"; post stays in list |
| Guest taps like / delete | Show "Sign in to continue" bottom sheet (same pattern as auth spec) |
| Post not found (detail screen) | `AsyncError` with "Post not found" message and back button |

---

## Testing

**Widget tests (mandatory per CLAUDE.md — one per screen):**

| File | What it covers |
|---|---|
| `post_feed_screen_test.dart` | Renders loading state; renders list of `PostCard`s when data loads; pull-to-refresh triggers reload; end-of-list indicator shown when `hasMore == false` |
| `post_detail_screen_test.dart` | Renders post title, body, author; like button visible; delete option hidden for non-author |

**Unit tests:**

| File | What it covers |
|---|---|
| `post_repository_impl_test.dart` | `PostModel` → `Post` mapping; `isLikedByCurrentUser` correctly resolved |
| `get_post_feed_test.dart` | Delegates to repository with correct page + pageSize |
| `toggle_like_test.dart` | Calls repository with correct postId and liked flag |
| `delete_post_test.dart` | Delegates to repository; propagates error |
| `post_feed_notifier_test.dart` | Optimistic like update; rollback on error; `fetchNextPage` appends posts; `_isFetchingMore` guard prevents duplicate requests |

**Mock strategy:** use `mocktail` to mock `PostRepository`. No real Firebase in unit or widget tests.

---

## Acceptance Criteria

- [ ] `/feed` loads the first 20 posts ordered by `createdAt` descending
- [ ] Scrolling to within 200 px of the bottom triggers `fetchNextPage`; no layout jump on append
- [ ] Tapping the like button immediately reflects the new count; reconciles on Firestore response
- [ ] Delete option is only visible to the post author; on confirm, post is removed from the list
- [ ] Guest users see the feed (read-only); tapping like or delete shows the sign-in prompt
- [ ] `flutter analyze` reports zero issues
- [ ] All widget and unit tests pass

---

## Out of Scope (this phase)

- Post creation (Create Post screen, media upload)
- Comments (entry point in `PostDetailScreen` is scaffolded but unimplemented)
- Feed filtering / tag search
- Ranking by `score` field (field is reserved but always 0)
- Push notifications for likes
- Hive offline seeding
