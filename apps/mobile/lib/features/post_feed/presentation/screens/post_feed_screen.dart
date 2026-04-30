import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/post.dart';
import '../../domain/entities/post_type.dart';
import '../providers/post_feed_provider.dart';
import '../widgets/post_card.dart';

enum _TypeFilter { all, note, exercise, pastExam }

extension on _TypeFilter {
  String get label {
    switch (this) {
      case _TypeFilter.all:
        return 'ALL';
      case _TypeFilter.note:
        return 'NOTES';
      case _TypeFilter.exercise:
        return 'EXERCISES';
      case _TypeFilter.pastExam:
        return 'PAST EXAMS';
    }
  }
}

class PostFeedScreen extends ConsumerStatefulWidget {
  const PostFeedScreen({super.key});

  @override
  ConsumerState<PostFeedScreen> createState() => _PostFeedScreenState();
}

class _PostFeedScreenState extends ConsumerState<PostFeedScreen> {
  final _scrollController = ScrollController();
  _TypeFilter _activeFilter = _TypeFilter.all;
  String _searchQuery = '';
  bool _searchActive = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(postFeedProvider.notifier)
          .fetchNextPage()
          .catchError((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't load more posts")),
          );
        }
      });
    }
  }

  List<Post> _filteredPosts(List<Post> posts) {
    var result = posts;

    if (_activeFilter != _TypeFilter.all) {
      final type = switch (_activeFilter) {
        _TypeFilter.note => PostType.note,
        _TypeFilter.exercise => PostType.exercise,
        _TypeFilter.pastExam => PostType.pastExam,
        _TypeFilter.all => PostType.note,
      };
      result = result.where((p) => p.type == type).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) {
        return p.title.toLowerCase().contains(q) ||
            p.tags.any((t) => t.toLowerCase().contains(q)) ||
            (p.courseCode?.toLowerCase().contains(q) ?? false) ||
            (p.courseDepartment?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(postFeedProvider);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _FilterStrip(
            activeFilter: _activeFilter,
            onFilterChanged: (f) => setState(() => _activeFilter = f),
          ),
          Expanded(
            child: feedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Failed to load feed',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(postFeedProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (feedState) {
                final posts = _filteredPosts(feedState.posts);
                if (posts.isEmpty) {
                  return _EmptyState(
                    hasFilter: _activeFilter != _TypeFilter.all ||
                        _searchQuery.isNotEmpty,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(postFeedProvider),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: posts.length + 1,
                    itemBuilder: (context, index) {
                      if (index < posts.length) {
                        return PostCard(
                          post: posts[index],
                          currentUserId: null,
                        );
                      }
                      if (feedState.isFetchingMore) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'New Post',
        child: const Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    if (_searchActive) {
      return AppBar(
        titleSpacing: 0,
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search posts or tags…',
            hintStyle: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: theme.textTheme.bodySmall?.color?.withAlpha(130),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          style: GoogleFonts.spaceGrotesk(fontSize: 14),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() {
            _searchActive = false;
            _searchQuery = '';
          }),
        ),
      );
    }

    return AppBar(
      title: Text(
        'Feed',
        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _searchActive = true),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final _TypeFilter activeFilter;
  final ValueChanged<_TypeFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amber = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.8),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: _TypeFilter.values.map((filter) {
            final isActive = filter == activeFilter;
            return GestureDetector(
              onTap: () => onFilterChanged(filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? amber : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  filter.label,
                  style: GoogleFonts.firaCode(
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? amber
                        : theme.textTheme.bodySmall?.color?.withAlpha(160),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilter});
  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Theme.of(context)
                .textTheme
                .bodySmall
                ?.color
                ?.withAlpha(100),
          ),
          const SizedBox(height: 12),
          Text(
            hasFilter
                ? 'No posts matched your filters.'
                : 'No posts yet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withAlpha(160),
                ),
          ),
        ],
      ),
    );
  }
}

