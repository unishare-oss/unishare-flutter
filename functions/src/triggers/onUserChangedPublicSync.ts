import { onDocumentUpdated, type FirestoreEvent, type Change, type QueryDocumentSnapshot } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { FieldValue, db } from '../admin';
import {
  publicUserProjection,
  publicUserProjectionsEqual,
} from '../lib/publicUserProjection';

/**
 * Mirrors the public-safe projection of `users/{uid}` into
 * `users_public/{uid}`. Public-readable per Firestore rules, so other
 * signed-in users can read names/badges/level for cross-user UI
 * (PostCard level chip, future leaderboards) without exposing private
 * fields from the main user doc.
 *
 * Diff-and-skip: the trigger fires on every `users/{uid}` write
 * (including the achievements evaluator's high-frequency
 * `gamification.totalPoints` updates), so we recompute the projection
 * for before+after and skip the write when the public-visible state
 * hasn't moved. This keeps cost bounded and prevents log noise.
 */
export async function onUserChangedPublicSyncHandler(
  uid: string,
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown> | undefined,
): Promise<void> {
  const beforeProjection = publicUserProjection(uid, before);
  const afterProjection = publicUserProjection(uid, after);

  if (publicUserProjectionsEqual(beforeProjection, afterProjection)) {
    return;
  }

  if (afterProjection === null) {
    // Profile became incomplete (rare — e.g., name cleared). Don't try to
    // expose a partial mirror; leave the previous `users_public/{uid}` in
    // place until the profile is complete again. A v1.1 follow-up could
    // delete the mirror here, but conservatism is safer for the launch.
    logger.info('public projection now null; leaving users_public unchanged', { uid });
    return;
  }

  await db.doc(`users_public/${uid}`).set(
    {
      ...afterProjection,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

export const onUserChangedPublicSync = onDocumentUpdated(
  'users/{uid}',
  async (event: FirestoreEvent<Change<QueryDocumentSnapshot> | undefined, { uid: string }>) => {
    const change = event.data;
    if (!change) return;
    await onUserChangedPublicSyncHandler(
      event.params.uid,
      change.before.data() as Record<string, unknown> | undefined,
      change.after.data() as Record<string, unknown> | undefined,
    );
  },
);
