---
title: '0001: Notification System'
description: 'In-app notification centre and push delivery for post/request activity events using FCM, Cloud Functions, and a Firestore subcollection.'
---

# SPEC-0001: Notification System

**Status:** APPROVED
**Author:** Nang Hayman Aye Mya
**Date:** 2026-05-15
**Proposal:** [PROP-0001](../tech-proposals/0001-notification.md)
**Approved by:** Nadi

---

## Overview

This spec implements the v1 notification system for Unishare. When activity occurs on a user's post or request — a comment, like, reply, upvote, or suggestion — a Firestore-triggered Cloud Function dispatches an FCM push to the owner's registered device(s) and writes a canonical notification document to `users/{uid}/notifications/{notifId}`. The Flutter client subscribes to this subcollection via a Riverpod `StreamProvider`, rendering the in-app notification centre. Read/unread state is updated by a client direct-write restricted to the `isRead` field only. Web silently degrades: the bell icon and Firestore stream work, but FCM push is not delivered in v1.

---

## Architecture

### Data flow: notification creation and delivery

```mermaid
flowchart TD
    subgraph Source events
        A1[posts/{postId}/comments — onCreate]
        A2[posts/{postId}/likes — onCreate]
        A3[posts/{postId}/comments — onCreate with parentId]
        A4[requests/{requestId}/upvotes — onCreate]
        A5[requests/{requestId}/suggestions — onCreate]
        A6[requests/{requestId} — onUpdate: status → fulfilled]
    end

    subgraph Cloud Functions (Node 20 / TypeScript)
        CF1[onCommentAdded]
        CF2[onPostLiked]
        CF3[onCommentReply]
        CF4[onRequestUpvoted]
        CF5[onSuggestionSubmitted]
        CF6[onRequestFulfilled]
    end

    subgraph Firestore
        NF[users/{uid}/notifications/{notifId}]
        TF[users/{uid}/fcmTokens/{tokenHash}]
    end

    subgraph FCM
        FCM_SVC[Firebase Cloud Messaging]
        DEVICE[Mobile device / push banner]
    end

    subgraph Flutter client
        DS[NotificationFirestoreDatasource]
        REPO[NotificationRepositoryImpl]
        SP[watchNotificationsProvider — StreamProvider]
        SCR[NotificationsScreen]
        TILE[NotificationItemTile]
    end

    A1 --> CF1
    A2 --> CF2
    A3 --> CF3
    A4 --> CF4
    A5 --> CF5
    A6 --> CF6

    CF1 --> NF
    CF2 --> NF
    CF3 --> NF
    CF4 --> NF
    CF5 --> NF
    CF6 --> NF

    CF1 --> TF
    CF2 --> TF
    CF3 --> TF
    CF4 --> TF
    CF5 --> TF
    CF6 --> TF

    TF -->|read tokens| FCM_SVC
    FCM_SVC --> DEVICE

    NF -->|real-time stream| DS
    DS --> REPO
    REPO --> SP
    SP --> SCR
    SCR --> TILE
```

### FCM token registration flow

```mermaid
flowchart LR
    APP[App startup — main.dart]
    INIT[FcmService.init]
    AUTH[authStateProvider — uid]
    TOKEN[FirebaseMessaging.getToken]
    HASH[SHA-256 of token]
    FS[users/{uid}/fcmTokens/{tokenHash}]
    FG[Foreground message handler]
    LOCAL[In-app notification banner / refresh trigger]

    APP --> INIT
    INIT --> AUTH
    AUTH -->|authenticated| TOKEN
    TOKEN --> HASH
    HASH --> FS
    INIT --> FG
    FG --> LOCAL
```

---

## Firestore Schema

### `users/{uid}/notifications/{notifId}`

