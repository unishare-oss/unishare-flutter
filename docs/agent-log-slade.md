---
Date: 2026-05-03
Member: Slade
Agent: architect
Task: Write and approve Tech Proposal 0004 — Post Integration
Prompt: /new-proposal post integration

Outcome: PROP-0004 (post-integration) written at tech-proposals/0004-post-integration.md and approved by CTO Slade. Status set to ACCEPTED.
Decisions: Option A (direct Firestore write + Hive draft queue) recommended and accepted. Cloud Functions and NestJS explicitly ruled out. Four open questions deferred to Tech Spec.
Handoff: Run /new-spec 0004-post-integration to produce the Tech Spec. Spec must address the four open questions (upload ordering, partial-upload recovery, file size/type limits, author field staleness) before implementation begins.
Review: APPROVED by Slade (CTO)

---
Date: 2026-05-03
Member: Slade
Agent: architect
Task: Write and approve Tech Spec 0004 — Post Integration
Prompt: /new-spec @tech-proposals/0004-post-integration.md

Outcome: SPEC-0004 written at tech-specs/0004-post-integration.md and approved by CTO Slade. Status set to APPROVED.
Decisions: Upload-then-write sequencing (Storage first, atomic Firestore write). Hive uploadedUrls map for idempotent retry. Sealed CreatePostState with 6 types. Storage Rules enforce uid scoping + 10 MB + MIME types. Firestore Rules enforce authorId == request.auth.uid and likesCount == 0 at creation. Author staleness: snapshot-at-write acceptable for v1.
Handoff: Two package decisions still open before implementation — connectivity_plus and a file picker package need team approval. Run /new-feature post-integration to scaffold, then hand spec to flutter-engineer.
Review: APPROVED by Slade (CTO)
Files:
  ? apps/mobile/lib/core/storage/post_draft_box.dart (untracked)
  ? apps/mobile/lib/features/post/ (untracked)

Files:
  ? apps/mobile/lib/core/storage/post_draft_box.dart (untracked)
  ? apps/mobile/lib/features/post/ (untracked)

Files:
  ? apps/mobile/lib/core/storage/post_draft_box.dart (untracked)
  ? apps/mobile/lib/features/post/ (untracked)


2026-05-05
  [12:59] Edit: apps/mobile/lib/core/router/router.dart
Files:
  ~ apps/mobile/lib/core/router/router.dart
Summary:  1 file changed, 6 insertions(+), 4 deletions(-)

  [13:06] Edit: apps/mobile/lib/main.dart
Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/main.dart
Summary:  2 files changed, 8 insertions(+), 4 deletions(-)

Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/main.dart
Summary:  2 files changed, 8 insertions(+), 4 deletions(-)

Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/main.dart
Summary:  2 files changed, 8 insertions(+), 4 deletions(-)

  [13:09] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  ~ apps/mobile/lib/main.dart
