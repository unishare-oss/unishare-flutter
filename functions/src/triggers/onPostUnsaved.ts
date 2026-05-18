import { onDocumentDeleted, type FirestoreEvent, type QueryDocumentSnapshot } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { FieldValue, db } from '../admin';
import { incrementStat } from '../badges/counters';

/**
 * Fires when a user un-saves a post (`users/{saverUid}/savedPosts/{postId}`
 * onDelete). Decrements savesReceived for the author and savesGiven for the
 * saver. The uniqueSavers presence document and `posts/{postId}.hasEverBeenSaved`
 * are intentionally left intact — the former is a monotonic high-water mark
 * for the `uniqueSaversCount` stat, the latter is the first-save marker
 * relied on by [onPostSaved].
 */
export async function onPostUnsavedHandler(saverUid: string, postId: string): Promise<void> {
  const postRef = db.doc(`posts/${postId}`);
  const postSnap = await postRef.get();
  const authorUid: string | undefined = postSnap.data()?.authorId;
  if (!authorUid) {
    logger.warn('onPostUnsaved skipped — post has no authorId', { postId });
    return;
  }
  if (authorUid === saverUid) return;

  // Clamp at 0 transactionally so out-of-order or duplicate delete events
  // can never drive `saveCount` negative — drift there would also break
  // older clients that read it for display.
  await db.runTransaction(async tx => {
    const snap = await tx.get(postRef);
    const current = (snap.data()?.saveCount as number | undefined) ?? 0;
    if (current <= 0) return;
    tx.update(postRef, { saveCount: FieldValue.increment(-1) });
  });
  await incrementStat(authorUid, 'savesReceived', -1);
  await incrementStat(saverUid, 'savesGiven', -1);
}

export const onPostUnsaved = onDocumentDeleted(
  'users/{uid}/savedPosts/{postId}',
  async (event: FirestoreEvent<QueryDocumentSnapshot | undefined, { uid: string; postId: string }>) => {
    await onPostUnsavedHandler(event.params.uid, event.params.postId);
  },
);
