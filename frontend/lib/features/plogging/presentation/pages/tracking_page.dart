import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';
import 'package:meta_plogging/features/plogging/presentation/providers/tracking_provider.dart';
import 'package:meta_plogging/features/plogging/presentation/widgets/end_session_sheet.dart';
import 'package:meta_plogging/features/plogging/presentation/widgets/trash_mark_sheet.dart';

class TrackingPage extends ConsumerStatefulWidget {
  const TrackingPage({super.key});

  @override
  ConsumerState<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends ConsumerState<TrackingPage> {
  NaverMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackingProvider);
    final notifier = ref.read(trackingProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 에러 처리
    ref.listen<TrackingState>(trackingProvider, (prev, next) {
      final err = next.error;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
        notifier.clearError();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1A14) : const Color(0xFFF0F7F2),
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 통계 바 ─────────────────────────────────
            _StatsBar(state: state, isDark: isDark),

            // ── 지도 ─────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  NaverMap(
                    options: NaverMapViewOptions(
                      initialCameraPosition: NCameraPosition(
                        target: state.currentPosition ??
                            const NLatLng(37.5665, 126.9780),
                        zoom: 16,
                      ),
                      locationButtonEnable: true,
                      consumeSymbolTapEvents: false,
                    ),
                    onMapReady: (controller) {
                      _mapController = controller;
                      controller.setLocationTrackingMode(
                        NLocationTrackingMode.follow,
                      );
                    },
                    forceGesture: false,
                  ),

                  // 경로 오버레이는 controller 통해 갱신
                  _MapOverlayUpdater(
                    controller: _mapController,
                    state: state,
                  ),
                ],
              ),
            ),

            // ── 하단 버튼 ─────────────────────────────────────
            _BottomControls(
              state: state,
              isDark: isDark,
              onPause: notifier.pauseSession,
              onResume: notifier.resumeSession,
              onEnd: () => _showEndSheet(context, state, notifier),
              onTrash: () => _showTrashSheet(context, notifier),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrashSheet(BuildContext ctx, TrackingNotifier notifier) {
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrashMarkSheet(
        onConfirm: (cat) => notifier.addTrashPoint(cat),
      ),
    );
  }

  void _showEndSheet(
      BuildContext ctx, TrackingState state, TrackingNotifier notifier) {
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EndSessionSheet(
        distanceKm: state.distanceKm.toStringAsFixed(2),
        duration: state.formattedTime,
        onConfirm: ({required trashItems, required locationDescription}) async {
          final session = await notifier.endSession(
            trashItems: trashItems,
            locationDescription: locationDescription,
          );
          if (session != null && ctx.mounted) {
            Navigator.of(ctx).pop(); // TrackingPage 닫기
          }
        },
      ),
    );
  }
}

// ── 지도 오버레이 갱신 ─────────────────────────────────────────
class _MapOverlayUpdater extends ConsumerStatefulWidget {
  final NaverMapController? controller;
  final TrackingState state;

  const _MapOverlayUpdater({required this.controller, required this.state});

  @override
  ConsumerState<_MapOverlayUpdater> createState() =>
      _MapOverlayUpdaterState();
}

class _MapOverlayUpdaterState extends ConsumerState<_MapOverlayUpdater> {
  @override
  void didUpdateWidget(_MapOverlayUpdater old) {
    super.didUpdateWidget(old);
    _updateOverlays();
  }

  Future<void> _updateOverlays() async {
    final ctrl = widget.controller;
    if (ctrl == null) return;

    final path = widget.state.path;
    if (path.length >= 2) {
      await ctrl.clearOverlays();
      final polyline = NPolylineOverlay(
        id: 'route',
        coords: path,
        color: AppColors.primary,
        width: 5,
      );
      await ctrl.addOverlay(polyline);
    }

    // 쓰레기 마커
    if (!mounted) return;
    final ctx = context;
    for (final tp in widget.state.trashPoints) {
      // ignore: use_build_context_synchronously
      final icon = await NOverlayImage.fromWidget(
        widget: const Icon(
          Icons.delete_rounded,
          color: Colors.orange,
          size: 24,
        ),
        size: const Size(24, 24),
        context: ctx, // ignore: use_build_context_synchronously
      );
      final marker = NMarker(
        id: tp.id,
        position: NLatLng(tp.lat, tp.lng),
        icon: icon,
      );
      await ctrl.addOverlay(marker);
    }

    // 카메라 현재 위치 따라가기
    final pos = widget.state.currentPosition;
    if (pos != null && widget.state.isActive) {
      await ctrl.updateCamera(
        NCameraUpdate.withParams(target: pos),
      );
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ── 상단 통계 바 ───────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final TrackingState state;
  final bool isDark;

  const _StatsBar({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.timer_outlined,
            value: state.formattedTime,
            label: '시간',
            color: AppColors.primary,
          ),
          _StatChip(
            icon: Icons.route_rounded,
            value: '${state.distanceKm.toStringAsFixed(2)}km',
            label: '거리',
            color: AppColors.secondary,
          ),
          _StatChip(
            icon: Icons.delete_outline_rounded,
            value: '${state.totalTrashCount}개',
            label: '수거',
            color: AppColors.accent,
          ),
          const Spacer(),
          // 상태 표시
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: state.isPaused
                  ? Colors.orange.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.isPaused ? Colors.orange : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  state.isPaused ? '일시정지' : '기록 중',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:
                        state.isPaused ? Colors.orange : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 하단 컨트롤 ────────────────────────────────────────────────
class _BottomControls extends StatelessWidget {
  final TrackingState state;
  final bool isDark;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onEnd;
  final VoidCallback onTrash;

  const _BottomControls({
    required this.state,
    required this.isDark,
    required this.onPause,
    required this.onResume,
    required this.onEnd,
    required this.onTrash,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 쓰레기 마킹
          _CircleButton(
            icon: Icons.delete_outline_rounded,
            label: '쓰레기',
            color: AppColors.accent,
            onTap: state.isActive ? onTrash : null,
          ),
          const SizedBox(width: 12),

          // 일시정지 / 재개
          _CircleButton(
            icon: state.isPaused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            label: state.isPaused ? '재개' : '일시정지',
            color: Colors.orange,
            onTap: state.isPaused ? onResume : onPause,
          ),
          const Spacer(),

          // 종료
          GestureDetector(
            onTap: onEnd,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '종료',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _CircleButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled
                  ? color.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.08),
              border: Border.all(
                color: enabled
                    ? color.withValues(alpha: 0.4)
                    : Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              icon,
              color: enabled ? color : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: enabled
                  ? theme.colorScheme.onSurface
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
