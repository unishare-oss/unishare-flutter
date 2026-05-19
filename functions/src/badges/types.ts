// Shared types and helpers for the achievements v1 badge evaluator.

import * as admin from 'firebase-admin';

export type StatKey =
  | 'postsCreated'
  | 'savesReceived'
  | 'postsWithAtLeastOneSave'
  | 'uniqueSaversCount'
  | 'requestsFulfilled'
  | 'requestsCreated'
  | 'commentsWritten'
  | 'savesGiven'
  | 'uniqueDepartmentsCount'
  | 'profileCompleted';

export type BadgeTier = 'onboarding' | 'progression' | 'prestige';
export type BadgeCategory = 'content' | 'community' | 'profile' | 'recognition';

export interface BadgeDoc {
  id: string;
  name: string;
  description: string;
  glyph: string;
  points: number;
  tier: BadgeTier;
  category: BadgeCategory;
  condition: { type: StatKey; threshold: number };
  order: number;
  active: boolean;
}

export interface UserStats {
  postsCreated: number;
  savesReceived: number;
  postsWithAtLeastOneSave: number;
  uniqueSaversCount: number;
  requestsFulfilled: number;
  requestsCreated: number;
  commentsWritten: number;
  savesGiven: number;
  uniqueDepartmentsContributed: string[];
  profileCompleted: boolean;
  moderationFlags: number;
  updatedAt: admin.firestore.Timestamp | null;
}

export interface LevelThreshold {
  level: number;
  cumulative: number;
}

export interface LevelConfig {
  thresholds: LevelThreshold[];
  perLevelAbove10: number;
}

export const EMPTY_STATS: UserStats = {
  postsCreated: 0,
  savesReceived: 0,
  postsWithAtLeastOneSave: 0,
  uniqueSaversCount: 0,
  requestsFulfilled: 0,
  requestsCreated: 0,
  commentsWritten: 0,
  savesGiven: 0,
  uniqueDepartmentsContributed: [],
  profileCompleted: false,
  moderationFlags: 0,
  updatedAt: null,
};

export function statValue(stats: UserStats, key: StatKey): number {
  switch (key) {
    case 'profileCompleted':
      return stats.profileCompleted ? 1 : 0;
    case 'uniqueDepartmentsCount':
      return stats.uniqueDepartmentsContributed.length;
    default:
      return stats[key] as number;
  }
}
