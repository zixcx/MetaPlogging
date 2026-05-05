import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';
import 'package:meta_plogging/features/feed/domain/entities/post_entity.dart';
import 'package:meta_plogging/features/feed/presentation/providers/feed_provider.dart';

class CreatePostSheet extends ConsumerStatefulWidget {
  const CreatePostSheet({super.key});

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet> {
  final _captionController = TextEditingController();
  final List<String> _selectedImages = [];
  bool _attachActivity = false;
  bool _isPosting = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _handlePost() async {
    if (_captionController.text.isEmpty && _selectedImages.isEmpty) return;

    setState(() => _isPosting = true);
    await Future.delayed(const Duration(milliseconds: 400));

    final post = PostEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorName: '플로깅 러너',
      authorEmoji: '🌿',
      imageMocks: List.from(_selectedImages),
      caption: _captionController.text.isEmpty
          ? null
          : _captionController.text,
      activityStats: _attachActivity
          ? const PostActivityStats(
              distanceKm: 3.2, trashCount: 24, durationMinutes: 42)
          : null,
      likeCount: 0,
      commentCount: 0,
      shareCount: 0,
      createdAt: DateTime.now(),
      locationName: _attachActivity ? '한강 반포지구' : null,
    );

    ref.read(feedProvider.notifier).addPost(post);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canPost =
        _captionController.text.isNotEmpty || _selectedImages.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────────
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A4035)
                  : const Color(0xFFDDE5DE),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '취소',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '새 게시글',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: canPost && !_isPosting ? _handlePost : null,
                  child: _isPosting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                      : Text(
                          '게시',
                          style: TextStyle(
                            color: canPost
                                ? AppColors.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Body ────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author + Text field
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        child: const Center(
                          child: Text('🌿',
                              style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '플로깅 러너',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _captionController,
                              onChanged: (_) => setState(() {}),
                              maxLines: null,
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: '오늘 어떤 플로깅을 했나요?',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                fillColor: Colors.transparent,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Selected images preview
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length + 1,
                        separatorBuilder: (context, i) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          if (i == _selectedImages.length) {
                            return _AddImageButton(
                              onTap: _showImagePicker,
                            );
                          }
                          final key = _selectedImages[i];
                          final style = kMockImageStyles[key]!;
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              children: [
                                Container(
                                  width: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: style.colors,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(style.icon,
                                        size: 28,
                                        color: Colors.white
                                            .withValues(alpha: 0.4)),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _selectedImages.removeAt(i)),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    _AddImageButton(onTap: _showImagePicker),
                  ],

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Attach activity section
                  Text(
                    '최근 활동 연결',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _ActivityAttachTile(
                    isAttached: _attachActivity,
                    onToggle: () =>
                        setState(() => _attachActivity = !_attachActivity),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Safe area bottom ─────────────────────────────────
          SizedBox(height: MediaQuery.viewPaddingOf(context).bottom + 8),
        ],
      ),
    );
  }

  void _showImagePicker() {
    if (_selectedImages.length >= 3) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _ImagePickerSheet(
        onSelect: (key) {
          Navigator.pop(ctx);
          setState(() => _selectedImages.add(key));
        },
      ),
    );
  }
}

// ── Add image button ───────────────────────────────────────────
class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddImageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E3528)
              : const Color(0xFFF0F7F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? const Color(0xFF2A4035)
                : const Color(0xFFD0E8D8),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 24, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              '사진 추가',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Activity attach tile ───────────────────────────────────────
class _ActivityAttachTile extends StatelessWidget {
  final bool isAttached;
  final VoidCallback onToggle;
  final bool isDark;

  const _ActivityAttachTile({
    required this.isAttached,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isAttached
              ? AppColors.primary.withValues(alpha: 0.06)
              : (isDark ? const Color(0xFF1E3528) : const Color(0xFFF6FBF7)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isAttached
                ? AppColors.primary.withValues(alpha: 0.4)
                : (isDark
                    ? const Color(0xFF2A4035)
                    : const Color(0xFFE0EDE4)),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_run_rounded,
                  size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘 07:32 · 한강 반포지구',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '3.2km · 24개 수거 · 42분',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isAttached
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 22,
              color: isAttached
                  ? AppColors.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Image picker sheet ─────────────────────────────────────────
class _ImagePickerSheet extends StatelessWidget {
  final void Function(String key) onSelect;

  const _ImagePickerSheet({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('배경 선택',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
              children: kMockImageStyles.entries.map((e) {
                final style = e.value;
                return GestureDetector(
                  onTap: () => onSelect(e.key),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
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
                            child: Icon(style.icon,
                                size: 36,
                                color:
                                    Colors.white.withValues(alpha: 0.3)),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Text(
                              style.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
