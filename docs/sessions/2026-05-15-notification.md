# Session: 2026-05-15-notification

**Date:** 2026-05-15
**Member:** Nang Hayman Aye Mya
**Agent:** flutter-engineer
**Task:** Implement the notification feature (SPEC-0001)

## Context

PROP-0001 approved. SPEC-0001 approved. Folder structure and domain stubs scaffolded by /new-feature.

Chosen approach (Option D): Cloud Functions fan out FCM push and write canonical
`users/{uid}/notifications/{notifId}` documents. Flutter client reads via StreamProvider;
client never creates notification documents. Read/unread toggled by direct client write
(restricted to `isRead` field only via security rule).

Relevant docs:
- Proposal: `tech-proposals/0001-notification.md`
- Spec: `tech-specs/0001-notification.md`
- ADR: `docs/decisions/0001-notification-delivery-mechanism.md`

## Plan

1. Add `firebase_messaging: ^15.0.0` to `pubspec.yaml` after team sign-off; run `flutter pub get`.
2. Implement `NotificationModel` (Freezed + `fromFirestore` + `toEntity`) in `data/models/`; run `build_runner`.
3. Implement `NotificationFirestoreDatasource` — Firestore stream, `markAsRead`, `markAllAsRead`, token CRUD.
4. Implement `NotificationRepositoryImpl` — delegates to datasource.
5. Wire `notification_repository_provider.dart`.
6. Implement `watchNotificationsProvider` and `unreadCountProvider` (code gen).
7. Implement `FcmService` (token registration, foreground handler, web guard); hook into `main.dart`.
8. Implement `NotificationItemTile` widget (unread indicator, deep-link tap, accessibility label).
9. Replace `NotificationsScreen` "Coming soon" scaffold with real list + loading/empty/error/guest states.
10. Add `notifications` and `fcmTokens` security rule blocks to `firestore.rules`; deploy.
11. Scaffold `functions/` directory (TypeScript): `package.json`, `tsconfig.json`, `src/index.ts`, shared helpers, 7 trigger files.
12. Add composite index to `firestore.indexes.json`; deploy indexes.
13. Write tests per SPEC-0001 test plan (7 test files).
14. Run `flutter analyze` and `dart format .` — must be clean before PR.

## Notes

Domain entities (`notification_item.dart`) and use case stubs are already filled in from the spec
— they are NOT TODO stubs, they are the real implementations (pure Dart, no framework imports).

Open questions to resolve before PR:
- [ ] `onCommentAdded` vs `onCommentReply` — merge into one function or keep separate?
- [ ] `suggestion_accepted` recipient resolution — extra Firestore read vs. denormalize `fulfilledBySuggesterId`?
- [ ] `firebase_messaging` version pin compatible with current `firebase_core` BoM?
- [ ] Firebase Emulator Suite config in `firebase.json`?
- [ ] `purgeOldNotifications` service account IAM permissions?

## Handoff

**To:** qa-engineer (review) / architect (PR review)
**Done:** (fill in when session ends)
**Not done:** (fill in when session ends)
**Watch out for:**
- `notification_item.dart` and use case files are already fully implemented from the spec contracts — do not regenerate them as stubs.
- `notifications_screen.dart` already exists and must be replaced (not created fresh).
- `lib/core/firebase/fcm_service.dart` must guard all FCM calls with `kIsWeb` — web build must not import `firebase_messaging` native platform channel.
- Cloud Function `onCommentAdded` and `onCommentReply` both trigger on `posts/{postId}/comments/{commentId}` — each must guard on `parentId` presence to avoid duplicate notifications.
- `suggestion_accepted` trigger fires on `requests/{requestId}` onUpdate (status → 'fulfilled'), NOT on the suggestions subcollection.
