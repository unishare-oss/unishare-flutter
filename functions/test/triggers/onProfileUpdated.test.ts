import { describe, it, expect, vi, beforeEach } from 'vitest';

const { setProfileCompletedMock, evaluateBadgesMock } = vi.hoisted(() => ({
  setProfileCompletedMock: vi.fn().mockResolvedValue(undefined),
  evaluateBadgesMock: vi.fn().mockResolvedValue({ newlyEarnedIds: [], pointsAdded: 0, newLevel: 1 }),
}));

vi.mock('../../src/badges/counters', () => ({ setProfileCompleted: setProfileCompletedMock }));
vi.mock('../../src/badges/evaluateBadges', () => ({ evaluateBadges: evaluateBadgesMock }));
vi.mock('firebase-functions/v2/firestore', () => ({
  onDocumentUpdated: (_path: string, h: unknown) => h,
}));

import { isProfileComplete, onProfileUpdatedHandler } from '../../src/triggers/onProfileUpdated';

beforeEach(() => {
  setProfileCompletedMock.mockClear();
  evaluateBadgesMock.mockClear();
});

const completeProfile = {
  name: 'Jane',
  departmentId: 'cs',
  enrollmentYear: 2024,
  bio: 'CS student.',
};

describe('isProfileComplete', () => {
  it('true when all required fields are present', () => {
    expect(isProfileComplete(completeProfile)).toBe(true);
  });
  it('false when bio is empty', () => {
    expect(isProfileComplete({ ...completeProfile, bio: '' })).toBe(false);
  });
  it('false when bio is whitespace only', () => {
    expect(isProfileComplete({ ...completeProfile, bio: '   ' })).toBe(false);
  });
  it('false when name is missing', () => {
    expect(isProfileComplete({ ...completeProfile, name: undefined })).toBe(false);
  });
});

describe('onProfileUpdatedHandler', () => {
  it('flips to complete and evaluates when fields become complete', async () => {
    await onProfileUpdatedHandler('u1', { name: 'Jane', stats: { profileCompleted: false } }, completeProfile);
    expect(setProfileCompletedMock).toHaveBeenCalledWith('u1', true);
    expect(evaluateBadgesMock).toHaveBeenCalledWith('u1', ['profileCompleted']);
  });

  it('flips back to incomplete (no evaluator call) when fields are removed', async () => {
    await onProfileUpdatedHandler(
      'u1',
      { ...completeProfile, stats: { profileCompleted: true } },
      { ...completeProfile, bio: '', stats: { profileCompleted: true } },
    );
    expect(setProfileCompletedMock).toHaveBeenCalledWith('u1', false);
    expect(evaluateBadgesMock).not.toHaveBeenCalled();
  });

  it('no-op when completeness did not change', async () => {
    await onProfileUpdatedHandler(
      'u1',
      { ...completeProfile, stats: { profileCompleted: true } },
      { ...completeProfile, stats: { profileCompleted: true } },
    );
    expect(setProfileCompletedMock).not.toHaveBeenCalled();
    expect(evaluateBadgesMock).not.toHaveBeenCalled();
  });

  it('skips when after is undefined', async () => {
    await onProfileUpdatedHandler('u1', completeProfile, undefined);
    expect(setProfileCompletedMock).not.toHaveBeenCalled();
  });
});
