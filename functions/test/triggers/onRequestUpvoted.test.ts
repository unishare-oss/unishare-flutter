import { describe, expect, it, vi, beforeEach } from 'vitest';

const { writeNotificationMock, sendPushMock, getActorMock, reqGetMock } =
  vi.hoisted(() => ({
    writeNotificationMock: vi.fn().mockResolvedValue('notif-1'),
    sendPushMock: vi.fn().mockResolvedValue(undefined),
    getActorMock: vi.fn(),
    reqGetMock: vi.fn(),
  }));

vi.mock('../../src/lib/writeNotification', () => ({
  writeNotification: writeNotificationMock,
}));
vi.mock('../../src/lib/sendPush', () => ({ sendPush: sendPushMock }));
vi.mock('../../src/lib/actorLookup', () => ({ getActor: getActorMock }));

vi.mock('../../src/admin', () => ({
  db: {
    collection: (col: string) => {
      if (col !== 'requests') throw new Error(`unexpected ${col}`);
      return { doc: () => ({ get: reqGetMock }) };
    },
  },
  FieldValue: {},
  Timestamp: {},
  messaging: {},
}));

vi.mock('firebase-functions/v2', () => ({
  logger: { info: vi.fn(), warn: vi.fn(), error: vi.fn() },
}));
vi.mock('firebase-functions/v2/firestore', () => ({
  onDocumentCreated: (_path: string, h: unknown) => h,
}));

import { onRequestUpvotedHandler } from '../../src/triggers/onRequestUpvoted';

beforeEach(() => {
  writeNotificationMock.mockClear();
  sendPushMock.mockClear();
  getActorMock.mockReset();
  reqGetMock.mockReset();
});

describe('onRequestUpvotedHandler', () => {
  it('notifies requester on upvote from someone else', async () => {
    reqGetMock.mockResolvedValueOnce({
      data: () => ({
        requesterId: 'req-uid',
        requesterName: 'Req',
        title: 'Need notes',
        status: 'open',
      }),
    });
    getActorMock.mockResolvedValueOnce({ name: 'Voter', photoUrl: null });

    await onRequestUpvotedHandler({
      params: { requestId: 'req-1', userId: 'voter-uid' },
    });

    expect(writeNotificationMock).toHaveBeenCalledWith(
      'req-uid',
      expect.objectContaining({
        type: 'request_upvoted',
        targetType: 'request',
        targetId: 'req-1',
        targetTitle: 'Need notes',
      }),
    );
    expect(sendPushMock).toHaveBeenCalled();
  });

  it('skips self-upvotes', async () => {
    reqGetMock.mockResolvedValueOnce({
      data: () => ({
        requesterId: 'me',
        requesterName: 'Me',
        title: 'x',
        status: 'open',
      }),
    });

    await onRequestUpvotedHandler({
      params: { requestId: 'req-1', userId: 'me' },
    });

    expect(writeNotificationMock).not.toHaveBeenCalled();
  });
});
