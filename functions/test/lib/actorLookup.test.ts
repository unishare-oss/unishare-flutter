import { describe, expect, it, vi, beforeEach } from 'vitest';

const { getMock } = vi.hoisted(() => ({ getMock: vi.fn() }));

vi.mock('../../src/admin', () => ({
  db: {
    collection: (name: string) => {
      if (name !== 'users') throw new Error(`unexpected ${name}`);
      return { doc: () => ({ get: getMock }) };
    },
  },
  FieldValue: {},
  Timestamp: {},
  messaging: {},
}));

vi.mock('firebase-functions/v2', () => ({
  logger: { info: vi.fn(), warn: vi.fn(), error: vi.fn() },
}));

import { getActor } from '../../src/lib/actorLookup';

beforeEach(() => {
  getMock.mockReset();
});

describe('getActor', () => {
  it('returns displayName + photoUrl when present', async () => {
    getMock.mockResolvedValueOnce({
      data: () => ({ displayName: 'Alice', photoUrl: 'https://a.jpg' }),
    });

    const actor = await getActor('uid-1');
    expect(actor).toEqual({ name: 'Alice', photoUrl: 'https://a.jpg' });
  });

  it('falls back to "Someone" when the user doc is missing', async () => {
    getMock.mockResolvedValueOnce({ data: () => undefined });

    const actor = await getActor('uid-1');
    expect(actor).toEqual({ name: 'Someone', photoUrl: null });
  });

  it('accepts camelCase photoURL fallback', async () => {
    getMock.mockResolvedValueOnce({
      data: () => ({ name: 'Bob', photoURL: 'https://b.jpg' }),
    });

    const actor = await getActor('uid-1');
    expect(actor).toEqual({ name: 'Bob', photoUrl: 'https://b.jpg' });
  });

  it('falls back gracefully when Firestore throws', async () => {
    getMock.mockRejectedValueOnce(new Error('network'));

    const actor = await getActor('uid-1');
    expect(actor).toEqual({ name: 'Someone', photoUrl: null });
  });
});
