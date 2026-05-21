import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/core/router/router.dart'
    show academicProfileSessionDismissed;
import 'package:unishare_mobile/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/widgets/academic_profile_dialog.dart';
import 'package:unishare_mobile/features/feed/presentation/providers/feed_filter_provider.dart';
import 'package:unishare_mobile/features/feed/presentation/providers/feed_provider.dart';
import 'package:unishare_mobile/features/feed/presentation/widgets/feed_empty_state_widget.dart';
import 'package:unishare_mobile/features/feed/presentation/widgets/feed_filter_drawer.dart';
import 'package:unishare_mobile/features/feed/presentation/widgets/post_card.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/presentation/providers/create_post_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/semantic_search_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/widgets/main_nav_bar.dart';
import 'package:unishare_mobile/shared/widgets/scroll_to_top_target.dart';

// ---------------------------------------------------------------------------
// Tab labels
// ---------------------------------------------------------------------------

const _kTabLabels = ['ALL', 'NOTES', 'EXERCISES'];

/// Reciprocal Rank Fusion blend of two ranked Post lists. A post that appears
/// in both lists gets the sum of `1 / (k + rank)` from each, naturally
/// floating dual-matched posts to the top. `k = 60` is the published default
/// from Cormack et al. — large enough that rank differences smooth out,
/// small enough that top-ranked items still dominate.
///
/// Pure function; no Riverpod / Flutter dependencies — exported for unit
/// testing. Callers apply tab/filter gating BEFORE calling this (so excluded
/// posts don't get votes in either list).
List<Post> hybridRankRRF(
  List<Post> keywordResults,
  List<Post> semanticPosts, {
  int cap = 30,
  int k = 60,
}) {
  if (semanticPosts.isEmpty) {
    return keywordResults.length <= cap
        ? keywordResults
        : keywordResults.take(cap).toList();
  }
  if (keywordResults.isEmpty) {
    return semanticPosts.length <= cap
        ? semanticPosts
        : semanticPosts.take(cap).toList();
  }

  final scores = <String, double>{};
  final posts = <String, Post>{};
  for (var i = 0; i < keywordResults.length; i++) {
    final p = keywordResults[i];
    scores[p.id] = (scores[p.id] ?? 0) + 1 / (k + i + 1);
    posts[p.id] = p;
  }
  for (var i = 0; i < semanticPosts.length; i++) {
    final p = semanticPosts[i];
    scores[p.id] = (scores[p.id] ?? 0) + 1 / (k + i + 1);
    posts[p.id] = p;
  }
  final ranked = scores.entries.toList()
    ..sort((a, b) {
      final cmp = b.value.compareTo(a.value);
      // Tie-breaker: lexicographic by post ID — deterministic ordering across
      // rebuilds so equal-score items don't cause UI jitter or flaky tests.
      return cmp != 0 ? cmp : a.key.compareTo(b.key);
    });
  return ranked.take(cap).map((e) => posts[e.key]!).toList();
}

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

  /// Debounced copy of [_searchQuery] used to gate the semantic-search
  /// network call. Updated ~300ms after the user stops typing so each
  /// keystroke doesn't fire a worker request. PROP-0011 Phase 4b.
  String _debouncedSearchQuery = '';
  Timer? _searchDebounce;
  static const _searchDebounceMs = 300;
  static const _semanticMinQuery = 3;
  static const _hybridResultCap = 30;

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
    _searchDebounce?.cancel();
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Updates the live query immediately, then schedules a debounced update
  /// to [_debouncedSearchQuery] which gates the semantic-search call.
  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.trim());
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      () {
        if (!mounted) return;
        setState(() => _debouncedSearchQuery = _searchQuery);
      },
    );
  }

  /// Tab + filter constraints applied to semantic results so a search on
  /// the NOTES tab doesn't surface exercises just because they're a
  /// vector neighbour of the query.
  bool _matchesTabAndFilter(Post p, FeedFilterState filter) {
    final tab = _tabController.index;
    if (tab == 1 && p.postType != PostType.lectureNote) return false;
    if (tab == 2 && p.postType != PostType.exercise) return false;
    if (filter.year != null && p.year != filter.year) return false;
    if (filter.courseId != null && p.courseId != filter.courseId) return false;
    if (filter.moduleNumber != null && p.moduleNumber != filter.moduleNumber) {
      return false;
    }
    return true;
  }

  /// Blended hybrid ranking: gate semantic results by tab/filter first
  /// (so a NOTES-tab search doesn't surface exercises), then RRF-merge with
  /// keyword results. Tag-mode (`#foo`) bypasses semantic entirely.
  List<Post> _hybridRank(
    List<Post> keywordResults,
    List<Post> semanticPosts,
    FeedFilterState filter,
  ) {
    if (_searchQuery.startsWith('#')) return keywordResults;
    if (_searchQuery.isEmpty) return keywordResults;
    if (semanticPosts.isEmpty) return keywordResults;

    final gatedSemantic = semanticPosts
        .where((p) => _matchesTabAndFilter(p, filter))
        .toList(growable: false);
    if (gatedSemantic.isEmpty) return keywordResults;

    try {
      return hybridRankRRF(
        keywordResults,
        gatedSemantic,
        cap: _hybridResultCap,
      );
    } catch (e) {
      // Defensive fallback — never block the feed on a rank-blend bug.
      return keywordResults;
    }
  }

  bool get _isGuest {
    final authAsync = ref.watch(authStateProvider);
    final isAuthenticated = authAsync.hasValue && authAsync.value != null;
    if (isAuthenticated) return false;
    return ref.watch(guestModeProvider);
  }

  List<Post> _filterPosts(List<Post> all, FeedFilterState filter) {
    var posts = switch (_tabController.index) {
      1 => all.where((p) => p.postType == PostType.lectureNote).toList(),
      2 => all.where((p) => p.postType == PostType.exercise).toList(),
      _ => all,
    };
    if (filter.year != null) {
      posts = posts.where((p) => p.year == filter.year).toList();
    }
    if (filter.courseId != null) {
      posts = posts.where((p) => p.courseId == filter.courseId).toList();
    }
    if (filter.moduleNumber != null) {
      posts = posts
          .where((p) => p.moduleNumber == filter.moduleNumber)
          .toList();
    }
    if (_searchQuery.isEmpty) return posts;
    if (_searchQuery.startsWith('#')) {
      final q = _searchQuery.substring(1).toLowerCase();
      return q.isEmpty
          ? posts
          : posts
                .where((p) => p.tags.any((t) => t.toLowerCase().contains(q)))
                .toList();
    }
    final q = _searchQuery.toLowerCase();
    return posts.where((p) {
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
    _onSearchChanged(suggestion);
    _searchFocusNode.requestFocus();
  }

  void _openFilterDrawer(List<Post> allPosts) {
    FeedFilterDrawer.show(context, allPosts);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CreatePostState>(createPostProvider, (_, next) {
      if (!mounted) return;
      if (next is CreatePostPublished) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post published!')));
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

    final filter = ref.watch(feedFilterProvider);
    final feedAsync = ref.watch(feedProvider);
    final suggestions = _buildSuggestions(feedAsync.value ?? const []);

    // PROP-0011 Phase 4b — fire semantic search only when the debounced query
    // is long enough and isn't a tag-mode query. Watching an empty-query
    // provider is a no-op, but we want to skip the worker call entirely when
    // there's nothing to search for.
    final shouldSearchSemantic =
        _debouncedSearchQuery.length >= _semanticMinQuery &&
        !_debouncedSearchQuery.startsWith('#');
    final semanticResults = shouldSearchSemantic
        ? ref.watch(semanticSearchProvider(_debouncedSearchQuery)).value ??
              const <Post>[]
        : const <Post>[];
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
              activeFilterCount: filter.activeCount,
              onTabChanged: () => setState(() {}),
              onFiltersPressed: () => _openFilterDrawer(feedAsync.value ?? []),
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
            final keywordResults = _filterPosts(allPosts, filter);
            final posts = _hybridRank(keywordResults, semanticResults, filter);
            if (posts.isEmpty) {
              return FeedEmptyStateWidget(
                onClear: () => ref.read(feedFilterProvider.notifier).clear(),
              );
            }
            return AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) => ListView.separated(
                padding: const EdgeInsets.only(bottom: MainNavBar.bottomInset),
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
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _buildSearchField()),
                  const SizedBox(width: 8),
                  _buildCreateButton(),
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
        onChanged: _onSearchChanged,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: cs.onSurface),
        decoration: InputDecoration(
          hintText: 'Search posts or #tags...',
          hintStyle: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: ac.textMuted),
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
      onTap: () =>
          _isGuest ? context.go('/welcome') : context.push('/posts/create'),
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
              labelStyle: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.55,
              ),
              unselectedLabelStyle: theme.textTheme.bodySmall?.copyWith(
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
            label: Text(
              'Filters',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
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
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
