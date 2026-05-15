---
Date: 2026-05-04 00:00
Member: Sudakarn
Agent: architect
Task: Write tech proposal PROP-0005 for feed filtering by tags
Prompt: Write the tech proposal file `tech-proposals/0005-feed-filtering-tags.md` covering discovery overload problem, options for Firestore-native tag filtering, and recommendation. Status DRAFT, author Sudakarn, date 2026-05-05.
Outcome: Wrote tech-proposals/0005-feed-filtering-tags.md (DRAFT) and companion ADR docs/decisions/0001-feed-filtering-via-array-contains-any.md (PROPOSED).
Decisions: Recommended Option A (array-contains-any on existing tags field) over fan-out sub-collections (Option B, high write cost) and flat primaryTag field (Option C, requires migration). Chose this because it is the only approach satisfying all three hard constraints simultaneously: no migration, free tier, offline support.
Handoff: Proposal is DRAFT — product owner and CTO must review and approve before the flutter-engineer begins the tech spec. Open questions on tag taxonomy ownership, filter persistence scope, empty-result UX contract, and tag count ceiling must be resolved first.
Review: PENDING

---
Date: 2026-05-04 00:00
Member: Sudakarn
Agent: architect
Task: Write tech spec SPEC-0005 for feed filtering by tags
Prompt: Write the tech spec at tech-specs/0005-feed-filtering-tags.md. Approved proposal PROP-0005 chosen Option A (array-contains-any). Open questions resolved: curated reference collection for tag enumeration, users/{uid}/preferences for persistence, empty state widget with no silent fallback, cross-device sync via Firestore read on login.
Outcome: Wrote tech-specs/0005-feed-filtering-tags.md (DRAFT). Spec covers full Clean Architecture layer breakdown, Mermaid flowchart, file map (22 files — Create/Modify across all three layers), complete Dart API contracts for all domain entities/interfaces/use cases/providers, Firestore schema for posts/preferences/courses, composite index JSON, Hive cache-key strategy, six-row test plan, out-of-scope list, and two blocking open questions.
Decisions: Modeled users/{uid}/preferences as a named Firestore document (not a field on the user doc) to isolate preference reads/writes to a single addressable path; kept collection name as courses/{courseId} placeholder pending seed-script confirmation; derived Hive cache key from sorted tag list hash to prevent filter-variant cache collisions; getPostFeed cursor typed as Object? to prevent cloud_firestore from leaking into the domain layer.
Handoff: Two open questions block APPROVED status — (1) confirm the curated tag collection name against tools/seed_firestore.js, (2) decide users/{uid}/preferences as sub-document vs top-level fields and audit existing Security Rules. Flutter-engineer must not begin TagRepositoryImpl until both are resolved. No new dependencies introduced — this spec requires no pubspec.yaml additions.
Review: PENDING

2026-05-05
  [00:28] Write: apps/mobile/lib/features/post_feed/domain/entities/post_filter_preferences.dart
  [00:28] Write: apps/mobile/lib/features/post_feed/domain/entities/tag_entity.dart
  [00:28] Write: apps/mobile/lib/features/post_feed/domain/repositories/tag_repository.dart
  [00:28] Write: apps/mobile/lib/features/post_feed/domain/repositories/preferences_repository.dart
  [00:28] Write: apps/mobile/lib/features/post_feed/domain/usecases/get_tag_list.dart
  [00:28] Write: apps/mobile/lib/features/post_feed/domain/usecases/save_filter_preferences.dart
  [00:28] Write: apps/mobile/lib/features/post_feed/domain/usecases/get_filter_preferences.dart
  [00:28] Write: apps/mobile/lib/features/post_feed/data/datasources/tag_firestore_datasource.dart
  [00:28] Write: apps/mobile/lib/features/post_feed/data/datasources/preferences_firestore_datasource.dart
  [00:28] Write: apps/mobile/lib/features/post_feed/data/models/tag_model.dart
  [00:28] Write: apps/mobile/lib/features/post_feed/data/models/post_filter_preferences_model.dart
  [00:28] Write: apps/mobile/lib/features/post_feed/data/repositories/tag_repository_impl.dart
  [00:28] Write: apps/mobile/lib/features/post_feed/data/repositories/preferences_repository_impl.dart
  [00:28] Write: apps/mobile/lib/features/post_feed/presentation/providers/tag_list_provider.dart
  [00:28] Write: apps/mobile/lib/features/post_feed/presentation/providers/filter_preferences_provider.dart
  [00:28] Write: apps/mobile/lib/features/post_feed/presentation/providers/feed_provider.dart
  [00:28] Write: apps/mobile/lib/features/post_feed/presentation/screens/feed_screen.dart
  [00:28] Write: apps/mobile/lib/features/post_feed/presentation/widgets/filter_picker_widget.dart
  [00:28] Write: apps/mobile/lib/features/post_feed/presentation/widgets/feed_empty_state_widget.dart
