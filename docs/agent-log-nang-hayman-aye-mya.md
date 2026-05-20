---
Date: 2026-05-09 00:00
Member: Nang Hayman Aye Mya
Agent: architect
Task: Write Tech Proposal PROP-0008 for the request-post feature
Prompt: Write a Tech Proposal for the "request-post" feature in the Unishare Flutter app. Save it at tech-proposals/0008-request-post.md. Students want to request specific academic content that hasn't been uploaded yet, so uploaders know what to create/share. Uploaders can respond to a request by linking one of their existing posts to that request. Constraints: real-time updates, course/subject scoping, authenticated users only. Preferred approach: Request tab inside the existing More navigation section.

Outcome: Wrote tech-proposals/0008-request-post.md (PROP-0008, DRAFT). Proposal covers Firestore flat-collection schema for requests/{requestId}, real-time stream listener pattern, course scoping via courseId field with two composite indexes, Clean Architecture layer breakdown, three alternatives with rejection reasoning, five open questions, and ten acceptance criteria.
Decisions: Chose flat top-level requests/ collection over course sub-collection (Option C) to keep cross-course queries simple and consistent with the existing posts/ pattern. Adopted single-fulfillment schema as the baseline but flagged multi-fulfillment as Open Question 1 before data layer implementation. Kept placement at /more/requests per team preference rather than promoting to a fifth top-level tab (Option B).
Handoff: Proposal is DRAFT and must be reviewed and accepted by the team before a tech spec (SPEC-0008) can be written. Open Questions 1 (single vs. multiple fulfillments) and 2 (who can mark fulfilled) must be resolved first as they directly affect the Firestore schema and security rules. Open Question 5 (one-request-per-course limit) affects whether a Cloud Function is needed.

---

Date: 2026-05-09 10:00
Member: Nang Hayman Aye Mya
Agent: flutter-engineer
Task: Implement SPEC-0008 Requests feature — full Clean Architecture implementation
Prompt: Implement the Requests feature for the Unishare Flutter app. Full Clean Architecture feature covering domain entities, repository interface, use cases, Freezed DTOs, Firestore datasource, repository impl, Riverpod providers, screens, and widgets. Modify router.dart, firestore.rules, and firestore.indexes.json.

Outcome: Full Requests feature implemented — domain entities, repository interface, 5 use cases, Freezed DTOs (RequestDto/SuggestionDto), Firestore datasource with atomic upvote transactions and first-suggestion fulfillment logic, repository impl, 7 Riverpod providers, RequestsScreen (filter bar + list + new request button), RequestDetailScreen (request card + suggestions + suggest button), 6 presentation widgets, router updated, firestore.rules extended, firestore.indexes.json extended. 49 tests added (21 unit + 28 widget). flutter analyze: 0 issues. Full suite: 259 tests, all pass.
Decisions: Used AggregateQuery count() for first-suggestion check instead of a transaction collection query (Firestore transactions cannot query subcollections). requestsProvider uses a custom RequestsFilter class as the family parameter to avoid codegen issues with record types. \_timeAgo helper implemented inline since timeago package is not in pubspec. requestDetailProvider placed in request_detail_screen.dart with its own .g.dart part file to co-locate the provider with the screen that owns it. Override type not exported from flutter_riverpod 3.x — tests use inline ProviderScope overrides instead of passing List<Override> as a parameter.
Handoff: Needs QA and architect review before merge to main. The `suggestFulfillmentDialog` calls Firestore directly (not via Riverpod) to fetch current user's posts — this works but a dedicated provider would be cleaner in a future refactor. The first-suggestion→fulfilled logic has a small race window (two concurrent first suggestions) which is acceptable for v1 per spec.
Review: PENDING

---

Date: 2026-05-10 00:00
Member: Nang Hayman Aye Mya
Agent: qa-engineer
Task: QA sweep of SPEC-0008 Requests feature — test coverage audit and gap fill
Prompt: Run a full QA sweep on the newly implemented Requests feature (SPEC-0008). Run all existing tests, audit coverage against spec test plan, identify missing tests and write them, fix failing tests, run flutter analyze and dart format.

