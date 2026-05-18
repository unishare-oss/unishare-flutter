import { onDocumentCreated, type FirestoreEvent, type QueryDocumentSnapshot } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { incrementStat, addUniqueDepartment } from '../badges/counters';
import { evaluateBadges } from '../badges/evaluateBadges';
import type { StatKey } from '../badges/types';

interface PostCreatedData {
  authorId?: string;
  departmentId?: string;
}

/**
 * Extracted handler — increments postsCreated, adds the department to the
 * unique-departments set (if new), then runs the badge evaluator against
 * the keys that just changed.
 *
 * Exported for unit-testing in isolation. The wrapped trigger below
 * delegates here.
 */
export async function onPostCreatedHandler(
  postId: string,
  post: PostCreatedData,
): Promise<void> {
  if (!post.authorId) {
    logger.warn('onPostCreated skipped — no authorId', { postId });
    return;
  }
  const changed: StatKey[] = ['postsCreated'];
  await incrementStat(post.authorId, 'postsCreated', 1);
  if (post.departmentId) {
    const added = await addUniqueDepartment(post.authorId, post.departmentId);
    if (added) changed.push('uniqueDepartmentsCount');
  }
  await evaluateBadges(post.authorId, changed);
}

export const onPostCreated = onDocumentCreated(
  'posts/{postId}',
  async (event: FirestoreEvent<QueryDocumentSnapshot | undefined, { postId: string }>) => {
    const snap = event.data;
    if (!snap) return;
    await onPostCreatedHandler(event.params.postId, snap.data() as PostCreatedData);
  },
);