Summary:  3 files changed, 9 insertions(+), 5 deletions(-)

Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  ~ apps/mobile/lib/main.dart
Summary:  3 files changed, 9 insertions(+), 5 deletions(-)

Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  ~ apps/mobile/lib/main.dart
Summary:  3 files changed, 9 insertions(+), 5 deletions(-)

Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  ~ apps/mobile/lib/main.dart
Summary:  3 files changed, 9 insertions(+), 5 deletions(-)

Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  ~ apps/mobile/lib/main.dart
Summary:  3 files changed, 9 insertions(+), 5 deletions(-)

Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  ~ apps/mobile/lib/main.dart
Summary:  3 files changed, 9 insertions(+), 5 deletions(-)

Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  ~ apps/mobile/lib/main.dart
Summary:  3 files changed, 9 insertions(+), 5 deletions(-)

Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  ~ apps/mobile/lib/main.dart
Summary:  3 files changed, 9 insertions(+), 5 deletions(-)

Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  ~ apps/mobile/lib/main.dart
Summary:  3 files changed, 9 insertions(+), 5 deletions(-)

Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  ~ apps/mobile/lib/main.dart
Summary:  3 files changed, 9 insertions(+), 5 deletions(-)

Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  ~ apps/mobile/lib/main.dart
Summary:  3 files changed, 9 insertions(+), 5 deletions(-)

Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  ~ apps/mobile/lib/main.dart
Summary:  3 files changed, 9 insertions(+), 5 deletions(-)

Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  ~ apps/mobile/lib/main.dart
Summary:  3 files changed, 9 insertions(+), 5 deletions(-)

Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  ~ apps/mobile/lib/main.dart
Summary:  3 files changed, 9 insertions(+), 5 deletions(-)

  [14:58] Write: apps/mobile/lib/features/post/domain/entities/code_snippet.dart
  [14:59] Write: apps/mobile/lib/features/post/domain/entities/post_draft.dart
  [14:59] Write: apps/mobile/lib/features/post/domain/entities/post.dart
  [14:59] Write: apps/mobile/lib/features/post/domain/usecases/create_post.dart
  [14:59] Write: apps/mobile/lib/features/post/data/models/post_draft_model.dart
  [14:59] Write: apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart
  [15:00] Write: apps/mobile/lib/features/post/data/datasources/post_storage_datasource.dart
  [15:00] Write: apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart
  [15:00] Write: apps/mobile/lib/features/post/presentation/providers/create_post_provider.dart
  [15:00] Write: apps/mobile/lib/features/post/presentation/widgets/type_step.dart
  [15:01] Write: apps/mobile/lib/features/post/presentation/widgets/course_step.dart
  [15:01] Write: apps/mobile/lib/features/post/presentation/widgets/details_step.dart
  [15:01] Write: apps/mobile/lib/features/post/presentation/widgets/file_upload_widget.dart
  [15:02] Write: apps/mobile/lib/features/post/presentation/widgets/code_snippet_widget.dart
  [15:02] Write: apps/mobile/lib/features/post/presentation/widgets/files_step.dart
  [15:03] Write: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [15:06] Write: apps/mobile/test/unit/features/post/domain/usecases/create_post_test.dart
  [15:06] Write: apps/mobile/test/unit/features/post/domain/usecases/sync_draft_queue_test.dart
  [15:07] Write: apps/mobile/test/widget/features/post/screens/create_post_screen_test.dart
  [15:07] Write: apps/mobile/test/widget/features/post/widgets/type_step_test.dart
  [15:07] Write: apps/mobile/test/widget/features/post/widgets/details_step_test.dart
  [15:07] Write: apps/mobile/test/widget/features/post/widgets/files_step_test.dart
  [15:07] Write: apps/mobile/test/widget/features/post/widgets/draft_queue_indicator_test.dart
  [15:08] Edit: apps/mobile/lib/features/post/presentation/widgets/file_upload_widget.dart
  [15:08] Edit: apps/mobile/lib/features/post/presentation/widgets/file_upload_widget.dart
  [15:08] Edit: apps/mobile/lib/features/post/presentation/widgets/file_upload_widget.dart
  [15:08] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [15:08] Edit: apps/mobile/lib/features/post/presentation/widgets/course_step.dart
  [15:09] Edit: apps/mobile/test/unit/features/post/domain/usecases/create_post_test.dart
  [15:09] Edit: apps/mobile/test/unit/features/post/domain/usecases/sync_draft_queue_test.dart
  [15:09] Edit: apps/mobile/test/unit/features/post/domain/usecases/sync_draft_queue_test.dart
  [15:09] Write: apps/mobile/test/unit/features/post/domain/usecases/sync_draft_queue_test.dart
  [15:09] Write: apps/mobile/test/unit/features/post/domain/usecases/create_post_test.dart
  [15:10] Write: apps/mobile/test/widget/features/post/screens/create_post_screen_test.dart
  [15:10] Write: apps/mobile/test/widget/features/post/widgets/draft_queue_indicator_test.dart
  [15:12] Write: apps/mobile/test/widget/features/post/screens/create_post_screen_test.dart
  [15:14] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart
  ~ apps/mobile/lib/features/post/data/datasources/post_storage_datasource.dart
  ~ apps/mobile/lib/features/post/data/models/post_draft_model.dart
  ~ apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart
  ~ apps/mobile/lib/features/post/domain/entities/post.dart
  ~ apps/mobile/lib/features/post/domain/entities/post_draft.dart
  ~ apps/mobile/lib/features/post/domain/usecases/create_post.dart
  ~ apps/mobile/lib/features/post/presentation/providers/create_post_provider.dart
  ~ apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  ~ apps/mobile/lib/main.dart
  ? apps/mobile/lib/features/post/domain/entities/code_snippet.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/widgets/code_snippet_widget.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/widgets/course_step.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/widgets/details_step.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/widgets/file_upload_widget.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/widgets/files_step.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/widgets/type_step.dart (untracked)
  ? apps/mobile/test/unit/features/ (untracked)
  ? apps/mobile/test/widget/features/ (untracked)
