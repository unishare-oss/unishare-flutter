import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';

import { Timestamp, db } from '../admin';
import { NOTIFICATION_RETENTION_DAYS } from '../config';

const MS_PER_DAY = 24 * 60 * 60 * 1000;
const BATCH_LIMIT = 400;

/**
 * Daily sweep that deletes notification documents older than the retention
 * window (default 30 days). Runs as a scheduled Cloud Function and uses a
 * collection-group query so it picks up every `users/{uid}/notifications`
 * subcollection in one pass.
 *
 * Batches deletes 400 at a time to stay safely under the 500 Firestore
 * write-batch ceiling, and loops until no more old documents remain.
 */
export const purgeOldNotifications = onSchedule(
  {
    schedule: 'every 24 hours',
    timeZone: 'UTC',
  },
  async () => {
    const cutoffMs = Date.now() - NOTIFICATION_RETENTION_DAYS * MS_PER_DAY;
    const cutoff = Timestamp.fromMillis(cutoffMs);

    let totalDeleted = 0;

    for (;;) {
      const snap = await db
        .collectionGroup('notifications')
        .where('createdAt', '<', cutoff)
        .limit(BATCH_LIMIT)
        .get();

      if (snap.empty) break;

      const batch = db.batch();
      snap.docs.forEach((d) => batch.delete(d.ref));
      await batch.commit();
      totalDeleted += snap.size;

      if (snap.size < BATCH_LIMIT) break;
    }

    logger.info('purgeOldNotifications complete', {
      retentionDays: NOTIFICATION_RETENTION_DAYS,
      cutoff: cutoff.toDate().toISOString(),
      totalDeleted,
    });
  },
);
