import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db, FieldValue } from '../admin';
import { canModerate } from '../lib/roles';

interface ApproveInput {
  postId: string;
  action: 'approve';
}
interface RejectInput {
  postId: string;
  action: 'reject';
  reason: string;
}
interface RestoreInput {
  postId: string;
  action: 'restore';
}
type Input = ApproveInput | RejectInput | RestoreInput;

const MAX_REASON_LEN = 500;

export interface ModerationActionDeps {
  /** Resolves the caller's role for the moderator gate. */
  getCallerRole: (uid: string) => Promise<unknown>;
  /** Returns the post's current status, or null when the post is missing. */
  getPost: (postId: string) => Promise<{ status?: string } | null>;
  /** Applies the field update (admin write, bypasses rules). */
  applyUpdate: (
    postId: string,
    update: Record<string, unknown>,
  ) => Promise<void>;
}

/**
 * Pure handler — validation, the moderator gate, and the status transition,
 * with I/O injected via {@link ModerationActionDeps} so it's unit-testable.
 *
 * approve/reject act on a `pending` post; restore reverses a `rejected` post
 * back to `pending` (dropping the prior decision) for re-review.
 */
export async function handleModerationActionHandler(
  uid: string | undefined,
  data: Input | undefined,
  deps: ModerationActionDeps,
): Promise<{ ok: true }> {
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required');

  const { postId, action } = data ?? ({} as Input);

  if (typeof postId !== 'string' || postId.length === 0) {
    throw new HttpsError('invalid-argument', 'postId required');
  }
  if (action !== 'approve' && action !== 'reject' && action !== 'restore') {
    throw new HttpsError(
      'invalid-argument',
      'action must be approve|reject|restore',
    );
  }

  if (!canModerate(await deps.getCallerRole(uid))) {
    logger.warn('moderation action denied — not a moderator', { uid, postId });
    throw new HttpsError('permission-denied', 'Moderator or admin role required');
  }

  const post = await deps.getPost(postId);
  if (!post) throw new HttpsError('not-found', 'Post not found');

  const currentStatus = post.status;
  const required = action === 'restore' ? 'rejected' : 'pending';
  if (currentStatus !== required) {
    throw new HttpsError(
      'failed-precondition',
      `Post is not ${required} (status=${currentStatus})`,
    );
  }

  let update: Record<string, unknown>;
  if (action === 'restore') {
    // Back to pending; drop the prior decision so it re-enters the queue
    // clean. The original aiVerdict is kept as the screening record.
    update = {
      status: 'pending',
      moderatedBy: FieldValue.delete(),
      moderatedAt: FieldValue.delete(),
      rejectionReason: FieldValue.delete(),
    };
  } else {
    update = {
      status: action === 'approve' ? 'approved' : 'rejected',
      moderatedBy: uid,
      moderatedAt: FieldValue.serverTimestamp(),
    };
    if (action === 'reject') {
      const reason = (data as RejectInput).reason ?? '';
      if (typeof reason !== 'string' || reason.trim().length === 0) {
        throw new HttpsError('invalid-argument', 'reason required on reject');
      }
      update.rejectionReason = reason.trim().slice(0, MAX_REASON_LEN);
    }
  }

  await deps.applyUpdate(postId, update);
  logger.info('moderation action applied', { postId, action, uid });
  return { ok: true };
}

export const handleModerationAction = onCall<Input>((request) =>
  handleModerationActionHandler(request.auth?.uid, request.data, {
    getCallerRole: async (uid) =>
      (await db.collection('users').doc(uid).get()).data()?.role,
    getPost: async (postId) => {
      const snap = await db.collection('posts').doc(postId).get();
      return snap.exists ? { status: snap.data()?.status } : null;
    },
    applyUpdate: async (postId, update) => {
      await db.collection('posts').doc(postId).update(update);
    },
  }),
);
