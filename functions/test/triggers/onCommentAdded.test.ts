import { describe, expect, it, vi, beforeEach } from 'vitest';

const { writeNotificationMock, sendPushMock, postGetMock } = vi.hoisted(() => ({
  writeNotificationMock: vi.fn().mockResolvedValue('notif-1'),
  sendPushMock: vi.fn().mockResolvedValue(undefined),
  postGetMock: vi.fn(),
}));

vi.mock('../../src/lib/writeNotification', () => ({
  writeNotification: writeNotificationMock,
}));
vi.mock('../../src/lib/sendPush', () => ({ sendPush: sendPushMock }));
vi.mock('../../src/lib/actorLookup', () => ({ getActor: vi.fn() }));

vi.mock('../../src/admin', () => ({
  db: {
    collection: (col: string) => {
      if (col === 'posts') {
        return { doc: () => ({ get: postGetMock }) };
      }
      throw new Error(`unexpected ${col}`);
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

import { onCommentAddedHandler } from '../../src/triggers/onCommentAdded';

beforeEach(() => {
  writeNotificationMock.mockClear();
  sendPushMock.mockClear();
  postGetMock.mockReset();
});

function event(commentData: Record<string, unknown>) {
  return {
    data: { data: () => commentData },
    params: { postId: 'post-1', commentId: 'c-1' },
  };
}

describe('onCommentAddedHandler', () => {
  it('writes notification + pushes to post owner on top-level comment', async () => {
    postGetMock.mockResolvedValueOnce({
      data: () => ({ authorId: 'owner-uid', title: 'A great post' }),
    });

    await onCommentAddedHandler(
      event({
        authorId: 'commenter-uid',
        authorName: 'Alice',
        authorAvatar: 'https://a.jpg',
        body: 'Nice!',
      }),
    );

    expect(writeNotificationMock).toHaveBeenCalledTimes(1);
    expect(writeNotificationMock.mock.calls[0][0]).toBe('owner-uid');
    expect(writeNotificationMock.mock.calls[0][1]).toMatchObject({
      type: 'post_comment_added',
      title: 'New comment on your post',
      actorId: 'commenter-uid',
      actorName: 'Alice',
      actorPhotoUrl: 'https://a.jpg',
      targetId: 'post-1',
      targetType: 'post',
      targetTitle: 'A great post',
    });

    expect(sendPushMock).toHaveBeenCalledTimes(1);
    expect(sendPushMock.mock.calls[0][0]).toBe('owner-uid');
    expect(sendPushMock.mock.calls[0][3]).toMatchObject({
      notificationId: 'notif-1',
      targetType: 'post',
      targetId: 'post-1',
    });
  });

  it('skips when comment has a parentId (handled by onCommentReply)', async () => {
    await onCommentAddedHandler(
      event({
        authorId: 'commenter-uid',
        authorName: 'Alice',
        authorAvatar: '',
        body: 'reply',
        parentId: 'parent-comment-id',
      }),
    );

    expect(postGetMock).not.toHaveBeenCalled();
    expect(writeNotificationMock).not.toHaveBeenCalled();
    expect(sendPushMock).not.toHaveBeenCalled();
  });

  it('skips self-comments', async () => {
    postGetMock.mockResolvedValueOnce({
      data: () => ({ authorId: 'commenter-uid', title: 'A great post' }),
    });

    await onCommentAddedHandler(
      event({
        authorId: 'commenter-uid',
        authorName: 'Alice',
        authorAvatar: '',
        body: 'self comment',
      }),
    );

    expect(writeNotificationMock).not.toHaveBeenCalled();
    expect(sendPushMock).not.toHaveBeenCalled();
  });

  it('skips when post is missing', async () => {
    postGetMock.mockResolvedValueOnce({ data: () => undefined });

    await onCommentAddedHandler(
      event({
        authorId: 'commenter-uid',
        authorName: 'Alice',
        authorAvatar: '',
        body: 'hi',
      }),
    );

    expect(writeNotificationMock).not.toHaveBeenCalled();
    expect(sendPushMock).not.toHaveBeenCalled();
  });
});
