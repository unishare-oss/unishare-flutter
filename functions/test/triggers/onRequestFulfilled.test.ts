import { describe, expect, it, vi, beforeEach } from 'vitest';

const { writeNotificationMock, sendPushMock, suggestionsGetMock } = vi.hoisted(
  () => ({
    writeNotificationMock: vi.fn().mockResolvedValue('notif-1'),
    sendPushMock: vi.fn().mockResolvedValue(undefined),
    suggestionsGetMock: vi.fn(),
  }),
);

vi.mock('../../src/lib/writeNotification', () => ({
  writeNotification: writeNotificationMock,
}));
vi.mock('../../src/lib/sendPush', () => ({ sendPush: sendPushMock }));

vi.mock('../../src/admin', () => ({
  db: {
    collection: (col: string) => {
      if (col !== 'requests') throw new Error(`unexpected ${col}`);
      return {
        doc: () => ({
          collection: (sub: string) => {
            if (sub !== 'suggestions') throw new Error(`unexpected ${sub}`);
            return {
              where: () => ({
                limit: () => ({ get: suggestionsGetMock }),
              }),
            };
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
  onDocumentUpdated: (_path: string, h: unknown) => h,
}));

import { onRequestFulfilledHandler } from '../../src/triggers/onRequestFulfilled';

beforeEach(() => {
  writeNotificationMock.mockClear();
  sendPushMock.mockClear();
  suggestionsGetMock.mockReset();
});

function event(before: Record<string, unknown>, after: Record<string, unknown>) {
  return {
    data: {
      before: { data: () => before },
      after: { data: () => after },
    },
    params: { requestId: 'req-1' },
  };
}

describe('onRequestFulfilledHandler', () => {
  it('notifies the winning suggester on first fulfillment', async () => {
    suggestionsGetMock.mockResolvedValueOnce({
      empty: false,
      docs: [
        {
          data: () => ({
            postId: 'post-7',
            postTitle: 'Lecture Notes',
            suggestedByUserId: 'suggester-uid',
            suggestedByName: 'Sam',
          }),
        },
      ],
    });

    await onRequestFulfilledHandler(
      event(
        { status: 'open' },
        {
          status: 'fulfilled',
          requesterId: 'req-uid',
          requesterName: 'Req',
          title: 'Need notes',
          fulfilledByPostId: 'post-7',
        },
      ),
    );

    expect(writeNotificationMock).toHaveBeenCalledWith(
      'suggester-uid',
      expect.objectContaining({
        type: 'suggestion_accepted',
        targetType: 'request',
        targetId: 'req-1',
      }),
    );
    expect(sendPushMock).toHaveBeenCalled();
  });

  it('skips when status did not transition to fulfilled', async () => {
    await onRequestFulfilledHandler(
      event({ status: 'fulfilled' }, { status: 'fulfilled' }),
    );
    expect(suggestionsGetMock).not.toHaveBeenCalled();
    expect(writeNotificationMock).not.toHaveBeenCalled();
  });

  it('skips when fulfilledByPostId is absent', async () => {
    await onRequestFulfilledHandler(
      event({ status: 'open' }, { status: 'fulfilled', requesterId: 'r' }),
    );
    expect(writeNotificationMock).not.toHaveBeenCalled();
  });

  it('skips when no matching suggestion is found', async () => {
    suggestionsGetMock.mockResolvedValueOnce({ empty: true, docs: [] });

    await onRequestFulfilledHandler(
      event(
        { status: 'open' },
        {
          status: 'fulfilled',
          requesterId: 'r',
          requesterName: 'R',
          title: 't',
          fulfilledByPostId: 'p',
        },
      ),
    );

    expect(writeNotificationMock).not.toHaveBeenCalled();
  });
});
