import { logger } from 'firebase-functions/v2';

import { db, messaging } from '../admin';
import type { FcmTokenDoc } from './types';

/**
 * Reads every FCM token for `recipientUid` and fans out a multicast push.
 * Stale tokens (rejected with `messaging/registration-token-not-registered`
 * or `messaging/invalid-registration-token`) are deleted from Firestore.
 *
 * Silent no-op when the recipient has no registered tokens.
 */
export async function sendPush(
  recipientUid: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<void> {
  const tokensSnap = await db
    .collection('users')
    .doc(recipientUid)
    .collection('fcmTokens')
    .get();

  if (tokensSnap.empty) {
    logger.info('no fcm tokens for recipient', { recipientUid });
    return;
  }

  const tokenDocs = tokensSnap.docs.map((d) => ({
    ref: d.ref,
    data: d.data() as FcmTokenDoc,
  }));
  const tokens = tokenDocs.map((t) => t.data.token);

  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'default' } } },
  });

  logger.info('fcm multicast sent', {
    recipientUid,
    successCount: response.successCount,
    failureCount: response.failureCount,
  });

  const stalePruneOps: Promise<unknown>[] = [];
  response.responses.forEach((res, i) => {
    if (res.success) return;
    const code = res.error?.code;
    if (
      code === 'messaging/registration-token-not-registered' ||
      code === 'messaging/invalid-registration-token' ||
      code === 'messaging/invalid-argument'
    ) {
      stalePruneOps.push(tokenDocs[i].ref.delete());
    } else {
      logger.warn('fcm send failed (kept token)', {
        recipientUid,
        code,
        message: res.error?.message,
      });
    }
  });

  if (stalePruneOps.length > 0) {
    await Promise.all(stalePruneOps);
    logger.info('stale tokens pruned', { recipientUid, pruned: stalePruneOps.length });
  }
}