| Field           | Type        | Constraints                                                                                                                   |
| --------------- | ----------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`            | `string`    | equals document ID; set by Cloud Function                                                                                     |
| `type`          | `string`    | one of: `post_comment_added`, `post_liked`, `comment_reply`, `request_upvoted`, `suggestion_submitted`, `suggestion_accepted` |
| `isRead`        | `boolean`   | default `false`; only this field may be updated by the client                                                                 |
| `createdAt`     | `timestamp` | server timestamp set by Cloud Function; used for ordering                                                                     |
| `title`         | `string`    | short notification headline, e.g. "New comment on your post"                                                                  |
| `body`          | `string`    | notification body copy, e.g. "Alice commented: Great resource!" (truncated to 100 chars)                                      |
| `actorId`       | `string`    | UID of the user who triggered the event                                                                                       |
| `actorName`     | `string`    | display name of the actor at event time (denormalised)                                                                        |
| `actorPhotoUrl` | `string?`   | nullable photo URL of the actor at event time (denormalised)                                                                  |
| `targetId`      | `string`    | `postId` for post events; `requestId` for request events                                                                      |
| `targetType`    | `string`    | `"post"` or `"request"`                                                                                                       |
| `targetTitle`   | `string`    | title of the post or request at event time (denormalised)                                                                     |

Notes:

- Documents are written exclusively by Cloud Functions via the Admin SDK. The client never creates notification documents.
- Retention: a scheduled Cloud Function purges documents older than 30 days.
- The subcollection is ordered by `createdAt DESC` in the client query. No composite index is required beyond the default single-field index on `createdAt`.

### `users/{uid}/fcmTokens/{tokenHash}`

`{tokenHash}` is the SHA-256 hex digest of the raw FCM token string. Using the hash as the document ID ensures one document per physical token and avoids storing the raw token as a path segment.

| Field       | Type        | Constraints                                       |
| ----------- | ----------- | ------------------------------------------------- |
| `token`     | `string`    | raw FCM registration token                        |
| `platform`  | `string`    | `"android"`, `"ios"`, or `"web"`                  |
| `createdAt` | `timestamp` | when this token was first registered              |
| `updatedAt` | `timestamp` | refreshed on every app startup via set-with-merge |

Notes:

- The client reads and writes only its own token documents.
- Cloud Functions read all tokens for a given `uid` to fan out push delivery across devices.
- Stale tokens (rejected by FCM with `messaging/registration-token-not-registered`) are deleted by the Cloud Function after a failed send attempt.

---

## Firestore Security Rules Delta

Add the following blocks to `firestore.rules` inside `match /users/{userId} { ... }`. These replace no existing rules — they are additive.

```
// Notification inbox — server (Admin SDK) writes; client reads and marks read only.
match /notifications/{notifId} {
  // Owner can read their own notifications.
  allow read: if request.auth != null && request.auth.uid == userId;

  // No client creates — all documents are written by Cloud Functions via Admin SDK.
  allow create: if false;

  // Owner may update only the isRead field.
  allow update: if request.auth != null
                && request.auth.uid == userId
                && request.resource.data.diff(resource.data).affectedKeys()
                     .hasOnly(['isRead'])
                && request.resource.data.isRead is bool;

  // No client deletes — retention is managed by the scheduled Cloud Function.
  allow delete: if false;
}

// FCM tokens — owner manages their own device tokens only.
match /fcmTokens/{tokenHash} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

---

## File Map

### New Flutter files (Domain layer — pure Dart, zero Firebase/Flutter imports)

| Action | Path                                                                          | Responsibility                                                    |
| ------ | ----------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| Create | `lib/features/notifications/domain/entities/notification_item.dart`           | `AppNotification` entity class + `NotificationType` enum          |
| Create | `lib/features/notifications/domain/repositories/notification_repository.dart` | Abstract `NotificationRepository` interface                       |
| Create | `lib/features/notifications/domain/usecases/watch_notifications.dart`         | `WatchNotifications` use case — wraps `watchNotifications` stream |
| Create | `lib/features/notifications/domain/usecases/mark_notification_read.dart`      | `MarkNotificationRead` use case — single document `isRead` update |
| Create | `lib/features/notifications/domain/usecases/mark_all_notifications_read.dart` | `MarkAllNotificationsRead` use case — batch `isRead` update       |