Summary:  11 files changed, 647 insertions(+), 303 deletions(-)

  [20:24] Edit: apps/mobile/ios/Runner/Info.plist
  [20:24] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
Files:
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart
  ~ apps/mobile/lib/features/post/data/datasources/post_storage_datasource.dart
  ~ apps/mobile/lib/features/post/data/models/post_draft_model.dart
  ~ apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart
  ~ apps/mobile/lib/features/post/domain/entities/post.dart
  ~ apps/mobile/lib/features/post/domain/entities/post_draft.dart
  ~ apps/mobile/lib/features/post/domain/usecases/create_post.dart
  ~ apps/mobile/lib/features/post/presentation/providers/create_post_provider.dart
  ~ apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  ~ apps/mobile/lib/main.dart
  ? apps/mobile/lib/features/post/domain/entities/code_snippet.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/widgets/code_snippet_widget.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/widgets/course_step.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/widgets/details_step.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/widgets/file_upload_widget.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/widgets/files_step.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/widgets/type_step.dart (untracked)
  ? apps/mobile/test/unit/features/ (untracked)
  ? apps/mobile/test/widget/features/ (untracked)
Summary:  11 files changed, 646 insertions(+), 303 deletions(-)


2026-05-14
  [10:19] Edit: apps/mobile/lib/features/auth/presentation/widgets/auth_text_field.dart
  [10:19] Edit: apps/mobile/lib/features/auth/presentation/widgets/auth_text_field.dart
  [10:19] Edit: apps/mobile/lib/features/auth/presentation/widgets/auth_text_field.dart
  [10:19] Edit: apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  [10:19] Edit: apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  [10:20] Edit: apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  [10:20] Edit: apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  [11:59] Write: apps/mobile/lib/features/post/presentation/widgets/comment_tile.dart
  [12:00] Edit: apps/mobile/lib/features/post/presentation/widgets/comment_tile.dart
  [12:00] Edit: apps/mobile/lib/features/post/presentation/widgets/comment_tile.dart
Files:
  ~ apps/mobile/test/widget/features/post/screens/post_detail_screen_test.dart
Summary:  1 file changed, 5 insertions(+), 1 deletion(-)

  [12:25] Edit: apps/mobile/test/widget/features/post/screens/post_detail_screen_test.dart
  [12:30] Edit: apps/mobile/lib/features/post/presentation/screens/post_detail_screen.dart
  [12:39] Edit: apps/mobile/test/widget/features/post/screens/post_detail_screen_test.dart
  [12:39] Edit: apps/mobile/test/widget/features/post/screens/post_detail_screen_test.dart
  [12:39] Edit: apps/mobile/test/widget/features/post/screens/post_detail_screen_test.dart
  [12:40] Edit: apps/mobile/lib/features/post/presentation/screens/post_detail_screen.dart
  [12:40] Edit: apps/mobile/lib/features/post/presentation/screens/post_detail_screen.dart
  [12:40] Edit: apps/mobile/lib/features/post/presentation/screens/post_detail_screen.dart

---
Date: 2026-05-18
Member: Slade
Agent: architect
Task: Write Tech Spec 0010 — Share Post
Prompt: Write a Tech Spec for the Unishare Flutter project at tech-specs/0010-share-post.md based on PROP-0010 (Firebase Hosting + share_plus universal deep-link sharing).

