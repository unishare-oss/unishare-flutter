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
