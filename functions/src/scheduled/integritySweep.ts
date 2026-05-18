import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';

import { db } from '../admin';
import { evaluateBadges } from '../badges/evaluateBadges';
import type { StatKey } from '../badges/types';

const ACTIVE_WINDOW_MS = 24 * 60 * 60 * 1000;

/**
 * Daily belt-and-braces job that recomputes a subset of user stat counters
 * from source-of-truth queries, writes corrections, and re-runs the badge
 * evaluator against drifted keys. Targets only users active in the last
 * 24h to keep cost bounded.
 *
 * Only counters that can be recomputed cheaply via Firestore aggregation
 * queries are covered: postsCreated, commentsWritten, requestsCreated,
 * uniqueSaversCount. The remaining counters (savesReceived, savesGiven,
 * requestsFulfilled, postsWithAtLeastOneSave) rely on their respective
 * triggers as the authoritative source.
 */
export const integritySweep = onSchedule(
  {
    schedule: '0 3 * * *',
    timeZone: 'Asia/Bangkok',
  },
  async () => {
    const cutoff = new Date(Date.now() - ACTIVE_WINDOW_MS);
    const active = await db
      .collection('users')
      .where('stats.updatedAt', '>=', cutoff)
      .get();

    let inspected = 0;
    let driftedUsers = 0;

    for (const userDoc of active.docs) {
      inspected += 1;
      const uid = userDoc.id;
      const stored = (userDoc.data().stats ?? {}) as Record<string, number | undefined>;

      const [posts, comments, requestsCreated, uniqueSavers] = await Promise.all([
        db.collection('posts').where('authorId', '==', uid).count().get(),
        db.collectionGroup('comments').where('authorId', '==', uid).count().get(),
        db.collection('requests').where('requesterId', '==', uid).count().get(),
        db.collection(`users/${uid}/uniqueSavers`).count().get(),
      ]);

      const truth: Record<string, number> = {
        postsCreated: posts.data().count,
        commentsWritten: comments.data().count,
        requestsCreated: requestsCreated.data().count,
        uniqueSaversCount: uniqueSavers.data().count,
      };

      const drifted: StatKey[] = [];
      const fixes: Record<string, number> = {};
      for (const [k, v] of Object.entries(truth)) {
        if ((stored[k] ?? 0) !== v) {
          drifted.push(k as StatKey);
          fixes[`stats.${k}`] = v;
        }
      }

      if (drifted.length === 0) continue;
      driftedUsers += 1;
      logger.warn('counter drift detected', { uid, drifted, fixes });
      await db.doc(`users/${uid}`).update(fixes);
      await evaluateBadges(uid, drifted);
    }

    logger.info('integritySweep complete', { inspected, driftedUsers });
  },
);
