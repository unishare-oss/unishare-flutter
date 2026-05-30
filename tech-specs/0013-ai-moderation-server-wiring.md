---
title: "0013: AI moderation server wiring"
description: "Completes the server-authoritative half of SPEC-0012 — Groq-powered AI verdict in a Cloud Function trigger, role-checked moderation actions via a callable, and the Firestore rules + index that make the queue actually safe."
---

# SPEC-0013: AI Moderation Server Wiring

**Status:** APPROVED
**Author:** Pyae Sone Shin Thant (drafted) — handed to teammate for implementation
**Date:** 2026-05-20
**Proposal:** (none — direct follow-up to PROP-0012)
**Supersedes parts of:** [SPEC-0012](./0012-ai-admin-moderation.md) — specifically the Cloud Function, callable, and Firestore-rules sections
**Approved by:** Sudakarn

---

## Overview

SPEC-0012 shipped the moderation **UI** (queue screen, pending-post card, role-gated More-drawer tile). A follow-up PR addressed some of the server gaps. This spec covers the remaining work: the AI verdict path, the role-checked callable, and the security/correctness gaps still on main.

It replaces the Claude-Haiku-via-Cloud-Function approach from SPEC-0012 with **Groq llama-3.3-70b-versatile via the existing functions package**, and replaces the client-direct Firestore writes with a **role-checked callable**.

---

## Current state on `main` (do NOT redo)

The following landed in commits up to `c5c2e6a0` and is already in the working tree. Treat as load-bearing — verify it still matches the spec below before changing anything:

- `post_firestore_datasource.dart:42` — `createPost` writes `status: 'pending'`.
- `post_firestore_datasource.dart:51` — `watchFeed` filters `where('status', isEqualTo: 'approved')`.
- `firestore.rules:220` — `isModerator()` helper using `get(/databases/$(database)/documents/users/$(request.auth.uid)).data.get('role', '') == 'moderator'`.
- `firestore.rules:159–199` — `posts` block has the read gate (`approved || author || moderator`), `status == 'pending'` enforced on create, and the moderator update branch on `['status', 'moderatedBy', 'moderatedAt', 'rejectionReason']` with `status in ['approved', 'rejected']`.
- `apps/mobile/lib/features/moderation/data/models/pending_post_model.dart` — `aiVerdict` Firestore round-trip exists (the field will just be `null` until the trigger writes it).
- `apps/mobile/lib/features/moderation/data/datasources/moderation_firestore_datasource.dart` — direct Firestore writes for approve/reject (rules-permitted today; SPEC-0013 still recommends moving to a callable, see D3).

## Gaps still to close — ordered by risk

Cross-check each against current code before writing the implementation. Items 1–4 are **exploitable or query-breaking today** and must land before any production deploy. Items 5–6 are the AI feature itself.

| # | Severity | Gap | Where |
|---|---|---|---|
| 1 | 🔴 critical | Composite index `posts: status ASC + createdAt DESC` missing. `watchFeed` and the moderation `watchPendingPosts` query throw `failed-precondition` on first run in any fresh environment. | `firestore.indexes.json` |
| 2 | 🔴 critical | `users/{uid}.role` is not locked from client writes. Any authed user can `update({role: 'moderator'})` from the Firebase SDK and bypass the entire moderation system. | `firestore.rules` `match /users/{userId}` update rule |
| 3 | 🟡 high | `watchPostsByCourse` does not filter by `status == 'approved'` — pending/rejected posts leak into the "more in this course" panel. | `apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart:149` |
| 4 | 🟡 high | `posts` create rule doesn't reject pre-seeded `aiVerdict` / `moderatedBy` / `moderatedAt`. An author can write a fake AI verdict on create; the moderator queue would display it. | `firestore.rules` `match /posts/{postId}` create rule |
| 5 | 🟢 feature | No Cloud Function calls an LLM, so `posts/{id}.aiVerdict` is always `null` and the verdict badge is dead UI. | `functions/src/triggers/onPostCreated.ts` + new `functions/src/lib/moderation.ts` |
| 6 | 🟢 feature | Moderation actions still write Firestore directly. Migrating to a `handleModerationAction` callable centralizes state validation and gives a single error surface. | `functions/src/callable/handleModerationAction.ts` + `apps/mobile/lib/features/moderation/data/datasources/moderation_firestore_datasource.dart` |

A backfill of `status: 'approved'` for legacy posts is also required if any production data predates the feed-filter change — see *Migration* below.

---

## Decisions

### D1 — AI provider: Groq llama-3.3-70b-versatile (not Claude Haiku)