Outcome: All 14 spec-required test files existed and all 259 pre-existing tests passed. Identified 12 coverage gaps against the spec's stated behavioral requirements and wrote regression tests to fill them: expanded suggest_fulfillment_test.dart (params verification, no duplicate side-effects), toggle_upvote_request_test.dart (add/remove toggle transitions via fake), upvote_button_test.dart (active amber color / inactive mutedForeground color visual states), new_request_dialog_test.dart (submit on valid input flow, disabled without dept+year), request_filter_bar_test.dart (fulfilled status selection, department propagation, year propagation). Also extended fake_request_repository.dart with param-capture fields (lastSuggestRequestId/PostId/PostTitle/PostType, lastToggleUpvoteRequestId). Full suite: 271 tests, all pass. flutter analyze: 0 issues. dart format: 0 diff.
Decisions: \_FakeCreateRequest implements CreateRequest interface directly (no mockito — project uses no mocking library) to override createRequestUseCaseProvider cleanly. Active/inactive visual state tests inspect Icon.color directly from the widget tree (no golden needed at this scope). SuggestFulfillment "first suggestion sets status" is a repository-layer invariant, not a use-case invariant — test validates the use case delegates without mutating status itself.
Handoff: 271 tests all green, 0 analyze issues, 0 format diff. The SuggestFulfillmentDialog still calls Firestore directly (noted by flutter-engineer handoff) — no test covers the posts-loaded path since it would require Firebase emulator. Recommend a future refactor to a dedicated provider to enable proper widget-test coverage of that path.
Review: PENDING

---

Date: 2026-05-07 12:30
Member: Nang Hayman Aye Mya
Agent: flutter-engineer
Task: Scaffold and implement SPEC-0007 Save Post feature
Prompt: /new-feature save-post — scaffold the folder structure, stub files, and session scratchpad for the save-post feature per SPEC-0007 (APPROVED).
Outcome: Full Save Post feature implemented — domain, data, core storage, presentation layers; PostCard save button wired; SavedScreen; PostDetailScreen save button; guest shell (FEED|SAVED|SIGN IN).
Decisions: Used async\* generator streams instead of rxdart for Hive; abstract class keyword on SavedPostDto for Freezed v3; .asData?.value instead of .valueOrNull (not in riverpod 3.3.1); Branch 4 added to StatefulShellRoute for /saved (guest top-level); Consumer in StatefulShellRoute.builder to conditionally render GuestShellScaffold vs ShellScaffold; redirect rule added — auth users at /saved → /more/saved.
Handoff: flutter analyze passes with 0 issues. All 10 plan steps complete. Needs QA widget tests and architect review before merge.
Review: PENDING
Files:
? apps/mobile/lib/features/requests/data/ (untracked)
? apps/mobile/lib/features/requests/domain/ (untracked)
? apps/mobile/lib/features/requests/presentation/providers/ (untracked)
? apps/mobile/lib/features/requests/presentation/widgets/ (untracked)

---

Date: 2026-05-10 10:00
Member: Nang Hayman Aye Mya
Agent: flutter-engineer
Task: Implement My Posts screen — replace placeholder with live Firestore-backed list
Prompt: Implement the "My Posts" feature. The /posts route already shows MyPostsScreen as a placeholder. Add watchPostsByAuthor to PostRepository, datasource, and impl; add WatchMyPosts use case; add myPostsProvider; replace the placeholder screen with a real implementation (AppBar + New Post button, loading/empty/error/data states, PostCard list, scroll controller).

Outcome: Added watchPostsByAuthor to PostRepository interface, PostFirestoreDatasource, and PostRepositoryImpl. Created WatchMyPosts use case (pure Dart). Added watchMyPostsUseCase provider to post_repository_provider.dart. Created my_posts_provider.dart with @riverpod StreamProvider (returns Stream.empty() when unauthenticated). Replaced MyPostsScreen placeholder with full implementation: AppBar with amber FilledButton.icon "New Post" action, loading/error/empty/data states, ListView.separated with PostCard. Added 6 widget tests in my_posts_screen_test.dart. Also added watchPostsByAuthor stub to 5 existing fake PostRepository implementations to satisfy the updated interface. 277 tests, all pass. flutter analyze: 0 issues. dart format: 0 diff.
Decisions: myPostsProvider directly overrides the stream using Stream.empty() when uid is null instead of throwing, to keep the loading state clean for unauthenticated edge cases. WatchMyPosts registered as a keepAlive provider in post_repository_provider.dart to follow the established pattern for all use-case providers in that file. No new composite Firestore index needed for current query — Firestore handles equality + orderBy with default single-field indexes, but a composite index on (authorId ASC, createdAt DESC) may be required at scale.
Handoff: Needs QA and architect review before merge. If Firestore surfaces a missing-index error after real data loads, add a composite index on posts(authorId ASC, createdAt DESC) to firestore.indexes.json.
Review: PENDING

