/**
 * Notification type strings. Stored as snake_case in Firestore so the
 * Flutter client's `_snakeToCamel` lookup resolves to the matching
 * `NotificationType` enum variant.
 */
export type NotificationType =
  | 'post_comment_added'
  | 'post_liked'
  | 'comment_reply'
  | 'request_upvoted'
  | 'suggestion_submitted'
  | 'suggestion_accepted'
  | 'badge_unlock';

export type TargetType = 'post' | 'request' | 'badge';

/**
 * Payload written to `users/{recipientUid}/notifications/{notifId}`.
 * Mirrors the Flutter `NotificationModel` Freezed DTO.
 */
export interface NotificationPayload {
  type: NotificationType;
  title: string;
  body: string;
  actorId: string;
  actorName: string;
  actorPhotoUrl: string | null;
  targetId: string;
  targetType: TargetType;
  targetTitle: string;
}

/** Shape of `posts/{postId}` documents in Firestore. */
export interface PostDoc {
  authorId: string;
  title: string;
}

/** Shape of `posts/{postId}/comments/{commentId}` documents. */
export interface CommentDoc {
  authorId: string;
  authorName: string;
  authorAvatar: string;
  body: string;
  parentId?: string | null;
}

/** Shape of `requests/{requestId}` documents. */
export interface RequestDoc {
  requesterId: string;
  requesterName: string;
  requesterAvatar?: string | null;
  title: string;
  status: 'open' | 'fulfilled';
  fulfilledByPostId?: string | null;
  fulfilledByPostTitle?: string | null;
}

/** Shape of `requests/{requestId}/suggestions/{suggestionId}` documents. */
export interface SuggestionDoc {
  postId: string;
  postTitle: string;
  postType: string;
  suggestedByUserId: string;
  suggestedByName: string;
  suggestedByAvatar?: string | null;
}

/** Shape of `users/{uid}/fcmTokens/{tokenHash}` documents. */
export interface FcmTokenDoc {
  token: string;
  platform: 'android' | 'ios' | 'web';
}

/** Truncates body copy to fit the spec's 100-char ceiling. */
export function truncate(s: string, max = 100): string {
  if (s.length <= max) return s;
  return `${s.slice(0, max - 1)}…`;
}
