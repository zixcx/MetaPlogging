import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';
import 'package:meta_plogging/features/plogging/data/repositories/tracking_repository_impl.dart';
import 'package:meta_plogging/features/plogging/domain/entities/session_photo_entity.dart';
import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';
import 'package:meta_plogging/features/plogging/presentation/providers/session_photos_provider.dart';
import 'package:meta_plogging/features/plogging/presentation/providers/sessions_provider.dart';

class SessionDetailPage extends ConsumerWidget {
  final String sessionId;

  const SessionDetailPage({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(
      _sessionDetailProvider(sessionId),
    );
    final photosAsync = ref.watch(sessionPhotosProvider(sessionId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오기 실패: $e')),
        data: (session) => _DetailBody(
          session: session,
          photosAsync: photosAsync,
          onAddPhotos: () => _pickAndUpload(context, ref),
          onDeletePhoto: (photo) =>
              _confirmDelete(context, ref, session.id, photo),
          onDeleteSession: () => _confirmDeleteSession(context, ref, session.id),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSession(
    BuildContext context,
    WidgetRef ref,
    String sid,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('이 플로깅 기록을 삭제할까요?\n삭제된 기록은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(trackingRepositoryProvider).deleteSession(sid);
      ref.read(completedSessionsProvider.notifier).refresh();
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;

    final notifier =
        ref.read(sessionPhotosProvider(sessionId).notifier);
    for (final xFile in files) {
      await notifier.uploadPhoto(File(xFile.path));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String sid,
    SessionPhotoEntity photo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('사진 삭제'),
        content: const Text('이 사진을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref
          .read(sessionPhotosProvider(sid).notifier)
          .deletePhoto(photo.id);
    }
  }
}

// ── 세션 상세 Provider ────────────────────────────────────────────
final _sessionDetailProvider = FutureProvider.family<TrackingSessionEntity, String>(
  (ref, sessionId) =>
      ref.read(trackingRepositoryProvider).getSession(sessionId),
);

// ── 본문 ────────────────────────────────────────────────────────
class _DetailBody extends StatelessWidget {
  final TrackingSessionEntity session;
  final AsyncValue<List<SessionPhotoEntity>> photosAsync;
  final VoidCallback onAddPhotos;
  final void Function(SessionPhotoEntity) onDeletePhoto;
  final VoidCallback onDeleteSession;

  const _DetailBody({
    required this.session,
    required this.photosAsync,
    required this.onAddPhotos,
    required this.onDeletePhoto,
    required this.onDeleteSession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        // ── AppBar ──────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
          backgroundColor: cs.surface,
          scrolledUnderElevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.locationLandmarkName ?? '플로깅 기록',
                style: theme.textTheme.titleMedium,
              ),
              Text(
                _formatDate(session.startedAt),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: onDeleteSession,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: '기록 삭제',
              style: IconButton.styleFrom(foregroundColor: cs.error),
            ),
          ],
        ),

        // ── 지도 ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _MapSection(session: session),
        ),

        // ── 통계 ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _StatsSection(session: session, isDark: isDark),
        ),

        // ── 사진 섹션 ─────────────────────────────────────────
        photosAsync.when(
          loading: () => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('수집 사진', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text('사진을 불러올 수 없습니다.',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ),
          ),
          data: (photos) => photos.isEmpty
              ? SliverToBoxAdapter(
                  child: _EmptyPhotos(
                    isDark: isDark,
                    onAdd: onAddPhotos,
                  ),
                )
              : SliverMainAxisGroup(slivers: [
                  // 헤더 + 아이콘 추가 버튼
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        children: [
                          Text('수집 사진', style: theme.textTheme.titleMedium),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: onAddPhotos,
                            icon: const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 18),
                            label: const Text('사진 추가'),
                            style: TextButton.styleFrom(
                              foregroundColor: cs.primary,
                              backgroundColor: cs.primaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 사진 그리드
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _PhotoTile(
                          photo: photos[i],
                          onLongPress: () => onDeletePhoto(photos[i]),
                        ),
                        childCount: photos.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                    ),
                  ),
                ]),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

// ── 지도 섹션 ─────────────────────────────────────────────────────
class _MapSection extends StatefulWidget {
  final TrackingSessionEntity session;

  const _MapSection({required this.session});

  @override
  State<_MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<_MapSection> {
  NaverMapController? _ctrl;

  @override
  Widget build(BuildContext context) {
    final path = widget.session.path;
    final center = path.isNotEmpty
        ? path[path.length ~/ 2]
        : const NLatLng(37.5665, 126.9780);

    return SizedBox(
      height: 220,
      child: NaverMap(
        options: NaverMapViewOptions(
          initialCameraPosition: NCameraPosition(target: center, zoom: 15),
          locationButtonEnable: false,
          scrollGesturesEnable: false,
          zoomGesturesEnable: false,
          tiltGesturesEnable: false,
          rotationGesturesEnable: false,
        ),
        onMapReady: (ctrl) async {
          _ctrl = ctrl;
          if (path.length >= 2) {
            await ctrl.addOverlay(NPolylineOverlay(
              id: 'route',
              coords: path,
              color: AppColors.primary,
              width: 5,
            ));
          }
          if (path.isNotEmpty) {
            await ctrl.addOverlay(
              NMarker(id: 'start', position: path.first)
                ..setIconTintColor(AppColors.primary),
            );
            await ctrl.addOverlay(
              NMarker(id: 'end', position: path.last)
                ..setIconTintColor(AppColors.secondary),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }
}

// ── 통계 섹션 ────────────────────────────────────────────────────
class _StatsSection extends StatelessWidget {
  final TrackingSessionEntity session;
  final bool isDark;

  const _StatsSection({required this.session, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.route_rounded,
            value: session.distanceKm.toStringAsFixed(2),
            unit: 'km',
            label: '거리',
          ),
          Container(width: 1, height: 40, color: cs.outlineVariant),
          _StatItem(
            icon: Icons.timer_outlined,
            value: session.formattedDuration,
            unit: '',
            label: '시간',
          ),
          Container(width: 1, height: 40, color: cs.outlineVariant),
          _StatItem(
            icon: Icons.local_fire_department_outlined,
            value: '${(session.distanceMeters * 0.06).round()}',
            unit: 'kcal',
            label: '칼로리',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

// ── 사진 없을 때 ──────────────────────────────────────────────────
class _EmptyPhotos extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAdd;

  const _EmptyPhotos({required this.isDark, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.photo_library_outlined,
              size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            '아직 사진이 없습니다',
            style: theme.textTheme.titleSmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            '수집한 사진을 추가해보세요.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: const Text('사진 추가'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 사진 타일 ────────────────────────────────────────────────────
class _PhotoTile extends StatelessWidget {
  final SessionPhotoEntity photo;
  final VoidCallback onLongPress;

  const _PhotoTile({required this.photo, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullscreen(context),
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          photo.url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(Icons.broken_image_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  void _showFullscreen(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            scrolledUnderElevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(photo.url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
