import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { db } from '../admin';
import { incrementStat } from '../badges/counters';
import { evaluateBadges } from '../badges/evaluateBadges';
import { writeNotification } from '../lib/writeNotification';
import { sendPush } from '../lib/sendPush';
import { truncate } from '../lib/types';
import type { CommentDoc, PostDoc } from '../lib/types';

/**
 * Fires when any comment is created. Skips replies (parentId != null) —
 * those are handled by onCommentReply on the same path. Notifies the
 * post owner that someone commented on their post.
 */
export async function onCommentAddedHandler(event: {
  data: { data(): unknown } | undefined;
  params: Record<string, string>;
}): Promise<void> {
  const snap = event.data;
  if (!snap) return;
  const comment = snap.data() as CommentDoc;

  // Achievements: every comment (top-level or reply) counts toward
  // commentsWritten. Done before the parentId early-return so replies still
  // increment, and only here — onCommentReply fires on the same path but
  // must not double-count.
  if (comment.authorId) {
    await incrementStat(comment.authorId, 'commentsWritten', 1);
    await evaluateBadges(comment.authorId, ['commentsWritten']);
  }

  if (comment.parentId) {
    return;
  }

  const { postId } = event.params as { postId: string };

  const postSnap = await db.collection('posts').doc(postId).get();
  const post = postSnap.data() as PostDoc | undefined;
  if (!post) {
    logger.warn('onCommentAdded: post not found', { postId });
    return;
  }

  if (comment.authorId === post.authorId) {
    return;
  }

  const title = 'New comment on your post';
  const body = truncate(`${comment.authorName} commented: ${comment.body}`);

  const notifId = await writeNotification(post.authorId, {
    type: 'post_comment_added',
    title,
    body,
    actorId: comment.authorId,
    actorName: comment.authorName,
    actorPhotoUrl: comment.authorAvatar || null,
    targetId: postId,
    targetType: 'post',
    targetTitle: post.title,
  });

  await sendPush(post.authorId, title, body, {
    notificationId: notifId,
    targetType: 'post',
    targetId: postId,
  });
}

export const onCommentAdded = onDocumentCreated(
  'posts/{postId}/comments/{commentId}',
  onCommentAddedHandler,
);