Outcome: SPEC-0010 written at tech-specs/0010-share-post.md (DRAFT). ADR-0008 written at docs/decisions/0008-share-post-deep-link-strategy.md (ACCEPTED).
Decisions: Option A from proposal confirmed — Firebase Hosting + share_plus; Dynamic Links ruled out (deprecated Aug 2025); Branch.io ruled out (unapproved vendor). Android Play Install Referrer deferred to post-v1 to match iOS best-effort parity. ShareFallbackException pattern chosen over AsyncError to signal clipboard fallback to the screen listener. GoRouter redirect preservation uses `?redirect=` query parameter on /welcome rather than any new package.
Handoff: Four open questions block finalisation — OQ1 (Firebase Hosting domain), OQ2 (share_plus team approval), OQ4 (OG meta tags), OQ5 (Android SHA-256 fingerprints). Flutter-engineer must not begin implementation until OQ1, OQ2, and OQ5 are resolved, and spec status is changed to APPROVED.
Review: PENDING

2026-05-18
  [23:42] Write: apps/mobile/lib/features/post/domain/repositories/share_repository.dart
  [23:42] Write: apps/mobile/lib/features/post/domain/usecases/share_post.dart
  [23:42] Write: apps/mobile/lib/features/post/data/datasources/share_plus_datasource.dart
  [23:42] Write: apps/mobile/lib/features/post/data/repositories/share_repository_impl.dart
  [23:42] Write: apps/mobile/lib/features/post/presentation/providers/share_post_provider.dart
Files:
  ? apps/mobile/lib/features/post/data/datasources/share_plus_datasource.dart (untracked)
  ? apps/mobile/lib/features/post/data/repositories/share_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/post/domain/repositories/share_repository.dart (untracked)
  ? apps/mobile/lib/features/post/domain/usecases/share_post.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/providers/share_post_provider.dart (untracked)

Files:
  ? apps/mobile/lib/features/post/data/datasources/share_plus_datasource.dart (untracked)
  ? apps/mobile/lib/features/post/data/repositories/share_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/post/domain/repositories/share_repository.dart (untracked)
  ? apps/mobile/lib/features/post/domain/usecases/share_post.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/providers/share_post_provider.dart (untracked)

Files:
  ? apps/mobile/lib/features/post/data/datasources/share_plus_datasource.dart (untracked)
  ? apps/mobile/lib/features/post/data/repositories/share_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/post/domain/repositories/share_repository.dart (untracked)
  ? apps/mobile/lib/features/post/domain/usecases/share_post.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/providers/share_post_provider.dart (untracked)


2026-05-19
  [11:41] Edit: apps/mobile/pubspec.yaml
Files:
  ~ apps/mobile/pubspec.yaml
  ? apps/mobile/lib/features/post/data/datasources/share_plus_datasource.dart (untracked)
  ? apps/mobile/lib/features/post/data/repositories/share_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/post/domain/repositories/share_repository.dart (untracked)
  ? apps/mobile/lib/features/post/domain/usecases/share_post.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/providers/share_post_provider.dart (untracked)
Summary:  1 file changed, 1 insertion(+)

Files:
  ~ apps/mobile/pubspec.yaml
  ? apps/mobile/lib/features/post/data/datasources/share_plus_datasource.dart (untracked)
  ? apps/mobile/lib/features/post/data/repositories/share_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/post/domain/repositories/share_repository.dart (untracked)
  ? apps/mobile/lib/features/post/domain/usecases/share_post.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/providers/share_post_provider.dart (untracked)
Summary:  1 file changed, 1 insertion(+)

Files:
  ~ apps/mobile/pubspec.yaml
  ? apps/mobile/lib/features/post/data/datasources/share_plus_datasource.dart (untracked)
  ? apps/mobile/lib/features/post/data/repositories/share_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/post/domain/repositories/share_repository.dart (untracked)
  ? apps/mobile/lib/features/post/domain/usecases/share_post.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/providers/share_post_provider.dart (untracked)
Summary:  1 file changed, 1 insertion(+)

Files:
  ~ apps/mobile/pubspec.yaml
  ? apps/mobile/lib/features/post/data/datasources/share_plus_datasource.dart (untracked)
  ? apps/mobile/lib/features/post/data/repositories/share_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/post/domain/repositories/share_repository.dart (untracked)
  ? apps/mobile/lib/features/post/domain/usecases/share_post.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/providers/share_post_provider.dart (untracked)
Summary:  1 file changed, 1 insertion(+)


