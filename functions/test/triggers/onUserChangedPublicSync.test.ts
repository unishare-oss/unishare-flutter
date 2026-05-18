import { describe, it, expect, vi, beforeEach } from 'vitest';

const { setMock } = vi.hoisted(() => ({ setMock: vi.fn().mockResolvedValue(undefined) }));

vi.mock('../../src/admin', () => ({
  db: {
    doc: (_path: string) => ({ set: setMock }),
  },
  FieldValue: { serverTimestamp: () => ({ __ts: true }) },
}));
vi.mock('firebase-functions/v2', () => ({
  logger: { info: vi.fn(), warn: vi.fn(), error: vi.fn() },
}));
vi.mock('firebase-functions/v2/firestore', () => ({
  onDocumentUpdated: (_path: string, h: unknown) => h,
}));

import { onUserChangedPublicSyncHandler } from '../../src/triggers/onUserChangedPublicSync';

beforeEach(() => {
  setMock.mockClear();
});

const baseUser = {
  name: 'Jane',
  email: 'jane@kmutt.ac.th',
  photoUrl: 'p',
  bio: 'hi',
  gamification: {
    level: 1,
    selectedTitle: null,
    displayedBadges: [],
    totalPoints: 0,
    earnedBadgesCache: [],
  },
};

describe('onUserChangedPublicSyncHandler', () => {
  it('skips when the public projection is unchanged', async () => {
    await onUserChangedPublicSyncHandler('u1', baseUser, baseUser);
    expect(setMock).not.toHaveBeenCalled();
  });

  it('skips when only private fields change (stats / totalPoints / earnedBadgesCache)', async () => {
    const after = {
      ...baseUser,
      stats: { postsCreated: 5 },
      gamification: {
        ...baseUser.gamification,
        totalPoints: 15,
        earnedBadgesCache: ['first_post'],
      },
    };
    await onUserChangedPublicSyncHandler('u1', baseUser, after);
    expect(setMock).not.toHaveBeenCalled();
  });

  it('writes once when name changes', async () => {
    const after = { ...baseUser, name: 'Janet' };
    await onUserChangedPublicSyncHandler('u1', baseUser, after);
    expect(setMock).toHaveBeenCalledOnce();
    const [payload, opts] = setMock.mock.calls[0];
    expect(payload.name).toBe('Janet');
    expect(payload.uid).toBe('u1');
    expect(opts).toEqual({ merge: true });
  });

  it('writes once when gamification.level changes', async () => {
    const after = {
      ...baseUser,
      gamification: { ...baseUser.gamification, level: 3 },
    };
    await onUserChangedPublicSyncHandler('u1', baseUser, after);
    expect(setMock).toHaveBeenCalledOnce();
    expect(setMock.mock.calls[0][0].level).toBe(3);
  });

  it('writes once when gamification.displayedBadges changes', async () => {
    const after = {
      ...baseUser,
      gamification: {
        ...baseUser.gamification,
        displayedBadges: ['first_post'],
      },
    };
    await onUserChangedPublicSyncHandler('u1', baseUser, after);
    expect(setMock).toHaveBeenCalledOnce();
    expect(setMock.mock.calls[0][0].displayedBadges).toEqual(['first_post']);
  });

  it('writes once when bio changes', async () => {
    const after = { ...baseUser, bio: 'new bio' };
    await onUserChangedPublicSyncHandler('u1', baseUser, after);
    expect(setMock).toHaveBeenCalledOnce();
    expect(setMock.mock.calls[0][0].bio).toBe('new bio');
  });

  it('does not write when the projection becomes null (incomplete profile)', async () => {
    const after = { ...baseUser, name: '' };
    await onUserChangedPublicSyncHandler('u1', baseUser, after);
    expect(setMock).not.toHaveBeenCalled();
  });
});
