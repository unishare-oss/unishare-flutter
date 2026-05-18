import { onDocumentCreated, type FirestoreEvent, type QueryDocumentSnapshot } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { FieldValue, db } from '../admin';
import { incrementStat } from '../badges/counters';
import { evaluateBadges } from '../badges/evaluateBadges';
import type { StatKey } from '../badges/types';

/**
 * Fires when a user saves a post — `users/{saverUid}/savedPosts/{postId}` onCreate.
 * Updates author counters (savesReceived, uniqueSaversCount when new, and
 * postsWithAtLeastOneSave when this is the post's FIRST EVER save) plus the
 * saver's savesGiven. Self-saves throw — Firestore rules already reject
 * them at the doc-create boundary, this is defense in depth.
 */
export async function onPostSavedHandler(saverUid: string, postId: string): Promise<void> {
  const postSnap = await db.doc(`posts/${postId}`).get();
  const authorUid: string | undefined = postSnap.data()?.authorId;
  if (!authorUid) {
    logger.warn('onPostSaved skipped — post has no authorId', { postId });
    return;
  }
  if (authorUid === saverUid) {
    throw new Error(`self-save not permitted (post=${postId}, uid=${saverUid})`);
  }

  // First-unique-saver check, transactional to avoid double-counting under
  // concurrent saves from the same user.
  const wasFirstUniqueSaver = await db.runTransaction(async tx => {
    const ref = db.doc(`users/${authorUid}/uniqueSavers/${saverUid}`);
    const existing = await tx.get(ref);
    if (existing.exists) return false;
    tx.set(ref, { savedAt: FieldValue.serverTimestamp() });
    return true;
  });

  // Monotonic first-save marker. We can't rely on `saveCount` 0→1 because
  // unsaves decrement it, so a post that returns to 0 saves and is saved
  // again would falsely count as "first save" a second time. The
  // `hasEverBeenSaved` flag is set exactly once and never cleared.
  const wasFirstSaveOnPost = await db.runTransaction(async tx => {
    const ref = db.doc(`posts/${postId}`);
    const snap = await tx.get(ref);
    const data = snap.data() ?? {};
    const alreadyMarked = (data.hasEverBeenSaved as boolean | undefined) === true;
    tx.update(ref, {
      saveCount: FieldValue.increment(1),
      ...(alreadyMarked ? {} : { hasEverBeenSaved: true }),
    });
    return !alreadyMarked;
  });

  const changedAuthor: StatKey[] = ['savesReceived'];
  await incrementStat(authorUid, 'savesReceived', 1);
  if (wasFirstUniqueSaver) {
    await incrementStat(authorUid, 'uniqueSaversCount', 1);
    changedAuthor.push('uniqueSaversCount');
  }
  if (wasFirstSaveOnPost) {
    await incrementStat(authorUid, 'postsWithAtLeastOneSave', 1);
    changedAuthor.push('postsWithAtLeastOneSave');
  }
  await evaluateBadges(authorUid, changedAuthor);

  await incrementStat(saverUid, 'savesGiven', 1);
  await evaluateBadges(saverUid, ['savesGiven']);
}

export const onPostSaved = onDocumentCreated(
  'users/{uid}/savedPosts/{postId}',
  async (event: FirestoreEvent<QueryDocumentSnapshot | undefined, { uid: string; postId: string }>) => {
    await onPostSavedHandler(event.params.uid, event.params.postId);
  },
);
