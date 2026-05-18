import { onDocumentUpdated, type FirestoreEvent, type Change, type QueryDocumentSnapshot } from 'firebase-functions/v2/firestore';

import { setProfileCompleted } from '../badges/counters';
import { evaluateBadges } from '../badges/evaluateBadges';

interface UserProfileShape {
  name?: string;
  departmentId?: string;
  enrollmentYear?: number;
  bio?: string;
  stats?: { profileCompleted?: boolean };
}

/**
 * A profile is "complete" when name, departmentId, enrollmentYear, and a
 * non-empty bio are all present. The flag only flips forward (incomplete → complete)
 * or backward (complete → incomplete) when those fields actually change; we
 * read the previous stored flag rather than recomputing both states so that
 * a single profile update doesn't repeatedly fire the evaluator.
 */
export function isProfileComplete(user: UserProfileShape): boolean {
  return Boolean(
    user.name &&
      user.departmentId &&
      user.enrollmentYear &&
      (user.bio ?? '').trim().length > 0,
  );
}

/**
 * Returns true if the relevant profile completion inputs (name, departmentId,
 * enrollmentYear, bio) are identical between [before] and [after]. Used to
 * short-circuit invocations triggered by our own server writes to
 * `stats.profileCompleted` / `stats.updatedAt`, which would otherwise
 * recompute completion only to hit the `beforeComplete === afterComplete`
 * early return.
 */
function profileInputsUnchanged(
  before: UserProfileShape | undefined,
  after: UserProfileShape,
): boolean {
  if (!before) return false;
  return before.name === after.name &&
      before.departmentId === after.departmentId &&
      before.enrollmentYear === after.enrollmentYear &&
      (before.bio ?? '') === (after.bio ?? '');
}

export async function onProfileUpdatedHandler(
  uid: string,
  before: UserProfileShape | undefined,
  after: UserProfileShape | undefined,
): Promise<void> {
  if (!after) return;
  // Skip when the change was to fields we don't care about (e.g. the
  // evaluator updating gamification, or this trigger's own stats write).
  if (profileInputsUnchanged(before, after)) return;
  const beforeComplete = before?.stats?.profileCompleted === true;
  const afterComplete = isProfileComplete(after);
  if (beforeComplete === afterComplete) return;
  await setProfileCompleted(uid, afterComplete);
  if (afterComplete) {
    await evaluateBadges(uid, ['profileCompleted']);
  }
}

export const onProfileUpdated = onDocumentUpdated(
  'users/{uid}',
  async (event: FirestoreEvent<Change<QueryDocumentSnapshot> | undefined, { uid: string }>) => {
    const change = event.data;
    if (!change) return;
    await onProfileUpdatedHandler(
      event.params.uid,
      change.before.data() as UserProfileShape,
      change.after.data() as UserProfileShape,
    );
  },
);
