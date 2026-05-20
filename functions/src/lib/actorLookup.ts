import { logger } from 'firebase-functions/v2';

import { db } from '../admin';

export interface Actor {
  name: string;
  photoUrl: string | null;
}

/**
 * Reads `users/{uid}` to denormalise the actor's display name and avatar
 * into the notification document. Falls back to "Someone" if the user
 * doc is missing or the fields are absent — the notification still
 * delivers, just with a generic actor.
 */
export async function getActor(uid: string): Promise<Actor> {
  try {
    const snap = await db.collection('users').doc(uid).get();
    const data = snap.data();
    if (!data) {
      return { name: 'Someone', photoUrl: null };
    }
    const name =
      (data.displayName as string | undefined) ??
      (data.name as string | undefined) ??
      'Someone';
    const photoUrl =
      (data.photoUrl as string | undefined) ??
      (data.photoURL as string | undefined) ??
      null;
    return { name, photoUrl };
  } catch (e) {
    logger.warn('actor lookup failed', { uid, err: (e as Error).message });
    return { name: 'Someone', photoUrl: null };
  }
}
