---
title: "0007: Save Post"
description: "Persistent bookmarking of feed posts for later reference, with Hive-backed local storage for guest users and Firestore sync for authenticated users, merged on login."
---

# PROP-0007: Save Post

**Status:** DRAFT  
**Author:** architect  
**Date:** 2026-05-07  
**Spec:** (pending approval)  
**Approved by:** (fill in when accepted)

---

## Problem

Students encounter valuable academic posts — lecture notes, past papers, study summaries — while scrolling the feed, but the app provides no mechanism to mark or retrieve those posts later. The only retrieval path is scrolling the feed again from the top, which is impractical once the feed grows beyond one page and becomes impossible for content that has aged off the visible window. There is no personal study collection surface: a student preparing for finals cannot quickly access the five posts they found most useful last week.

Two distinct user contexts make the storage strategy non-trivial:

1. **Guest users** (browsing without an account) need save functionality immediately — blocking saves behind a login wall degrades the guest experience and reduces the perceived value of signing up. Guest saves must survive app restarts but have no server identity to sync against, so they can only be stored locally.

2. **Authenticated users** need their saved list to survive device changes, app reinstalls, and simultaneous access from multiple devices (e.g., phone + web). Local-only storage is insufficient. When a guest user later creates an account and signs in, their locally saved posts must not silently disappear — the transition from guest to authenticated must be handled explicitly.

The feature must also integrate cleanly into the existing navigation structure. PROP-0005 established `StatefulShellRoute` with a MORE tab containing `/more/saved` as a child route. The Saved screen exists as a stub (`SavedScreen` returning "Coming soon"). This proposal fills that stub with a real feature.

---

## Proposed Solution

**Option C — Hybrid: Hive for all users as local cache, Firestore as sync layer for authenticated users, merge on login.**

### Summary of the choice

Option C is recommended because it satisfies all hard constraints without sacrificing any user context. Guest saves are durable across app restarts. Authenticated saves sync cross-device. The merge-on-login path preserves guest work rather than discarding it, which is the correct product behavior for a tool students rely on for study. The complexity cost of the merge is bounded and one-time; it does not recur after login.

### Architecture

The feature is scoped to a new `features/saved/` directory following the established Clean Architecture layer pattern.

#### Domain layer (pure Dart — zero Flutter or Firebase imports)

```
features/saved/domain/
  entities/
    saved_post.dart          ← SavedPost { postId, savedAt, postSnapshot? }
  repositories/
    saved_post_repository.dart   ← abstract SavedPostRepository
  usecases/
    save_post.dart           ← validates postId non-empty, delegates to repository
    unsave_post.dart         ← delegates to repository
    get_saved_posts.dart     ← returns Stream<List<SavedPost>>
    is_post_saved.dart       ← returns Stream<bool> for a given postId
    merge_guest_saves.dart   ← copies local Hive saves into Firestore on login
```

`SavedPost` carries a `postId` and `savedAt` timestamp. It optionally carries a `postSnapshot` — a denormalized copy of the post fields used to render the Saved tab without additional Firestore reads (see Open Question 2 and Firestore schema below).

`SavedPostRepository` defines the interface that both the Hive implementation (guest) and the Firestore implementation (authenticated) satisfy:

```dart
abstract class SavedPostRepository {
  Stream<List<SavedPost>> watchSavedPosts();
  Future<void> savePost(String postId, PostSnapshot snapshot);
  Future<void> unsavePost(String postId);
  Stream<bool> isPostSaved(String postId);
  Future<void> mergeFrom(List<SavedPost> guestSaves); // no-op on Hive impl
}
```

#### Data layer

| File | Responsibility |
|---|---|
| `data/models/saved_post_hive_model.dart` | `HiveObject` with manual `TypeAdapter` (typeId: 2 — next available after `PostDraftModelAdapter` at typeId 1); stores `postId`, `savedAt`, and denormalized snapshot fields |
| `data/models/saved_post_dto.dart` | Freezed + `fromJson`/`toJson` for Firestore document mapping |
| `data/datasources/saved_post_hive_datasource.dart` | Opens `Box<SavedPostHiveModel>('saved_posts')`; CRUD via Hive box |
| `data/datasources/saved_post_firestore_datasource.dart` | Reads/writes `users/{uid}/savedPosts/{postId}` |
| `data/repositories/saved_post_hive_repository_impl.dart` | Implements `SavedPostRepository` against Hive; `mergeFrom` is a no-op |
| `data/repositories/saved_post_firestore_repository_impl.dart` | Implements `SavedPostRepository` against Firestore; `mergeFrom` batch-writes all guest saves |

