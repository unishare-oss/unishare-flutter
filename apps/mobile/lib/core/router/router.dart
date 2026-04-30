import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/post_feed/presentation/screens/post_detail_screen.dart';
import '../../features/post_feed/presentation/screens/post_feed_screen.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/feed',
    routes: [
      GoRoute(
        path: '/feed',
        builder: (context, state) => const PostFeedScreen(),
        routes: [
          GoRoute(
            path: 'posts/:id',
            builder: (context, state) =>
                PostDetailScreen(postId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
}
