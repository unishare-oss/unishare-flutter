import {
  onDocumentUpdated,
  type FirestoreEvent,
  type Change,
  type QueryDocumentSnapshot,
} from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { defineSecret, defineString } from 'firebase-functions/params';

import { db, FieldValue } from '../admin';

/// SPEC-0013 — AI moderation (advisory).
///
/// The AI never mutates `status`; a human moderator still approves/rejects via
/// `handleModerationAction`. This trigger only writes the advisory `aiVerdict`
/// onto the post, which the moderation queue surfaces as a hint. `aiVerdict` is
/// a client-locked field in firestore.rules — only this admin-privileged
/// trigger can write it, which is exactly why the rule can stay locked.
///
/// It fires on the edge where the summarize pipeline first *settles* (the post
/// goes pending → done/flagged/...), so the classifier can judge the actual
/// extracted document content rather than author-supplied metadata alone.
export const MODERATION_WORKER_KEY = defineSecret('MODERATION_WORKER_KEY');
export const WORKER_URL = defineString('WORKER_URL');

/// summaryStatus values that mean the summarize pipeline has finished reading
/// the file. createPost seeds `pending`; summarize writes one of these.
const SETTLED_SUMMARY_STATES = new Set([
  'done',
  'flagged',
  'unsupported_type',
  'error',
]);

const FLAGGED_REASON =
  'Flagged as inappropriate during automated content analysis.';

export interface AiVerdict {
  recommended: 'approve' | 'reject';
  confidence: number;
  reason: string;
}

interface PostShape {
  title?: string;
  description?: string;
  tags?: unknown;
  postType?: string;
  status?: string;
  summaryStatus?: string;
  extractedText?: string;
  aiVerdict?: unknown;
}

interface ModerationDeps {
  /** Calls the worker classifier. Throws on transport/HTTP failure. */
  moderate: (input: {
    title: string;
    description: string;
    tags: string[];
    postType: string;
    extractedText: string;
  }) => Promise<AiVerdict>;
  /** Persists the verdict onto the post (admin write, bypasses rules). */
  writeVerdict: (postId: string, verdict: AiVerdict) => Promise<void>;
}

/// Fail-open verdict — recommend approve at zero confidence so the post falls
/// through to a human moderator instead of being silently rejected when the
/// classifier is unreachable.
function deferToHuman(reason: string): AiVerdict {
  return { recommended: 'approve', confidence: 0, reason };
}

export async function onPostUpdatedHandler(
  postId: string,
  before: PostShape | undefined,
  after: PostShape | undefined,
  deps: ModerationDeps,
): Promise<void> {
  if (!after) return;

  // Only act on the single edge where summarize first settles. This also
  // makes the trigger ignore its own aiVerdict write, human moderation writes
  // (status/moderatedBy), and likesCount bumps — none of which touch
  // summaryStatus, so before/after stay equally (un)settled.
  const beforeSettled = SETTLED_SUMMARY_STATES.has(before?.summaryStatus ?? '');
  const afterSettled = SETTLED_SUMMARY_STATES.has(after.summaryStatus ?? '');
  if (!afterSettled || beforeSettled) return;

  // Idempotency + don't override a decision a human already made.
  if (after.aiVerdict != null) return;
  if (after.status !== 'pending') return;

  // Fast path: the content-aware summarizer already judged the file harmful.
  // Trust that directly instead of paying for a second model call.
  if (after.summaryStatus === 'flagged') {
    await deps.writeVerdict(postId, {
      recommended: 'reject',
      confidence: 0.9,
      reason: FLAGGED_REASON,
    });
    logger.info('moderation verdict written (flagged shortcut)', { postId });
    return;
  }

  const tags = Array.isArray(after.tags)
    ? after.tags.filter((t): t is string => typeof t === 'string')
    : [];

  let verdict: AiVerdict;
  try {
    verdict = await deps.moderate({
      title: after.title ?? '',
      description: after.description ?? '',
      tags,
      postType: after.postType ?? '',
      extractedText: after.extractedText ?? '',
    });
  } catch (e) {
    logger.error('moderation: worker call failed', {
      postId,
      error: (e as Error).message,
    });
    verdict = deferToHuman('AI unavailable — defer to human moderator');
  }

  await deps.writeVerdict(postId, verdict);
  logger.info('moderation verdict written', {
    postId,
    recommended: verdict.recommended,
    confidence: verdict.confidence,
  });
}

async function callWorkerModerate(input: {
  title: string;
  description: string;
  tags: string[];
  postType: string;
  extractedText: string;
}): Promise<AiVerdict> {
  const base = WORKER_URL.value();
  if (!base) throw new Error('WORKER_URL not configured');

  const res = await fetch(`${base}/ai/moderate`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Internal-Key': MODERATION_WORKER_KEY.value(),
    },
    body: JSON.stringify(input),
  });
  if (!res.ok) {
    throw new Error(`worker responded ${res.status}`);
  }
  const data = (await res.json()) as Record<string, unknown>;
  const recommended = data.recommended === 'reject' ? 'reject' : 'approve';
  const rawConf = typeof data.confidence === 'number' ? data.confidence : 0;
  return {
    recommended,
    confidence: Math.max(0, Math.min(1, rawConf)),
    reason: typeof data.reason === 'string' ? data.reason : 'No reason provided',
  };
}

async function persistVerdict(postId: string, verdict: AiVerdict): Promise<void> {
  await db.collection('posts').doc(postId).update({
    aiVerdict: {
      recommended: verdict.recommended,
      confidence: verdict.confidence,
      reason: verdict.reason,
      processedAt: FieldValue.serverTimestamp(),
    },
  });
}

export const onPostUpdated = onDocumentUpdated(
  { document: 'posts/{postId}', secrets: [MODERATION_WORKER_KEY] },
  async (
    event: FirestoreEvent<
      Change<QueryDocumentSnapshot> | undefined,
      { postId: string }
    >,
  ) => {
    const change = event.data;
    if (!change) return;
    await onPostUpdatedHandler(
      event.params.postId,
      change.before.data() as PostShape,
      change.after.data() as PostShape,
      { moderate: callWorkerModerate, writeVerdict: persistVerdict },
    );
  },
);