The project already runs `worker/src/ai-summarize.ts` against Groq's `llama-3.3-70b-versatile` (text) and `meta-llama/llama-4-scout-17b-16e-instruct` (vision), with a `GROQ_API_KEY` secret already provisioned. Reusing this model:

- avoids opening an Anthropic billing relationship;
- reuses the prompt-engineering experience the team already has from the summarize path (the summarize prompt already classifies `status: "flagged"` for harmful content — the moderation prompt is a sibling);
- keeps token/cost characteristics predictable (Groq free-tier is generous; moderation is text-only and short).

**Cost note:** the moderation prompt is ~200 tokens in, ~80 tokens out. At Groq free-tier rate limits this is comfortably within the same envelope as the summarize traffic.

### D2 — Where the AI call lives: Cloud Function trigger, not Worker route

The Cloudflare Worker has **no Firebase Admin SDK** (it only verifies JWTs, calls Groq, and writes to R2). Any write of `aiVerdict` back to Firestore would have to go through the client, which means a malicious client can forge an `aiVerdict: { recommended: "approve", confidence: 1.0 }` without ever calling the worker.

Putting the Groq call inside the **`onPostCreated` Firestore trigger** gives us:

- A server-only code path (no client can skip or forge it).
- Direct Admin-SDK writes back to the post doc (no shared-secret server-to-server hop).
- A natural place to also write the post-author notification on rejection later (already the pattern of the other triggers in `functions/src/triggers/`).

The Worker route `/ai/moderate` originally proposed is dropped. If we ever want a "preview AI verdict before submitting" feature, that becomes a separate worker route and a separate spec — the security-bearing verdict still comes from the trigger.

### D3 — Moderator role validation: callable, with rules-level defense in depth

Approve/Reject actions go through a `handleModerationAction` callable that:

1. Verifies the caller's Firebase Auth token (callables do this for us).
2. Reads `users/{caller.uid}.role` via Admin SDK.
3. Writes the moderation outcome via Admin SDK.

`firestore.rules` get **a defense-in-depth `isModerator()` helper** so that any direct-write attempts also fail rules-side. This costs one extra `get()` per moderation write, which is fine (low traffic, only moderators trigger it).

`users/{uid}.role` is **locked from client self-update** in the rules — without this, any user could promote themselves and bypass D3 entirely.

---

## Architecture

```mermaid
flowchart TD
    subgraph Flutter
        Compose[ComposePostScreen]
        ModScreen[ModerationScreen]
        FeedScreen[FeedScreen]
    end

    subgraph Firestore
        postsDoc[posts/{postId}<br/>status · aiVerdict<br/>moderatedBy · moderatedAt]
        usersDoc[users/{uid}<br/>role: moderator?]
    end

    subgraph Functions[Cloud Functions asia-southeast1]
        Trigger[onPostCreated trigger]
        Callable[handleModerationAction callable]
        Groq[(Groq API<br/>llama-3.3-70b-versatile)]
    end

    Compose -- create with status: 'pending' --> postsDoc
    postsDoc -- onCreate --> Trigger
    Trigger -- moderate prompt --> Groq
    Groq -- JSON verdict --> Trigger
    Trigger -- aiVerdict + status (no flip) --> postsDoc

    ModScreen -- approve/reject --> Callable
    Callable -- read role --> usersDoc
    Callable -- write status, moderatedBy --> postsDoc

    FeedScreen -- where status==approved --> postsDoc
```

---

## Firestore schema

### `posts/{postId}` — fields added or constrained

| Field | Type | Values | Writer |
|---|---|---|---|
| `status` | `string` | `"pending"` \| `"approved"` \| `"rejected"` | Client on create (`"pending"` only). Callable on transition. |
| `aiVerdict.recommended` | `string` | `"approve"` \| `"reject"` | Trigger only |
| `aiVerdict.confidence` | `number` | `0.0 – 1.0` | Trigger only |
| `aiVerdict.reason` | `string` | One-sentence rationale | Trigger only |
| `aiVerdict.processedAt` | `timestamp` | Server timestamp at write | Trigger only |
| `aiVerdict.error` | `string?` | Present when the LLM call failed; recommended falls back to `"approve"` (fail-open for now, see Open Questions) | Trigger only |
| `moderatedBy` | `string?` | UID of moderator who acted | Callable only |
| `moderatedAt` | `timestamp?` | Server timestamp at action | Callable only |
| `rejectionReason` | `string?` | Free-text reason on reject (≤ 500 chars) | Callable only |

