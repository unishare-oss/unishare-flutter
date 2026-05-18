import { logger } from 'firebase-functions/v2';

import { FieldValue, db } from '../admin';
import { findNewlyEarnedBadges } from './findNewlyEarnedBadges';
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

  const [userSnap, badgesSnap, earnedSnap, levelsSnap] = await Promise.all([
    db.doc(`users/${uid}`).get(),
    db.collection('badges')
      .where('active', '==', true)
      .where('condition.type', 'in', changedStatKeys)
      .get(),
    db.collection(`users/${uid}/earnedBadges`).get(),
    db.doc('app_config/levels').get(),
  ]);

  const stats: UserStats = { ...EMPTY_STATS, ...((userSnap.data()?.stats as Partial<UserStats>) ?? {}) };
  const currentPoints: number = (userSnap.data()?.gamification?.totalPoints as number | undefined) ?? 0;
  const earnedIds = new Set(earnedSnap.docs.map(d => d.id));
  const candidates: BadgeDoc[] = badgesSnap.docs.map(d => d.data() as BadgeDoc);
  const levelConfig: LevelConfig = (levelsSnap.data() as LevelConfig | undefined) ?? DEFAULT_LEVEL_CONFIG;

  const newlyEarned = findNewlyEarnedBadges(stats, candidates, earnedIds);

  if (newlyEarned.length === 0) {
    return {
      newlyEarnedIds: [],
      pointsAdded: 0,
      newLevel: levelForPoints(currentPoints, levelConfig),
    };
  }

  const pointsAdded = newlyEarned.reduce((s, b) => s + b.points, 0);
  const newTotal = currentPoints + pointsAdded;
  const newLevel = levelForPoints(newTotal, levelConfig);

  await db.runTransaction(async tx => {
    for (const b of newlyEarned) {
      tx.set(db.doc(`users/${uid}/earnedBadges/${b.id}`), {
        badgeId: b.id,
        earnedAt: FieldValue.serverTimestamp(),
        pointsAwarded: b.points,
        snapshot: { value: statValue(stats, b.condition.type), threshold: b.condition.threshold },
      });
    }
    tx.update(db.doc(`users/${uid}`), {
      'gamification.totalPoints': newTotal,
      'gamification.level': newLevel,
      'gamification.earnedBadgesCache': FieldValue.arrayUnion(...newlyEarned.map(b => b.id)),
    });
  });

  logger.info('badges granted', { uid, ids: newlyEarned.map(b => b.id), pointsAdded, newLevel });

  return {
    newlyEarnedIds: newlyEarned.map(b => b.id),
    pointsAdded,
    newLevel,
  };
}
