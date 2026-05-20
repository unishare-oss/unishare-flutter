import { logger } from 'firebase-functions/v2';

import { FieldValue, db } from '../admin';
import type { NotificationPayload } from './types';

/**
 * Writes one notification document to `users/{recipientUid}/notifications/{auto-id}`.
 *
 * Returns the new notification doc ID, which the caller forwards in the FCM
 * data payload so client tap-handling can mark-as-read on open.
 */
export async function writeNotification(
  recipientUid: string,
  payload: NotificationPayload,
): Promise<string> {
  const docRef = db.collection('users').doc(recipientUid).collection('notifications').doc();

  await docRef.set({
    id: docRef.id,
    type: payload.type,
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
    title: payload.title,
    body: payload.body,
    actorId: payload.actorId,
    actorName: payload.actorName,
    actorPhotoUrl: payload.actorPhotoUrl,
    targetId: payload.targetId,
    targetType: payload.targetType,
    targetTitle: payload.targetTitle,
  });

  logger.info('notification written', {
    recipientUid,
    notifId: docRef.id,
    type: payload.type,
  });

  return docRef.id;
}
