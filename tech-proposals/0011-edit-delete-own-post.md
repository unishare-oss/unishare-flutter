---
title: "0011: Edit and Delete Own Post"
description: "Allow post authors to correct or remove their own posts via a contextual action menu."
---

# PROP-0011: Edit and Delete Own Post

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-05-19
**Spec:** [SPEC-0011](../tech-specs/0011-edit-delete-own-post.md)
**Approved by:** Slade

---

## Problem

Once a post is published, its author has no mechanism to fix errors in the title or description, update metadata, or remove the post entirely. The only recourse is to leave incorrect or unwanted content visible to all users indefinitely. This affects two groups: the author, who cannot exercise basic ownership over their content, and all readers, who encounter stale or erroneous material with no path to correction.

The analogous feature already exists for comments — `CommentTile` exposes `onEdit` and `onDelete` callbacks gated on `comment.authorId == currentUser.uid`, and a `DeleteComment` use case handles the deletion side. The post layer lacks equivalent domain and presentation support: `PostRepository` has no `deletePost()` or `updatePost()` method, `PostFirestoreDatasource` has no delete or update path, and `PostDetailScreen`'s AppBar contains only a share button.

The constraint from the product owner is a hard delete only (no soft-delete / recycle bin needed) with a standard online-only flow (no offline queue for mutations).

---

## Goals

- Authors can delete any post they own; the Firestore document and all associated Storage files are removed permanently.
- Authors can edit the mutable text fields of a post they own (title, description, tags, external URL, module number) and the change is reflected immediately for all readers via the existing `watchPost` stream.
- The action surface is visible only to the post's owner; other users never see it.
- Ownership check is enforced in both the client UI and Firestore security rules.
- The domain layer remains pure Dart — no Firebase imports leak into use cases or repository interfaces.
- No new third-party packages are required.

## Non-goals

- Soft delete, archiving, or a recycle bin — hard delete only per product-owner constraint.
- Offline queuing for edit or delete operations — online-only per product-owner constraint.
- Admin / moderator delete of other users' posts — out of scope for this proposal.
- Editing media attachments (adding, reordering, or removing uploaded files) — file management is significantly more complex and is deferred to a separate proposal.
- Bulk delete from `MyPostsScreen`.
- Analytics or audit logging of mutations.

---

## Options

### Option A — Overflow menu on PostDetailScreen only

A 3-dot `PopupMenuButton` is added to the AppBar of `PostDetailScreen`, visible only when `post.authorId == currentUser.uid`. The menu exposes two items: **Edit** and **Delete**. Edit navigates to a new `EditPostScreen` pre-populated with existing values; Delete shows a confirmation `AlertDialog` (matching the pattern used by `_deleteComment` in the same file) then hard-deletes the Firestore document and all Storage files before navigating back to the feed.

**Pros:**
- The detail screen is the single place where all post content is visible, so the full edit form is contextually appropriate there.
- Follows the established comment-deletion pattern in the same screen; reviewers see a familiar structure.
- The AppBar already has an `actions` list — adding a `PopupMenuButton` is additive with no layout disruption.
- Does not require any changes to `PostCard` or the feed layer.
- Accidental taps are rare since the detail screen requires intentional navigation to reach.

**Cons:**
- Authors must navigate into the detail view of a post to delete it; they cannot act directly from the `MyPostsScreen` list.
- `EditPostScreen` is a net-new screen with its own route, provider, and widget test.

**Effort:** M — two use cases, repository/datasource additions, one new screen, two tests.

---

### Option B — Contextual menu on PostCard (feed + detail)

