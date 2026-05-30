import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';
import type {
  DocumentData,
  QueryDocumentSnapshot,
} from 'firebase-admin/firestore';

import { FieldValue, Timestamp, db } from '../admin';
import { REJECTED_MEDIA_RETENTION_DAYS } from '../config';
import { MODERATION_WORKER_KEY, WORKER_URL } from '../triggers/onPostUpdated';

const MS_PER_DAY = 24 * 60 * 60 * 1000;
const PAGE = 200;

/**
 * Daily sweep that purges R2 media for posts rejected more than
 * {@link REJECTED_MEDIA_RETENTION_DAYS} ago. Rejected posts (and their
 * attachments) otherwise persist indefinitely; this bounds storage of
 * unpublished — and potentially abusive — content while leaving an
 * appeal/resubmit window.
 *
 * Media files live in Cloudflare R2, so deletion goes through the upload
 * Worker's internal `/media/delete` endpoint (same shared secret as
 * `/ai/moderate`). After a post's files are deleted we clear `mediaUrls` /
 * `mediaTypes` and stamp `mediaPurgedAt` on the doc.
 *
 * Pages with a document cursor rather than the delete-until-empty pattern:
 * we don't delete the post docs (they stay as a rejection record), so a
 * cursor is needed to make progress. Already-purged posts re-match the query
 * on later runs but are skipped cheaply (empty `mediaUrls`, no Worker call).
 */
export const purgeRejectedPostMedia = onSchedule(
  {
    schedule: 'every 24 hours',
    timeZone: 'UTC',
    secrets: [MODERATION_WORKER_KEY],
  },
  async () => {
    const cutoff = Timestamp.fromMillis(
      Date.now() - REJECTED_MEDIA_RETENTION_DAYS * MS_PER_DAY,
    );

    const base = WORKER_URL.value();
    if (!base) {
      logger.error('purgeRejectedPostMedia: WORKER_URL not configured');
      return;
    }

    let lastDoc: QueryDocumentSnapshot<DocumentData> | undefined;
    let scanned = 0;
    let purgedPosts = 0;
    let purgedFiles = 0;
    let failures = 0;

    for (;;) {
      let query = db
        .collection('posts')
        .where('status', '==', 'rejected')
        .where('moderatedAt', '<', cutoff)
        .orderBy('moderatedAt')
        .limit(PAGE);
      if (lastDoc) query = query.startAfter(lastDoc);

      const snap = await query.get();
      if (snap.empty) break;
      scanned += snap.size;
      lastDoc = snap.docs[snap.docs.length - 1];

      for (const doc of snap.docs) {
        const urls = (doc.data().mediaUrls as unknown[] | undefined)?.filter(
          (u): u is string => typeof u === 'string',
        );
        if (!urls || urls.length === 0) continue;

        try {
          const res = await fetch(`${base}/media/delete`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-Internal-Key': MODERATION_WORKER_KEY.value(),
            },
            body: JSON.stringify({ urls }),
          });
          if (!res.ok) throw new Error(`worker responded ${res.status}`);

          await doc.ref.update({
            mediaUrls: [],
            mediaTypes: [],
            mediaPurgedAt: FieldValue.serverTimestamp(),
          });
          purgedPosts += 1;
          purgedFiles += urls.length;
        } catch (e) {
          // Leave the doc untouched so the next run retries it.
          failures += 1;
          logger.warn('purgeRejectedPostMedia: failed to purge post media', {
            postId: doc.id,
            error: (e as Error).message,
          });
        }
      }

      if (snap.size < PAGE) break;
    }

    logger.info('purgeRejectedPostMedia complete', {
      retentionDays: REJECTED_MEDIA_RETENTION_DAYS,
      cutoff: cutoff.toDate().toISOString(),
      scanned,
      purgedPosts,
      purgedFiles,
      failures,
    });
  },
);
