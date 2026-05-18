import { describe, it, expect, vi, beforeEach } from 'vitest';

const { incrementStatMock, evaluateBadgesMock, postGetMock, runTransactionMock, postUpdateMock } = vi.hoisted(() => ({
  incrementStatMock: vi.fn().mockResolvedValue(undefined),
  evaluateBadgesMock: vi.fn().mockResolvedValue({ newlyEarnedIds: [], pointsAdded: 0, newLevel: 1 }),
  postGetMock: vi.fn(),
  runTransactionMock: vi.fn(),
  postUpdateMock: vi.fn().mockResolvedValue(undefined),
}));

vi.mock('../../src/badges/counters', () => ({
  incrementStat: incrementStatMock,
}));
vi.mock('../../src/badges/evaluateBadges', () => ({
  evaluateBadges: evaluateBadgesMock,
}));
vi.mock('../../src/admin', () => ({
  db: {
    doc: (path: string) => {
      if (path.startsWith('posts/')) {
        return { get: postGetMock, update: postUpdateMock };
      }
      return { get: vi.fn(), update: vi.fn() };
    },
    runTransaction: runTransactionMock,
  },
  FieldValue: { increment: (n: number) => ({ __increment: n }), serverTimestamp: () => ({ __ts: true }) },
}));
vi.mock('firebase-functions/v2', () => ({
  logger: { info: vi.fn(), warn: vi.fn(), error: vi.fn() },
}));
vi.mock('firebase-functions/v2/firestore', () => ({
  onDocumentCreated: (_path: string, h: unknown) => h,
  onDocumentDeleted: (_path: string, h: unknown) => h,
}));

import { onPostSavedHandler } from '../../src/triggers/onPostSaved';

beforeEach(() => {
  incrementStatMock.mockClear();
  evaluateBadgesMock.mockClear();
  postGetMock.mockClear();
  runTransactionMock.mockClear();
  postUpdateMock.mockClear();
});

describe('onPostSavedHandler', () => {
  it('happy path — new saver, first save on post', async () => {
    postGetMock.mockResolvedValue({ data: () => ({ authorId: 'author' }) });
    runTransactionMock
      .mockImplementationOnce(async (fn) => fn({ get: async () => ({ exists: false }), set: () => {} })) // uniqueSavers
      .mockImplementationOnce(async (fn) => fn({ get: async () => ({ data: () => ({ saveCount: 0 }) }), update: () => {} })); // saveCount

    await onPostSavedHandler('saver1', 'p1');

    expect(incrementStatMock).toHaveBeenCalledWith('author', 'savesReceived', 1);
    expect(incrementStatMock).toHaveBeenCalledWith('author', 'uniqueSaversCount', 1);
    expect(incrementStatMock).toHaveBeenCalledWith('author', 'postsWithAtLeastOneSave', 1);
    expect(incrementStatMock).toHaveBeenCalledWith('saver1', 'savesGiven', 1);
    expect(evaluateBadgesMock).toHaveBeenCalledWith('author', ['savesReceived', 'uniqueSaversCount', 'postsWithAtLeastOneSave']);
    expect(evaluateBadgesMock).toHaveBeenCalledWith('saver1', ['savesGiven']);
  });

  it('rejects self-saves with an error', async () => {
    postGetMock.mockResolvedValue({ data: () => ({ authorId: 'author' }) });
    await expect(onPostSavedHandler('author', 'p1')).rejects.toThrow(/self-save/);
    expect(incrementStatMock).not.toHaveBeenCalled();
  });

  it('returning saver — no uniqueSaversCount bump', async () => {
    postGetMock.mockResolvedValue({ data: () => ({ authorId: 'author' }) });
    runTransactionMock
      .mockImplementationOnce(async (fn) => fn({ get: async () => ({ exists: true }), set: () => {} })) // already-known saver
      .mockImplementationOnce(async (fn) => fn({ get: async () => ({ data: () => ({ saveCount: 3 }) }), update: () => {} }));

    await onPostSavedHandler('saver1', 'p1');

    expect(incrementStatMock).toHaveBeenCalledWith('author', 'savesReceived', 1);
    expect(incrementStatMock).not.toHaveBeenCalledWith('author', 'uniqueSaversCount', 1);
    expect(incrementStatMock).not.toHaveBeenCalledWith('author', 'postsWithAtLeastOneSave', 1);
    expect(evaluateBadgesMock).toHaveBeenCalledWith('author', ['savesReceived']);
  });

  it('skips when post has no authorId', async () => {
    postGetMock.mockResolvedValue({ data: () => ({}) });
    await onPostSavedHandler('saver1', 'p1');
    expect(incrementStatMock).not.toHaveBeenCalled();
    expect(evaluateBadgesMock).not.toHaveBeenCalled();
  });
});
