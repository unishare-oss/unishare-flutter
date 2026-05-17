---
title: "0001: Use FCM + Cloud Functions for notification delivery with Firestore subcollection for in-app history"
description: "Hybrid push architecture: Cloud Functions fan out FCM pushes and write canonical notification documents; the Flutter client reads those documents for the in-app center."
---

# 0001 — Use FCM + Cloud Functions for notification delivery with Firestore subcollection for in-app history

**Status:** ACCEPTED  
**Author:** Nang Hayman Aye Mya  
**Date:** 2026-05-14

## Problem

Unishare students need to know when activity happens on their posts and requests (comments, upvotes, suggestions) without manually polling the app. Two requirements are in tension: true push delivery when the app is closed, and a persistent in-app notification history. A pure client-side or local-notification approach cannot satisfy both simultaneously within the existing Firebase stack.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | In-app only — Firestore stream + `flutter_local_notifications` | No Blaze required; easiest to build | Cannot wake a terminated app; no true push; client-to-client Firestore writes create security rule complexity |
| 2 | Client-side FCM dispatch (writing client sends push) | No dedicated Cloud Function | Exposes FCM server key on client (security violation); unreliable if writer goes offline; does not scale |
| 3 | FCM via Cloud Functions + Firestore `notifications` subcollection (hybrid) | True push when app is closed; server-written notification history is tamper-free; security rules are simple | Requires Blaze plan; adds Cloud Function operational surface |

## Decision

**Chosen:** Option 3 — FCM via Cloud Functions + Firestore `users/{uid}/notifications` subcollection

Firestore trigger Cloud Functions are the only mechanism in the Firebase stack that can reliably dispatch FCM pushes from a trusted server context without exposing credentials to clients; this satisfies the terminated-app push requirement. The same Cloud Function write that triggers FCM also creates the canonical notification document, so the in-app center reads an authoritative, client-tamper-free history without needing a separate write path. The assumption this relies on is that the team will upgrade to Blaze plan — expected costs are within the free invocation tier for a university-cohort audience.

## Reversal Cost

**Medium-to-High.** Decommissioning Cloud Functions would require relocating fan-out logic to a different backend or accepting degraded client-side delivery. The `users/{uid}/notifications` Firestore schema and the `firebase_messaging` Flutter integration are reusable regardless of what writes notification documents, so those artifacts survive a function replacement. However, rewriting the trigger logic and re-testing delivery reliability represents meaningful rework.

## Consequences

**Easier:**
- Security rules for notifications are simple read-only rules per UID — no client ever writes to another user's notification path.
- FCM token rotation and stale-token cleanup can be handled centrally in the function, not across multiple clients.
- Adding new notification types (e.g., suggestion accepted, request fulfilled) requires only a new function trigger and a new `type` enum value — the Flutter data layer does not change.

**Harder:**
- Local development requires the Firebase Emulator Suite to test end-to-end notification flow.
- The team must budget for Blaze plan billing (even if actual cost is near zero at current scale).
- Function cold-start latency may add a few hundred milliseconds to first notification delivery after a period of inactivity.

**Follow-up decisions required:**
- FCM token storage schema (`users/{uid}/fcmTokens` subcollection vs. array field on user document).
- Read/unread state write ownership (client direct write vs. callable function).
- Notification document TTL / retention policy (to prevent unbounded Firestore growth).
- Web push VAPID configuration (deferred — not in scope for v1).