#### Presentation layer

| File | Responsibility |
|---|---|
| `presentation/providers/saved_post_repository_provider.dart` | `@riverpod keepAlive` — returns the Hive impl when guest, the Firestore impl when authenticated; switches when auth state changes |
| `presentation/providers/saved_posts_provider.dart` | `@riverpod` — `StreamProvider` wrapping `GetSavedPosts`; exposes `AsyncValue<List<SavedPost>>` |
| `presentation/providers/is_post_saved_provider.dart` | `@riverpod` family keyed on `postId` — `StreamProvider<bool>` for save-button state on `PostCard` |
| `presentation/screens/saved_screen.dart` | Replaces the "Coming soon" stub; renders saved list or empty state |
| `presentation/widgets/saved_post_card.dart` | Renders a saved post from the denormalized snapshot — no additional Firestore reads |
| `presentation/widgets/save_button.dart` | Stateless toggle button; receives `isSaved` + `onTap`; placed on `PostCard` and `PostDetailScreen` |

#### Firestore schema

```
users/{uid}/savedPosts/{postId}
  postId:       string   (== document ID, for query convenience)
  savedAt:      Timestamp
  title:        string   (denormalized from post document at save time)
  authorName:   string   (denormalized)
  courseId:     string   (denormalized)
  postType:     string   (denormalized — "note" | "assignment" | ...)
  tags:         string[] (denormalized)
```

The `savedAt` field enables ordering the Saved tab by most-recently saved. Denormalized fields enable rendering the Saved tab as a flat list without issuing one `get()` per saved post. Staleness of denormalized fields is acceptable: the post's title and author are rarely edited after publication, and if they are, the Saved tab showing an outdated title is a minor cosmetic issue rather than a functional one. A background migration to refresh stale snapshots is deferred to a future proposal.

#### Merge-on-login flow

When `authStateProvider` transitions from unauthenticated to authenticated, `saved_post_repository_provider` switches from the Hive implementation to the Firestore implementation. Before switching, `MergeGuestSaves` reads all entries from the Hive box and calls `SavedPostRepository.mergeFrom(guestSaves)`. The Firestore implementation batch-writes the guest saves into `users/{uid}/savedPosts/`, using `SetOptions(merge: true)` so that posts already saved on another device are not overwritten. After the merge, the Hive box is cleared to prevent duplicate saves from accumulating.

The merge is triggered once per login event inside `saved_post_repository_provider`'s build method, which re-runs when `authStateProvider` changes. The result of the merge is not surfaced to the user unless it fails — on failure, local Hive saves are retained and the merge is retried on the next app launch.

#### Hive box registration

A new `initSavedPostBox()` function is added to `core/storage/` following the existing pattern in `post_draft_box.dart`. It registers `SavedPostHiveModelAdapter` (typeId: 2) and opens the `saved_posts` box. It must be called from `main.dart` alongside `initPostDraftBox()`.

#### Router integration

`/more/saved` already exists as a child route of the MORE branch in `router.dart`. No router changes are required. The `SavedScreen` at that path is replaced in-place.

The `PostCard` widget in the feed gains a `SaveButton` that calls `savePost` / `unsavePost` via a tap. The button's state is driven by `isPostSavedProvider(postId)`, which is a `StreamProvider` reflecting the current repository (Hive or Firestore). No `PostCard` structural changes are needed beyond adding the button to the existing action row.

---

## Alternatives Considered

### A — Hive-only local saves (no Firestore sync)

All saves, for all users, are stored in a local Hive box. No Firestore collection is introduced. The feature is symmetric across guest and authenticated users.

**Pros:**
- Simplest implementation. No new Firestore subcollection, no merge logic, no auth-switching repository.
- Works for guests and authenticated users identically.
- Zero Firestore reads/writes for the save feature — no impact on billing or quota.
- No sync latency — saves are instant and always available offline.

**Cons:**
- Authenticated users lose their saved list on device change, app reinstall, or when using the web version. This is a significant regression relative to user expectations for a signed-in experience.
- The feature's value proposition for authenticated users is substantially weaker than for a cloud-synced list.
- Cross-device access is impossible.

**Effort:** XS.

**Verdict:** Acceptable as a v1 MVP for guest users but inadequate for authenticated users. It is the correct choice only if cross-device sync is explicitly out of scope and communicated to users.

---

### B — Firestore subcollection only (`users/{uid}/savedPosts/{postId}`)

