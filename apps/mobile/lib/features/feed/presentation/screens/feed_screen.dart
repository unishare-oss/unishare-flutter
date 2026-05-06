import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/core/router/router.dart'
    show academicProfileSessionDismissed;
import 'package:unishare_mobile/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/widgets/academic_profile_dialog.dart';
import 'package:unishare_mobile/features/feed/presentation/providers/active_tag_filters_provider.dart';
import 'package:unishare_mobile/features/feed/presentation/widgets/feed_empty_state_widget.dart';
import 'package:unishare_mobile/features/feed/presentation/widgets/filter_picker_widget.dart';
import 'package:unishare_mobile/features/feed/presentation/widgets/post_card_widget.dart';
import 'package:unishare_mobile/shared/widgets/scroll_to_top_target.dart';

// ---------------------------------------------------------------------------
// Color constants
// ---------------------------------------------------------------------------

const _kOrange = Color(0xFFD97706);
const _kBorder = Color(0xFFE2DAD0);
const _kMuted = Color(0xFFF7F3EE);
const _kTextMuted = Color(0xFF8A837E);
const _kForeground = Color(0xFF1C1917);

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

const _mockPosts = [
  MockPost(
    type: MockPostType.note,
    courseCode: 'CSC233',
    title: 'LR Parsing',
    topicTags: [],
    authorInitials: 'LYP',
    authorName: 'La Yaung Phyo',
    authorYear: 1,
    commentCount: 0,
    timeAgo: '21 days ago',
  ),
  MockPost(
    type: MockPostType.note,
    courseCode: 'CSC220',
    title: '3.7 TCP Congestion Control (jim kurose)',
    topicTags: ['networking'],
    authorInitials: 'MTK',
    authorName: 'May Thu Khaing',
    authorYear: 2,
    commentCount: 2,
    timeAgo: '15 days ago',
  ),
  MockPost(
    type: MockPostType.note,
    courseCode: 'CSC220',
    title: 'Gemini Notes for Network',
    topicTags: ['networking'],
    authorInitials: 'HOJ',
    authorName: 'HackerOrJoker',
    authorYear: 1,
    commentCount: 1,
    timeAgo: '16 days ago',
  ),
  MockPost(
    type: MockPostType.note,
    courseCode: 'CSC217',
    title: 'Chapter 7',
    topicTags: [
      'concurrency',
      'data structures',
      'system design',
      'software engineering',
      'os',
    ],
    authorInitials: 'S',
    authorName: 'Slade',
    authorYear: 2,
    commentCount: 0,
    timeAgo: '19 days ago',
  ),
  MockPost(
    type: MockPostType.assignment,
    courseCode: 'CSC233',
    title: 'Assignment 9 - Regular expressions (more) of texts and',
    topicTags: [],
    authorInitials: 'LYP',
    authorName: 'La Yaung Phyo',
    authorYear: 1,
    commentCount: 2,
    timeAgo: 'about 1 month ago',
  ),
  MockPost(
    type: MockPostType.assignment,
    courseCode: 'GEN231',
    title: 'M2_Final_Assignment',
    topicTags: [],
    authorInitials: 'TPT',
    authorName: 'Thiha Phone Thaw',
    authorYear: 1,
    commentCount: 0,
    timeAgo: 'about 1 month ago',
  ),
];

// All curated tags available in the picker (superset of tags on mock posts)
const _kAvailableTags = [
  'concurrency',
  'data structures',
  'linux',
  'memory management',
  'networking',
  'os',
  'software engineering',
  'system design',
];

// ---------------------------------------------------------------------------
// Tab labels
// ---------------------------------------------------------------------------

const _kTabLabels = ['ALL', 'NOTES', 'ASSIGNMENTS'];

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

  @override
  ScrollController get scrollController => _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _kTabLabels.length, vsync: this);
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
    super.dispose();
  }

  bool get _isGuest {
    final authAsync = ref.watch(authStateProvider);
    final isAuthenticated = authAsync.hasValue && authAsync.value != null;
    if (isAuthenticated) return false;
    return ref.watch(guestModeProvider);
  }

  List<MockPost> _visiblePosts(List<String> activeTagFilters) {
    final posts = switch (_tabController.index) {
      1 => _mockPosts.where((p) => p.type == MockPostType.note).toList(),
      2 => _mockPosts.where((p) => p.type == MockPostType.assignment).toList(),
      _ => _mockPosts,
    };

    if (activeTagFilters.isEmpty) return posts;
    return posts
        .where((p) => p.topicTags.any((t) => activeTagFilters.contains(t)))
        .toList();
  }

  void _openFilterPicker(List<String> activeTagFilters) {
    FilterPickerWidget.show(
      context,
      availableTags: _kAvailableTags,
      selectedTags: activeTagFilters,
      onConfirm: (selected) =>
          ref.read(activeTagFiltersProvider.notifier).set(selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTagFilters = ref.watch(activeTagFiltersProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(child: _buildAppBar()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabRowDelegate(
              tabController: _tabController,
              activeFilterCount: activeTagFilters.length,
              onTabChanged: () => setState(() {}),
              onFiltersPressed: () => _openFilterPicker(activeTagFilters),
            ),
          ),
        ],
        body: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            final posts = _visiblePosts(activeTagFilters);
            if (posts.isEmpty) {
              return FeedEmptyStateWidget(
                onClear: () =>
                    ref.read(activeTagFiltersProvider.notifier).clear(),
              );
            }
            return ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: posts.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, thickness: 1, color: _kBorder),
              itemBuilder: (context, index) =>
                  PostCardWidget(post: posts[index]),
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // App bar
  // -------------------------------------------------------------------------

  Widget _buildAppBar() {
    return SafeArea(
      bottom: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Text(
              'Feed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _kForeground,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _buildSearchField()),
            if (!_isGuest) ...[const SizedBox(width: 8), _buildCreateButton()],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 38,
      child: TextField(
        style: const TextStyle(fontSize: 13, color: _kForeground),
        decoration: InputDecoration(
          hintText: 'Search posts or #tags...',
          hintStyle: const TextStyle(fontSize: 13, color: _kTextMuted),
          filled: true,
          fillColor: _kMuted,
          prefixIcon: const Icon(Icons.search, size: 18, color: _kTextMuted),
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
            borderSide: const BorderSide(color: _kOrange, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: () => context.push('/posts/create'),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: _kOrange,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
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
  bool shouldRebuild(covariant _TabRowDelegate oldDelegate) =>
      oldDelegate.tabController != tabController ||
      oldDelegate.activeFilterCount != activeFilterCount;

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
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(
        children: [
          Flexible(
            child: TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: _kOrange,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: _kOrange,
              unselectedLabelColor: _kTextMuted,
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
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          TextButton.icon(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: activeCount > 0 ? _kOrange : _kTextMuted,
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
                decoration: const BoxDecoration(
                  color: _kOrange,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$activeCount',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
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
