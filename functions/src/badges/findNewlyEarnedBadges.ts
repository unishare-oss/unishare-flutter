import type { BadgeDoc, UserStats } from './types';
import { statValue } from './types';

/**
 * Pure filter: given current stats, the active badge catalog, and the set of
 * badge ids the user has already earned, returns the badges that should be
 * newly granted (threshold met AND not already earned).
 *
 * Caller passes only candidate badges whose `condition.type` matches a key
 * that just changed — this function does NOT re-filter on changed-key set,
 * because it has no notion of which keys changed.
 */
export function findNewlyEarnedBadges(
  stats: UserStats,
  candidates: BadgeDoc[],
  alreadyEarnedIds: Set<string>,
): BadgeDoc[] {
  return candidates.filter(b => {
    if (alreadyEarnedIds.has(b.id)) return false;
    return statValue(stats, b.condition.type) >= b.condition.threshold;
  });
}
