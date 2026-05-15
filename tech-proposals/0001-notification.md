---
title: '0001: Notification System'
description: 'Push and in-app notifications so students are alerted when their posts receive replies, upvotes, or suggestion responses — without polling the app manually.'
---

# PROP-0001: Notification System

**Status:** APPROVED  
**Author:** Nang Hayman Aye Mya  
**Date:** 2026-05-14  
**Spec:** (pending approval)  
**Approved by:** Nadi

---

## Problem

Students who post academic content or create content requests have no way to know when activity happens on their content unless they open the app and navigate to the relevant screen. Specifically:

- A student publishes a post; someone replies in comments — the author never knows.
- A student creates a content request; another user upvotes it or suggests a fulfillment — the requester is not alerted.
- A student's suggestion is accepted by the request author — the suggester has no feedback.

The result is that engagement loops break down: authors do not return to follow up on replies, and requesters do not see when their needs are met. The missing capability is a notification system that reaches users both when the app is open (in-app) and when it is closed (push).

The app currently has a `NotificationsScreen` scaffold at `lib/features/notifications/presentation/screens/notifications_screen.dart` that renders "Coming soon" — the shell exists but nothing backs it.

---

## Goals

1. Users receive a push notification on their device within 30 seconds of any of these events: post comment added, post upvote, request upvote, suggestion submitted on their request, suggestion accepted.
2. Push notifications arrive even when the app is fully closed (terminated state) on iOS and Android.
3. An in-app notification center (the existing bell-icon screen) shows the full history of notifications for the signed-in user, persisted across sessions.
4. Each notification item carries enough context to deep-link directly to the relevant post or request detail screen via `go_router`.
5. Unread notifications are visually distinguished from read ones; marking all as read is supported.
6. The system works on iOS and Android at launch; web push is explicitly deferred (see Non-goals).
7. All notification state is scoped to the authenticated user — guests see no notifications.

---

## Non-goals

- Email or SMS notifications of any kind.
- Broadcast / admin-to-all-users notifications.
- Notification analytics (delivery rate, click-through rate, funnel metrics).
- Web push notifications (Chrome/Safari background push on web). Web in-app display may be done as a follow-up.
- Notification preferences / per-type opt-out settings (may follow in a later iteration).
- Rich media (image thumbnails) inside push notification payloads.

---

## Options

### Option A — FCM triggered by Cloud Functions (server-side fan-out)

**Description:** Firestore trigger Cloud Functions listen to writes on `posts/{postId}/comments`, `requests/{requestId}/upvotes`, and `requests/{requestId}/suggestions`. When triggered, the function looks up the target user's FCM token(s) from a `users/{uid}/fcmTokens` subcollection, calls the FCM Admin SDK to dispatch the push, and also writes a document to `users/{uid}/notifications` for the in-app center.

**Pros:**

- True server-side push — no client needs to be running to fan out a notification.
- Atomic and reliable: the function runs even if the triggering client goes offline immediately after writing.
- Scales naturally to fan-out scenarios (e.g., notifying every upvoter when a request is fulfilled).
- Keeps security rules simple: clients never write to `users/{otherUid}/notifications` directly.
- Standard industry pattern for Firebase-native apps.

**Cons:**

- Requires Cloud Functions, which requires upgrading from Spark to Blaze (pay-as-you-go) plan.
- Adds operational surface: function cold starts, deployment pipeline, log monitoring.
- Development loop is slower — functions must be deployed or run in the Firebase Emulator Suite.
- Estimated cost at Unishare scale (small university cohort) is likely within the always-free Cloud Functions invocation allowance (2 M invocations/month free on Blaze), but billing must be enabled.

**Effort:** L (Cloud Function authoring, Blaze upgrade, emulator setup, FCM token management, token refresh handling)  
**Requires Blaze:** Yes

---

### Option B — FCM triggered client-side (polling a Firestore sentinel document)

**Description:** Instead of Cloud Functions, the writing client itself sends the FCM push after completing its Firestore write. For example, after `toggleUpvote` writes to `requests/{requestId}/upvotes/{uid}`, the client also reads the request owner's FCM token from Firestore and calls the FCM HTTP v1 API directly with a service-account token fetched via a Firebase App Check–protected Cloud Function — or alternatively the client writes a `pendingNotifications` document that another client (the recipient's app) polls via a Firestore stream and converts to a `flutter_local_notifications` local notification.

