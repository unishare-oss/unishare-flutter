import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { db } from '../admin';
import { incrementStat } from '../badges/counters';
import { evaluateBadges } from '../badges/evaluateBadges';
import { writeNotification } from '../lib/writeNotification';
import { sendPush } from '../lib/sendPush';
import type { RequestDoc, SuggestionDoc } from '../lib/types';

/**
 * Fires when a request document is updated. Acts only when the status
 * transitions to "fulfilled" for the first time. Resolves the winning
 * suggestion by matching `fulfilledByPostId` against the suggestions
 * subcollection, then notifies the suggester whose post was chosen.
 */
export async function onRequestFulfilledHandler(event: {
  data:
    | {
        before: { data(): unknown };
        after: { data(): unknown };
      }
    | undefined;
  params: Record<string, string>;
}): Promise<void> {
  const change = event.data;
  if (!change) return;
  const before = change.before.data() as RequestDoc;
  const after = change.after.data() as RequestDoc;

  const becameFulfilled =
    before.status !== 'fulfilled' && after.status === 'fulfilled';
  if (!becameFulfilled) return;

  const { requestId } = event.params as { requestId: string };

  if (!after.fulfilledByPostId) {
    logger.warn('onRequestFulfilled: status fulfilled but no fulfilledByPostId', {
      requestId,
    });
    return;
  }

  const suggestionsSnap = await db
    .collection('requests')
    .doc(requestId)
    .collection('suggestions')
    .where('postId', '==', after.fulfilledByPostId)
    .limit(1)
    .get();

  if (suggestionsSnap.empty) {
    logger.warn('onRequestFulfilled: no matching suggestion', {
      requestId,
      fulfilledByPostId: after.fulfilledByPostId,
    });
    return;
  }

  const suggestion = suggestionsSnap.docs[0].data() as SuggestionDoc;

  if (suggestion.suggestedByUserId === after.requesterId) {
    return;
  }

  const title = 'Your suggestion was accepted';
  const body = `${after.requesterName} accepted your suggestion "${suggestion.postTitle}"`;

  const notifId = await writeNotification(suggestion.suggestedByUserId, {
    type: 'suggestion_accepted',
    title,
    body,
    actorId: after.requesterId,
    actorName: after.requesterName,
    actorPhotoUrl: after.requesterAvatar ?? null,
    targetId: requestId,
    targetType: 'request',
    targetTitle: after.title,
  });

  await sendPush(suggestion.suggestedByUserId, title, body, {
    notificationId: notifId,
    targetType: 'request',
    targetId: requestId,
  });

  // Achievements: the fulfiller earns toward requestsFulfilled.
  await incrementStat(suggestion.suggestedByUserId, 'requestsFulfilled', 1);
  await evaluateBadges(suggestion.suggestedByUserId, ['requestsFulfilled']);
}

export const onRequestFulfilled = onDocumentUpdated(
  'requests/{requestId}',
  onRequestFulfilledHandler,
);
