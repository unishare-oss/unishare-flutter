import { describe, expect, it, vi, beforeEach } from 'vitest';

const {
  writeNotificationMock,
  sendPushMock,
  postGetMock,
  parentCommentGetMock,
} = vi.hoisted(() => ({
  writeNotificationMock: vi.fn().mockResolvedValue('notif-1'),
  sendPushMock: vi.fn().mockResolvedValue(undefined),
  postGetMock: vi.fn(),
  parentCommentGetMock: vi.fn(),
}));

vi.mock('../../src/lib/writeNotification', () => ({
  writeNotification: writeNotificationMock,
}));
vi.mock('../../src/lib/sendPush', () => ({ sendPush: sendPushMock }));

vi.mock('../../src/admin', () => ({
  db: {
    collection: (col: string) => {
      if (col !== 'posts') throw new Error(`unexpected ${col}`);
      return {
        doc: () => ({
          get: postGetMock,
          collection: (sub: string) => {
            if (sub !== 'comments') throw new Error(`unexpected ${sub}`);
            return { doc: () => ({ get: parentCommentGetMock }) };
          },
        }),
      };
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

import { onCommentReplyHandler } from '../../src/triggers/onCommentReply';

beforeEach(() => {
  writeNotificationMock.mockClear();
  sendPushMock.mockClear();
  postGetMock.mockReset();
  parentCommentGetMock.mockReset();
});

function event(replyData: Record<string, unknown>) {
  return {
    data: { data: () => replyData },
    params: { postId: 'post-1', commentId: 'reply-1' },
  };
}

describe('onCommentReplyHandler', () => {
  it('notifies the parent comment author on reply', async () => {
    parentCommentGetMock.mockResolvedValueOnce({
      data: () => ({
        authorId: 'parent-author',
        authorName: 'Parent',
        authorAvatar: '',
        body: 'original',
      }),
    });
    postGetMock.mockResolvedValueOnce({
      data: () => ({ authorId: 'post-owner', title: 'My Post' }),
    });

    await onCommentReplyHandler(
      event({
        authorId: 'replier-uid',
        authorName: 'Bob',
        authorAvatar: 'https://b.jpg',
        body: 'good point',
        parentId: 'parent-comment-id',
      }),
    );

    expect(writeNotificationMock).toHaveBeenCalledTimes(1);
    expect(writeNotificationMock.mock.calls[0][0]).toBe('parent-author');
    expect(writeNotificationMock.mock.calls[0][1]).toMatchObject({
      type: 'comment_reply',
      targetTitle: 'My Post',
    });
    expect(sendPushMock).toHaveBeenCalledWith(
      'parent-author',
      expect.any(String),
      expect.any(String),
      expect.objectContaining({ targetType: 'post', targetId: 'post-1' }),
    );
  });

  it('skips top-level comments (no parentId)', async () => {
    await onCommentReplyHandler(
      event({
        authorId: 'a',
        authorName: 'A',
        authorAvatar: '',
        body: 'top-level',
      }),
    );

    expect(parentCommentGetMock).not.toHaveBeenCalled();
    expect(writeNotificationMock).not.toHaveBeenCalled();
  });

  it('skips when parent comment is missing', async () => {
    parentCommentGetMock.mockResolvedValueOnce({ data: () => undefined });

    await onCommentReplyHandler(
      event({
        authorId: 'replier',
        authorName: 'B',
        authorAvatar: '',
        body: 'r',
        parentId: 'gone',
      }),
    );

    expect(writeNotificationMock).not.toHaveBeenCalled();
  });

  it('skips self-reply to own comment', async () => {
    parentCommentGetMock.mockResolvedValueOnce({
      data: () => ({
        authorId: 'same-uid',
        authorName: 'Self',
        authorAvatar: '',
        body: 'orig',
      }),
    });

    await onCommentReplyHandler(
      event({
        authorId: 'same-uid',
        authorName: 'Self',
        authorAvatar: '',
        body: 'reply to self',
        parentId: 'parent-id',
      }),
    );

    expect(writeNotificationMock).not.toHaveBeenCalled();
  });
});
