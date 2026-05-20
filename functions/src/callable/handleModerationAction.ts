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

  const data = request.data ?? ({} as Input);
  const { postId, action } = data;

  if (typeof postId !== 'string' || postId.length === 0) {
    throw new HttpsError('invalid-argument', 'postId required');
  }
  if (action !== 'approve' && action !== 'reject') {
    throw new HttpsError('invalid-argument', 'action must be approve|reject');
  }

  const userSnap = await db.collection('users').doc(uid).get();
  if (userSnap.data()?.role !== 'moderator') {
    logger.warn('moderation action denied — not a moderator', { uid, postId });
    throw new HttpsError('permission-denied', 'Moderator role required');
  }

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
    const reason = (data as RejectInput).reason ?? '';
    if (typeof reason !== 'string' || reason.trim().length === 0) {
      throw new HttpsError('invalid-argument', 'reason required on reject');
    }
    update.rejectionReason = reason.trim().slice(0, MAX_REASON_LEN);
  }

  await postRef.update(update);
  logger.info('moderation action applied', { postId, action, uid });
  return { ok: true };
});
