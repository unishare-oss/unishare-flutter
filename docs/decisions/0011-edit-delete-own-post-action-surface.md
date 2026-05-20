---
title: "0011: Edit and delete own post — action surface on PostDetailScreen only"
description: "Owner edit/delete actions are placed in a PostDetailScreen AppBar overflow menu, not on PostCard or exclusively on MyPostsScreen."
---

# 0011 — Edit and delete own post — action surface on PostDetailScreen only

**Status:** PROPOSED
**Author:** architect
**Date:** 2026-05-19

## Problem

Post owners need a way to correct errors or remove their own posts. Three surfaces are candidates: the detail screen AppBar, the `PostCard` widget (visible in the feed and on `MyPostsScreen`), and `MyPostsScreen` exclusively. Each involves a different coupling risk, discovery model, and accidental-action probability. A decision was needed before the Tech Spec could enumerate files and routes.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Overflow menu on `PostDetailScreen` AppBar only | Follows established `_deleteComment` pattern; detail screen is where authors notice errors; lowest accidental-tap risk; no changes to `PostCard` | Author must navigate to detail view before acting; one extra navigation step to delete |
| 2 | Overflow menu on `PostCard` (feed + detail) | Fastest path to delete from any list; consistent action surface everywhere the card appears | Adds ownership-awareness coupling to a shared widget; competes for top-right layout space with `SaveButton`; higher accidental-tap risk in dense scroll lists; two call sites to maintain |
| 3 | Long-press or swipe-to-reveal on `MyPostsScreen` only | Zero changes to `PostCard` or `PostDetailScreen`; management intent is explicit | Requires gesture interceptor wrapping over `PostCard` in `MyPostsScreen`; hides edit from the most natural discovery point; not reachable from deep-link entry into detail |

## Decision

**Chosen:** Option 1 — overflow menu on `PostDetailScreen` AppBar only.

The detail screen is where an author is most likely to notice a mistake — they are reading the full content. Putting the action there creates a direct cause-effect relationship with no intermediate navigation. Option 2's faster delete path does not justify adding ownership-awareness to a shared feed widget and doubling the accidental-action surface. Option 3 breaks discoverability for deep-link entry paths and adds gesture complexity without meaningful benefit over Option 1.

## Reversal Cost

**Low.** The domain layer (use cases, repository interface) is independent of which widget hosts the trigger. Moving from Option 1 to Option 2 later requires extending `PostCard` with an optional ownership parameter and wiring a second call site — no schema changes. Moving to Option 3 requires rerouting the navigation trigger but no domain changes.

## Consequences

**Easier:**
- `PostCard` stays a pure display widget with no ownership or mutation logic.
- The implementation pattern mirrors `_deleteComment` in `PostDetailScreen`, making it immediately reviewable by the team.
- The new `EditPostScreen` route is additive — no existing screens are modified beyond `PostDetailScreen`'s AppBar actions list.

**Harder:**
- Authors who arrive at `MyPostsScreen` must tap into a post's detail view before they can delete it — one extra tap compared to a swipe-to-delete card pattern.
- A future "quick-delete from My Posts" request would require revisiting this decision, though the reversal cost is low.

**Follow-up decisions required:**
- Which fields are mutable in an edit (title, description, tags, external URL, module number — explicit allowlist needed for security rules). Resolved in the Tech Spec.
- Whether Storage file deletion is client-side or Cloud Function cascaded. Resolved in the Tech Spec.
- Whether an "edited" indicator should appear in `PostDetailScreen` when `updatedAt != createdAt`. Product owner decision.
