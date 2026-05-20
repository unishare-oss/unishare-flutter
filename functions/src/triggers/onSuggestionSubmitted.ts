import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { db } from '../admin';
import { writeNotification } from '../lib/writeNotification';
import { sendPush } from '../lib/sendPush';
import { truncate } from '../lib/types';
import type { RequestDoc, SuggestionDoc } from '../lib/types';

/**
 * Fires when a user suggests a post in answer to a request. Notifies the
 * requester. Skips self-suggestions.
 */
export async function onSuggestionSubmittedHandler(event: {
  data: { data(): unknown } | undefined;
  params: Record<string, string>;
}): Promise<void> {
  const snap = event.data;
  if (!snap) return;
  const suggestion = snap.data() as SuggestionDoc;

  const { requestId } = event.params as { requestId: string };

  const reqSnap = await db.collection('requests').doc(requestId).get();
  const request = reqSnap.data() as RequestDoc | undefined;
  if (!request) {
    logger.warn('onSuggestionSubmitted: request not found', { requestId });
    return;
  }

  if (suggestion.suggestedByUserId === request.requesterId) {
    return;
  }

  const title = 'New suggestion on your request';
  const body = truncate(
    `${suggestion.suggestedByName} suggested "${suggestion.postTitle}"`,
  );

  const notifId = await writeNotification(request.requesterId, {
    type: 'suggestion_submitted',
    title,
    body,
    actorId: suggestion.suggestedByUserId,
    actorName: suggestion.suggestedByName,
    actorPhotoUrl: suggestion.suggestedByAvatar ?? null,
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

export const onSuggestionSubmitted = onDocumentCreated(
  'requests/{requestId}/suggestions/{suggestionId}',
  onSuggestionSubmittedHandler,
);
