import { onDocumentDeleted, type FirestoreEvent, type QueryDocumentSnapshot } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { FieldValue, db } from '../admin';
import { incrementStat } from '../badges/counters';

export async function onPostUnsavedHandler(postId: string, saverUid: string): Promise<void> {
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
  // uniqueSavers presence doc + uniqueSaversCount stay — high-water mark by design.
}

export const onPostUnsaved = onDocumentDeleted(
  'posts/{postId}/saves/{saverUid}',
  async (event: FirestoreEvent<QueryDocumentSnapshot | undefined, { postId: string; saverUid: string }>) => {
    await onPostUnsavedHandler(event.params.postId, event.params.saverUid);
  },
);
