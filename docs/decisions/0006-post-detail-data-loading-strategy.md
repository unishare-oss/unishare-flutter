---
title: "0006: Post Detail screen uses hybrid seed-then-stream data loading"
description: "The PostDetailScreen seeds its initial state from GoRouter extra (feed data already in memory) and immediately opens a Firestore snapshots() stream for live updates, rather than always fetching fresh or relying solely on cached feed data."
---

# 0006 — Post Detail screen uses hybrid seed-then-stream data loading

**Status:** PROPOSED  
**Author:** architect  
**Date:** 2026-05-06

## Problem

The Post Detail screen must support two entry paths with conflicting data requirements. The warm-start path (user taps a `PostCard`) has the full `Post` entity in memory; issuing a redundant Firestore read would produce a visible loading spinner for no reason. The cold-start path (deep link from push notification or shared URL) has only a `postId` string; the screen must fetch the post from Firestore before it can render. Additionally, social interaction counts (`likesCount`) are updated by a Cloud Function after the user opens the screen and must stay current without a manual refresh. A single data-loading strategy must satisfy all three constraints: instant warm-start render, correct cold-start fetch, and live updates.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Pass `Post` via GoRouter `extra`, no Firestore call | Zero latency on feed tap; no new use case needed | Breaks on cold start (deep link); data is stale immediately; comments subcollection is never loaded |
| 2 | Always fetch fresh via one-shot `get()` on `posts/{postId}` | Uniform code path; fresh data at open time | Spinner on every feed tap even when data is in memory; no live updates after open; comments require separate polling |
| 3 | Seed from `extra` if available, then open `snapshots()` stream | Instant render on warm start; correct cold-start fallback; live updates throughout the session | Slightly more complex provider; persistent Firestore listener per open screen; `extra` is not URL-serializable (OS kill/restore falls back to fetch path, which is acceptable) |

## Decision

**Chosen:** Option 3 — seed from GoRouter `extra`, then open a Firestore `snapshots()` stream.

`postDetailProvider` (a Riverpod `AsyncNotifier` family keyed on `postId`) accepts an optional `Post` seed via GoRouter `extra`. If the seed is present it is emitted immediately, then the provider opens `PostRepository.watchPost(postId)` whose first emission and all subsequent emissions supersede the seed. If the seed is absent (cold start), the provider starts in `AsyncValue.loading()` and populates on the first stream event. This design keeps the presentation layer unaware of the entry path — `PostDetailScreen` always consumes a single `AsyncValue<Post>` stream regardless of how it was reached.

## Reversal Cost

Medium. Switching to Option 2 (always-fetch) requires replacing the `AsyncNotifier` with a `FutureProvider.family`, removing the seed parameter from the provider and from GoRouter push calls, and updating widget tests. No Firebase schema or domain interface changes are needed. Estimated effort: half a day.

## Consequences

- **Easier:** Feed-tap UX is instant with no spinner; deep-link and notification tap UX degrades gracefully to a skeleton loader then content. Real-time `likesCount` updates require no user action.
- **Harder:** The `postDetailProvider` implementation is more complex than a plain `FutureProvider` — it must handle the seed-and-stream merge pattern. This pattern must be documented in the provider file so future engineers understand why it is not a simple fetch.
- **Follow-up required:** A `userLikeStatusProvider` family (keyed on `postId`) must be decided separately — whether the current user's like state is fetched inside `WatchPost` or as a parallel provider affects how `LikeButton` receives its `isLiked` flag. See PROP-0006 Open Question 4.
- **GoRouter `extra` contract:** `extra` carries a Dart object that is not URL-serializable. If the OS kills the app mid-session and Flutter's state restoration navigates back to `/posts/:postId`, `extra` will be null and the screen falls back correctly to the Firestore fetch path. This behavior must be covered by an integration test.