Saves are stored exclusively in Firestore. Guest users cannot save posts — the Save button is hidden or disabled when not authenticated, with a prompt to sign in.

**Pros:**
- No Hive complexity for this feature. Only one storage backend to maintain.
- Authenticated saves are fully cross-device from day one.
- No merge logic on login.
- Simpler `SavedPostRepository` — one implementation, not two.

**Cons:**
- Guest users cannot save posts. This directly contradicts the stated requirement: "Guest users (not logged in): saved posts are stored locally using Hive (offline-first, no Firestore writes)."
- A guest who finds a useful post must either sign up immediately (friction) or lose the post (poor UX).
- On logout, all saves are inaccessible until the user signs back in, even on the same device.

**Effort:** S (single backend, no merge).

**Verdict:** Does not meet the guest requirement. Acceptable only if the product decision is explicitly made to require authentication before saving.

---

### C — Hybrid: Hive for guests, Firestore for authenticated users, merge on login (recommended)

Described fully in Proposed Solution above.

**Pros:**
- Satisfies all stated requirements: guest saves work offline, authenticated saves sync cross-device.
- Guest saves are not lost on login — they are merged into Firestore.
- The domain repository interface is unified — the presentation layer is unaware of which backend is active.
- No new pub.dev dependencies. `hive_flutter` and `cloud_firestore` are already in `pubspec.yaml`.

**Cons:**
- Two repository implementations to maintain instead of one.
- Merge-on-login logic adds complexity. Edge cases must be handled: merge failure, partial merge on network drop, posts that were saved on both a guest session and an existing authenticated account.
- The `saved_post_repository_provider` must react to `authStateProvider` changes, which requires careful provider lifecycle management to avoid read-after-dispose errors when the provider switches implementations mid-session.
- Hive box for `saved_posts` adds a second registered adapter alongside `PostDraftModelAdapter`.

**Effort:** M.

**Verdict:** Recommended. The added complexity is concentrated in the Data layer and merge use case, leaving the Domain interface and Presentation layer clean. The product experience is correct for all user types.

---

### D — Firestore subcollection with Firestore offline persistence as local cache

Use Firestore's built-in offline persistence (already enabled by `cloud_firestore`) as the offline layer for all users, including guests. Guest users are assigned an anonymous Firebase Auth UID (`signInAnonymously`), enabling Firestore writes. On explicit sign-in, the anonymous account is linked to the authenticated account, preserving all data.

**Pros:**
- Single storage backend (Firestore) for all users.
- No custom Hive model or merge logic.
- Firebase anonymous auth handles the guest identity problem cleanly.
- Offline reads are served from Firestore's local cache automatically.

**Cons:**
- Requires introducing anonymous Firebase Auth (`signInAnonymously`) — a new auth flow not currently in the codebase. The `_RouterNotifier` and `GuestMode` provider would need rearchitecting: currently guest mode is a simple boolean, not a Firebase identity.
- Anonymous accounts have a 30-day inactivity expiry on Firebase. A guest who returns after a month loses their saves silently.
- Linking anonymous accounts to authenticated accounts is a one-way operation that can fail (e.g., if the authenticated account already has data). Error handling for link failures is non-trivial.
- `signInAnonymously` counts toward Firebase Auth monthly active users, which may affect billing at scale.
- Firestore offline persistence does not guarantee writes are durable across app reinstalls — the local cache is cleared on reinstall, meaning guest saves on a reinstalled app are lost even with this approach.

**Effort:** L (rearchitecting the guest auth model).

**Verdict:** Architecturally elegant but introduces a significant dependency on anonymous auth that rewrites the existing guest model. The merge problem is shifted from the data layer to the auth layer, where failure modes are harder to handle. Not recommended for this scope.

---

## Open Questions

1. **What happens to guest saves on login — merge, discard, or user choice?**
   The recommended approach (Option C) merges automatically and silently. An alternative is to present a modal at login time: "You have N saved posts from your guest session — would you like to add them to your account?" This gives the user control but adds a UI step and assumes the user understands the concept of guest session saves. The decision is a product judgment call that must be made before the tech spec is written. The default recommendation is silent auto-merge, as it is the least surprising behavior.

2. **Does the Saved tab render from denormalized snapshots or issue Firestore reads per saved record?**
   The proposal recommends denormalized snapshots (a subset of post fields stored on the save record). This avoids N+1 Firestore reads when the Saved tab loads. The tradeoff is that the saved title, author name, or course ID may become stale if the original post is edited. For v1, stale snapshots are acceptable — posts are rarely edited after publication. If staleness becomes a problem, a Cloud Function that updates save snapshots on post edits can be added later without a schema migration (the fields are already there).