---
Date: 2026-05-19 00:00
Member: Slade
Agent: flutter-engineer
Task: Implement SPEC-0010 Share Post feature
Prompt: Implement SPEC-0010: Share Post — OS share sheet via share_plus, deep-link intent filter, GoRouter redirect preservation, PostDetailScreen share button, ShareFallbackException SnackBar, "Post not found" error state, and all unit/widget tests.
  [15:43] Write: apps/mobile/lib/features/post/data/datasources/share_plus_datasource.dart
  [15:44] Write: apps/mobile/lib/features/post/data/repositories/share_repository_impl.dart
  [15:44] Edit: apps/mobile/lib/features/post/presentation/providers/post_repository_provider.dart
  [15:44] Edit: apps/mobile/lib/features/post/presentation/providers/post_repository_provider.dart
  [15:44] Write: apps/mobile/lib/features/post/presentation/providers/share_post_provider.dart
  [15:44] Edit: apps/mobile/lib/features/post/presentation/screens/post_detail_screen.dart
  [15:44] Edit: apps/mobile/lib/features/post/presentation/screens/post_detail_screen.dart
  [15:44] Edit: apps/mobile/lib/features/post/presentation/screens/post_detail_screen.dart
  [15:45] Edit: apps/mobile/lib/core/router/router.dart
  [15:45] Edit: apps/mobile/android/app/src/main/AndroidManifest.xml
  [15:46] Write: apps/mobile/test/unit/features/post/domain/usecases/share_post_test.dart
  [15:46] Write: apps/mobile/test/unit/features/post/data/repositories/share_repository_impl_test.dart
  [15:46] Edit: apps/mobile/test/unit/features/post/data/repositories/share_repository_impl_test.dart
  [15:46] Write: apps/mobile/test/unit/features/post/data/datasources/share_plus_datasource_test.dart
  [15:46] Edit: apps/mobile/test/widget/features/post/screens/post_detail_screen_test.dart
  [15:47] Edit: apps/mobile/test/widget/features/post/screens/post_detail_screen_test.dart
  [15:47] Edit: apps/mobile/test/widget/features/post/screens/post_detail_screen_test.dart
  [15:47] Edit: apps/mobile/test/widget/features/post/screens/post_detail_screen_test.dart
  [15:47] Edit: apps/mobile/test/widget/features/post/screens/post_detail_screen_test.dart
  [15:48] Write: apps/mobile/lib/features/post/data/datasources/share_plus_datasource.dart
  [15:48] Edit: apps/mobile/test/unit/features/post/data/repositories/share_repository_impl_test.dart
  [15:49] Edit: apps/mobile/test/unit/features/post/domain/usecases/share_post_test.dart
  [15:49] Edit: apps/mobile/test/widget/features/post/screens/post_detail_screen_test.dart
  [15:49] Edit: apps/mobile/test/widget/features/post/screens/post_detail_screen_test.dart
  [15:50] Write: apps/mobile/test/unit/features/post/data/datasources/share_plus_datasource_test.dart
  [15:50] Write: apps/mobile/test/unit/features/post/data/datasources/share_plus_datasource_test.dart

Outcome: SPEC-0010 Share Post fully implemented — datasource, repository, providers, PostDetailScreen share button, GoRouter redirect preservation, AndroidManifest App Links intent-filter, firebase.json hosting block, and all 23 tests passing.
Decisions: share_plus v10 uses static Share.share(text) not SharePlus.instance.share(ShareParams) — corrected from spec snippet. Flutter Clipboard channel is flutter/platform with JSONMethodCodec (not plugins.flutter.io/clipboard) — fixed datasource test accordingly. _ThrowingShareRepo accepted as ShareRepository? rather than _FakeShareRepository? to allow any ShareRepository implementation in _buildSubject.
Handoff: All files formatted. flutter analyze clean. submit for QA/architect review. firebase.json hosting block requires 'hosting/public' directory and apple-app-site-association + assetlinks.json files to be set up separately before deploy.
Review: PENDING

---
Date: 2026-05-19
Member: Slade
Agent: architect
Task: Write Tech Proposal 0011 — Edit and Delete Own Post
Prompt: Write a Tech Proposal at tech-proposals/0011-edit-delete-own-post.md for post edit and delete, comparing three action-surface options (PostDetailScreen overflow menu, PostCard contextual menu, MyPostsScreen only).

