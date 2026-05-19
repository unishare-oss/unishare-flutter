import type { LevelConfig } from './types';

export function levelForPoints(points: number, config: LevelConfig): number {
  const sorted = [...config.thresholds].sort((a, b) => a.cumulative - b.cumulative);
  let current = 1;
  let lastCumulative = 0;
  let lastLevel = 1;
  for (const t of sorted) {
    if (points >= t.cumulative) {
      current = t.level;
      lastCumulative = t.cumulative;
      lastLevel = t.level;
    } else {
      break;
    }
  }
  if (lastLevel >= 10 && config.perLevelAbove10 > 0) {
    const extra = Math.floor((points - lastCumulative) / config.perLevelAbove10);
    return lastLevel + extra;
  }
  return current;
}
