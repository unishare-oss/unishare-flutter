import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { db } from '../admin';
import { writeNotification } from '../lib/writeNotification';
import { sendPush } from '../lib/sendPush';
import { truncate } from '../lib/types';
import type { CommentDoc, PostDoc } from '../lib/types';

/**
 * Fires on the same path as onCommentAdded. Only acts when parentId is
 * present — i.e. the new doc is a reply to another comment. Notifies
 * the parent comment's author. Falls back silently if the parent has
 * been deleted.
 */
export async function onCommentReplyHandler(event: {
  data: { data(): unknown } | undefined;
  params: Record<string, string>;
}): Promise<void> {
  const snap = event.data;
  if (!snap) return;
  const reply = snap.data() as CommentDoc;

  if (!reply.parentId) {
    return;
  }

  const { postId } = event.params as { postId: string };

  const parentSnap = await db
    .collection('posts')
    .doc(postId)
    .collection('comments')
    .doc(reply.parentId)
    .get();
  const parent = parentSnap.data() as CommentDoc | undefined;
  if (!parent) {
    logger.warn('onCommentReply: parent comment missing', {
      postId,
      parentId: reply.parentId,
    });
    return;
  }

  if (reply.authorId === parent.authorId) {
    return;
  }

  const postSnap = await db.collection('posts').doc(postId).get();
  const post = postSnap.data() as PostDoc | undefined;
  if (!post) {
    logger.warn('onCommentReply: post missing', { postId });
    return;
  }

  const title = 'New reply to your comment';
  const body = truncate(`${reply.authorName} replied: ${reply.body}`);

  const notifId = await writeNotification(parent.authorId, {
    type: 'comment_reply',
    title,
    body,
    actorId: reply.authorId,
    actorName: reply.authorName,
    actorPhotoUrl: reply.authorAvatar || null,
    targetId: postId,
    targetType: 'post',
    targetTitle: post.title,
  });

  await sendPush(parent.authorId, title, body, {
    notificationId: notifId,
    targetType: 'post',
    targetId: postId,
  });
}

export const onCommentReply = onDocumentCreated(
  'posts/{postId}/comments/{commentId}',
  onCommentReplyHandler,
);
