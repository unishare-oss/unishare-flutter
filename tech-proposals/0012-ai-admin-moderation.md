---
title: "0012: AI Admin Moderation"
description: "Posts enter a pending queue; AI pre-screens each one and an admin approves or rejects before the post appears on the feed."
---

# PROP-0012: AI Admin Moderation

**Status:** ACCEPTED  
**Author:** Sudakarn  
**Date:** 2026-05-20  
**Spec:** [SPEC-0012](../tech-specs/0012-ai-admin-moderation.md)  
**Approved by:** Sudakarn

---

## Problem

Currently any authenticated user can submit a post and it immediately appears on the feed with no review step. This allows low-quality, irrelevant, or inappropriate content to surface to all students. The platform needs a lightweight content gate that catches problems before they reach the feed, without requiring admins to read every post from scratch.

## Proposed Solution

Introduce a **pending → approved / rejected** lifecycle for every post submission.

1. **Post submission** — when a user submits a post, it is written to Firestore with `status: "pending"`. It does not appear on the public feed.
2. **AI pre-screening** — a Firebase Cloud Function triggers on the new document. It calls the Claude API, passes the post title, description, tags, and file type, and receives a structured verdict: `recommended: approve | reject`, `confidence: 0–1`, and a short `reason` string. The verdict is written back to the post document as `aiVerdict`.
3. **Admin moderation queue** — admins (identified by a `role: "moderator"` field on their Firestore user document) see a dedicated **Moderation** screen in the app. It lists all `pending` posts ordered by submission time, with the AI verdict and reason surfaced as a visual hint.
4. **Admin decision** — the admin taps Approve or Reject. A Cloud Function validates the admin's role and updates `status` to `"approved"` or `"rejected"` and records `moderatedBy` and `moderatedAt`. Approved posts become visible on the feed immediately. Rejected posts trigger an in-app notification to the author explaining the reason.

## Alternatives Considered

### A — Fully automatic AI moderation (no human step)

Auto-approve or auto-reject based solely on the AI verdict, no admin queue. **Rejected:** false positives would silently block legitimate academic content with no recourse; students would have no way to appeal.

### B — Human-only moderation (no AI)

Admins read every post manually with no AI hint. **Rejected:** does not scale as the platform grows; reviewers would spend time on obviously fine posts.

### C — Optimistic publish with post-hoc removal

Posts appear immediately; AI and admins flag and remove retroactively. **Rejected:** bad content is already visible to students during the review window, which is the core problem we are solving.

## Open Questions

1. Which Claude model should power the screener — Haiku 4.5 (fast, cheap) or Sonnet 4.6 (better reasoning)? Haiku is likely sufficient for structured classification.
2. Should rejected posts be permanently deleted or soft-deleted (retained for appeals)?
3. How is the `moderator` role granted — manually via Firebase Console, or through an in-app flow?
4. Should the AI verdict be shown to the post author (transparency) or kept internal to admins only?

## Acceptance Criteria

- Newly submitted posts have `status: "pending"` and are invisible on the public feed.
- A Cloud Function runs within 30 s of submission and writes `aiVerdict` to the post document.
- Users with `role: "moderator"` can access the Moderation screen; non-moderators cannot.
- Approving a post sets `status: "approved"` and makes it appear on the feed.
- Rejecting a post sets `status: "rejected"` and sends the author an in-app notification with the reason.
- The moderation action is recorded (`moderatedBy`, `moderatedAt`) for audit purposes.