### New Flutter files (Data layer)

| Action | Path                                                                                 | Responsibility                                                                             |
| ------ | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------ |
| Create | `lib/features/notifications/data/models/notification_model.dart`                     | Freezed DTO with `fromFirestore` factory and `toEntity` mapper                             |
| Create | `lib/features/notifications/data/datasources/notification_firestore_datasource.dart` | Firestore reads (`watchNotifications`, `markAsRead`, `markAllAsRead`) and FCM token writes |
| Create | `lib/features/notifications/data/repositories/notification_repository_impl.dart`     | Implements `NotificationRepository`; delegates to datasource                               |

### New Flutter files (Presentation layer)

| Action | Path                                                                                      | Responsibility                                                                  |
| ------ | ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| Create | `lib/features/notifications/presentation/providers/notification_repository_provider.dart` | Riverpod provider wiring `NotificationRepositoryImpl`                           |
| Create | `lib/features/notifications/presentation/providers/notifications_provider.dart`           | `@riverpod Stream<List<AppNotification>> watchNotifications(Ref ref)`           |
| Create | `lib/features/notifications/presentation/providers/unread_count_provider.dart`            | `@riverpod int unreadNotificationCount(Ref ref)` — derived from stream          |
| Create | `lib/features/notifications/presentation/widgets/notification_item_tile.dart`             | Single notification row widget; handles tap-to-navigate and read state          |
| Modify | `lib/features/notifications/presentation/screens/notifications_screen.dart`               | Replace "Coming soon" with real list + empty/loading/error states; guest prompt |

### New Flutter files (Core)

| Action | Path                                 | Responsibility                                                                     |
| ------ | ------------------------------------ | ---------------------------------------------------------------------------------- |
| Create | `lib/core/firebase/fcm_service.dart` | Token registration, token removal, foreground message handler; platform-guards web |

### Modified Flutter files

| Action | Path            | Responsibility                                                               |
| ------ | --------------- | ---------------------------------------------------------------------------- |
| Modify | `lib/main.dart` | Call `FcmService.init(uid)` after auth state resolves; re-call on UID change |

### New dependency (requires team approval before merge)

| Package              | Version constraint | Reason                                               |
| -------------------- | ------------------ | ---------------------------------------------------- |
| `firebase_messaging` | `^15.0.0`          | FCM token retrieval and foreground message callbacks |

`firebase_messaging` is an official FlutterFire package consistent with the existing stack. It must be added to `pubspec.yaml` under `dependencies` and registered in `firebase_options.dart` via `flutterfire configure`. Flag for team approval per CLAUDE.md convention.

### Cloud Functions (new directory)

| Action | Path                                              | Responsibility                                                                                                  |
| ------ | ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| Create | `functions/`                                      | Root Cloud Functions directory                                                                                  |
| Create | `functions/package.json`                          | Node 20 dependencies: `firebase-admin`, `firebase-functions` v6, TypeScript                                     |
| Create | `functions/tsconfig.json`                         | TypeScript compiler config targeting ES2020                                                                     |
| Create | `functions/src/index.ts`                          | Entry point — exports all trigger functions                                                                     |
| Create | `functions/src/triggers/onCommentAdded.ts`        | Firestore trigger on `posts/{postId}/comments/{commentId}` onCreate                                             |
| Create | `functions/src/triggers/onPostLiked.ts`           | Firestore trigger on `posts/{postId}/likes/{userId}` onCreate                                                   |
| Create | `functions/src/triggers/onCommentReply.ts`        | Same collection as onCommentAdded; differentiates by presence of `parentId` field                               |
| Create | `functions/src/triggers/onRequestUpvoted.ts`      | Firestore trigger on `requests/{requestId}/upvotes/{userId}` onCreate                                           |
| Create | `functions/src/triggers/onSuggestionSubmitted.ts` | Firestore trigger on `requests/{requestId}/suggestions/{suggestionId}` onCreate                                 |
| Create | `functions/src/triggers/onRequestFulfilled.ts`    | Firestore trigger on `requests/{requestId}` onUpdate when `status` transitions to `"fulfilled"`                 |
| Create | `functions/src/triggers/purgeOldNotifications.ts` | Scheduled function (every 24 h): deletes notification docs older than 30 days                                   |
| Create | `functions/src/lib/sendPush.ts`                   | Shared helper: reads `fcmTokens` subcollection, fans out `messaging.sendEachForMulticast`, removes stale tokens |
| Create | `functions/src/lib/writeNotification.ts`          | Shared helper: writes one `users/{uid}/notifications/{notifId}` document via Admin SDK                          |
| Create | `functions/src/lib/types.ts`                      | Shared TypeScript types: `NotificationType`, `NotificationPayload`                                              |

