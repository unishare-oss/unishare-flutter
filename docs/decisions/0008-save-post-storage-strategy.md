---
title: "0008: Save-post feature uses Hive for guest storage and Firestore subcollection for authenticated users, merged on login"
description: "The save-post feature stores saves in a local Hive box for guest users and in users/{uid}/savedPosts/{postId} for authenticated users, with an automatic merge when a guest signs in."
---

# 0008 — Save-post feature uses Hive for guest storage and Firestore subcollection for authenticated users, merged on login

**Status:** PROPOSED  
**Author:** architect  
**Date:** 2026-05-07

## Problem

The save-post feature must serve two user contexts with incompatible storage requirements. Guest users have no server identity, so saves can only be stored locally; they must survive app restarts without requiring a Firebase account. Authenticated users expect saves to sync across devices and survive reinstalls, which requires Firestore. A single storage strategy cannot satisfy both contexts simultaneously, and the transition from guest to authenticated must not silently discard locally saved posts.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Hive-only for all users | Simplest; no Firestore writes; fully offline | Authenticated users lose saves on device change or reinstall; no cross-device access |
| 2 | Firestore-only; guests cannot save | Single backend; no merge logic; full cross-device sync from day one | Violates the stated guest requirement; forces sign-up before saving |
| 3 | Hive for guests + Firestore for authenticated, merge on login | Satisfies all stated requirements; domain interface unified; no new dependencies | Two repository implementations; merge logic adds complexity; provider must react to auth state transitions |
| 4 | Anonymous Firebase Auth for guests, link account on sign-in | Single Firestore backend for all users; no custom merge logic | Rewrites the guest auth model; anonymous account expiry risk; auth-link failure edge cases; higher implementation effort |

## Decision

**Chosen:** Option 3 — Hive for guest users, Firestore subcollection `users/{uid}/savedPosts/{postId}` for authenticated users, automatic merge on login.

`SavedPostRepository` is a unified domain interface implemented by two Data-layer classes: `SavedPostHiveRepositoryImpl` (active for guests) and `SavedPostFirestoreRepositoryImpl` (active for authenticated users). `saved_post_repository_provider` switches between them in response to `authStateProvider` changes. On the transition from unauthenticated to authenticated, `MergeGuestSaves` batch-writes all Hive entries into Firestore using `SetOptions(merge: true)` and then clears the Hive box. This approach is chosen because it satisfies all product requirements without introducing new dependencies or restructuring the existing guest-mode model, and the added complexity is confined entirely to the Data layer and one use case.

## Reversal Cost

Medium. Reverting to Hive-only (Option 1) removes the Firestore implementation, merge use case, and auth-reactive provider switch — roughly one day of work. Reverting to Firestore-only (Option 2) removes the Hive implementation and merge logic but requires a product decision to drop guest saves, which is a UX regression. Switching to anonymous auth (Option 4) requires restructuring `GuestMode` provider and `_RouterNotifier` — estimated at two to three days and affects the auth feature beyond the saved-posts scope.

## Consequences

- **Easier:** Guest users save posts immediately without sign-up friction. Authenticated users get cross-device sync. The domain interface is unified, so the presentation layer never branches on storage backend.
- **Harder:** Two `SavedPostRepository` implementations must be kept in sync with the interface. The merge-on-login path has failure-mode edge cases (partial merge on network drop, posts already saved on the authenticated account) that must be covered by unit tests. `saved_post_repository_provider` must be a `keepAlive` notifier that reacts correctly to auth state changes without causing read-after-dispose errors during the implementation switch.
- **Follow-up required:** The Hive `typeId: 2` for `SavedPostHiveModelAdapter` must be reserved and documented alongside the existing `typeId: 1` for `PostDraftModelAdapter`. A future proposal may address refresh of denormalized post snapshots stored on save records if post-edit staleness becomes a reported issue.