**Backward-compat:** documents written before this spec have no `status` field. The feed query filters via `where('status', whereIn: ['approved'])`, which **excludes those legacy docs**. A one-time backfill is required — see *Migration* below.

### `users/{uid}` — fields constrained

| Field | Type | Writer |
|---|---|---|
| `role` | `string?` (`"moderator"` or absent) | Admin only (Firebase Console / scripted backfill). **Locked from client writes** in rules. |

---

## File map

Legend: ✅ already on main · ⬜ to implement.

### Cloud Functions (TypeScript)

| | Action | Path | Responsibility |
|---|---|---|---|
| ⬜ | Modify | `functions/package.json` | Add `groq-sdk` dependency |
| ⬜ | Create | `functions/src/lib/moderation.ts` | Groq client setup, prompt builder, JSON parsing with defensive fallbacks |
| ⬜ | Modify | `functions/src/triggers/onPostCreated.ts` | After existing badge logic, call moderation lib and write `aiVerdict`. Switch trigger to the options-object form so `secrets: [GROQ_API_KEY]` injects at runtime. |
| ⬜ | Create | `functions/src/callable/handleModerationAction.ts` | Role-checked callable for approve/reject |
| ⬜ | Modify | `functions/src/index.ts` | Export new callable |
| ⬜ | Set | `GROQ_API_KEY` secret | `firebase functions:secrets:set GROQ_API_KEY` once per environment (no file change — see Deployment order) |

### Firestore configuration

