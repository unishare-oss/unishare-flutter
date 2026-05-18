import { describe, it, expect, vi, beforeEach } from 'vitest';

const { incrementStatMock, evaluateBadgesMock } = vi.hoisted(() => ({
  incrementStatMock: vi.fn().mockResolvedValue(undefined),
  evaluateBadgesMock: vi.fn().mockResolvedValue({ newlyEarnedIds: [], pointsAdded: 0, newLevel: 1 }),
}));

vi.mock('../../src/badges/counters', () => ({ incrementStat: incrementStatMock }));
vi.mock('../../src/badges/evaluateBadges', () => ({ evaluateBadges: evaluateBadgesMock }));
vi.mock('firebase-functions/v2', () => ({
  logger: { info: vi.fn(), warn: vi.fn(), error: vi.fn() },
}));
vi.mock('firebase-functions/v2/firestore', () => ({
  onDocumentCreated: (_path: string, h: unknown) => h,
}));

import { onRequestCreatedHandler } from '../../src/triggers/onRequestCreated';

beforeEach(() => {
  incrementStatMock.mockClear();
  evaluateBadgesMock.mockClear();
});

describe('onRequestCreatedHandler', () => {
  it('increments requestsCreated and evaluates badges for the requester', async () => {
    await onRequestCreatedHandler({
      requesterId: 'r1',
      requesterName: 'Req',
      title: 'Need notes',
      status: 'open',
    });
    expect(incrementStatMock).toHaveBeenCalledWith('r1', 'requestsCreated', 1);
    expect(evaluateBadgesMock).toHaveBeenCalledWith('r1', ['requestsCreated']);
  });

  it('skips when requesterId is missing', async () => {
    await onRequestCreatedHandler(undefined);
    expect(incrementStatMock).not.toHaveBeenCalled();
    expect(evaluateBadgesMock).not.toHaveBeenCalled();
  });
});
