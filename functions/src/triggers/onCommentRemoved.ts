import { onDocumentDeleted, type FirestoreEvent, type QueryDocumentSnapshot } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { incrementStat } from '../badges/counters';
import type { CommentDoc } from '../lib/types';

export async function onCommentRemovedHandler(comment: CommentDoc | undefined): Promise<void> {
  if (!comment?.authorId) {
    logger.warn('onCommentRemoved skipped — no authorId');
    return;
  }
  await incrementStat(comment.authorId, 'commentsWritten', -1);
}

export const onCommentRemoved = onDocumentDeleted(
  'posts/{postId}/comments/{commentId}',
  async (event: FirestoreEvent<QueryDocumentSnapshot | undefined, { postId: string; commentId: string }>) => {
    const snap = event.data;
    if (!snap) return;
    await onCommentRemovedHandler(snap.data() as CommentDoc);
  },
);
