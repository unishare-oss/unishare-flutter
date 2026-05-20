---
Date: 2026-05-06 00:00
Member: khinnadiko
Agent: architect
Task: Write Tech Proposal PROP-0006 for the post-detail-page feature
Prompt: Write a Tech Proposal for the post-detail-page feature (PROP-0006). The app has a post feed (PROP-0003) with PostCard widgets but tapping a card has no destination. Students need a dedicated screen to read full post content, see all attachments, and interact (comments, likes). The screen must also serve as a deep-link destination for push notifications and shared URLs. UI must match Figma exactly. Evaluate multiple options (pass Post via GoRouter extra, always fetch fresh, hybrid optimistic + stream) and recommend the best fit. Write to tech-proposals/0006-post-detail-page.md.
Outcome: Wrote tech-proposals/0006-post-detail-page.md (PROP-0006, status DRAFT) and docs/decisions/0006-post-detail-data-loading-strategy.md (ADR-0006, status PROPOSED). No code was written.
Decisions: Recommended Option C (hybrid seed-then-stream): GoRouter extra carries the Post entity for warm-start instant render; postDetailProvider simultaneously opens a Firestore snapshots() stream for live updates; cold-start path falls back cleanly to stream-only with a skeleton loader. Rejected Option A (extra-only) because it breaks cold-start deep links. Rejected Option B (always fetch) because it adds a visible spinner on the dominant warm-start path and provides no live updates. Introduced a comments subcollection (posts/{postId}/comments) and three new domain use cases (WatchPost, WatchComments, AddComment) and one new entity (Comment). ToggleLike delegates to the existing likes subcollection; likesCount remains Cloud-Function-owned.
Handoff: Tech spec author (architect) must first audit the Figma file (node-id=0-1) to enumerate new vs existing design-system components before writing SPEC-0006. Seven open questions in PROP-0006 must be resolved before the spec is finalized — most critical are the Figma component audit (Q1), like-state provider design (Q4), and deep-link URL scheme (Q5). Flutter engineer implements against the approved spec only.
Review: PENDING

---
Date: 2026-05-06 10:00
Member: khinnadiko
Agent: architect
Task: Write Tech Spec SPEC-0006 for the post-detail-page feature
Prompt: Write the full Tech Spec at tech-specs/0006-post-detail-page.md using the approved PROP-0006 (Option C: hybrid seed-then-stream). All seven open questions have been resolved by the user. Spec must include file map, full Dart API contracts, Firestore schema, attachment media type handling, test plan, out-of-scope list, and resolved open questions.
Outcome: Wrote tech-specs/0006-post-detail-page.md (SPEC-0006, status DRAFT). All seven PROP-0006 open questions marked resolved. No code was written.
Decisions: Added LikeRepository as a distinct domain interface (separate from CommentRepository) so that ToggleLike has a clean dependency with a single toggleLike method and a watchLikeStatus stream, avoiding mixing concerns into CommentRepository. Added mediaTypes: List<String> to the Post entity as a parallel array to mediaUrls with a default of const [] for backward compatibility with existing Firestore documents that predate this spec. Specified that type derivation for publishDraft uses file extension matching, with "image" as the safe fallback for unknown extensions.
Handoff: Flutter engineer implements against SPEC-0006. Before starting: (1) confirm PDF viewer package with team (flutter_pdfview or equivalent) as it is a new dependency requiring approval; (2) locate PostCard widget path (feed feature) to add the context.push tap handler; (3) add the comments subcollection createdAt ASC index to firestore.indexes.json before deploying.
Review: PENDING
Files:
  ? apps/mobile/lib/features/post/data/datasources/comment_firestore_datasource.dart (untracked)
  ? apps/mobile/lib/features/post/data/models/comment_dto.dart (untracked)
  ? apps/mobile/lib/features/post/data/repositories/comment_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/post/data/repositories/like_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/post/domain/entities/comment.dart (untracked)
  ? apps/mobile/lib/features/post/domain/repositories/comment_repository.dart (untracked)
  ? apps/mobile/lib/features/post/domain/repositories/like_repository.dart (untracked)
  ? apps/mobile/lib/features/post/domain/usecases/add_comment.dart (untracked)
  ? apps/mobile/lib/features/post/domain/usecases/toggle_like.dart (untracked)
  ? apps/mobile/lib/features/post/domain/usecases/watch_comments.dart (untracked)
  ? apps/mobile/lib/features/post/domain/usecases/watch_post.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/providers/comments_provider.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/providers/post_detail_provider.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/providers/user_like_status_provider.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/screens/post_detail_screen.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/widgets/attachment_carousel.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/widgets/comment_tile.dart (untracked)
  ? apps/mobile/lib/features/post/presentation/widgets/like_button.dart (untracked)

Files:
  ~ apps/mobile/lib/features/post/presentation/screens/post_detail_screen.dart
  ~ apps/mobile/lib/features/post/presentation/widgets/attachment_list.dart
  ~ apps/mobile/test/unit/features/post/presentation/providers/post_detail_provider_test.dart
Summary:  3 files changed, 53 insertions(+), 26 deletions(-)

Files:
  ~ apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart
  ~ apps/mobile/lib/features/post/domain/entities/post.dart
  ~ apps/mobile/lib/features/post/presentation/screens/post_detail_screen.dart
Summary:  3 files changed, 407 insertions(+), 57 deletions(-)

Files:
  ~ apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart
  ~ apps/mobile/lib/features/post/domain/entities/post.dart
  ~ apps/mobile/lib/features/post/presentation/screens/post_detail_screen.dart
Summary:  3 files changed, 477 insertions(+), 57 deletions(-)

Files:
  ~ apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart
  ~ apps/mobile/lib/features/post/data/repositories/reaction_repository_impl.dart
  ~ apps/mobile/lib/features/post/presentation/providers/reaction_providers.dart
  ~ apps/mobile/lib/features/post/presentation/screens/post_detail_screen.dart
Summary:  4 files changed, 23 insertions(+), 28 deletions(-)