**Pros:**

- No dedicated Cloud Function for fan-out; avoids Blaze requirement for compute.
- Relatively straightforward to prototype.

**Cons:**

- FCM push cannot be sent directly from a Flutter client without exposing a server key or service-account credentials — this is a security violation. The "polling" variant degrades to a client-side local notification, which only fires while the recipient's app is open or backgrounded (not terminated).
- The writing client may be offline or crash before completing the secondary write, causing silent notification loss.
- Sharing FCM tokens in a readable Firestore path creates a privilege-escalation risk: any authenticated user could read another user's device token.
- The polling variant is functionally equivalent to Option C — it does not deliver true push when the app is closed.
- Requires non-trivial security rule gymnastics to prevent clients from faking notifications to arbitrary users.

**Effort:** M (token storage, security-rule hardening, local notification plugin) but the result is architecturally unsound.  
**Requires Blaze:** No (polling variant) / Partial (FCM variant still needs a backend proxy)

---

### Option C — In-app only via Firestore stream and `flutter_local_notifications`

**Description:** A `users/{uid}/notifications` subcollection is written by the triggering client at write time (e.g., the upvoter writes a notification document to the post owner's path). The recipient's app subscribes to this subcollection via a Firestore `StreamProvider`. When the stream emits a new document, `flutter_local_notifications` fires a local notification that appears in the system tray — but only while the app is running in the foreground or background (not terminated). In-app history is backed by the same Firestore stream.

**Pros:**

- No Blaze upgrade required.
- Simplest implementation path: one new Firestore subcollection, one `StreamProvider`, one `flutter_local_notifications` integration.
- In-app notification center is fully functional regardless of push delivery.

**Cons:**

- Does NOT satisfy the hard requirement: notifications do not arrive when the app is terminated. `flutter_local_notifications` is a local API — it cannot wake a terminated process.
- Writing a notification document to another user's `users/{otherUid}/notifications` path from the client requires permissive security rules that are difficult to constrain correctly (any authenticated user can write to any other user's notifications path given naive rules).
- Notification delivery reliability is tied to whether the triggering client's Firestore write succeeds before it goes offline.
- Does not scale: if a post has 100 upvoters, the upvoting client writes 1 notification; but if a popular post receives 100 comments, the post author gets 100 documents written by 100 different clients — no fan-out control.

**Effort:** S (no new platform dependencies beyond `flutter_local_notifications`)  
**Requires Blaze:** No

---

### Option D — Hybrid: Firestore subcollection for in-app history + FCM via Cloud Functions for push (Recommended)

**Description:** This combines the reliable delivery of Option A with a clean data model for the in-app center. A Cloud Function (Firestore trigger) handles all push dispatch and writes the canonical notification document to `users/{uid}/notifications/{notifId}`. The Flutter app subscribes to that subcollection via a Riverpod `StreamProvider` to power the notification center and badge count. FCM tokens are stored in `users/{uid}/fcmTokens` and refreshed by the client on each login or token rotation. On app open, the app registers its FCM token; on notification tap, `go_router` deep-links to the relevant content.

The Firestore document written by the Cloud Function serves a dual purpose: it is the push trigger (function reads it and dispatches FCM) and the persistent record for the in-app center. This avoids two separate writes and gives the in-app center an authoritative source of truth that was never touched by another client.

**Pros:**

- True push when the app is closed — satisfies the hard requirement.
- Notification history is authoritative (server-written) and consistent: the client only reads.
- Security rules are simple: clients read only their own `users/{uid}/notifications`; only Cloud Functions write to them.
- FCM token exposure is limited: tokens live under `users/{uid}/fcmTokens` and are only readable server-side.
- Decoupled from the writing client — the upvoter's client does not need to know the target's FCM token or notification logic.
- Scales well: one function invocation per triggering event, regardless of how many clients are online.

**Cons:**

- Requires Blaze plan and Cloud Functions deployment.
- Adds operational complexity (emulator setup, function CI/CD, monitoring).
- Cold-start latency may add a few hundred milliseconds to the first notification after function inactivity — acceptable for a notification system (not a synchronous user action).
- Web push requires additional VAPID key configuration; deferred to Non-goals.

