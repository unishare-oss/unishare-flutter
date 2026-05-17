import { describe, expect, it, vi, beforeEach } from 'vitest';

const { sendEachForMulticast, getMock, deleteMock } = vi.hoisted(() => ({
  sendEachForMulticast: vi.fn(),
  getMock: vi.fn(),
  deleteMock: vi.fn().mockResolvedValue(undefined),
}));

function makeTokenDoc(id: string, token: string) {
  return {
    ref: { delete: deleteMock, id },
    data: () => ({ token, platform: 'android' }),
  };
}

vi.mock('../../src/admin', () => ({
  db: {
    collection: (name: string) => {
      if (name !== 'users') throw new Error(`unexpected ${name}`);
      return {
        doc: () => ({
          collection: (sub: string) => {
            if (sub !== 'fcmTokens') throw new Error(`unexpected ${sub}`);
            return { get: getMock };
          },
        }),
      };
    },
  },
  messaging: { sendEachForMulticast },
  FieldValue: {},
  Timestamp: {},
}));

vi.mock('firebase-functions/v2', () => ({
  logger: { info: vi.fn(), warn: vi.fn(), error: vi.fn() },
}));

import { sendPush } from '../../src/lib/sendPush';

beforeEach(() => {
  sendEachForMulticast.mockReset();
  getMock.mockReset();
  deleteMock.mockClear();
});

describe('sendPush', () => {
  it('no-ops when the recipient has no tokens', async () => {
    getMock.mockResolvedValueOnce({ empty: true, docs: [] });

    await sendPush('uid-1', 'T', 'B', { foo: 'bar' });

    expect(sendEachForMulticast).not.toHaveBeenCalled();
    expect(deleteMock).not.toHaveBeenCalled();
  });

  it('sends a multicast with all tokens', async () => {
    const docs = [makeTokenDoc('t1', 'tok-1'), makeTokenDoc('t2', 'tok-2')];
    getMock.mockResolvedValueOnce({ empty: false, docs, size: docs.length });
    sendEachForMulticast.mockResolvedValueOnce({
      successCount: 2,
      failureCount: 0,
      responses: [{ success: true }, { success: true }],
    });

    await sendPush('uid-1', 'Hi', 'Body', { x: 'y' });

    expect(sendEachForMulticast).toHaveBeenCalledTimes(1);
    const arg = sendEachForMulticast.mock.calls[0][0];
    expect(arg.tokens).toEqual(['tok-1', 'tok-2']);
    expect(arg.notification).toEqual({ title: 'Hi', body: 'Body' });
    expect(arg.data).toEqual({ x: 'y' });
    expect(deleteMock).not.toHaveBeenCalled();
  });

  it('prunes tokens that FCM reports as not-registered', async () => {
    const docs = [makeTokenDoc('t1', 'tok-1'), makeTokenDoc('t2', 'tok-2')];
    getMock.mockResolvedValueOnce({ empty: false, docs, size: docs.length });
    sendEachForMulticast.mockResolvedValueOnce({
      successCount: 1,
      failureCount: 1,
      responses: [
        { success: true },
        {
          success: false,
          error: { code: 'messaging/registration-token-not-registered' },
        },
      ],
    });

    await sendPush('uid-1', 'T', 'B', {});

    expect(deleteMock).toHaveBeenCalledTimes(1);
  });

  it('keeps tokens on transient failures', async () => {
    const docs = [makeTokenDoc('t1', 'tok-1')];
    getMock.mockResolvedValueOnce({ empty: false, docs, size: docs.length });
    sendEachForMulticast.mockResolvedValueOnce({
      successCount: 0,
      failureCount: 1,
      responses: [
        {
          success: false,
          error: { code: 'messaging/server-unavailable' },
        },
      ],
    });

    await sendPush('uid-1', 'T', 'B', {});

    expect(deleteMock).not.toHaveBeenCalled();
  });
});
