import { FieldValue, db } from '../admin';
import type { StatKey } from './types';

/** Stat keys that store a numeric counter at `users/{uid}.stats.<key>`. */
type CounterKey = Exclude<StatKey, 'profileCompleted' | 'uniqueDepartmentsCount'>;

/**
 * Atomically adjusts a single numeric stat counter on the user doc.
 * Uses Firestore FieldValue.increment so concurrent writes don't clobber.
 */
export async function incrementStat(
  uid: string,
  key: CounterKey,
  delta: number = 1,
): Promise<void> {
  await db.doc(`users/${uid}`).set({
    stats: {
      [key]: FieldValue.increment(delta),
      updatedAt: FieldValue.serverTimestamp(),
    },
  }, { merge: true });
}

/**
 * Adds a department id to `users/{uid}.stats.uniqueDepartmentsContributed`
 * iff it isn't already present. Returns true when the array grew.
 */
export async function addUniqueDepartment(
  uid: string,
  departmentId: string,
): Promise<boolean> {
  const ref = db.doc(`users/${uid}`);
  return db.runTransaction(async tx => {
    const snap = await tx.get(ref);
    const arr: string[] = (snap.data()?.stats?.uniqueDepartmentsContributed as string[] | undefined) ?? [];
    if (arr.includes(departmentId)) return false;
    tx.set(ref, {
      stats: {
        uniqueDepartmentsContributed: FieldValue.arrayUnion(departmentId),
        updatedAt: FieldValue.serverTimestamp(),
      },
    }, { merge: true });
    return true;
  });
}

/** Sets the boolean `users/{uid}.stats.profileCompleted` flag. */
export async function setProfileCompleted(uid: string, completed: boolean): Promise<void> {
  await db.doc(`users/${uid}`).set({
    stats: {
      profileCompleted: completed,
      updatedAt: FieldValue.serverTimestamp(),
    },
  }, { merge: true });
}
