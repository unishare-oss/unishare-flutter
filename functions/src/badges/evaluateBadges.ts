import { logger } from 'firebase-functions/v2';

import { FieldValue, db } from '../admin';
import { findNewlyEarnedBadges } from './findNewlyEarnedBadges';
import { grantBadgeNotification } from './grantNotification';
import { levelForPoints } from './levelForPoints';
import { EMPTY_STATS, statValue, type BadgeDoc, type LevelConfig, type StatKey, type UserStats } from './types';

export interface EvalResult {
  newlyEarnedIds: string[];
  pointsAdded: number;
  newLevel: number;
}

const DEFAULT_LEVEL_CONFIG: LevelConfig = {
  thresholds: [{ level: 1, cumulative: 0 }],
  perLevelAbove10: 500,
};

/**
 * Evaluates the badge catalog against a user's current stats and grants any
 * newly-earned badges atomically. Targeted: only checks badges whose
 * `condition.type` matches a key that just changed.
 *
 * Concurrency: the user doc is read INSIDE the transaction so concurrent
 * trigger invocations for the same user can't clobber each other's
 * `totalPoints`/`level` updates. The candidate badge catalog and level
 * config are read outside the transaction since they're read-mostly and
 * cheap to refetch on retry.
 *
 * Server-only — caller must be a Cloud Function trigger or the integrity
 * sweep. Firestore rules deny client writes to all paths touched here.
 */
export async function evaluateBadges(
  uid: string,
  changedStatKeys: StatKey[],
): Promise<EvalResult> {
  if (changedStatKeys.length === 0) {
    const u = await db.doc(`users/${uid}`).get();
    return {
      newlyEarnedIds: [],
      pointsAdded: 0,
      newLevel: (u.data()?.gamification?.level as number | undefined) ?? 1,
    };
  }

  // Read-mostly references — fetched outside the transaction. The badge
  // catalog rarely changes; level config is a single doc.
  const [badgesSnap, levelsSnap] = await Promise.all([
    db.collection('badges')
      .where('active', '==', true)
      .where('condition.type', 'in', changedStatKeys)
      .get(),
    db.doc('app_config/levels').get(),
  ]);

  const candidates: BadgeDoc[] = badgesSnap.docs.map(d => d.data() as BadgeDoc);
  const levelConfig: LevelConfig = (levelsSnap.data() as LevelConfig | undefined) ?? DEFAULT_LEVEL_CONFIG;

  if (candidates.length === 0) {
    const u = await db.doc(`users/${uid}`).get();
    return {
      newlyEarnedIds: [],
      pointsAdded: 0,
      newLevel: levelForPoints(
        (u.data()?.gamification?.totalPoints as number | undefined) ?? 0,
        levelConfig,
      ),
    };
  }

  const userRef = db.doc(`users/${uid}`);
  const result = await db.runTransaction(async tx => {
    const userSnap = await tx.get(userRef);
    const userData = userSnap.data() ?? {};
    const stats: UserStats = { ...EMPTY_STATS, ...((userData.stats as Partial<UserStats>) ?? {}) };
    const currentPoints: number = (userData.gamification?.totalPoints as number | undefined) ?? 0;
    // `earnedBadgesCache` is the mirror maintained by this evaluator on
    // every grant. Using it avoids a full subcollection read every trigger.
    const earnedIds = new Set<string>(
      (userData.gamification?.earnedBadgesCache as string[] | undefined) ?? [],
    );

    const newlyEarned = findNewlyEarnedBadges(stats, candidates, earnedIds);

    if (newlyEarned.length === 0) {
      return {
        newlyEarnedIds: [] as string[],
        pointsAdded: 0,
        newLevel: levelForPoints(currentPoints, levelConfig),
        newlyEarned: [] as BadgeDoc[],
        stats,
      };
    }

    const pointsAdded = newlyEarned.reduce((s, b) => s + b.points, 0);
    const newTotal = currentPoints + pointsAdded;
    const newLevel = levelForPoints(newTotal, levelConfig);

    for (const b of newlyEarned) {
      tx.set(userRef.collection('earnedBadges').doc(b.id), {
        badgeId: b.id,
        earnedAt: FieldValue.serverTimestamp(),
        pointsAwarded: b.points,
        snapshot: { value: statValue(stats, b.condition.type), threshold: b.condition.threshold },
      });
    }
    tx.update(userRef, {
      'gamification.totalPoints': newTotal,
      'gamification.level': newLevel,
      'gamification.earnedBadgesCache': FieldValue.arrayUnion(...newlyEarned.map(b => b.id)),
    });

    return {
      newlyEarnedIds: newlyEarned.map(b => b.id),
      pointsAdded,
      newLevel,
      newlyEarned,
      stats,
    };
  });

  if (result.newlyEarned.length > 0) {
    // Notifications are fire-and-forget after the grant transaction
    // commits. If any send fails, the badge stays earned; v1.1 will move
    // dispatch into an `onDocumentCreated(earnedBadges)` trigger for
    // retry-safety.
    await Promise.all(result.newlyEarned.map(b => grantBadgeNotification(uid, b)));
    logger.info('badges granted', {
      uid,
      ids: result.newlyEarnedIds,
      pointsAdded: result.pointsAdded,
      newLevel: result.newLevel,
    });
  }

  return {
    newlyEarnedIds: result.newlyEarnedIds,
    pointsAdded: result.pointsAdded,
    newLevel: result.newLevel,
  };
}
