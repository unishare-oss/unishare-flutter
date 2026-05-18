import { describe, it, expect } from 'vitest';

import { publicUserProjection } from '../../src/lib/publicUserProjection';

const fullDoc = {
  name: 'Jane Doe',
  email: 'jane@kmutt.ac.th',
  photoUrl: 'https://example.com/avatar.jpg',
  bio: 'MSc CS',
  enrollmentYear: 2024,
  role: 'student',
  departmentId: 'cs',
  gamification: {
    totalPoints: 250,
    level: 5,
    selectedTitle: 'first_post',
    displayedBadges: ['first_post', 'first_comment'],
    earnedBadgesCache: ['first_post', 'first_comment', 'first_request'],
  },
  stats: { postsCreated: 7 },
};

describe('publicUserProjection', () => {
  it('extracts public-safe fields only', () => {
    const p = publicUserProjection('u1', fullDoc);
    expect(p).toEqual({
      uid: 'u1',
      name: 'Jane Doe',
      photoUrl: 'https://example.com/avatar.jpg',
      bio: 'MSc CS',
      level: 5,
      selectedTitle: 'first_post',
      displayedBadges: ['first_post', 'first_comment'],
    });
  });

  it('does NOT include email, stats, totalPoints, earnedBadgesCache, role, departmentId, enrollmentYear', () => {
    const p = publicUserProjection('u1', fullDoc) as Record<string, unknown>;
    expect(p).not.toHaveProperty('email');
    expect(p).not.toHaveProperty('stats');
    expect(p).not.toHaveProperty('role');
    expect(p).not.toHaveProperty('departmentId');
    expect(p).not.toHaveProperty('enrollmentYear');
    expect(p.totalPoints).toBeUndefined();
    expect(p.earnedBadgesCache).toBeUndefined();
  });

  it('returns null when data is undefined', () => {
    expect(publicUserProjection('u1', undefined)).toBeNull();
  });

  it('returns null when name is missing (incomplete profile)', () => {
    const { name: _omit, ...withoutName } = fullDoc;
    expect(publicUserProjection('u1', withoutName)).toBeNull();
  });

  it('defaults missing optional fields safely', () => {
    const minimal = { name: 'Bare' };
    expect(publicUserProjection('u1', minimal)).toEqual({
      uid: 'u1',
      name: 'Bare',
      photoUrl: null,
      bio: null,
      level: 1,
      selectedTitle: null,
      displayedBadges: [],
    });
  });

  it('normalises empty-string bio to null', () => {
    expect(publicUserProjection('u1', { name: 'X', bio: '' })?.bio).toBeNull();
    expect(publicUserProjection('u1', { name: 'X', bio: '   ' })?.bio).toBeNull();
  });

  it('trims bio of surrounding whitespace', () => {
    expect(publicUserProjection('u1', { name: 'X', bio: '  hi  ' })?.bio).toBe('hi');
  });
});