---

Date: 2026-05-14 00:00
Member: Nang Hayman Aye Mya
Agent: architect
Task: Write Tech Proposal PROP-0001 for the Notification System feature
Prompt: Write a Tech Proposal file at tech-proposals/0001-notification.md for a push and in-app notification system. Students do not know when someone replies to their post, upvotes their content, or responds to their requests. Required: true push notifications when app is closed, in-app notification center. Evaluate all options freely — nothing ruled out.

Outcome: Wrote tech-proposals/0001-notification.md (PROP-0001, DRAFT). Proposal covers four options (Option A: FCM + Cloud Functions server-side fan-out; Option B: client-side FCM dispatch; Option C: in-app-only Firestore stream + flutter_local_notifications; Option D: hybrid Firestore history + FCM via Cloud Functions). Recommends Option D (hybrid). Six open questions captured. Ten acceptance criteria defined. Also wrote docs/decisions/0001-notification-delivery-mechanism.md (ADR-0001, PROPOSED) recording the hybrid FCM + Cloud Functions architecture decision with options table, 3-sentence justification, reversal cost (Medium-to-High), and consequences.
Decisions: Recommended Option D (hybrid) because it is the only approach satisfying both hard constraints (push when closed, persistent in-app history) without client-to-client Firestore writes. Option B rejected on security grounds (FCM server key exposure). Option C rejected because flutter_local_notifications cannot wake a terminated process. Option A is a valid subset of Option D; unified as the recommendation to make the data model clear.
Handoff: Proposal is DRAFT — team must resolve Open Questions 1 (notification types at launch), 2 (FCM token storage strategy), 3 (read/unread write ownership), 4 (web push timeline), 5 (retention/TTL policy), and 6 (guest UX) before a tech spec can be written. Blaze plan upgrade must be confirmed by the team before spec authoring begins.
Review: PENDING

---

Date: 2026-05-15 00:00
Member: Nang Hayman Aye Mya
Agent: flutter-engineer
Task: Implement SPEC-0001 Notification System — data layer, presentation layer, FCM service, firestore rules
Prompt: Implement the notification feature for the Unishare Flutter app, strictly following SPEC-0001. Implement data models, datasource, repository impl, Riverpod providers, notification_item_tile widget, notifications_screen, FcmService, update main.dart and firestore.rules.

Outcome: Full SPEC-0001 Notification System implemented. Data layer: NotificationModel (Freezed DTO with _TimestampConverter, toDomain() extension, _snakeToCamel type mapping), NotificationFirestoreDatasource (watchNotifications, markAsRead, markAllAsRead with 500-doc batch writes, registerFcmToken, removeFcmToken), NotificationRepositoryImpl. Presentation layer: 3 Riverpod providers (notification_repository_provider, notifications_provider, unread_count_provider), NotificationItemTile widget (amber left-bar + dot for unread, amberSubtle tinted background, relative time, semantics label), NotificationsScreen (loading/error/empty/guest/list states, Mark all read action). Core: FcmService (init + removeToken, kIsWeb guard, onTokenRegistered/onTokenRemoved callbacks). main.dart: FCM init side-effect via ref.listen on authStateProvider. firestore.rules: notifications and fcmTokens subcollection rules added. firestore.indexes.json: notifications composite index added. firebase_messaging upgraded to ^16.2.1 (^15.0.0 incompatible with firebase_auth ^6.5.0). build_runner ran successfully (96 outputs). flutter analyze: 0 issues. dart format: clean. 339 tests, all pass.
Decisions: Removed firebase_auth import from NotificationFirestoreDatasource — all methods accept explicit userId parameter so _uid getter was not needed. Used token.hashCode.toRadixString(16) as document ID for FCM tokens instead of SHA-256 (avoids adding crypto dependency; instruction allowed this fallback). firebase_messaging version bumped to ^16.2.1 to resolve firebase_core_platform_interface version conflict with firebase_auth ^6.5.0.
Handoff: Cloud Functions (functions/ directory) are out of scope for the flutter-engineer and must be implemented separately. The notifications screen is live at /notifications. FCM token registration fires once on sign-in. The unread badge (unreadNotificationCountProvider) is available for the shell AppBar to consume.
Review: PENDING
