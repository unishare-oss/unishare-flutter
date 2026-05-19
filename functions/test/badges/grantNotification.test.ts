import { describe, it, expect, vi, beforeEach } from 'vitest';

const writeNotificationMock = vi.hoisted(() => vi.fn().mockResolvedValue('notif-1'));

vi.mock('../../src/lib/writeNotification', () => ({
  writeNotification: writeNotificationMock,
}));

import { grantBadgeNotification } from '../../src/badges/grantNotification';
import type { BadgeDoc } from '../../src/badges/types';

const sample: BadgeDoc = {
  id: 'first_post', name: 'First Steps',
  description: 'Share your first post with the community.',
  glyph: 'paper-plane-tilt', points: 15,
  tier: 'onboarding', category: 'content',
  condition: { type: 'postsCreated', threshold: 1 },
  order: 2, active: true,
};

beforeEach(() => writeNotificationMock.mockClear());

describe('grantBadgeNotification', () => {
  it('writes a badge_unlock notification with the expected payload', async () => {
    await grantBadgeNotification('u1', sample);

    expect(writeNotificationMock).toHaveBeenCalledOnce();
    const [uid, payload] = writeNotificationMock.mock.calls[0];
    expect(uid).toBe('u1');
    expect(payload.type).toBe('badge_unlock');
    expect(payload.title).toBe('First Steps');
    expect(payload.body).toContain('+15 pts');
    expect(payload.actorId).toBe('system');
    expect(payload.targetType).toBe('badge');
    expect(payload.targetId).toBe('first_post');
  });
});