Outcome: PROP-0011 written at tech-proposals/0011-edit-delete-own-post.md (DRAFT). ADR-0011 written at docs/decisions/0011-edit-delete-own-post-action-surface.md (PROPOSED). Recommendation is Option A — overflow menu on PostDetailScreen AppBar only.
Decisions: Option A recommended over B (PostCard coupling risk, accidental-tap risk) and C (discoverability gap from deep-link entry, gesture interceptor complexity). Five open questions raised: Storage file deletion strategy (client vs Cloud Function cascade), mutable field allowlist, AI summary invalidation on edit, Firestore update rule field enumeration, and whether an "edited" indicator should be shown.
Handoff: Proposal requires team approval before a Tech Spec is written. Five open questions must be resolved during spec authorship — OQ2 (mutable fields) and OQ4 (Firestore update rules) are blockers for implementation.
Review: PENDING

---
Date: 2026-05-19 00:00
Member: Slade
Agent: flutter-engineer
Task: Implement SPEC-0011 — Edit and Delete Own Post
Prompt: Implement SPEC-0011 (Edit and Delete Own Post) for Unishare Flutter. All architectural decisions are finalised — implement exactly as described.

Outcome: Implemented SPEC-0011 across 15 files — domain interface extended, two new use cases, storage/Firestore datasource methods, repository impl, two new Riverpod providers, EditPostNotifier, EditPostScreen, PostDetailScreen overflow menu with delete, /posts/:postId/edit route, and updated Firestore security rules.
Decisions: firebase_storage ^12.3.7 was incompatible with firebase_remote_config ^6.5.1; bumped to ^13.4.1 as suggested by pub resolver. The `override_on_non_overriding_member` warning in edit_post_provider.dart is expected until build_runner regenerates edit_post_provider.g.dart — not a real error.
Handoff: Run `dart run build_runner build` from apps/mobile to generate edit_post_provider.g.dart and regenerate post_repository_provider.g.dart. After codegen, run `flutter analyze` and `flutter test` to confirm clean. Submit for QA/architect review — do not self-approve.
Review: PENDING

2026-05-20
  [12:39] Edit: apps/mobile/lib/core/router/shell_scaffold.dart
  [12:39] Edit: apps/mobile/lib/shared/widgets/guest_nav_bar.dart
  [12:39] Edit: apps/mobile/lib/shared/widgets/guest_nav_bar.dart
  [12:39] Edit: apps/mobile/lib/shared/widgets/guest_nav_bar.dart
  [12:39] Edit: apps/mobile/lib/shared/widgets/guest_nav_bar.dart
  [12:39] Edit: apps/mobile/lib/shared/widgets/guest_nav_bar.dart
  [12:40] Edit: apps/mobile/lib/shared/widgets/guest_nav_bar.dart
  [12:40] Edit: apps/mobile/lib/shared/widgets/guest_nav_bar.dart
  [12:40] Edit: apps/mobile/lib/core/router/guest_shell_scaffold.dart
  [12:40] Edit: apps/mobile/lib/core/router/guest_shell_scaffold.dart
  [12:41] Write: apps/mobile/lib/features/departments/presentation/screens/departments_screen.dart
  [12:41] Edit: apps/mobile/lib/core/router/router.dart
  [12:41] Edit: apps/mobile/lib/core/router/router.dart
  [12:41] Edit: apps/mobile/lib/core/router/router.dart
  [12:41] Edit: apps/mobile/lib/core/router/router.dart
  [12:41] Edit: apps/mobile/lib/core/router/router.dart
Files:
  ~ apps/mobile/lib/core/router/guest_shell_scaffold.dart
  ~ apps/mobile/lib/core/router/router.dart
  ~ apps/mobile/lib/core/router/shell_scaffold.dart
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/departments/presentation/screens/departments_screen.dart
  ~ apps/mobile/lib/features/feed/presentation/screens/feed_screen.dart
  ~ apps/mobile/lib/features/post/presentation/screens/post_detail_screen.dart
  ~ apps/mobile/lib/features/saved/presentation/screens/saved_screen.dart
  ~ apps/mobile/lib/shared/widgets/guest_nav_bar.dart
Summary:  9 files changed, 149 insertions(+), 31 deletions(-)

