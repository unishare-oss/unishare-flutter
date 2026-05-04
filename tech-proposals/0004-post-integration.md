---
id: PROP-0004
title: "Post Integration"
status: ACCEPTED
author: architect
date: 2026-05-03
---

# PROP-0004: Post Integration

**Status:** ACCEPTED | **Author:** architect | **Date:** 2026-05-03 | **Approved by:** Slade (CTO) on 2026-05-03

---

## Problem

Students can browse the Unishare feed (established in PROP-0003) but have no mechanism to contribute content. There is no UI, no write path, and no offline-capable draft queue for creating posts. The Firestore schema from PROP-0003 defines the target shape of a published post:

```
posts/{postId}
  authorId, authorName, authorAvatar   ← denormalized at write time
  title, body
  mediaUrls: string[]                  ← Firebase Storage download URLs
  tags:      string[]
  likesCount: int                       ← read-only from client perspective
  createdAt, updatedAt: Timestamp
```

Every field except `likesCount` must be written by the client when a post is published. Until this write path exists, the feed is read-only and the core value proposition of peer content sharing cannot be exercised by any user.

---

## Goals

- Allow any authenticated student to author and publish a post (title, body, optional tags, optional media).
- Support attaching files or images that are uploaded to Firebase Storage; the resulting download URLs are stored in `mediaUrls` on the Firestore document.
- Enable offline drafting: a post started without connectivity must be persisted locally (Hive) and queued for publication when connectivity is restored.
- Write directly to Firestore (`posts/{postId}`) from the client — no Cloud Functions or REST intermediary in the publish path.
- Published posts must appear in the existing real-time feed immediately for all connected users, relying on Firestore's live listeners already established by PROP-0003.

---

## Non-goals

- Cloud Functions for post creation or validation.
- NestJS or any REST API involvement in the write path.
- Post editing or deletion (separate proposal).
- Comment threads or reactions beyond the existing `likesCount` mechanism.
- Full-text search or content moderation at publish time.
- Admin or moderation tooling.

---

## Options

### Option A: Direct Firestore Write with Optimistic UI and Hive Draft Queue

The client is solely responsible for the entire publish sequence. When the user taps "Publish":

1. Any attached media is uploaded to Firebase Storage; download URLs are collected.
2. The client writes a new document to `posts/{postId}` with all fields populated, including the collected URLs and a denormalized snapshot of the author's display name and avatar from the current auth session.
3. The presentation layer applies an optimistic update (prepends the new post to the local feed list) immediately, then reconciles once the Firestore write confirms.

For the offline case, the draft is serialized to Hive before any network operation begins. On reconnect, a background sync worker reads queued drafts, executes the upload-then-write sequence in order, and removes each draft upon confirmed Firestore write.

**Pros:**
- Minimal complexity — no new backend surface; write path is a single Firestore document write after Storage upload.
- Aligns directly with the PROP-0003 schema; no bridging documents or status fields required.
- Real-time propagation to other users is automatic via existing Firestore listeners.
- Optimistic UI gives immediate feedback without waiting for round-trip latency.
- Offline draft queue is self-contained in the client; Hive is already in the stack.

**Cons:**
- Upload ordering is sequential per post (Storage upload must complete before Firestore write); a failed upload leaves no Firestore record but the local draft remains, requiring clear retry UX.
- Client is trusted to write correct `authorId`, `authorName`, and `authorAvatar` values — Firestore Security Rules must enforce that `authorId == request.auth.uid` and that the client cannot spoof other users' content.
- Partial failure state (Storage upload succeeded, Firestore write failed) must be handled explicitly in the draft queue — the stored draft must record which media URLs are already uploaded to avoid re-uploading.
- No server-side validation of content (size, type, profanity) beyond Security Rules.

**Effort:** M

---

### Option B: Firestore "Pending Post" Document Pattern

The client writes to a separate `pendingPosts/{id}` collection with `status: "pending"` rather than directly to `posts/`. A reconciliation process — either a client-side reconnect handler or a lightweight scheduled Cloud Function — reads `pendingPosts` documents and promotes them to `posts/` once all media is confirmed uploaded.

**Pros:**
- Clear, inspectable state machine: `draft → pending → published`. Each transition is a document field update.
- Partial failure is explicit in the document (`status: "upload_failed"`, `status: "write_failed"`), making debugging and retry logic easier to reason about.
- The `posts/` collection remains clean — no partially-formed documents ever appear in the feed.
- Easier to extend later with server-side moderation: a Cloud Function could intercept `pending` documents before promotion.

**Cons:**
- Requires maintaining a second collection (`pendingPosts`) with its own Security Rules, indexes, and cleanup strategy.
- The promotion step is an additional async operation; if done client-side it reintroduces the same partial failure problem at the promotion boundary. If done via Cloud Function, that conflicts with the hard constraint ruling out Cloud Functions.
- Real-time feed appearance is delayed until promotion completes, adding latency for the publishing user.
- Significantly more code surface: state machine, reconciler, two-collection Security Rules, and cleanup jobs.
- Cloud Functions are ruled out by project constraints, so the reconciler must be client-side — which largely negates the state-machine benefit.

**Effort:** L

---

## Recommendation

**Chosen option:** Option A — Direct Firestore Write with Optimistic UI and Hive Draft Queue.

The team has explicitly ruled out Cloud Functions, which removes the primary advantage of Option B: a server-side reconciler that can reliably promote pending documents. Without a server-side actor, Option B's state machine still runs on the client and inherits the same partial-failure risks as Option A, while adding a second collection and significantly more code. Option A fits the existing schema exactly — the `posts/{postId}` document written by the client is already the final, feed-visible document, so there is no promotion gap and real-time propagation is immediate. The partial-failure risk (Storage upload succeeded, Firestore write failed) is manageable by recording uploaded URLs in the local Hive draft before committing the Firestore write, giving the retry path idempotency without a server component.

---

## Open questions

- [ ] **Upload ordering** — Should the client upload all media to Firebase Storage and collect all download URLs before writing the Firestore document, or should it write the document first with an empty `mediaUrls` and patch it after upload? Writing after upload is simpler (one atomic write) but leaves the post invisible in the feed until all media is transferred. Writing first with a patch allows the post to appear immediately with a loading placeholder, but introduces a window where the document exists without its media.

- [ ] **Offline partial-upload recovery** — If media upload succeeds but the subsequent Firestore write fails (e.g., connectivity drops between the two operations), the next retry must not re-upload already-transferred files. The Hive draft must record which Storage paths have been successfully uploaded so the retry path skips completed uploads. What is the canonical format for this upload-progress snapshot in the draft record?

- [ ] **File size and type enforcement** — Firebase Storage Security Rules can reject uploads by size and content type, but they cannot surface a user-friendly error message. Should the client enforce limits locally before attempting upload (fast feedback, but bypassable), and also rely on Storage Rules as the hard backstop? What are the agreed limits (e.g., max file size, allowed MIME types)?

- [ ] **Author field staleness** — PROP-0003 raised this for the feed; it is equally relevant here. If a user updates their display name or avatar between posts, older posts retain the stale snapshot. Is a background reconciliation job in scope for v1, or is the snapshot-at-write-time approach acceptable indefinitely?

---

## References

- PROP-0003: Post Feed — `tech-proposals/0003-post-feed.md` (defines the `posts/{postId}` schema this proposal writes to)