The same 3-dot `PopupMenuButton` is surfaced directly on `PostCard` (shown in the card's top-right area, visible to the author only) in addition to `PostDetailScreen`. This gives faster access: the author can delete or edit from the feed or from `MyPostsScreen` without entering the detail view.

**Pros:**
- Faster path to delete — one tap from any list that shows the card.
- Consistent action surface wherever the post appears.

**Cons:**
- `PostCard` is a shared feed widget used across the main feed, `MyPostsScreen`, and public profile pages. Adding ownership-awareness means the card must receive `currentUid` as a parameter or read it from a Riverpod provider, increasing coupling.
- The card layout is compact; the 3-dot icon competes with the existing `SaveButton` for top-right space.
- Edit from a card in the feed jumps straight to `EditPostScreen` without context — the author cannot review the full post first.
- Accidental taps are more likely in a scrollable feed where cards are dense.
- Higher surface area for bugs — two call sites for the same action logic.

**Effort:** L — same domain work as A plus PostCard modifications across three call sites and corresponding widget tests.

---

### Option C — Actions on MyPostsScreen only

Edit and delete are accessible exclusively from `MyPostsScreen` via long-press or a swipe-to-reveal action on each row. The feature is completely absent from the main feed and from `PostDetailScreen`.

**Pros:**
- `MyPostsScreen` is already the author's management hub, so the mental model is coherent.
- Zero changes to `PostCard` or `PostDetailScreen`.
- Swipe-to-delete is a recognised mobile pattern.

**Cons:**
- `MyPostsScreen` currently renders `PostCard` widgets inside `ListView.separated` — a swipe-to-reveal or long-press gesture interceptor would require replacing `PostCard` with a wrapper (e.g. `Dismissible`) or adding `GestureDetector` layering, either of which leaks management-mode concerns into the card.
- If a user navigates to a post's detail screen via a deep link or from another user's profile, they have no route back to manage it without leaving the screen and opening `MyPostsScreen`.
- Edit is hidden from the place where the author is reading their own post and most likely to notice the error they want to fix.
- Long-press and swipe-to-reveal are less discoverable than a visible icon and require documentation or onboarding hints.

**Effort:** M — same domain work as A, but swipe/long-press gesture work replaces the EditPostScreen navigation concern.

---

## Recommendation

**Option A — Overflow menu on PostDetailScreen only.**

The detail screen is where an author is most likely to notice content that needs correction — they are reading it. Placing the action there creates a direct cause-effect loop with the lowest accidental-action risk. Option B gives marginally faster delete access from the feed but adds fragile coupling to the shared `PostCard` widget and increases the likelihood of accidental taps in dense scroll lists; the one-navigation-step cost of Option A does not justify those tradeoffs. Option C hides the edit action from the most natural discovery point and introduces gesture interceptors that complicate the card layer without meaningful benefit over A.

The pattern established by `_deleteComment` in `PostDetailScreen` — confirmation dialog, use case call, error snackbar — maps directly onto the delete flow, keeping the implementation predictable and reviewable.

**Reversal cost if the team changes its mind:** Low-to-medium. Moving from A to B requires extending `PostCard` to accept ownership context and adding a second call site; the domain and data layers do not change. Moving from A to C requires rerouting the navigation trigger but the same use cases, repository methods, and datasource calls remain.

---

## Open Questions

1. **Storage file deletion:** When a post is deleted, its associated media files must also be removed from Firebase Storage. The Storage paths are derivable from the `mediaUrls` field on the `Post` entity. Should the client delete Storage files directly via `firebase_storage`, or should a Cloud Function trigger handle cascading file cleanup on `posts/{postId}` document deletion? The choice affects whether the client ever writes to Storage outside the upload flow, and has security rule and error-handling implications.

2. **Edit scope — which fields are mutable?** Text fields (title, description, tags, external URL, module number, posting identity) are straightforward. Changing `courseId` or `year` would invalidate the feed query ordering index. Changing `postingIdentity` from anonymous to named would retroactively reveal the author. The spec must define an explicit allowlist before implementation begins.

3. **AI summary invalidation:** If a user edits the description of a post whose `summaryStatus == done`, should the existing summary be cleared and re-queued for summarization? Clearing it silently and setting `summaryStatus` back to `pending` is the simplest path, but it depends on whether the summarization pipeline re-triggers on document update or only on create.

4. **Firestore security rules:** Existing write rules allow creation when `authorId == request.auth.uid`. Update rules must be added that restrict which fields an owner may mutate and must prevent changes to `authorId`, `likesCount`, `createdAt`, and `summaryStatus`. The spec must enumerate the permitted field set for the update rule.

5. **`updatedAt` field:** On edit, `updatedAt` should be set to `FieldValue.serverTimestamp()`. Is it acceptable to surface an "edited" indicator in `PostDetailScreen` (comparing `updatedAt != createdAt`), or should edits be silent? The product owner has not specified this.

---

## Acceptance Criteria

- A post owner navigating to `PostDetailScreen` sees a 3-dot overflow menu in the AppBar; no other user sees this menu.
- Tapping **Delete** from the overflow menu presents a confirmation dialog with a "Delete" and "Cancel" action.
- Confirming delete removes the Firestore document and all associated Storage files, then navigates the user back to the feed.
- Cancelling the confirmation dialog leaves the post unchanged and dismisses the dialog.
- Tapping **Edit** from the overflow menu opens an `EditPostScreen` pre-populated with the current values of all mutable fields.
- Saving an edit updates the Firestore document; the `watchPost` stream on `PostDetailScreen` reflects the changes immediately.
- Saving an edit with an empty title or empty description is rejected with an inline error message — the save action does not fire.
- The domain `DeletePost` use case and `UpdatePost` use case contain zero Flutter or Firebase imports.
- `PostRepository` interface declares `deletePost(String postId)` and `updatePost(...)` as abstract methods.
- Ownership enforcement is present in both the client (`post.authorId == currentUser.uid`) and Firestore security rules (the update/delete rules reject requests from non-owners).
- A widget test for `PostDetailScreen` asserts the overflow menu is present when the current user is the author and absent otherwise.
- A widget test for `EditPostScreen` asserts that submitting with a blank title shows a validation error and does not trigger the save use case.
- A unit test for `DeletePost` verifies it delegates to `PostRepository.deletePost` and propagates errors.
- A unit test for `UpdatePost` verifies it validates required fields before delegating to `PostRepository.updatePost`.
