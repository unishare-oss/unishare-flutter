import { onDocumentCreated, type FirestoreEvent, type QueryDocumentSnapshot } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { FieldValue, db } from '../admin';
import { incrementStat } from '../badges/counters';
import { evaluateBadges } from '../badges/evaluateBadges';
import type { StatKey } from '../badges/types';

/**
 * Fires when a user saves a post — `users/{saverUid}/savedPosts/{postId}` onCreate.
 * Updates author counters (savesReceived, uniqueSaversCount when new, and
 * postsWithAtLeastOneSave when this is the post's first save) plus the
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

  // First-save-on-this-post check — `saveCount` transitions 0 → 1. The
  // field is server-maintained; clients neither read nor write it.
  const wasFirstSaveOnPost = await db.runTransaction(async tx => {
    const ref = db.doc(`posts/${postId}`);
    const snap = await tx.get(ref);
    const cur: number = (snap.data()?.saveCount as number | undefined) ?? 0;
    tx.update(ref, { saveCount: FieldValue.increment(1) });
    return cur === 0;
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