### Firestore config files

| Action | Path                     | Responsibility                                                                              |
| ------ | ------------------------ | ------------------------------------------------------------------------------------------- |
| Modify | `firestore.rules`        | Add `notifications` and `fcmTokens` subcollection rules as specified above                  |
| Modify | `firestore.indexes.json` | Add composite index for `users/{uid}/notifications` ordered by `createdAt DESC` (see below) |

New index entry to add to `firestore.indexes.json`:

```json
{
  "collectionGroup": "notifications",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "isRead", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

This index supports a future "unread first" sort. The basic `createdAt DESC` query used in v1 does not require a composite index.

---

## API Contracts

### Domain — entities

```dart
// lib/features/notifications/domain/entities/notification_item.dart
// Pure Dart — zero Flutter or Firebase imports.

enum NotificationType {
  postCommentAdded,
  postLiked,
  commentReply,
  requestUpvoted,
  suggestionSubmitted,
  suggestionAccepted,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.title,
    required this.body,
    required this.actorId,
    required this.actorName,
    this.actorPhotoUrl,
    required this.targetId,
    required this.targetType,
    required this.targetTitle,
  });

  final String id;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String title;
  final String body;
  final String actorId;
  final String actorName;
  final String? actorPhotoUrl;
  final String targetId;    // postId or requestId
  final String targetType;  // 'post' | 'request'
  final String targetTitle;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        title: title,
        body: body,
        actorId: actorId,
        actorName: actorName,
        actorPhotoUrl: actorPhotoUrl,
        targetId: targetId,
        targetType: targetType,
        targetTitle: targetTitle,
      );
}
```

### Domain — repository interface

```dart
// lib/features/notifications/domain/repositories/notification_repository.dart
// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/notifications/domain/entities/notification_item.dart';

abstract interface class NotificationRepository {
  /// Emits the full notification list for [userId] ordered by createdAt DESC.
  /// Re-emits on every Firestore snapshot change.
  Stream<List<AppNotification>> watchNotifications(String userId);

  /// Marks a single notification document isRead = true.
  Future<void> markAsRead(String userId, String notificationId);

  /// Marks all unread notification documents isRead = true for [userId].
  /// Implemented as a batched write (max 500 docs per batch).
  Future<void> markAllAsRead(String userId);

  /// Writes or refreshes the FCM token document at
  /// users/{userId}/fcmTokens/{sha256(token)}.
  Future<void> registerFcmToken(String userId, String token, String platform);

  /// Deletes the FCM token document for [token] (called on sign-out).
  Future<void> removeFcmToken(String userId, String token);
}
```

### Domain — use cases

```dart
// lib/features/notifications/domain/usecases/watch_notifications.dart
import 'package:unishare_mobile/features/notifications/domain/entities/notification_item.dart';
import 'package:unishare_mobile/features/notifications/domain/repositories/notification_repository.dart';

class WatchNotifications {
  const WatchNotifications(this._repository);
  final NotificationRepository _repository;

