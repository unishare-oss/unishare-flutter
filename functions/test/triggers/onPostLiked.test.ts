import { describe, expect, it, vi, beforeEach } from 'vitest';

const { writeNotificationMock, sendPushMock, getActorMock, postGetMock } =
  vi.hoisted(() => ({
    writeNotificationMock: vi.fn().mockResolvedValue('notif-1'),
    sendPushMock: vi.fn().mockResolvedValue(undefined),
    getActorMock: vi.fn(),
    postGetMock: vi.fn(),
  }));

vi.mock('../../src/lib/writeNotification', () => ({
  writeNotification: writeNotificationMock,
}));
vi.mock('../../src/lib/sendPush', () => ({ sendPush: sendPushMock }));
vi.mock('../../src/lib/actorLookup', () => ({ getActor: getActorMock }));

vi.mock('../../src/admin', () => ({
  db: {
    collection: (col: string) => {
      if (col !== 'posts') throw new Error(`unexpected ${col}`);
      return { doc: () => ({ get: postGetMock }) };
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

import { onPostLikedHandler } from '../../src/triggers/onPostLiked';

beforeEach(() => {
  writeNotificationMock.mockClear();
  sendPushMock.mockClear();
  getActorMock.mockReset();
  postGetMock.mockReset();
});

describe('onPostLikedHandler', () => {
  it('notifies post owner when someone else likes', async () => {
    postGetMock.mockResolvedValueOnce({
      data: () => ({ authorId: 'owner', title: 'Cool Post' }),
    });
    getActorMock.mockResolvedValueOnce({
      name: 'Liker',
      photoUrl: 'https://l.jpg',
    });

    await onPostLikedHandler({
      params: { postId: 'post-1', userId: 'liker-uid' },
    });

    expect(writeNotificationMock).toHaveBeenCalledWith(
      'owner',
      expect.objectContaining({
        type: 'post_liked',
        actorId: 'liker-uid',
        actorName: 'Liker',
        actorPhotoUrl: 'https://l.jpg',
        targetId: 'post-1',
        targetType: 'post',
        targetTitle: 'Cool Post',
      }),
    );
    expect(sendPushMock).toHaveBeenCalled();
  });

  it('skips self-likes', async () => {
    postGetMock.mockResolvedValueOnce({
      data: () => ({ authorId: 'me', title: 'My Post' }),
    });

    await onPostLikedHandler({
      params: { postId: 'post-1', userId: 'me' },
    });

    expect(getActorMock).not.toHaveBeenCalled();
    expect(writeNotificationMock).not.toHaveBeenCalled();
  });

  it('skips when post is missing', async () => {
    postGetMock.mockResolvedValueOnce({ data: () => undefined });

    await onPostLikedHandler({
      params: { postId: 'gone', userId: 'liker' },
    });

    expect(writeNotificationMock).not.toHaveBeenCalled();
  });
});