Files:
  ? apps/mobile/lib/features/post_feed/data/datasources/preferences_firestore_datasource.dart (untracked)
  ? apps/mobile/lib/features/post_feed/data/datasources/tag_firestore_datasource.dart (untracked)
  ? apps/mobile/lib/features/post_feed/data/models/post_filter_preferences_model.dart (untracked)
  ? apps/mobile/lib/features/post_feed/data/models/tag_model.dart (untracked)
  ? apps/mobile/lib/features/post_feed/data/repositories/preferences_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/post_feed/data/repositories/tag_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/post_feed/domain/entities/post_filter_preferences.dart (untracked)
  ? apps/mobile/lib/features/post_feed/domain/entities/tag_entity.dart (untracked)
  ? apps/mobile/lib/features/post_feed/domain/repositories/preferences_repository.dart (untracked)
  ? apps/mobile/lib/features/post_feed/domain/repositories/tag_repository.dart (untracked)
  ? apps/mobile/lib/features/post_feed/domain/usecases/get_filter_preferences.dart (untracked)
  ? apps/mobile/lib/features/post_feed/domain/usecases/get_tag_list.dart (untracked)
  ? apps/mobile/lib/features/post_feed/domain/usecases/save_filter_preferences.dart (untracked)
  ? apps/mobile/lib/features/post_feed/presentation/providers/feed_provider.dart (untracked)
  ? apps/mobile/lib/features/post_feed/presentation/providers/filter_preferences_provider.dart (untracked)
  ? apps/mobile/lib/features/post_feed/presentation/providers/tag_list_provider.dart (untracked)
  ? apps/mobile/lib/features/post_feed/presentation/screens/feed_screen.dart (untracked)
  ? apps/mobile/lib/features/post_feed/presentation/widgets/feed_empty_state_widget.dart (untracked)
  ? apps/mobile/lib/features/post_feed/presentation/widgets/filter_picker_widget.dart (untracked)

---
Date: 2026-05-04 10:00
Member: Sudakarn
Agent: flutter-engineer
Task: Implement FeedScreen with mock post list, PostCardWidget, and wire router to FeedScreen
Prompt: Implement the Feed screen for the Unishare Flutter app based on Figma design. Create feed_screen.dart (ConsumerStatefulWidget with NestedScrollView, sticky tab row, 3-tab TabController + Filters button, BottomNavigationBar with 4 items, mock post list), post_card_widget.dart (extracted card widget), and modify router.dart to replace _HomeScreen placeholder with the real FeedScreen.
  [00:41] Write: apps/mobile/lib/features/post_feed/presentation/widgets/post_card_widget.dart
  [00:41] Write: apps/mobile/lib/features/post_feed/presentation/screens/feed_screen.dart
  [00:42] Edit: apps/mobile/lib/core/router/router.dart
  [00:42] Edit: apps/mobile/lib/core/router/router.dart
  [00:42] Edit: apps/mobile/lib/features/post_feed/presentation/screens/feed_screen.dart
  [00:42] Edit: apps/mobile/lib/features/post_feed/presentation/screens/feed_screen.dart
  [00:43] Edit: apps/mobile/lib/features/post_feed/presentation/screens/feed_screen.dart
  [00:43] Edit: apps/mobile/lib/features/post_feed/presentation/widgets/post_card_widget.dart
  [00:43] Edit: apps/mobile/lib/features/post_feed/presentation/widgets/post_card_widget.dart
  [00:45] Write: apps/mobile/test/widget/feed/feed_screen_test.dart
