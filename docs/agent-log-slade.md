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

