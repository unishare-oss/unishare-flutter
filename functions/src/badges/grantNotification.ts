import { writeNotification } from '../lib/writeNotification';
import { truncate, type NotificationPayload } from '../lib/types';
import type { BadgeDoc } from './types';

/**
 * Writes one badge-unlock notification under
 * `users/{uid}/notifications/{auto-id}`, following the existing notification
 * schema. The notification is system-authored (actorId='system').
 */
export async function grantBadgeNotification(uid: string, badge: BadgeDoc): Promise<string> {
  const payload: NotificationPayload = {
    type: 'badge_unlock',
    title: badge.name,
    body: truncate(`${badge.description}  +${badge.points} pts`),
    actorId: 'system',
    actorName: 'Unishare',
    actorPhotoUrl: null,
    targetId: badge.id,
    targetType: 'badge',
    targetTitle: badge.name,
  };
  return writeNotification(uid, payload);
}
