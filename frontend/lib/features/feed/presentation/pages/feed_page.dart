import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';
import 'package:meta_plogging/features/feed/presentation/providers/feed_provider.dart';
import 'package:meta_plogging/features/feed/presentation/widgets/create_post_sheet.dart';
import 'package:meta_plogging/features/feed/presentation/widgets/post_card.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  final _scrollController = ScrollController();
  bool _isFabVisible = true;
  DateTime? _lastRefreshTime;

  static const _refreshCooldown = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && _isFabVisible) {
      setState(() => _isFabVisible = false);
    } else if (direction == ScrollDirection.forward && !_isFabVisible) {
      setState(() => _isFabVisible = true);
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();

    final now = DateTime.now();
    final elapsed =
        _lastRefreshTime == null ? null : now.difference(_lastRefreshTime!);

    if (elapsed == null || elapsed >= _refreshCooldown) {
      _lastRefreshTime = now;
      await ref.read(feedProvider.notifier).refresh();
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  void _openCreateSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreatePostSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final postsAsync = ref.watch(feedProvider);
    final notifier = ref.read(feedProvider.notifier);

    return Scaffold(
      backgroundColor: cs.surface,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        displacement: 60,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── App bar ─────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: cs.surface,
              scrolledUnderElevation: 0,
              title: Text('피드', style: theme.textTheme.titleLarge),
              actions: [
                IconButton(
                  icon: Icon(Icons.search_rounded, color: cs.onSurface),
                  onPressed: () {},
                ),
              ],
            ),

            // ── Content ──────────────────────────────────────────
            postsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (e, st) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text('피드를 불러오지 못했어요',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () => ref.invalidate(feedProvider),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (posts) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = posts[index];
                    return PostCard(
                      key: ValueKey(post.id),
                      post: post,
                      onLike: () => notifier.toggleLike(post.id, post.isLiked),
                      onComment: () => _showCommentHint(context, isDark),
                      onBookmark: () => notifier.toggleBookmark(post.id),
                    );
                  },
                  childCount: posts.length,
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),

      // ── FAB ────────────────────────────────────────────────
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2.5),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: _isFabVisible ? 1.0 : 0.0,
          child: FloatingActionButton(
            onPressed: _openCreateSheet,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.edit_rounded, size: 22),
          ),
        ),
      ),
    );
  }

  void _showCommentHint(BuildContext context, bool isDark) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('댓글 기능은 준비 중입니다'),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF1E3528) : AppColors.primaryDark,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
