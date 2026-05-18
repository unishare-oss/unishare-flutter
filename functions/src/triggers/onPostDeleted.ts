import { onDocumentDeleted, type FirestoreEvent, type QueryDocumentSnapshot } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { incrementStat } from '../badges/counters';

interface PostData {
  authorId?: string;
}

export async function onPostDeletedHandler(post: PostData): Promise<void> {
  if (!post.authorId) {
    logger.warn('onPostDeleted skipped — no authorId');
    return;
  }
  await incrementStat(post.authorId, 'postsCreated', -1);
}

export const onPostDeleted = onDocumentDeleted(
  'posts/{postId}',
  async (event: FirestoreEvent<QueryDocumentSnapshot | undefined, { postId: string }>) => {
    const snap = event.data;
    if (!snap) return;
    await onPostDeletedHandler(snap.data() as PostData);
  },
);
