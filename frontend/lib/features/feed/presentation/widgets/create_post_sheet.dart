import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';
import 'package:meta_plogging/features/auth/presentation/providers/auth_provider.dart';
import 'package:meta_plogging/features/feed/presentation/providers/feed_provider.dart';
import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';
import 'package:meta_plogging/features/profile/presentation/providers/profile_provider.dart';

class CreatePostSheet extends ConsumerStatefulWidget {
  const CreatePostSheet({super.key});

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet> {
  final _captionController = TextEditingController();
  final List<XFile> _selectedFiles = [];
  TrackingSessionEntity? _attachedSession;
  bool _isPosting = false;

  // 백엔드: caption 필수 + (images 또는 tracking_id) 중 하나 이상 필수
  bool get _canPost =>
      _captionController.text.isNotEmpty &&
      (_selectedFiles.isNotEmpty || _attachedSession != null);

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _handlePost() async {
    if (!_canPost) return;
    setState(() => _isPosting = true);

    try {
      await ref.read(feedProvider.notifier).createPost(
            caption: _captionController.text,
            imageFiles: _selectedFiles.map((f) => File(f.path)).toList(),
            session: _attachedSession,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPosting = false);

      String message = '게시 실패';
      if (e is DioException) {
        final detail = e.response?.data;
        if (detail != null) {
          message = '게시 실패 (${e.response?.statusCode}): $detail';
        } else {
          message = '게시 실패: ${e.message}';
        }
      } else {
        message = '게시 실패: $e';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _pickImages() async {
    if (_selectedFiles.length >= 5) return;
    final picker = ImagePicker();
    final remaining = 5 - _selectedFiles.length;
    final picked = await picker.pickMultiImage(limit: remaining);
    if (picked.isNotEmpty) {
      setState(() => _selectedFiles.addAll(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(authProvider).asData?.value;
    final authorName = user?.name ?? '플로깅 러너';
    final recentSessions = ref.watch(recentSessionsProvider);
    final latestSession = recentSessions.asData?.value.firstOrNull;

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
                  onPressed: _canPost && !_isPosting ? _handlePost : null,
                  child: _isPosting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          '게시',
                          style: TextStyle(
                            color: _canPost
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
                          child:
                              Text('🌿', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authorName,
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
                  if (_selectedFiles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedFiles.length + 1,
                        separatorBuilder: (context, i) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          if (i == _selectedFiles.length) {
                            return _selectedFiles.length < 5
                                ? _AddImageButton(onTap: _pickImages)
                                : const SizedBox.shrink();
                          }
                          return _FileThumb(
                            file: _selectedFiles[i],
                            onRemove: () =>
                                setState(() => _selectedFiles.removeAt(i)),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    _AddImageButton(onTap: _pickImages),
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
                  if (latestSession != null)
                    _ActivityAttachTile(
                      session: latestSession,
                      isAttached: _attachedSession?.id == latestSession.id,
                      onToggle: () => setState(() {
                        _attachedSession =
                            _attachedSession?.id == latestSession.id
                                ? null
                                : latestSession;
                      }),
                      isDark: isDark,
                    )
                  else
                    Text(
                      '완료된 플로깅 기록이 없어요',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
}

// ── File thumbnail ──────────────────────────────────────────────
class _FileThumb extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;

  const _FileThumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Image.file(
            File(file.path),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
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
            const Icon(Icons.add_photo_alternate_outlined,
                size: 24, color: AppColors.primary),
            const SizedBox(height: 4),
            const Text(
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
  final TrackingSessionEntity session;
  final bool isAttached;
  final VoidCallback onToggle;
  final bool isDark;

  const _ActivityAttachTile({
    required this.session,
    required this.isAttached,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationLabel = session.locationLandmarkName ??
        session.locationDescription ??
        '플로깅 기록';
    final stats =
        '${session.distanceKm.toStringAsFixed(1)}km · ${session.totalTrashCount}개 수거 · ${session.durationSeconds ~/ 60}분';

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isAttached
              ? AppColors.primary.withValues(alpha: 0.06)
              : (isDark
                  ? const Color(0xFF1E3528)
                  : const Color(0xFFF6FBF7)),
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
                    locationLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stats,
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
