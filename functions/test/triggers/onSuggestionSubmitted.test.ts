import { describe, expect, it, vi, beforeEach } from 'vitest';

const { writeNotificationMock, sendPushMock, reqGetMock } = vi.hoisted(() => ({
  writeNotificationMock: vi.fn().mockResolvedValue('notif-1'),
  sendPushMock: vi.fn().mockResolvedValue(undefined),
  reqGetMock: vi.fn(),
}));

vi.mock('../../src/lib/writeNotification', () => ({
  writeNotification: writeNotificationMock,
}));
vi.mock('../../src/lib/sendPush', () => ({ sendPush: sendPushMock }));

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

import { onSuggestionSubmittedHandler } from '../../src/triggers/onSuggestionSubmitted';

beforeEach(() => {
  writeNotificationMock.mockClear();
  sendPushMock.mockClear();
  reqGetMock.mockReset();
});

function event(suggestionData: Record<string, unknown>) {
  return {
    data: { data: () => suggestionData },
    params: { requestId: 'req-1', suggestionId: 'sug-1' },
  };
}

describe('onSuggestionSubmittedHandler', () => {
  it('notifies requester on third-party suggestion', async () => {
    reqGetMock.mockResolvedValueOnce({
      data: () => ({
        requesterId: 'req-uid',
        requesterName: 'Req',
        title: 'Need notes',
        status: 'open',
      }),
    });

    await onSuggestionSubmittedHandler(
      event({
        postId: 'post-7',
        postTitle: 'Lecture Notes',
        postType: 'document',
        suggestedByUserId: 'sug-uid',
        suggestedByName: 'Sam',
        suggestedByAvatar: 'https://s.jpg',
      }),
    );

    expect(writeNotificationMock).toHaveBeenCalledWith(
      'req-uid',
      expect.objectContaining({
        type: 'suggestion_submitted',
        actorId: 'sug-uid',
        actorName: 'Sam',
        actorPhotoUrl: 'https://s.jpg',
        targetType: 'request',
      }),
    );
    expect(sendPushMock).toHaveBeenCalled();
  });

  it('skips self-suggestions', async () => {
    reqGetMock.mockResolvedValueOnce({
      data: () => ({
        requesterId: 'me',
        requesterName: 'Me',
        title: 'x',
        status: 'open',
      }),
    });

    await onSuggestionSubmittedHandler(
      event({
        postId: 'p',
        postTitle: 't',
        postType: 'document',
        suggestedByUserId: 'me',
        suggestedByName: 'Me',
      }),
    );

    expect(writeNotificationMock).not.toHaveBeenCalled();
  });
});