Outcome: Created post_card_widget.dart (MockPost model + PostCardWidget + sub-widgets _TypeBadge, _CourseCodeChip, _TagChip), rewrote feed_screen.dart (ConsumerStatefulWidget with NestedScrollView sticky header, TabController for ALL/NOTES/ASSIGNMENTS, Filters TextButton, BottomNavigationBar with 4 items, academic profile dialog trigger moved from _HomeScreen), modified router.dart (replaced _HomeScreen with FeedScreen at / route, kept academic_profile_dialog import for the dialog call in FeedScreen, renamed _academicProfileSessionDismissed to academicProfileSessionDismissed so FeedScreen can access it via show import). Created test/widget/feed/feed_screen_test.dart with 15 tests covering FeedScreen and PostCardWidget.
Decisions: Moved academic profile dialog trigger from the old _HomeScreen into FeedScreen.initState via a postFrameCallback — kept the session dismissal flag in router.dart as a package-level variable (renamed non-private) and imported it into feed_screen.dart using a targeted show import to avoid circular dependency. Used NestedScrollView + SliverPersistentHeader for the sticky tab row rather than a plain Column to avoid unbounded-height layout violations. Tab filtering driven by AnimatedBuilder on TabController so switching tabs rebuilds only the list body without rebuilding the entire scaffold.
Handoff: Tests structurally correct but cannot execute until build_runner is run to generate *.g.dart and *.freezed.dart files. No new pub dependencies added. The Filters button and BottomNavigationBar secondary tabs are wired for state only (no navigation), ready for real routing in a follow-up.
Review: PENDING

---
Date: 2026-05-06 10:44
Member: Sudakarn
Agent: flutter-engineer
Task: Implement feed UI to match Figma designs — guest mode, comment count text, FilterPickerWidget, FeedEmptyStateWidget
Prompt: User shared Figma screenshots showing feed in three states (logged-in departments, logged-in general, guest). Requested implementation to match the design.

Outcome: Implemented all feed UI to match Figma designs. (1) Fixed PostCardWidget comment count to show "1 comment" / "N comments" text. (2) Added guest mode differentiation in FeedScreen — guests see FEED|SAVED|SIGN IN bottom nav and no "+" create button. (3) Implemented FilterPickerWidget as a DraggableScrollableSheet with checkboxes, Confirm/Clear actions, and a badge count on the Filters button. (4) Implemented FeedEmptyStateWidget with icon, message, and "Clear filter" button. (5) Wired the Filters button to open the picker and applied tag filtering to the visible posts list.
Decisions: Used local mock state (_activeTagFilters list on FeedScreen) for tag filtering instead of wiring the unimplemented Firestore providers — the spec's data layer is still in draft/stub status. FilterPickerWidget accepts availableTags/selectedTags params and an onConfirm callback so it is easy to swap in real providers later. Guest mode detection checks both authStateProvider (for authenticated users) and guestModeProvider (for explicit guest browsing) so the loading state defaults to the logged-in nav.
Handoff: All 23 widget tests pass. The FilterPickerWidget, FeedEmptyStateWidget, and guest bottom nav are complete. Next step: wire FeedNotifier and FilterPreferencesNotifier to real Firestore (once the curated tags collection name is confirmed from the seed script — open question in SPEC-0005). Pre-existing unused-import analyzer warnings in the stub providers are unaffected.
Review: PENDING
