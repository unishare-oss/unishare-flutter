import { describe, expect, it, vi, beforeEach } from 'vitest';

const {
  setMock,
  docMock,
  collectionDocCollectionMock,
  userDocMock,
  usersCollectionMock,
} = vi.hoisted(() => {
  const setMock = vi.fn().mockResolvedValue(undefined);
  const docMock = vi.fn(() => ({ id: 'notif-abc', set: setMock }));
  const collectionDocCollectionMock = vi.fn(() => ({ doc: docMock }));
  const userDocMock = vi.fn(() => ({ collection: collectionDocCollectionMock }));
  const usersCollectionMock = vi.fn(() => ({ doc: userDocMock }));
  return {
    setMock,
    docMock,
    collectionDocCollectionMock,
    userDocMock,
    usersCollectionMock,
  };
});

vi.mock('../../src/admin', () => ({
  db: {
    collection: (name: string) => {
      if (name === 'users') return { doc: userDocMock };
      throw new Error(`unexpected collection ${name}`);
    },
  },
  FieldValue: { serverTimestamp: () => 'SERVER_TIMESTAMP' },
  Timestamp: {},
  messaging: {},
}));

vi.mock('firebase-functions/v2', () => ({
  logger: { info: vi.fn(), warn: vi.fn(), error: vi.fn() },
}));

import { writeNotification } from '../../src/lib/writeNotification';

beforeEach(() => {
  setMock.mockClear();
  docMock.mockClear();
  collectionDocCollectionMock.mockClear();
  userDocMock.mockClear();
  usersCollectionMock.mockClear();
});

describe('writeNotification', () => {
  it('writes a notification doc with the correct path and fields', async () => {
    const id = await writeNotification('recipient-uid', {
      type: 'post_comment_added',
      title: 'New comment on your post',
      body: 'Alice commented: hi',
      actorId: 'actor-uid',
      actorName: 'Alice',
      actorPhotoUrl: 'https://alice.jpg',
      targetId: 'post-1',
      targetType: 'post',
      targetTitle: 'My Post',
    });

    expect(id).toBe('notif-abc');
    expect(userDocMock).toHaveBeenCalledWith('recipient-uid');
    expect(collectionDocCollectionMock).toHaveBeenCalledWith('notifications');
    expect(setMock).toHaveBeenCalledTimes(1);

    const written = setMock.mock.calls[0][0];
    expect(written).toMatchObject({
      id: 'notif-abc',
      type: 'post_comment_added',
      isRead: false,
      createdAt: 'SERVER_TIMESTAMP',
      title: 'New comment on your post',
      body: 'Alice commented: hi',
      actorId: 'actor-uid',
      actorName: 'Alice',
      actorPhotoUrl: 'https://alice.jpg',
      targetId: 'post-1',
      targetType: 'post',
      targetTitle: 'My Post',
    });
  });
});
