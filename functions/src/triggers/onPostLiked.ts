import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { db } from '../admin';
import { writeNotification } from '../lib/writeNotification';
import { sendPush } from '../lib/sendPush';
import { getActor } from '../lib/actorLookup';
import type { PostDoc } from '../lib/types';

/**
 * Fires when a user likes a post. The like document ID is the liker's UID.
 * Notifies the post owner. Skips self-likes.
 */
export async function onPostLikedHandler(event: {
  params: Record<string, string>;
}): Promise<void> {
  const { postId, userId: actorId } = event.params as {
    postId: string;
    userId: string;
  };

  const postSnap = await db.collection('posts').doc(postId).get();
  const post = postSnap.data() as PostDoc | undefined;
  if (!post) {
    logger.warn('onPostLiked: post not found', { postId });
    return;
  }

  if (actorId === post.authorId) {
    return;
  }

  const actor = await getActor(actorId);

  const title = 'Someone liked your post';
  const body = `${actor.name} liked "${post.title}"`;

  const notifId = await writeNotification(post.authorId, {
    type: 'post_liked',
    title,
    body,
    actorId,
    actorName: actor.name,
    actorPhotoUrl: actor.photoUrl,
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

export const onPostLiked = onDocumentCreated(
  'posts/{postId}/likes/{userId}',
  onPostLikedHandler,
);