| | Action | Path | Responsibility |
|---|---|---|---|
| ✅ | Done | `firestore.rules` | `isModerator()` helper at `:220`; `posts` read gate + create `status == 'pending'` + moderator update branch all present at `:159–199` |
| ⬜ | Modify | `firestore.rules` | (Gap #2) Lock `users/{uid}.role` with a `writesRole()` helper in the user update rule |
| ⬜ | Modify | `firestore.rules` | (Gap #4) Extend `posts` create rule so authors cannot pre-seed `aiVerdict`, `moderatedBy`, or `moderatedAt` |
| ⬜ | Modify | `firestore.indexes.json` | (Gap #1) Composite: `posts` — `status` ASC + `createdAt` DESC. **Add a second composite for course view: `posts` — `courseId` ASC + `status` ASC + `createdAt` DESC** if Gap #3 lands. |

### Flutter app

| | Action | Path | Responsibility |
|---|---|---|---|
| ⬜ | Modify | `apps/mobile/pubspec.yaml` | Add `cloud_functions: ^5.x` (latest compatible with `firebase_core ^4.7.0`) |
| ⬜ | Modify | `apps/mobile/lib/features/post/domain/entities/post.dart` | Add `ModerationStatus` enum + `aiVerdict` + `status` + `moderatedBy` + `moderatedAt` + `rejectionReason` fields. **Update `copyWith`.** |
| ⬜ | Modify | `apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart` | (Gap #3) Filter `watchPostsByCourse` to `status == 'approved'`. Also extend `_docToPost` to populate the new entity fields. |
| ✅ | Done | `apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart` | `createPost` already writes `status: 'pending'` (line 42); `watchFeed` already filters `status == 'approved'` (line 51) |
| ⬜ | Modify | `apps/mobile/lib/features/moderation/data/datasources/moderation_firestore_datasource.dart` | (Gap #6) Replace direct Firestore writes with `FirebaseFunctions.instanceFor(region: 'asia-southeast1').httpsCallable('handleModerationAction')`. Keep `watchPendingPosts` as a Firestore stream — it stays a query, not a callable. |
| ⬜ | Modify | `apps/mobile/lib/features/moderation/data/models/pending_post_model.dart` | Map the new `aiVerdict.error` field |
| ⬜ | Modify | `apps/mobile/lib/features/moderation/presentation/providers/moderation_action_provider.dart` | Map `FirebaseFunctionsException` codes (`unauthenticated`, `permission-denied`, `not-found`, `failed-precondition`, `invalid-argument`) to user-facing snackbar messages |

### Migration script

| Action | Path | Responsibility |
|---|---|---|
| Create | `tools/backfill_post_status.js` | One-time: set `status: 'approved'` on every existing `posts/*` doc missing the field, so old content stays visible after the feed query change |

---

## API contracts

### Cloud Functions — `functions/src/lib/moderation.ts`

```ts
import Groq from 'groq-sdk';
import { logger } from 'firebase-functions/v2';
import { defineSecret } from 'firebase-functions/params';

export const GROQ_API_KEY = defineSecret('GROQ_API_KEY');

const TEXT_MODEL = 'llama-3.3-70b-versatile';

export interface AiVerdict {
  recommended: 'approve' | 'reject';
  confidence: number;
  reason: string;
  error?: string;
}

interface ModerationInput {
  title: string;
  description: string;
  tags: string[];
  postType: string;
}

const PROMPT = (input: ModerationInput) => `You are a content moderator for an academic file-sharing platform used by university students.

Decide if this post should be APPROVED for the public feed or REJECTED.

Approve when the post is:
- academic in nature (lecture notes, exercises, study material, course-relevant)
- non-offensive (no slurs, sexual content, harassment, illegal material)
- not obvious spam or self-promotion

Reject when the post contains:
- harmful or clearly inappropriate content
- spam, advertising, or content unrelated to academic work
- harassment or attacks against a person or group

POST
title: ${input.title}
description: ${input.description}
tags: ${input.tags.join(', ') || '(none)'}
postType: ${input.postType}

Respond with EXACTLY this JSON shape. No preamble, no markdown fence, no closing remarks:
{ "recommended": "approve" | "reject", "confidence": <number between 0 and 1>, "reason": "<one short sentence>" }`;

export async function classifyPost(
  apiKey: string,
  input: ModerationInput,
): Promise<AiVerdict> {
  const groq = new Groq({ apiKey });
  let raw: string;
  try {
    const completion = await groq.chat.completions.create({
      model: TEXT_MODEL,
      temperature: 0,
      max_tokens: 200,
      response_format: { type: 'json_object' },
      messages: [{ role: 'user', content: PROMPT(input) }],
    });
    raw = completion.choices[0]?.message?.content ?? '';
  } catch (e) {
    logger.error('moderation: groq call failed', { error: (e as Error).message });
    // Fail-open: don't trap legitimate posts behind a hard-failed API.
    // The post still sits in the queue for human review.
    return {
      recommended: 'approve',
      confidence: 0,
      reason: 'AI unavailable — defer to human moderator',
      error: (e as Error).message,
    };
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    logger.warn('moderation: non-JSON model output', { raw });
    return {
      recommended: 'approve',
      confidence: 0,
      reason: 'AI returned unparseable output',
      error: 'parse_failed',
    };
  }

  const obj = parsed as Record<string, unknown>;
  const recommended = obj.recommended === 'reject' ? 'reject' : 'approve';
  const rawConf = typeof obj.confidence === 'number' ? obj.confidence : 0;
  const confidence = Math.max(0, Math.min(1, rawConf));
  const reason = typeof obj.reason === 'string' && obj.reason.length > 0
    ? obj.reason.slice(0, 240)
    : 'No reason provided';

  return { recommended, confidence, reason };
}
```

### Cloud Functions — `functions/src/triggers/onPostCreated.ts` (extension)

The existing handler stays as-is (badges + counters). After it runs, kick off moderation. Use a single doc `update()` to write the verdict atomically; failures only log because the trigger has already done its primary work.

```ts
import { onDocumentCreated, type FirestoreEvent, type QueryDocumentSnapshot } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { db, FieldValue } from '../admin';
import { incrementStat, addUniqueDepartment } from '../badges/counters';
import { evaluateBadges } from '../badges/evaluateBadges';
import type { StatKey } from '../badges/types';
import { classifyPost, GROQ_API_KEY } from '../lib/moderation';

interface PostCreatedData {
  authorId?: string;
  departmentId?: string;
  status?: string;
  title?: string;
  description?: string;
  tags?: string[];
  postType?: string;
}

export async function onPostCreatedHandler(
  postId: string,
  post: PostCreatedData,
): Promise<void> {
  // ---- existing badge bookkeeping (unchanged) -------------------------------
  if (!post.authorId) {
    logger.warn('onPostCreated skipped — no authorId', { postId });
    return;
  }
  const changed: StatKey[] = ['postsCreated'];
  await incrementStat(post.authorId, 'postsCreated', 1);
  if (post.departmentId) {
    const added = await addUniqueDepartment(post.authorId, post.departmentId);
    if (added) changed.push('uniqueDepartmentsCount');
  }
  await evaluateBadges(post.authorId, changed);

  // ---- new: AI moderation verdict -------------------------------------------
  // Only screen pending posts. Backfilled or legacy docs (status='approved')
  // bypass screening — this also gives us a kill switch if we ever need it.
  if (post.status !== 'pending') return;

  try {
    const verdict = await classifyPost(GROQ_API_KEY.value(), {
      title: post.title ?? '',
      description: post.description ?? '',
      tags: post.tags ?? [],
      postType: post.postType ?? 'unknown',
    });
    await db.collection('posts').doc(postId).update({
      aiVerdict: {
        ...verdict,
        processedAt: FieldValue.serverTimestamp(),
      },
    });
  } catch (e) {
    // classifyPost has its own fail-open. If even the Firestore write fails,
    // log and move on — the queue will just show the post without a verdict.
    logger.error('moderation verdict write failed', { postId, error: (e as Error).message });
  }
}

export const onPostCreated = onDocumentCreated(
  {
    document: 'posts/{postId}',
    secrets: [GROQ_API_KEY],
  },
  async (event: FirestoreEvent<QueryDocumentSnapshot | undefined, { postId: string }>) => {
    const snap = event.data;
    if (!snap) return;
    await onPostCreatedHandler(event.params.postId, snap.data() as PostCreatedData);
  },
);
```

**Important:** the existing `onDocumentCreated('posts/{postId}', async (event) => …)` signature uses the string-only first arg. Switching to the options-object form is required to declare `secrets: [GROQ_API_KEY]` (otherwise the secret isn't injected at runtime). Verify this against `firebase-functions ^7.2.5` — the option name is `secrets` and the import is `defineSecret` from `firebase-functions/params`.

### Cloud Functions — `functions/src/callable/handleModerationAction.ts`

```ts
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db, FieldValue } from '../admin';

interface ApproveInput {
  postId: string;
  action: 'approve';
}
interface RejectInput {
  postId: string;
  action: 'reject';
  reason: string;
}
type Input = ApproveInput | RejectInput;

const MAX_REASON_LEN = 500;

export const handleModerationAction = onCall<Input>(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required');

  const { postId, action } = request.data ?? ({} as Input);
  if (typeof postId !== 'string' || postId.length === 0) {
    throw new HttpsError('invalid-argument', 'postId required');
  }
  if (action !== 'approve' && action !== 'reject') {
    throw new HttpsError('invalid-argument', 'action must be approve|reject');
  }

  // Role check — single get() against users/{uid}.role.
  const userSnap = await db.collection('users').doc(uid).get();
  if (userSnap.data()?.role !== 'moderator') {
    logger.warn('moderation action denied — not a moderator', { uid, postId });
    throw new HttpsError('permission-denied', 'Moderator role required');
  }

  // Load the post defensively — we won't transition out of an unexpected state.
  const postRef = db.collection('posts').doc(postId);
  const postSnap = await postRef.get();
  if (!postSnap.exists) throw new HttpsError('not-found', 'Post not found');
  if (postSnap.data()?.status !== 'pending') {
    throw new HttpsError(
      'failed-precondition',
      `Post is not pending (status=${postSnap.data()?.status})`,
    );
  }

  const update: Record<string, unknown> = {
    status: action === 'approve' ? 'approved' : 'rejected',
    moderatedBy: uid,
    moderatedAt: FieldValue.serverTimestamp(),
  };
  if (action === 'reject') {
    const reason = (request.data as RejectInput).reason ?? '';
    if (typeof reason !== 'string' || reason.length === 0) {
      throw new HttpsError('invalid-argument', 'reason required on reject');
    }
    update.rejectionReason = reason.slice(0, MAX_REASON_LEN);
  }

  await postRef.update(update);
  return { ok: true };
});
```

### Cloud Functions — `functions/src/index.ts`

Add the export:

```ts
export { handleModerationAction } from './callable/handleModerationAction';
```

### Flutter — `apps/mobile/lib/features/post/domain/entities/post.dart`

Add the enum, fields, and threading through `copyWith`:

```dart
enum ModerationStatus {
  pending,
  approved,
  rejected;

  static ModerationStatus? fromFirestore(String? raw) => switch (raw) {
    'pending' => ModerationStatus.pending,
    'approved' => ModerationStatus.approved,
    'rejected' => ModerationStatus.rejected,
    _ => null,
  };
}

class AiVerdict {
  const AiVerdict({
    required this.recommended,
    required this.confidence,
    required this.reason,
    required this.processedAt,
    this.error,
  });

  final String recommended; // 'approve' | 'reject'
  final double confidence;
  final String reason;
  final DateTime processedAt;
  final String? error;
}
```

Add to `Post`:

```dart
final ModerationStatus? status;  // null on legacy docs; treat as approved
final AiVerdict? aiVerdict;
final String? moderatedBy;
final DateTime? moderatedAt;
final String? rejectionReason;
```

### Flutter — `apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart`

**(a) `createPost` writes `status: 'pending'` — ✅ already at line 42.** Skip.

**(b) `watchFeed` filters approved — ✅ already at line 51.** Skip.

**(c) `watchPostsByCourse` — ⬜ still missing the filter (Gap #3).**

Current state at `:149–165`:

```dart
Stream<List<Post>> watchPostsByCourse(
  String courseId, {
  String? excludeId,
  int limit = 5,
}) {
  return _firestore
      .collection('posts')
      .where('courseId', isEqualTo: courseId)
      .orderBy('createdAt', descending: true)
      // ...
```

Add the status filter:

```dart
return _firestore
    .collection('posts')
    .where('courseId', isEqualTo: courseId)
    .where('status', isEqualTo: 'approved')   // <-- NEW
    .orderBy('createdAt', descending: true)
    // ...
```

This needs the `courseId + status + createdAt` composite from the Index section.

**Do not** filter `watchPostsByAuthor` — the author should see their own pending/rejected posts (security rules permit this; SPEC-0012 implicitly relies on it for the future "my posts" view).

**Backward-compat warning:** legacy posts without a `status` field are excluded by all approved-filter queries. Run the backfill script (see *Migration*) before deploying the next environment.

**Index requirement:** confirm both composites in the Index section are **Enabled** in the target environment before this change lands.

### Flutter — `apps/mobile/lib/features/moderation/data/datasources/moderation_firestore_datasource.dart`

Drop the direct Firestore writes; call the callable instead.

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:unishare_mobile/features/moderation/data/models/pending_post_model.dart';
import 'package:unishare_mobile/features/moderation/domain/entities/pending_post.dart';

class ModerationFirestoreDatasource {
  ModerationFirestoreDatasource({FirebaseFunctions? functions})
    : _functions = functions
        ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFunctions _functions;
  final _db = FirebaseFirestore.instance;

  Stream<List<PendingPost>> watchPendingPosts() {
    return _db
        .collection('posts')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(PendingPostModel.fromFirestore)
            .map((m) => m.toEntity())
            .toList());
  }

  Future<void> approvePost(String postId) async {
    await _functions
        .httpsCallable('handleModerationAction')
        .call({'postId': postId, 'action': 'approve'});
  }

  Future<void> rejectPost(String postId, String reason) async {
    await _functions
        .httpsCallable('handleModerationAction')
        .call({'postId': postId, 'action': 'reject', 'reason': reason});
  }
}
```

The callable returns `{ok: true}` on success or throws a `FirebaseFunctionsException` with codes `unauthenticated`, `permission-denied`, `not-found`, `failed-precondition`, `invalid-argument`. Surface these in `moderation_action_provider.dart` as user-friendly error states.

### Migration — `tools/backfill_post_status.js`

```js
// Run once per environment, after deploying SPEC-0013 but BEFORE shipping
// the new feed query. Sets status='approved' on every legacy post so they
// remain visible in the feed.
//
// Usage: node tools/backfill_post_status.js service-account.json
const admin = require('firebase-admin');
const cert = require(process.argv[2]);

admin.initializeApp({ credential: admin.credential.cert(cert) });
const db = admin.firestore();

(async () => {
  let scanned = 0;
  let updated = 0;
  const batchSize = 400;
  let lastDoc = null;

  while (true) {
    let q = db.collection('posts').orderBy('__name__').limit(batchSize);
    if (lastDoc) q = q.startAfter(lastDoc);
    const snap = await q.get();
    if (snap.empty) break;

    const batch = db.batch();
    for (const doc of snap.docs) {
      scanned++;
      if (!('status' in doc.data())) {
        batch.update(doc.ref, { status: 'approved' });
        updated++;
      }
    }
    if (updated > 0) await batch.commit();
    lastDoc = snap.docs[snap.docs.length - 1];
    console.log(`scanned=${scanned} updated=${updated}`);
  }
})();
```

---

## Firestore rules — what's already there and what still needs adding

### Already in main ✅

- `isModerator()` helper at `firestore.rules:220`, using `get(/databases/$(database)/documents/users/$(request.auth.uid)).data.get('role', '')`.
- `posts/{postId}` read gate (`approved || author || moderator`) at `:162–164`.
- Create rule enforcing `status == 'pending'` at `:165–170`.
- Update rule with moderator branch on `['status', 'moderatedBy', 'moderatedAt', 'rejectionReason']` constrained to `status in ['approved', 'rejected']` at `:191–196`.

### Still to add ⬜

#### (a) Lock `users/{userId}.role` from client self-write — Gap #2

Update the `users/{userId}` `allow update` rule. Add a `writesRole()` guard alongside the existing protected-field checks.

```javascript
match /users/{userId} {
  // ... existing read/create rules unchanged ...

  allow update: if request.auth != null
                && request.auth.uid == userId
                && !writesProtectedAchievementsFields()
                && !writesRole()                              // <-- NEW
                && (!touchesDisplayedBadges() || validDisplayedBadges())
                && (!touchesSelectedTitle() || validSelectedTitle());

  // ... existing helper functions unchanged ...

  function writesRole() {                                     // <-- NEW
    return request.resource.data.get('role', null)
        != resource.data.get('role', null);
  }
}
```

#### (b) Block client-supplied verdict fields on `posts` create — Gap #4

Extend the existing `allow create` rule at `firestore.rules:165–170` so the create cannot smuggle in `aiVerdict`, `moderatedBy`, or `moderatedAt`. Add three `!('field' in request.resource.data)` clauses:

```javascript
allow create: if request.auth != null
              && request.resource.data.authorId == request.auth.uid
              && request.resource.data.title is string
              && request.resource.data.title.size() > 0
              && request.resource.data.likesCount == 0
              && request.resource.data.status == 'pending'
              && !('aiVerdict' in request.resource.data)        // <-- NEW
              && !('moderatedBy' in request.resource.data)      // <-- NEW
              && !('moderatedAt' in request.resource.data)      // <-- NEW
              && !('rejectionReason' in request.resource.data); // <-- NEW
```

#### (c) Author edit rule — verify it still excludes moderation fields

The current author update branch (`:175–185`) restricts authors to `['title', 'description', 'tags', 'externalUrl', 'moduleNumber', 'updatedAt', 'summary', 'summaryStatus', 'summarizedAt']`. Confirm none of `status`, `aiVerdict`, `moderatedBy`, `moderatedAt`, `rejectionReason` were ever added to that list. No change needed today; this is a regression-guard note for reviewers.

### `get()` cost note

`isModerator()` only fires on the read-gate's fallback branch (when `status != 'approved'` AND the caller is not the author). Approved-post reads short-circuit the first clause and skip the `get()`. So the per-read cost is bounded by moderator browsing, not feed traffic.

---

## Firestore index addition — Gap #1

Append two composites to `firestore.indexes.json`. The first powers `watchFeed` and the moderation queue. The second powers `watchPostsByCourse` once Gap #3 lands.

```json
{
  "collectionGroup": "posts",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
},
{
  "collectionGroup": "posts",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "courseId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

Deploy with:

```bash
firebase deploy --only firestore:indexes
```

Wait until both indexes show **Enabled** in the Firebase Console. The feed-filter query is already shipping on main — **any environment that doesn't have this index will hit `failed-precondition` on every feed open today**. Treat as a hot fix.

---

## Test plan

### Cloud Functions

| Test file | Covers |
|---|---|
| `functions/test/lib/moderation.test.ts` | `classifyPost` parses well-formed JSON; clamps confidence; returns fail-open verdict on Groq throw; returns fail-open on parse failure |
| `functions/test/triggers/onPostCreated.test.ts` | When `status='pending'` is present, calls classifier and writes `aiVerdict`. When `status != 'pending'`, skips classification (legacy/backfilled docs). |
| `functions/test/callable/handleModerationAction.test.ts` | Rejects unauthenticated; rejects non-moderator; rejects non-pending post; approves writes correct fields; rejects writes `rejectionReason` (trimmed to 500 chars). |

Use the existing `firebase-functions-test` pattern from `functions/test/` for trigger tests. Mock the Groq client (intercept the `groq-sdk` constructor) — do not make real LLM calls in CI.

### Firestore rules

Add `firestore-tests/posts.test.ts` (or wherever existing rules tests live — check the repo) covering:

- An unauthed reader cannot read a `status='pending'` post.
- The author can read their own pending and rejected posts.
- A non-moderator authed reader can read approved but not pending.
- A user cannot self-set `role: 'moderator'` on their `users/{uid}` doc.
- A moderator (set via Admin SDK in the test) CAN update `status` on a pending post.
- An author CANNOT update `status` on their own post directly.
- An author CANNOT write `aiVerdict` on create.

### Flutter

| Test file | Covers |
|---|---|
| `apps/mobile/test/widget/features/moderation/moderation_screen_test.dart` | Existing tests still pass against the callable-based datasource. Mock `FirebaseFunctions` via a fake; assert `httpsCallable('handleModerationAction').call(...)` is invoked with the right payload. |
| `apps/mobile/test/unit/features/moderation/pending_post_model_test.dart` | `aiVerdict.error` round-trips when present. |
| `apps/mobile/test/unit/features/post/post_firestore_datasource_test.dart` | `createPost` writes `status: 'pending'`. (If this test file doesn't exist, add it.) |

---

## Deployment order

The Flutter feed-filter change is already on main, so any environment that hasn't deployed the new index is broken **right now**. Treat steps 1–3 as a hot fix; steps 4–7 ship with the rest of SPEC-0013.

**Hot fix — unblocks current main:**

1. **Build & deploy the new indexes** (Gap #1):
   ```bash
   firebase deploy --only firestore:indexes
   ```
   Wait for both `posts: status + createdAt` and `posts: courseId + status + createdAt` to show **Enabled** in the Firebase Console.
2. **Run the backfill** so legacy posts (created before `status: 'pending'` shipped) stay visible:
   ```bash
   cd tools && node backfill_post_status.js service-account.json
   ```
3. **Deploy the rules update** that adds Gap #2 (lock `role`) and Gap #4 (block client `aiVerdict` on create):
   ```bash
   firebase deploy --only firestore:rules
   ```

**Feature deploy — Gaps #5 and #6:**

4. **Set the Groq secret** once per environment:
   ```bash
   firebase functions:secrets:set GROQ_API_KEY
   ```
5. **Deploy functions** (trigger now writes `aiVerdict`, callable available):
   ```bash
   cd functions && npm run deploy
   ```
6. **Ship the Flutter build** with the `cloud_functions` dependency, the new `Post` entity fields, the moderation datasource swap to the callable, and the `watchPostsByCourse` filter (Gap #3).
7. **Assign moderator role** to test users by manually editing `users/{uid}.role` in the Firebase Console (the rule from step 3 blocks all other paths).

Rollback: revert step 6 first (clients stop calling the callable), then 5, then 3. Backfill (step 2) is non-reversible but harmless. Step 1's indexes can be left in place.

---

## Out of scope

- Push / in-app notification to the author on rejection (in-app notification only is the SPEC-0012 default; can be added later by writing a notification doc from the callable's reject branch).
- Appeals flow for rejected authors.
- Bulk approve/reject actions.
- Moderation history / audit log screen.
- Showing the AI verdict to the post author.
- Background re-screening of already-approved posts when the prompt changes.
- Multilingual moderation prompt — Groq llama-3.3 handles English well; other languages are best-effort until evaluated.

---

## Open questions

- [ ] **Fail-open vs fail-closed on AI failure.** Spec currently fails open (recommends approve, confidence 0, error field set). Argument for fail-closed: rejecting on AI error preserves safety but creates a moderator-overhead spike during outages. Argument for fail-open: AI is advisory; humans approve anyway. **Default: fail-open.** Revisit if we ever auto-approve on high-confidence AI verdicts.
- [ ] **Auto-approve threshold.** Should we auto-approve a post if `aiVerdict.recommended == 'approve'` AND `confidence >= 0.95`? Out of scope for this spec — would require adding a confidence-tuning telemetry path first.
- [ ] **`role` enum.** Currently we only check `role == 'moderator'`. If more roles emerge (e.g. `admin`, `verified`), generalize `isModerator()` into `hasRole(...)`.
- [ ] **Token cost monitoring.** Add a Groq usage counter on the trigger and surface in the existing billing dashboard? Defer until we see real volume.

---

## Acceptance criteria

The feature is shippable when all of the following are observable in a staging Firebase project:

1. A post created from the app appears in `posts/{id}` with `status: 'pending'` and is **not** visible on the feed for any user (including the author seeing it on the public feed query — but they DO see it on `watchPostsByAuthor`).
2. Within ~10s of creation, `posts/{id}.aiVerdict` is populated with `recommended`, `confidence`, `reason`, `processedAt`.
3. A user with `users/{uid}.role == 'moderator'` sees the post in the Moderation queue with the AI verdict badge.
4. Approve via the moderation screen → post becomes visible on the feed, `moderatedBy`/`moderatedAt` set.
5. Reject via the moderation screen → post does NOT become visible, `rejectionReason` set.
6. A non-moderator user calling `handleModerationAction` directly via the Firebase SDK receives `permission-denied`.
7. A user attempting to write `role: 'moderator'` to their own `users/{uid}` doc receives `permission-denied`.
8. A user attempting to write `aiVerdict` directly to their post receives `permission-denied`.
9. Existing posts created before deployment remain visible on the feed (backfill verified).