**Effort:** L (Cloud Function authoring, Blaze upgrade, FCM token management, `firebase_messaging` plugin, `flutter_local_notifications` for foreground display)  
**Requires Blaze:** Yes

---

## Recommendation

**Option D — Hybrid Firestore + FCM + Cloud Functions** is the recommended approach.

It is the only option that satisfies both stated constraints simultaneously: push delivery when the app is closed, and a persistent in-app notification history. The dual-purpose notification document (written once by the Cloud Function, read by the Flutter client) gives the in-app center an authoritative, tamper-free source of truth without requiring any client-to-client Firestore writes, which keeps security rules straightforward. The Blaze upgrade cost is justified because Unishare is already Firebase-native and Cloud Functions are the standard mechanism for trusted server-side logic in that ecosystem — the free invocation tier will cover the expected notification volume for a university cohort.

**Reversal cost if the team changes its mind:** Medium-to-High. Cloud Functions would need to be decommissioned and the notification fan-out logic would need to move somewhere else (another backend or a degraded client-side model). The `users/{uid}/notifications` Firestore schema and the `firebase_messaging` integration in the Flutter app are reusable regardless of what triggers the writes, so those artifacts are not wasted.

---

## Open Questions

1. **Notification types at launch:** Which event types are in scope for v1? The proposal assumes: post comment added, post liked, request upvoted, suggestion submitted on your request, your suggestion accepted. Are there others (e.g., your request fulfilled/closed, a post you saved is updated)? The answer determines the number of Cloud Function triggers needed.

2. **FCM token storage and multi-device:** Should a user's FCM tokens be stored as a subcollection (`users/{uid}/fcmTokens/{tokenHash}`) or as an array field on the user document? The subcollection approach handles multi-device and stale token cleanup more cleanly but requires an extra read in the function. How many concurrent devices per user should the system support, and is the team prepared to handle token invalidation / `registration-token-not-registered` FCM errors?

3. **Read/unread state ownership:** Who marks a notification as read — the client writing `isRead: true` directly to `users/{uid}/notifications/{notifId}`, or a dedicated Cloud Function? Client-side writes are simpler to implement but require a permissive security rule (`allow update: if request.auth.uid == userId && onlyIsReadChanged()`). A function call is safer but adds latency. Which is acceptable?

4. **Web push timeline:** The Non-goals defer web push, but the `NotificationsScreen` is shared across platforms. Should the web build show a "notifications not supported on web" message, hide the bell icon, or silently degrade to in-app-only (Firestore stream without local push)? This must be decided before the spec is written to avoid conditional build complexity.

5. **Notification retention and pagination:** How long should notification documents be retained in Firestore? Indefinite retention with no pagination cap will grow unbounded. A TTL policy (e.g., delete documents older than 30 days via a scheduled Cloud Function) or a max-count eviction strategy should be agreed on before the data layer is designed.

6. **Anonymous / guest users:** The app supports a guest mode (see `GuestModeProvider`). Guests have no `uid` and cannot receive notifications. Should the bell icon be hidden in guest mode, or should it be visible but prompt sign-in when tapped?

---

## Acceptance Criteria

1. A user who has the app closed (process terminated) receives an iOS/Android system push notification within 30 seconds of another user commenting on one of their posts.
2. A user who has the app closed receives a push notification within 30 seconds of their request being upvoted or a suggestion being submitted on their request.
3. Opening the app from a push notification deep-links the user directly to the relevant post or request detail screen via `go_router` — not just to the home feed.
4. The in-app notification center (bell icon screen) displays all notifications for the signed-in user in reverse-chronological order, with unread items visually distinct from read items.
5. Notifications persist across app restarts — the notification history is not lost when the app is closed and reopened.
6. Tapping "mark all as read" transitions all unread notification items to the read state within one Firestore batch write.
7. A user never receives a notification triggered by their own action (e.g., upvoting your own post does not send a push to yourself).
8. FCM tokens are never readable by any client other than the token owner — they are only accessible server-side (Cloud Function).
9. The notification feature has zero impact on the Domain layer's purity constraint: `features/notifications/domain/` contains only pure Dart entities, repository interfaces, and use cases with no Flutter or Firebase imports.
10. The feature degrades gracefully when FCM token registration fails (e.g., user denies notification permission on iOS): the app continues to function normally, and in-app notification history still loads from Firestore.
