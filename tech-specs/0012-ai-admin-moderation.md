---
title: "0012: AI Admin Moderation"
description: "Posts enter a pending queue; a Cloud Function AI-screens each one; admins approve or reject from a dedicated screen."
---

# SPEC-0012: AI Admin Moderation

**Status:** APPROVED  
**Author:** Sudakarn  
**Date:** 2026-05-20  
**Proposal:** [PROP-0012](../tech-proposals/0012-ai-admin-moderation.md)  
**Approved by:** Sudakarn

---

## Overview

Every newly submitted post is written with `status: "pending"` and hidden from the public feed. A Firestore-triggered Cloud Function calls Claude Haiku 4.5 within 30 s and writes an `aiVerdict` (recommended decision + confidence + reason) back to the post document. Users whose Firestore profile has `role: "moderator"` see a **Moderation** screen in the app listing all pending posts with the AI hint. An admin taps Approve or Reject; a callable Cloud Function validates the role, flips the status, and notifies the author on rejection. Rejected posts are soft-deleted (status `"rejected"`, retained in Firestore for audit/appeals).

---

## Architecture

```mermaid
flowchart TD
    subgraph Flutter App
        ModerationScreen
        PendingPostCard
        moderationQueueProvider
        ModerationRepositoryImpl
    end

    subgraph Domain
        ModerationRepository[ModerationRepository\n(abstract)]
        GetPendingPosts
        ApprovePost
        RejectPost
        PendingPostEntity
        ModerationVerdictEntity
    end

    subgraph Firestore
        posts[posts/{postId}\nstatus · aiVerdict\nmoderatedBy · moderatedAt]
        users[users/{uid}\nrole: moderator]
    end

    subgraph Cloud Functions
        moderatePost[moderatePost\n(onCreate trigger)]
        handleModerationAction[handleModerationAction\n(callable)]
        ClaudeAPI[Claude Haiku 4.5]
    end

    ModerationScreen --> moderationQueueProvider
    moderationQueueProvider --> ModerationRepositoryImpl
    ModerationRepositoryImpl --> ModerationRepository
    ModerationRepositoryImpl --> Firestore

    posts -- onCreate --> moderatePost
    moderatePost --> ClaudeAPI
    moderatePost -- writes aiVerdict --> posts

    ModerationScreen -- approve/reject --> handleModerationAction
    handleModerationAction -- validates role --> users
    handleModerationAction -- updates status --> posts
```

---

## Firestore schema

### `posts/{postId}` — extended fields

| Field | Type | Values |
|---|---|---|
| `status` | `string` | `"pending"` \| `"approved"` \| `"rejected"` |
| `aiVerdict.recommended` | `string` | `"approve"` \| `"reject"` |
| `aiVerdict.confidence` | `number` | `0.0 – 1.0` |
| `aiVerdict.reason` | `string` | Short human-readable rationale |
| `aiVerdict.processedAt` | `timestamp` | When the Cloud Function wrote the verdict |
| `moderatedBy` | `string?` | UID of admin who took action |
| `moderatedAt` | `timestamp?` | When admin acted |

### `users/{uid}` — extended field

| Field | Type | Values |
|---|---|---|
| `role` | `string?` | `"moderator"` or absent |

Moderator role is assigned manually via Firebase Console — no in-app role-grant flow in this spec.

---

## File map

| Action | Path | Responsibility |
|---|---|---|
| Create | `apps/mobile/lib/features/moderation/domain/entities/moderation_verdict.dart` | Pure Dart entity: `recommended`, `confidence`, `reason`, `processedAt` |
| Create | `apps/mobile/lib/features/moderation/domain/entities/pending_post.dart` | Pure Dart entity wrapping post fields + `aiVerdict` |
| Create | `apps/mobile/lib/features/moderation/domain/repositories/moderation_repository.dart` | Abstract interface: `getPendingPosts`, `approvePost`, `rejectPost` |
| Create | `apps/mobile/lib/features/moderation/domain/usecases/get_pending_posts.dart` | Delegates to `ModerationRepository.getPendingPosts()` |
| Create | `apps/mobile/lib/features/moderation/domain/usecases/approve_post.dart` | Delegates to `ModerationRepository.approvePost(postId)` |
| Create | `apps/mobile/lib/features/moderation/domain/usecases/reject_post.dart` | Delegates to `ModerationRepository.rejectPost(postId, reason)` |
| Create | `apps/mobile/lib/features/moderation/data/models/pending_post_model.dart` | Freezed model with `fromFirestore` and `toEntity()` |
| Create | `apps/mobile/lib/features/moderation/data/models/moderation_verdict_model.dart` | Freezed model with `fromMap` and `toEntity()` |
| Create | `apps/mobile/lib/features/moderation/data/datasources/moderation_firestore_datasource.dart` | Firestore reads/writes for pending posts and moderation actions |
| Create | `apps/mobile/lib/features/moderation/data/repositories/moderation_repository_impl.dart` | Implements `ModerationRepository`; delegates to datasource |
| Create | `apps/mobile/lib/features/moderation/presentation/providers/moderation_queue_provider.dart` | `@riverpod AsyncNotifier<List<PendingPost>>` streaming pending posts |
| Create | `apps/mobile/lib/features/moderation/presentation/providers/moderation_action_provider.dart` | `@riverpod AsyncNotifier` handling approve/reject calls |
| Create | `apps/mobile/lib/features/moderation/presentation/screens/moderation_screen.dart` | Lists pending posts; calls action provider on Approve/Reject tap |
| Create | `apps/mobile/lib/features/moderation/presentation/widgets/pending_post_card.dart` | Card showing title, tags, file type, AI verdict badge, action buttons |
| Modify | `apps/mobile/lib/core/router/router.dart` | Add `/moderation` route; redirect non-moderators to `/feed` |
| Modify | `apps/mobile/lib/shared/widgets/main_nav_bar.dart` | Show Moderation tab only when `role == "moderator"` |
| Modify | `firestore.rules` | Pending posts readable only by owner + moderators; status writable only by Cloud Function admin SDK |
| Modify | `firestore.indexes.json` | Composite index: `posts` — `status` (Asc) + `createdAt` (Desc) |

