import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { db } from '../admin';
import { writeNotification } from '../lib/writeNotification';
import { sendPush } from '../lib/sendPush';
import { getActor } from '../lib/actorLookup';
import type { RequestDoc } from '../lib/types';

/**
 * Fires when a user upvotes a request. The upvote document ID is the
 * voter's UID. Notifies the requester. Skips self-upvotes.
 */
export async function onRequestUpvotedHandler(event: {
  params: Record<string, string>;
}): Promise<void> {
  const { requestId, userId: actorId } = event.params as {
    requestId: string;
    userId: string;
  };

  const reqSnap = await db.collection('requests').doc(requestId).get();
  const request = reqSnap.data() as RequestDoc | undefined;
  if (!request) {
    logger.warn('onRequestUpvoted: request not found', { requestId });
    return;
  }

  if (actorId === request.requesterId) {
    return;
  }

  const actor = await getActor(actorId);

  const title = 'Someone upvoted your request';
  const body = `${actor.name} upvoted "${request.title}"`;

  const notifId = await writeNotification(request.requesterId, {
    type: 'request_upvoted',
    title,
    body,
    actorId,
    actorName: actor.name,
    actorPhotoUrl: actor.photoUrl,
    targetId: requestId,
    targetType: 'request',
    targetTitle: request.title,
  });

  await sendPush(request.requesterId, title, body, {
    notificationId: notifId,
    targetType: 'request',
    targetId: requestId,
  });
}

export const onRequestUpvoted = onDocumentCreated(
  'requests/{requestId}/upvotes/{userId}',
  onRequestUpvotedHandler,
);
