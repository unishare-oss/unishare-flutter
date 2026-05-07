import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/core/router/router.dart'
    show academicProfileSessionDismissed;
import 'package:unishare_mobile/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/widgets/academic_profile_dialog.dart';
import 'package:unishare_mobile/features/feed/presentation/providers/active_tag_filters_provider.dart';
import 'package:unishare_mobile/features/feed/presentation/providers/feed_provider.dart';
import 'package:unishare_mobile/features/feed/presentation/widgets/feed_empty_state_widget.dart';
import 'package:unishare_mobile/features/feed/presentation/widgets/filter_picker_widget.dart';
import 'package:unishare_mobile/features/feed/presentation/widgets/post_card.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/presentation/providers/create_post_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/widgets/scroll_to_top_target.dart';

// ---------------------------------------------------------------------------
// Tab labels
// ---------------------------------------------------------------------------

const _kTabLabels = ['ALL', 'NOTES', 'EXERCISES'];

// ---------------------------------------------------------------------------
// FeedScreen
// ---------------------------------------------------------------------------

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({required GlobalKey<State> scrollKey})
    : super(key: scrollKey);

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with SingleTickerProviderStateMixin, ScrollToTopTarget {
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  ScrollController get scrollController => _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _kTabLabels.length, vsync: this);
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        setState(() {});
      } else {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() {});
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeShowAcademicProfile(),
    );
  }

  void _maybeShowAcademicProfile() {
    if (!mounted) return;
    final authAsync = ref.read(authStateProvider);
    final user = authAsync.hasValue ? authAsync.value : null;
    if (user != null &&
        user.departmentId == null &&
        !academicProfileSessionDismissed) {
      academicProfileSessionDismissed = true;
      showAcademicProfileBottomSheet(context);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool get _isGuest {
    final authAsync = ref.watch(authStateProvider);
    final isAuthenticated = authAsync.hasValue && authAsync.value != null;
    if (isAuthenticated) return false;
    return ref.watch(guestModeProvider);
  }

  List<Post> _filterPosts(List<Post> all, List<String> activeTagFilters) {
    final byTab = switch (_tabController.index) {
      1 => all.where((p) => p.postType == PostType.lectureNote).toList(),
      2 => all.where((p) => p.postType == PostType.exercise).toList(),
      _ => all,
    };
    final byTag = activeTagFilters.isEmpty
        ? byTab
        : byTab
              .where((p) => p.tags.any((t) => activeTagFilters.contains(t)))
              .toList();
    if (_searchQuery.isEmpty) return byTag;
    if (_searchQuery.startsWith('#')) {
      final q = _searchQuery.substring(1).toLowerCase();
      return q.isEmpty
          ? byTag
          : byTag
                .where((p) => p.tags.any((t) => t.toLowerCase().contains(q)))
                .toList();
    }
    final q = _searchQuery.toLowerCase();
    return byTag.where((p) {
      return p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();
  }

  List<String> _buildSuggestions(List<Post> allPosts) {
    if (_searchQuery.isEmpty || !_searchFocusNode.hasFocus) return const [];
    final isTagSearch = _searchQuery.startsWith('#');
    final q = isTagSearch
        ? _searchQuery.substring(1).toLowerCase()
        : _searchQuery.toLowerCase();
    if (q.isEmpty) return const [];

    final suggestions = <String>[];

    final tagLimit = isTagSearch ? 5 : 3;
    final tags = allPosts.expand((p) => p.tags).toSet().toList()..sort();
    for (final tag in tags) {
      if (tag.toLowerCase().contains(q)) {
        suggestions.add('#$tag');
        if (suggestions.length >= tagLimit) break;
      }
    }

    if (!isTagSearch) {
      final seen = <String>{};
      for (final post in allPosts) {
        if (!seen.add(post.title)) continue;
        if (post.title.toLowerCase().contains(q)) {
          suggestions.add(post.title);
          if (suggestions.length >= 5) break;
        }
      }
    }

    return suggestions;
  }

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    setState(() => _searchQuery = suggestion.trim());
    _searchFocusNode.requestFocus();
  }

  void _openFilterPicker(List<Post> allPosts, List<String> activeTagFilters) {
    final availableTags = allPosts.expand((p) => p.tags).toSet().toList()
      ..sort();
    FilterPickerWidget.show(
      context,
      availableTags: availableTags,
      selectedTags: activeTagFilters,
      onConfirm: (selected) =>
          ref.read(activeTagFiltersProvider.notifier).set(selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CreatePostState>(createPostProvider, (_, next) {
      if (!mounted) return;
      if (next is CreatePostPublished) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published!')),
        );
        ref.read(createPostProvider.notifier).reset();
      } else if (next is CreatePostQueued) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved offline — will publish when you reconnect.'),
          ),
        );
        ref.read(createPostProvider.notifier).reset();
      }
    });

    final activeTagFilters = ref.watch(activeTagFiltersProvider);
    final feedAsync = ref.watch(feedProvider);
    final suggestions = _buildSuggestions(feedAsync.value ?? const []);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(child: _buildAppBar(suggestions)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabRowDelegate(
              tabController: _tabController,
              activeFilterCount: activeTagFilters.length,
              onTabChanged: () => setState(() {}),
              onFiltersPressed: () =>
                  _openFilterPicker(feedAsync.value ?? [], activeTagFilters),
            ),
          ),
        ],
        body: feedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Failed to load feed',
              style: TextStyle(
                color: Theme.of(context).extension<AppColors>()!.textMuted,
              ),
            ),
          ),
          data: (allPosts) {
            final posts = _filterPosts(allPosts, activeTagFilters);
            if (posts.isEmpty) {
              return FeedEmptyStateWidget(
                onClear: () =>
                    ref.read(activeTagFiltersProvider.notifier).clear(),
              );
            }
            return AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) => ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: posts.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor,
                ),
                itemBuilder: (_, i) => PostCard(post: posts[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // App bar
  // -------------------------------------------------------------------------

  Widget _buildAppBar(List<String> suggestions) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Container(
        color: theme.cardColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Feed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _buildSearchField()),
                  if (!_isGuest) ...[
                    const SizedBox(width: 8),
                    _buildCreateButton(),
                  ],
                ],
              ),
            ),
            if (suggestions.isNotEmpty) _buildSuggestionChips(suggestions),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChips(List<String> suggestions) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final s = suggestions[i];
          final isTag = s.startsWith('#');
          return GestureDetector(
            onTap: () => _onSuggestionTap(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isTag ? ac.amber.withValues(alpha: 0.08) : ac.muted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isTag
                      ? ac.amber.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                s,
                style: TextStyle(
                  fontSize: 12,
                  color: isTag ? ac.amber : cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (value) => setState(() => _searchQuery = value.trim()),
        style: TextStyle(fontSize: 13, color: cs.onSurface),
        decoration: InputDecoration(
          hintText: 'Search posts or #tags...',
          hintStyle: TextStyle(fontSize: 13, color: ac.textMuted),
          filled: true,
          fillColor: ac.muted,
          prefixIcon: Icon(Icons.search, size: 18, color: ac.textMuted),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: ac.amber, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.push('/posts/create'),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
        child: Icon(Icons.add, color: cs.onPrimary, size: 20),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky tab row delegate
// ---------------------------------------------------------------------------

class _TabRowDelegate extends SliverPersistentHeaderDelegate {
  _TabRowDelegate({
    required this.tabController,
    required this.activeFilterCount,
    required this.onTabChanged,
    required this.onFiltersPressed,
  });

  final TabController tabController;
  final int activeFilterCount;
  final VoidCallback onTabChanged;
  final VoidCallback onFiltersPressed;

  static const _height = 44.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(covariant _TabRowDelegate oldDelegate) => true;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _TabRow(
      tabController: tabController,
      activeFilterCount: activeFilterCount,
      onTabChanged: onTabChanged,
      onFiltersPressed: onFiltersPressed,
    );
  }
}

class _TabRow extends StatelessWidget {
  const _TabRow({
    required this.tabController,
    required this.activeFilterCount,
    required this.onTabChanged,
    required this.onFiltersPressed,
  });

  final TabController tabController;
  final int activeFilterCount;
  final VoidCallback onTabChanged;
  final VoidCallback onFiltersPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          Flexible(
            child: TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: ac.amber,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: ac.amber,
              unselectedLabelColor: ac.textMuted,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.55,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.55,
              ),
              padding: EdgeInsets.zero,
              tabs: _kTabLabels
                  .map((label) => Tab(height: 44, child: Text(label)))
                  .toList(),
              onTap: (_) => onTabChanged(),
            ),
          ),
          _FiltersButton(
            activeCount: activeFilterCount,
            onPressed: onFiltersPressed,
          ),
        ],
      ),
    );
  }
}

class _FiltersButton extends StatelessWidget {
  const _FiltersButton({required this.activeCount, required this.onPressed});

  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          TextButton.icon(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: activeCount > 0 ? ac.amber : ac.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.tune, size: 14),
            label: const Text(
              'Filters',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          if (activeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 16,
                height: 16,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ac.amber,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$activeCount',
                  style: TextStyle(
                    fontSize: 9,
                    color: cs.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