  Stream<List<AppNotification>> call(String userId) =>
      _repository.watchNotifications(userId);
}

// lib/features/notifications/domain/usecases/mark_notification_read.dart
import 'package:unishare_mobile/features/notifications/domain/repositories/notification_repository.dart';

class MarkNotificationRead {
  const MarkNotificationRead(this._repository);
  final NotificationRepository _repository;

  Future<void> call(String userId, String notificationId) =>
      _repository.markAsRead(userId, notificationId);
}

// lib/features/notifications/domain/usecases/mark_all_notifications_read.dart
import 'package:unishare_mobile/features/notifications/domain/repositories/notification_repository.dart';

class MarkAllNotificationsRead {
  const MarkAllNotificationsRead(this._repository);
  final NotificationRepository _repository;

  Future<void> call(String userId) => _repository.markAllAsRead(userId);
}
```

### Data — Freezed model (interface only)

```dart
// lib/features/notifications/data/models/notification_model.dart
// (partial — full Freezed boilerplate generated by build_runner)

@freezed
abstract class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    required String type,
    required bool isRead,
    required DateTime createdAt,
    required String title,
    required String body,
    required String actorId,
    required String actorName,
    String? actorPhotoUrl,
    required String targetId,
    required String targetType,
    required String targetTitle,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  // Requires a const constructor extension for the factory below.
  // const NotificationModel._();

  factory NotificationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return NotificationModel.fromJson({
      ...data,
      'id': doc.id,
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
    });
  }

  AppNotification toEntity() => AppNotification(
        id: id,
        type: _parseType(type),
        isRead: isRead,
        createdAt: createdAt,
        title: title,
        body: body,
        actorId: actorId,
        actorName: actorName,
        actorPhotoUrl: actorPhotoUrl,
        targetId: targetId,
        targetType: targetType,
        targetTitle: targetTitle,
      );
}

NotificationType _parseType(String raw) => NotificationType.values.firstWhere(
      (e) => e.name == _snakeToCamel(raw),
      orElse: () => NotificationType.postCommentAdded,
    );

// Maps 'post_comment_added' → 'postCommentAdded' for enum lookup.
String _snakeToCamel(String s) => s.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (m) => m.group(1)!.toUpperCase(),
    );
```

### Presentation — providers (signatures)

```dart
// lib/features/notifications/presentation/providers/notifications_provider.dart

@riverpod
Stream<List<AppNotification>> watchNotifications(Ref ref) {
  // Reads uid from authStateProvider; emits empty list when unauthenticated.
}

// lib/features/notifications/presentation/providers/unread_count_provider.dart

@riverpod
int unreadNotificationCount(Ref ref) {
  // Derived synchronously from watchNotificationsProvider.
  // Returns 0 on loading/error states.
}
```

### Core — FcmService (public interface)

```dart
// lib/core/firebase/fcm_service.dart

class FcmService {
  /// Call once from main.dart after auth resolves.
  /// No-op on web (kIsWeb guard).
  static Future<void> init(String uid) async { ... }

  /// Call on sign-out to remove the current device token.
  static Future<void> removeToken(String uid) async { ... }
}
```

### Cloud Functions — trigger signatures (TypeScript)

```typescript
// functions/src/triggers/onCommentAdded.ts
export const onCommentAdded = onDocumentCreated(
  'posts/{postId}/comments/{commentId}',
  async (event: FirestoreEvent<QueryDocumentSnapshot, { postId: string; commentId: string }>) => { ... }
);

// functions/src/triggers/onPostLiked.ts
export const onPostLiked = onDocumentCreated(
  'posts/{postId}/likes/{userId}',
  async (event: FirestoreEvent<QueryDocumentSnapshot, { postId: string; userId: string }>) => { ... }
);

// functions/src/triggers/onCommentReply.ts
// Same Firestore path as onCommentAdded; guard: event.data.data().parentId !== undefined
export const onCommentReply = onDocumentCreated(
  'posts/{postId}/comments/{commentId}',
  async (event: FirestoreEvent<QueryDocumentSnapshot, { postId: string; commentId: string }>) => { ... }
);

