import { describe, it, expect } from 'vitest';
import { findNewlyEarnedBadges } from '../../src/badges/findNewlyEarnedBadges';
import { EMPTY_STATS, type BadgeDoc, type UserStats } from '../../src/badges/types';

const firstPost: BadgeDoc = {
  id: 'first_post', name: 'First Steps', description: '',
  glyph: 'paper-plane-tilt', points: 15,
  tier: 'onboarding', category: 'content',
  condition: { type: 'postsCreated', threshold: 1 },
  order: 1, active: true,
};

const steadySharer: BadgeDoc = {
  ...firstPost,
  id: 'steady_sharer', name: 'Steady Sharer',
  tier: 'progression', points: 30,
  condition: { type: 'postsCreated', threshold: 10 },
  order: 10,
};

const renaissance: BadgeDoc = {
  ...firstPost,
  id: 'renaissance', tier: 'prestige', points: 100,
  condition: { type: 'uniqueDepartmentsCount', threshold: 5 },
  order: 23,
};

const profileComplete: BadgeDoc = {
  ...firstPost,
  id: 'profile_complete', points: 10,
  condition: { type: 'profileCompleted', threshold: 1 },
  order: 0,
};

function statsWith(overrides: Partial<UserStats>): UserStats {
  return { ...EMPTY_STATS, ...overrides };
}

describe('findNewlyEarnedBadges', () => {
  it('returns empty when no candidate meets its threshold', () => {
    const stats = statsWith({ postsCreated: 0 });
    expect(findNewlyEarnedBadges(stats, [firstPost, steadySharer], new Set())).toEqual([]);
  });

  it('returns the badge when threshold is exactly met', () => {
    const stats = statsWith({ postsCreated: 1 });
    expect(findNewlyEarnedBadges(stats, [firstPost], new Set()).map(b => b.id)).toEqual(['first_post']);
  });

  it('returns the badge when threshold is exceeded', () => {
    const stats = statsWith({ postsCreated: 10 });
    expect(findNewlyEarnedBadges(stats, [firstPost], new Set()).map(b => b.id)).toEqual(['first_post']);
  });

  it('returns multiple badges if multiple thresholds are crossed at once', () => {
    const stats = statsWith({ postsCreated: 10 });
    const result = findNewlyEarnedBadges(stats, [firstPost, steadySharer], new Set());
    expect(new Set(result.map(b => b.id))).toEqual(new Set(['first_post', 'steady_sharer']));
  });

  it('excludes badges already earned (idempotency)', () => {
    const stats = statsWith({ postsCreated: 10 });
    const earned = new Set(['first_post']);
    expect(findNewlyEarnedBadges(stats, [firstPost, steadySharer], earned).map(b => b.id))
      .toEqual(['steady_sharer']);
  });

  it('treats uniqueDepartmentsCount via the derived stat key', () => {
    const stats = statsWith({ uniqueDepartmentsContributed: ['cs', 'math', 'eie', 'cpe', 'che'] });
    expect(findNewlyEarnedBadges(stats, [renaissance], new Set()).map(b => b.id))
      .toEqual(['renaissance']);
  });

  it('treats profileCompleted via the derived stat key (truthy → 1)', () => {
    const stats = statsWith({ profileCompleted: true });
    expect(findNewlyEarnedBadges(stats, [profileComplete], new Set()).map(b => b.id))
      .toEqual(['profile_complete']);
  });

  it('returns empty when profileCompleted is false even though candidate exists', () => {
    const stats = statsWith({ profileCompleted: false });
    expect(findNewlyEarnedBadges(stats, [profileComplete], new Set())).toEqual([]);
  });
});
