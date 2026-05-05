import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    final posts = ref.watch(feedProvider);
    final notifier = ref.read(feedProvider.notifier);

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── App bar ──────────────────────────────────────────
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

          // ── Feed list ─────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = posts[index];
                return PostCard(
                  key: ValueKey(post.id),
                  post: post,
                  onLike: () => notifier.toggleLike(post.id),
                  onComment: () => _showCommentHint(context, isDark),
                  onBookmark: () => notifier.toggleBookmark(post.id),
                );
              },
              childCount: posts.length,
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
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