// functions/src/triggers/onRequestUpvoted.ts
export const onRequestUpvoted = onDocumentCreated(
  'requests/{requestId}/upvotes/{userId}',
  async (event: FirestoreEvent<QueryDocumentSnapshot, { requestId: string; userId: string }>) => { ... }
);

// functions/src/triggers/onSuggestionSubmitted.ts
export const onSuggestionSubmitted = onDocumentCreated(
  'requests/{requestId}/suggestions/{suggestionId}',
  async (event: FirestoreEvent<QueryDocumentSnapshot, { requestId: string; suggestionId: string }>) => { ... }
);

// functions/src/triggers/onRequestFulfilled.ts
// Trigger: onUpdate of requests/{requestId}
// Guard: before.status !== 'fulfilled' && after.status === 'fulfilled'
// Target recipient: after.suggestedByUserId (read from the winning suggestion document)
export const onRequestFulfilled = onDocumentUpdated(
  'requests/{requestId}',
  async (event: FirestoreEvent<Change<QueryDocumentSnapshot>, { requestId: string }>) => { ... }
);

// functions/src/triggers/purgeOldNotifications.ts
// Runs every 24 hours; deletes notification documents with createdAt < now - 30 days
// Uses collectionGroup('notifications') query + batched deletes
export const purgeOldNotifications = onSchedule(
  { schedule: 'every 24 hours', timeZone: 'UTC' },
  async (_event: ScheduledEvent) => { ... }
);
```

Implementation note for `onCommentAdded` vs `onCommentReply`: because both listen on the same Firestore path, they are exported as two separate Cloud Functions that both fire on every new comment document. Each function guards internally: `onCommentAdded` skips documents where `parentId` is present; `onCommentReply` skips documents where `parentId` is absent. This avoids deploying a single function that must handle two distinct notification targets.

Implementation note for `onRequestFulfilled`: the `suggestion_accepted` notification is sent to the user whose suggestion caused the fulfillment. The function reads `after.data().fulfilledByPostId`, queries `requests/{requestId}/suggestions` where `postId == fulfilledByPostId`, and sends to that suggester's UID.

---

## Deep-Link Navigation

| Notification `targetType` | `targetId`  | GoRouter destination        |
| ------------------------- | ----------- | --------------------------- |
| `"post"`                  | `postId`    | `/posts/:postId`            |
| `"request"`               | `requestId` | `/more/requests/:requestId` |

`NotificationItemTile` calls `context.push(destination)` on tap and then invokes `MarkNotificationRead` if `isRead` is false.

---

## Guest Mode Behaviour

When the user is not authenticated (`authStateProvider` emits `null`):

- `watchNotificationsProvider` emits an empty list immediately.
- `NotificationsScreen` renders a sign-in prompt widget (matching the pattern used by other gated features in the app) instead of the notification list.
- The bell icon in the shell app bar remains visible but shows no unread badge.

---

## Test Plan

| Test file                                                                                   | Type   | Covers                                                                                                                                                                                                                                                   |
| ------------------------------------------------------------------------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `test/unit/features/notifications/domain/usecases/watch_notifications_test.dart`            | unit   | `WatchNotifications.call` delegates to repository; emits stream values correctly                                                                                                                                                                         |
| `test/unit/features/notifications/domain/usecases/mark_notification_read_test.dart`         | unit   | `MarkNotificationRead.call` invokes `repository.markAsRead` with correct args                                                                                                                                                                            |
| `test/unit/features/notifications/domain/usecases/mark_all_notifications_read_test.dart`    | unit   | `MarkAllNotificationsRead.call` invokes `repository.markAllAsRead`                                                                                                                                                                                       |
| `test/unit/features/notifications/data/models/notification_model_test.dart`                 | unit   | `NotificationModel.fromJson` round-trips all fields; `toEntity` maps `NotificationType` correctly for all 6 enum values; `_parseType` handles unknown strings without throwing                                                                           |
| `test/unit/features/notifications/data/repositories/notification_repository_impl_test.dart` | unit   | `watchNotifications` maps Firestore snapshots to `AppNotification` list; `markAsRead` issues correct Firestore `update`; `markAllAsRead` uses batched writes; `registerFcmToken` writes correct document path; `removeFcmToken` deletes correct document |
| `test/widget/features/notifications/screens/notifications_screen_test.dart`                 | widget | Loading state shows spinner; populated state renders notification tiles; empty state renders empty copy; guest state renders sign-in prompt; "Mark all read" button triggers `MarkAllNotificationsRead`                                                  |
| `test/widget/features/notifications/widgets/notification_item_tile_test.dart`               | widget | Unread tile renders accent indicator; read tile has no indicator; tap on post notification navigates to `/posts/:postId`; tap on request notification navigates to `/more/requests/:requestId`; tile is accessible (semantic label present)              |

All tests use `mockito` or `mocktail` for repository mocks. Widget tests use `ProviderScope` with override providers. No live Firebase connections in unit or widget tests.

---

## Out of Scope

The following items are explicitly excluded from this spec. They may be addressed in future specs.

- **Web push (FCM VAPID):** The bell icon and Firestore stream work on web, but FCM push banners to the browser tab are not implemented. Web silently degrades.
- **Notification preferences / opt-out:** Users cannot disable specific notification types in v1. A preferences screen is a future feature.
- **Batch or digest notifications:** Each triggering event produces one notification document. No grouping, throttling, or digest roll-up is implemented.
- **Notification sounds and vibration patterns:** Default OS push presentation is used. No custom sound assets.
- **Rich push media (images in push payload):** Only title and body strings are sent in the FCM payload.
- **Android notification channels:** Default channel only in v1; custom channels for priority segmentation are deferred.
- **iOS notification categories / action buttons:** Deferred.
- **Analytics / impression tracking:** No notification-open event is logged to Firebase Analytics in v1.
- **Admin / moderation notifications:** No notifications for content flagging or moderation actions.
- **Email or SMS fallback:** Firebase-only delivery; no third-party email/SMS channel.
- **Read receipt sync across multiple devices:** `isRead` is per-document; marking read on one device does not propagate to other devices in v1.
- **Full rules file rewrite:** Only the delta blocks described in the rules section need to be added; the rest of `firestore.rules` is unchanged.

---

## Open Questions

- [ ] **`onCommentAdded` vs `onCommentReply` cold-start duplication:** Both functions are deployed on the same Firestore path and will each cold-start on every new comment. At current scale this is acceptable, but the team should decide before implementation whether to merge them into a single function with internal routing, accepting the added branching complexity in exchange for halved cold-starts.

- [ ] **`suggestion_accepted` recipient resolution:** The spec assumes `onRequestFulfilled` reads `fulfilledByPostId` from the updated request document, then queries the suggestions subcollection to find the matching suggester UID. This is one additional Firestore read per fulfillment event. Confirm this is acceptable, or alternatively store `fulfilledBySuggesterId` on the request document to avoid the extra read.

- [ ] **`firebase_messaging` version pin:** `^15.0.0` is specified. Confirm it is compatible with the current `firebase_core: ^4.7.0` and the FlutterFire BoM in use before adding to `pubspec.yaml`. Team approval required per CLAUDE.md before the dependency is added.

- [ ] **Emulator Suite setup:** Cloud Functions require the Firebase Emulator Suite for local development. Confirm whether `firebase.json` already includes an `emulators` config block, and document the local dev setup steps before implementation begins.

- [ ] **`purgeOldNotifications` permissions:** The scheduled function runs in a Cloud Scheduler context. Confirm the Firebase project's service account has the `datastore.documents.delete` IAM permission, or whether the Admin SDK's default service account is sufficient.
