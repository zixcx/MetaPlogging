import 'package:flutter/material.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';
import 'package:meta_plogging/features/feed/domain/entities/post_entity.dart';

class PostCard extends StatefulWidget {
  final PostEntity post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onBookmark;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onBookmark,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _heartScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _handleLike() {
    _heartController.forward(from: 0);
    widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final post = widget.post;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Author row ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          child: _AuthorRow(post: post, isDark: isDark),
        ),

        // ── Images ────────────────────────────────────────────
        if (post.imageMocks.isNotEmpty)
          _ImageCarousel(imageMocks: post.imageMocks),

        // ── Activity stats ────────────────────────────────────
        if (post.activityStats != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _ActivityPills(stats: post.activityStats!),
          ),

        // ── Caption ───────────────────────────────────────────
        if (post.caption != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _Caption(
              caption: post.caption!,
              isExpanded: _isExpanded,
              onExpand: () => setState(() => _isExpanded = true),
            ),
          ),

        // ── Tags ──────────────────────────────────────────────
        if (post.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _TagRow(tags: post.tags),
          ),

        // ── Action bar ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 14),
          child: _ActionBar(
            post: post,
            heartController: _heartController,
            heartScale: _heartScale,
            onLike: _handleLike,
            onComment: widget.onComment,
            onBookmark: widget.onBookmark,
          ),
        ),

        Divider(
          height: 1,
          thickness: 0.5,
          color: isDark
              ? const Color(0xFF2A4035)
              : const Color(0xFFE8EEE9),
        ),
      ],
    );
  }
}

// ── Author row ─────────────────────────────────────────────────
class _AuthorRow extends StatelessWidget {
  final PostEntity post;
  final bool isDark;

  const _AuthorRow({required this.post, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.secondary, AppColors.primary],
            ),
          ),
          child: Center(
            child: Text(
              post.authorEmoji,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Name + time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Text(
                    _timeAgo(post.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  if (post.locationName != null) ...[
                    Text(
                      ' · ',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        post.locationName!,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Menu
        IconButton(
          icon: Icon(
            Icons.more_horiz_rounded,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          onPressed: () {},
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${diff.inDays ~/ 7}주 전';
  }
}

// ── Image carousel ─────────────────────────────────────────────
class _ImageCarousel extends StatefulWidget {
  final List<String> imageMocks;

  const _ImageCarousel({required this.imageMocks});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.imageMocks.length;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: PageView.builder(
            controller: _pageController,
            itemCount: count,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) =>
                _MockImageWidget(mockKey: widget.imageMocks[i]),
          ),
        ),
        if (count > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                count,
                (i) => _PageDot(isActive: i == _currentPage),
              ),
            ),
          ),
      ],
    );
  }
}

class _PageDot extends StatelessWidget {
  final bool isActive;

  const _PageDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isActive ? 16 : 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : const Color(0xFFCDD6D0),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _MockImageWidget extends StatelessWidget {
  final String mockKey;

  const _MockImageWidget({required this.mockKey});

  @override
  Widget build(BuildContext context) {
    final style = kMockImageStyles[mockKey] ??
        kMockImageStyles['mock:park']!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.colors,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              style.icon,
              size: 96,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                style.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity stats pills ────────────────────────────────────────
class _ActivityPills extends StatelessWidget {
  final PostActivityStats stats;

  const _ActivityPills({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        _Pill(
          icon: Icons.route_rounded,
          label: '${stats.distanceKm}km',
          color: AppColors.primary,
        ),
        _Pill(
          icon: Icons.delete_outline_rounded,
          label: '${stats.trashCount}개 수거',
          color: AppColors.secondary,
        ),
        _Pill(
          icon: Icons.timer_outlined,
          label: '${stats.durationMinutes}분',
          color: AppColors.accent,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Caption ────────────────────────────────────────────────────
class _Caption extends StatelessWidget {
  final String caption;
  final bool isExpanded;
  final VoidCallback onExpand;

  const _Caption({
    required this.caption,
    required this.isExpanded,
    required this.onExpand,
  });

  static const _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface,
      height: 1.55,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: caption, style: baseStyle),
          maxLines: _maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflow = tp.didExceedMaxLines;

        if (!isOverflow || isExpanded) {
          return Text(caption, style: baseStyle);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(caption, style: baseStyle, maxLines: _maxLines,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onExpand,
              child: Text(
                '더보기',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Tags ───────────────────────────────────────────────────────
class _TagRow extends StatelessWidget {
  final List<String> tags;

  const _TagRow({required this.tags});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColors.primary;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags
          .map(
            (tag) => Text(
              '#$tag',
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Action bar ─────────────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  final PostEntity post;
  final AnimationController heartController;
  final Animation<double> heartScale;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onBookmark;

  const _ActionBar({
    required this.post,
    required this.heartController,
    required this.heartScale,
    required this.onLike,
    required this.onComment,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;

    return Row(
      children: [
        // Like
        GestureDetector(
          onTap: onLike,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: heartScale,
                child: Icon(
                  post.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 22,
                  color: post.isLiked ? const Color(0xFFFF4757) : mutedColor,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${post.likeCount}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: post.isLiked ? const Color(0xFFFF4757) : mutedColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),

        // Comment
        GestureDetector(
          onTap: onComment,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 22, color: mutedColor),
              const SizedBox(width: 5),
              Text(
                '${post.commentCount}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),

        // Share
        GestureDetector(
          onTap: () {},
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.ios_share_rounded, size: 20, color: mutedColor),
              const SizedBox(width: 5),
              Text(
                '${post.shareCount}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Bookmark
        GestureDetector(
          onTap: onBookmark,
          child: Icon(
            post.isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            size: 22,
            color: post.isBookmarked ? AppColors.primary : mutedColor,
          ),
        ),
      ],
    );
  }
}
