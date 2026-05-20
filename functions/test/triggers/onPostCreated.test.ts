import { describe, it, expect, vi, beforeEach } from 'vitest';

const { incrementStatMock, addUniqueDepartmentMock, evaluateBadgesMock } = vi.hoisted(() => ({
  incrementStatMock: vi.fn().mockResolvedValue(undefined),
  addUniqueDepartmentMock: vi.fn().mockResolvedValue(true),
  evaluateBadgesMock: vi.fn().mockResolvedValue({ newlyEarnedIds: [], pointsAdded: 0, newLevel: 1 }),
}));

vi.mock('../../src/badges/counters', () => ({
  incrementStat: incrementStatMock,
  addUniqueDepartment: addUniqueDepartmentMock,
}));
vi.mock('../../src/badges/evaluateBadges', () => ({
  evaluateBadges: evaluateBadgesMock,
}));
vi.mock('firebase-functions/v2', () => ({
  logger: { info: vi.fn(), warn: vi.fn(), error: vi.fn() },
}));
vi.mock('firebase-functions/v2/firestore', () => ({
  onDocumentCreated: (_path: string, h: unknown) => h,
}));

import { onPostCreatedHandler } from '../../src/triggers/onPostCreated';

beforeEach(() => {
  incrementStatMock.mockClear();
  addUniqueDepartmentMock.mockClear();
  evaluateBadgesMock.mockClear();
});

describe('onPostCreatedHandler', () => {
  it('increments postsCreated and evaluates with changed keys', async () => {
    addUniqueDepartmentMock.mockResolvedValueOnce(true);
    await onPostCreatedHandler('p1', { authorId: 'u1', departmentId: 'cs' });
    expect(incrementStatMock).toHaveBeenCalledWith('u1', 'postsCreated', 1);
    expect(addUniqueDepartmentMock).toHaveBeenCalledWith('u1', 'cs');
    expect(evaluateBadgesMock).toHaveBeenCalledWith('u1', ['postsCreated', 'uniqueDepartmentsCount']);
  });

  it('skips uniqueDepartmentsCount when the dept was already known', async () => {
    addUniqueDepartmentMock.mockResolvedValueOnce(false);
    await onPostCreatedHandler('p1', { authorId: 'u1', departmentId: 'cs' });
    expect(evaluateBadgesMock).toHaveBeenCalledWith('u1', ['postsCreated']);
  });

  it('skips altogether when authorId is missing', async () => {
    await onPostCreatedHandler('p1', {});
    expect(incrementStatMock).not.toHaveBeenCalled();
    expect(evaluateBadgesMock).not.toHaveBeenCalled();
  });

  it('does not call addUniqueDepartment when departmentId is missing', async () => {
    await onPostCreatedHandler('p1', { authorId: 'u1' });
    expect(addUniqueDepartmentMock).not.toHaveBeenCalled();
    expect(evaluateBadgesMock).toHaveBeenCalledWith('u1', ['postsCreated']);
  });
});
