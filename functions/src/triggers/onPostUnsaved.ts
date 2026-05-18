import { onDocumentDeleted, type FirestoreEvent, type QueryDocumentSnapshot } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { FieldValue, db } from '../admin';
import { incrementStat } from '../badges/counters';

/**
 * Fires when a user un-saves a post (`users/{saverUid}/savedPosts/{postId}`
 * onDelete). Decrements savesReceived for the author and savesGiven for the
 * saver. The uniqueSavers presence document is intentionally left intact —
 * uniqueSaversCount is a monotonic high-water mark by design.
 */
export async function onPostUnsavedHandler(saverUid: string, postId: string): Promise<void> {
  const postSnap = await db.doc(`posts/${postId}`).get();
  const authorUid: string | undefined = postSnap.data()?.authorId;
  if (!authorUid) {
    logger.warn('onPostUnsaved skipped — post has no authorId', { postId });
    return;
  }
  if (authorUid === saverUid) return;

  await db.doc(`posts/${postId}`).update({ saveCount: FieldValue.increment(-1) });
  await incrementStat(authorUid, 'savesReceived', -1);
  await incrementStat(saverUid, 'savesGiven', -1);
}

export const onPostUnsaved = onDocumentDeleted(
  'users/{uid}/savedPosts/{postId}',
  async (event: FirestoreEvent<QueryDocumentSnapshot | undefined, { uid: string; postId: string }>) => {
    await onPostUnsavedHandler(event.params.uid, event.params.postId);
  },
);