---

## API contracts

### Domain entities

```dart
// lib/features/moderation/domain/entities/moderation_verdict.dart
class ModerationVerdict {
  const ModerationVerdict({
    required this.recommended, // 'approve' | 'reject'
    required this.confidence,  // 0.0 – 1.0
    required this.reason,
    required this.processedAt,
  });

  final String recommended;
  final double confidence;
  final String reason;
  final DateTime processedAt;
}

// lib/features/moderation/domain/entities/pending_post.dart
class PendingPost {
  const PendingPost({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.tags,
    required this.postType,
    required this.createdAt,
    this.aiVerdict,        // null while Cloud Function is processing
    this.moderatedBy,
    this.moderatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final List<String> tags;
  final String postType;
  final DateTime createdAt;
  final ModerationVerdict? aiVerdict;
  final String? moderatedBy;
  final DateTime? moderatedAt;
}
```

### Repository interface

```dart
// lib/features/moderation/domain/repositories/moderation_repository.dart
abstract class ModerationRepository {
  Stream<List<PendingPost>> getPendingPosts();
  Future<void> approvePost(String postId);
  Future<void> rejectPost(String postId, String reason);
}
```

### Riverpod providers

```dart
// moderation_queue_provider.dart
@riverpod
Stream<List<PendingPost>> moderationQueue(Ref ref) {
  final repo = ref.read(moderationRepositoryProvider);
  return repo.getPendingPosts();
}

// moderation_action_provider.dart
@riverpod
class ModerationAction extends _$ModerationAction {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> approve(String postId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(approvePostProvider).call(postId),
    );
  }

  Future<void> reject(String postId, String reason) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(rejectPostProvider).call(postId, reason),
    );
  }
}
```

### Cloud Function — `moderatePost` (TypeScript)

Triggered on `posts/{postId}` create. Calls Claude Haiku 4.5 with prompt:

```
You are a content moderator for an academic file-sharing platform.
Review this post and decide if it should be approved or rejected.
Approved posts must be: academic in nature, relevant to coursework, non-offensive.

Title: {title}
Description: {description}
Tags: {tags}
File type: {postType}

Respond with JSON only:
{ "recommended": "approve" | "reject", "confidence": 0.0–1.0, "reason": "<one sentence>" }
```

Writes result to `posts/{postId}.aiVerdict`.

### Cloud Function — `handleModerationAction` (callable)

Accepts `{ postId, action: "approve" | "reject", reason?: string }`. Validates caller has `role: "moderator"` in Firestore. Updates `posts/{postId}` with `status`, `moderatedBy`, `moderatedAt`. On reject, writes a notification document to `users/{authorId}/notifications`.

---

## Firestore security rules (additions)

```javascript
// posts collection
match /posts/{postId} {
  // Public feed: only approved posts
  allow read: if resource.data.status == 'approved'
              || isOwner(resource.data.authorId)
              || isModerator();

  // Status fields written only by admin SDK (Cloud Functions)
  allow write: if isOwner(request.auth.uid) && isCreating()
               && request.resource.data.status == 'pending';
}

function isModerator() {
  return get(/databases/$(database)/documents/users/$(request.auth.uid))
           .data.role == 'moderator';
}
```

---

## Test plan

| Test file | Covers |
|---|---|
| `test/unit/features/moderation/approve_post_test.dart` | `ApprovePost` use case delegates correctly |
| `test/unit/features/moderation/reject_post_test.dart` | `RejectPost` use case delegates correctly |
| `test/unit/features/moderation/pending_post_model_test.dart` | `fromFirestore` / `toEntity()` round-trip |
| `test/widget/features/moderation/moderation_screen_test.dart` | Shows pending list; Approve/Reject buttons trigger provider |
| `test/widget/features/moderation/pending_post_card_test.dart` | Renders AI verdict badge; confidence colour correct |

---

## Out of scope

- In-app role assignment (moderator role set manually via Firebase Console)
- Appeals flow for rejected authors
- Bulk approve/reject actions
- Moderation history / audit log screen
- Push notifications to author on rejection (in-app notification only)
- AI verdict shown to post author

---

## Open questions

- [ ] None — all open questions from PROP-0012 resolved with defaults above.
