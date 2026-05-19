import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';
import 'package:meta_plogging/features/plogging/presentation/providers/sessions_provider.dart';
import 'package:meta_plogging/features/plogging/presentation/providers/tracking_provider.dart';
import 'package:meta_plogging/features/plogging/presentation/widgets/end_session_sheet.dart';

class TrackingPage extends ConsumerStatefulWidget {
  const TrackingPage({super.key});

  @override
  ConsumerState<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends ConsumerState<TrackingPage> {
  NaverMapController? _mapController;
  bool _isFollowing = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackingProvider);
    final notifier = ref.read(trackingProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
      backgroundColor:
          isDark ? const Color(0xFF0F1A14) : const Color(0xFFF0F7F2),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          // ── 지도 (상단 풀블리드 — Dynamic Island 아래까지) ──
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
                    locationButtonEnable: false,
                    consumeSymbolTapEvents: false,
                  ),
                  onMapReady: (controller) {
                    _mapController = controller;
                    controller.setLocationTrackingMode(
                      NLocationTrackingMode.follow,
                    );
                  },
                  onCameraChange: (reason, animated) {
                    if (reason == NCameraUpdateReason.gesture &&
                        _isFollowing) {
                      setState(() => _isFollowing = false);
                      _mapController?.setLocationTrackingMode(
                        NLocationTrackingMode.noFollow,
                      );
                    }
                  },
                  forceGesture: false,
                ),

                // 경로·마커 오버레이 갱신
                _MapOverlayUpdater(
                  controller: _mapController,
                  state: state,
                ),

                // ── 내 위치 따라가기 버튼 ──────────────────────
                if (!_isFollowing)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isFollowing = true);
                        _mapController?.setLocationTrackingMode(
                          NLocationTrackingMode.follow,
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── 하단 컨트롤 + 통계 (홈 인디케이터 위 safe area 확보) ──
          ColoredBox(
            color: isDark ? const Color(0xFF0A1410) : const Color(0xFFF8FBF9),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BottomControls(
                    state: state,
                    isDark: isDark,
                    onPause: notifier.pauseSession,
                    onResume: notifier.resumeSession,
                    onEnd: () => _showEndSheet(context, state, notifier),
                    onDiscard: () => _confirmDiscard(context, notifier),
                  ),
                  _StatsBar(state: state, isDark: isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDiscard(
      BuildContext ctx, TrackingNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('현재 플로깅 기록을 저장하지 않고 삭제할까요?\n삭제된 기록은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await notifier.discardSession();
      if (success && ctx.mounted) {
        Navigator.of(ctx, rootNavigator: true).pop();
      }
    }
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
            ref.read(completedSessionsProvider.notifier).refresh();
            Navigator.of(ctx).pop();
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

    // 카메라 이동 없음 — NLocationTrackingMode.follow 가 담당
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ── 하단 통계 바 ────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final TrackingState state;
  final bool isDark;

  const _StatsBar({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1410) : const Color(0xFFF8FBF9),
        border: Border(
          top: BorderSide(color: cs.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.timer_outlined,
            value: state.formattedTime,
            label: '시간',
          ),
          _StatChip(
            icon: Icons.route_rounded,
            value: '${state.distanceKm.toStringAsFixed(2)}km',
            label: '거리',
          ),
          _StatChip(
            icon: Icons.photo_library_outlined,
            value: '${state.photoCount}장',
            label: '사진',
          ),
          const Spacer(),
          if (state.isPaused)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
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
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '일시정지',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            const _PingBadge(),
        ],
      ),
    );
  }
}

// ── Ping 애니메이션 뱃지 ──────────────────────────────────────
class _PingBadge extends StatefulWidget {
  const _PingBadge();

  @override
  State<_PingBadge> createState() => _PingBadgeState();
}

class _PingBadgeState extends State<_PingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  static const _green = Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _scale = Tween<double>(begin: 1.0, end: 2.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 퍼져나가는 ping 링
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, child) => Transform.scale(
                    scale: _scale.value,
                    child: Opacity(
                      opacity: _opacity.value,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _green,
                        ),
                      ),
                    ),
                  ),
                ),
                // 고정 dot
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '기록 중',
            style: theme.textTheme.labelSmall?.copyWith(
              color: _green,
              fontWeight: FontWeight.w800,
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

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: cs.primary),
              const SizedBox(width: 3),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
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
  final VoidCallback onDiscard;

  const _BottomControls({
    required this.state,
    required this.isDark,
    required this.onPause,
    required this.onResume,
    required this.onEnd,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
          // 일시정지 / 재개
          _CircleButton(
            icon: state.isPaused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            label: state.isPaused ? '재개' : '일시정지',
            onTap: state.isPaused ? onResume : onPause,
          ),
          const Spacer(),

          // 삭제 (저장 안 함)
          _CircleButton(
            icon: Icons.delete_forever_rounded,
            label: '삭제',
            onTap: onDiscard,
            isDestructive: true,
          ),
          const SizedBox(width: 12),

          // 저장
          _CircleButton(
            icon: Icons.check_rounded,
            label: '저장',
            onTap: onEnd,
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isDestructive;

  const _CircleButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final enabled = onTap != null;

    final Color bgColor;
    final Color iconColor;
    final Color borderColor;

    if (!enabled) {
      bgColor = cs.surfaceContainerHighest.withValues(alpha: 0.4);
      iconColor = cs.onSurfaceVariant;
      borderColor = cs.outlineVariant;
    } else if (isPrimary) {
      bgColor = cs.primary;
      iconColor = cs.onPrimary;
      borderColor = cs.primary;
    } else if (isDestructive) {
      bgColor = cs.errorContainer.withValues(alpha: 0.6);
      iconColor = cs.error;
      borderColor = cs.error.withValues(alpha: 0.4);
    } else {
      bgColor = cs.primaryContainer.withValues(alpha: 0.6);
      iconColor = cs.primary;
      borderColor = cs.outline;
    }

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
              color: bgColor,
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: enabled ? cs.onSurface : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
