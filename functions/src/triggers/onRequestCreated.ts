import { onDocumentCreated, type FirestoreEvent, type QueryDocumentSnapshot } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { incrementStat } from '../badges/counters';
import { evaluateBadges } from '../badges/evaluateBadges';
import type { RequestDoc } from '../lib/types';

export async function onRequestCreatedHandler(request: RequestDoc | undefined): Promise<void> {
  if (!request?.requesterId) {
    logger.warn('onRequestCreated skipped — no requesterId');
    return;
  }
  await incrementStat(request.requesterId, 'requestsCreated', 1);
  await evaluateBadges(request.requesterId, ['requestsCreated']);
}

export const onRequestCreated = onDocumentCreated(
  'requests/{requestId}',
  async (event: FirestoreEvent<QueryDocumentSnapshot | undefined, { requestId: string }>) => {
    const snap = event.data;
    if (!snap) return;
    await onRequestCreatedHandler(snap.data() as RequestDoc);
  },
);