3. **What is the Firestore document shape for a save record — minimal reference or denormalized snapshot?**
   The proposal recommends a denormalized snapshot: `postId`, `savedAt`, `title`, `authorName`, `courseId`, `postType`, `tags`. The alternative is a minimal reference: just `postId` and `savedAt`, with each Saved tab load issuing one `posts/{postId}` read per entry. The minimal reference is simpler to write but produces N reads per tab load, which is expensive at scale and produces visible load latency per card. Denormalization is preferred. The Firestore document size for the proposed snapshot is well under 1 MB per document.

4. **Should un-saving a post that was merged from a guest session also delete from Hive, or only from Firestore?**
   After a successful merge, the Hive box is cleared entirely (all guest saves are moved to Firestore). Un-saving thereafter only removes the Firestore document — the Hive entry no longer exists. If the merge fails and Hive entries are retained, un-saving the same post in Hive and Firestore requires the `unsavePost` use case to call both backends, or the user must re-login to retry the merge first. The simplest safe rule: after a successful merge, Hive is the cleared; un-save targets only the active backend (Hive for guests, Firestore for authenticated users). The merge failure path retains Hive and retries on next login.

5. **What does the Saved tab look like when there are zero saves?**
   The Saved tab must render a meaningful empty state rather than a blank screen. The proposed empty state shows an illustration or icon, the text "No saved posts yet", and a secondary call-to-action "Browse the feed to find posts worth saving" with a button that navigates to `/feed`. The empty state must be distinct for guest users (optionally adding "Sign in to sync saves across devices") versus authenticated users. The exact copy and illustration are design decisions deferred to the flutter-engineer and Figma audit, but the requirement that an empty state exists is a hard acceptance criterion.

---

## Acceptance Criteria

**Guest user path:**
- A guest user can tap the Save button on a `PostCard` in the feed, and the post is immediately marked as saved (button state toggles, no loading spinner).
- Saved posts persist across app restarts for a guest user (Hive-backed; survives hot restart and cold start).
- The Saved tab (`/more/saved`) displays the guest user's saved posts as a list, rendered from the local Hive store without any Firestore reads.
- A guest user can unsave a post; the post is immediately removed from the Saved tab.
- The Save button does not require authentication — it is active for guest users.
- The Saved tab shows a non-empty empty state UI (illustration + descriptive text + CTA to feed) when no posts are saved.

**Authenticated user path:**
- An authenticated user's saved posts are stored in `users/{uid}/savedPosts/{postId}` in Firestore.
- The Saved tab reflects the Firestore state in real time via a `snapshots()` stream — saves made on another device appear without a manual refresh.
- A saved post is retrievable on a second device after signing in with the same account, within one Firestore sync round-trip.
- Un-saving a post removes the Firestore document and the post disappears from the Saved tab within one round-trip.

**Merge-on-login path:**
- When a guest user with locally saved posts signs in, all local saves are merged into `users/{uid}/savedPosts/` in Firestore automatically, without user intervention.
- Posts that were already saved on the authenticated account (from a previous session or another device) are not duplicated — `SetOptions(merge: true)` semantics apply.
- After a successful merge, the Hive box is cleared.
- If the merge fails (e.g., no network), the Hive box is retained and the merge is retried on the next login event.
- A guest user who has not saved any posts and then signs in sees no merge prompt and experiences no change in behavior.

**Clean Architecture compliance:**
- All entities (`SavedPost`), repository interfaces (`SavedPostRepository`), and use cases (`SavePost`, `UnsavePost`, `GetSavedPosts`, `IsPostSaved`, `MergeGuestSaves`) are pure Dart — zero Flutter or Firebase imports in the domain layer.
- The presentation layer depends only on the domain interface, never on the Hive or Firestore implementations directly.

**Quality gates:**
- `flutter analyze` reports zero issues on all new code.
- Every new screen (`SavedScreen`) has a widget test covering: non-empty list state, empty state, and (for authenticated users) a loading state.
- `SaveButton` has a widget test for both saved and unsaved visual states.
- `MergeGuestSaves` use case has a unit test covering: successful merge, merge with pre-existing Firestore saves (no duplicate), and merge failure (Hive retained).
- No new pub.dev dependencies are introduced — `hive_flutter` and `cloud_firestore` are already declared in `pubspec.yaml`.
