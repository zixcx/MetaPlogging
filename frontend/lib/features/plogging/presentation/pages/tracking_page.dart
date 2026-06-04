import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';
import 'package:meta_plogging/features/plogging/data/photo_exif.dart';
import 'package:meta_plogging/features/feed/presentation/providers/feed_provider.dart';
import 'package:meta_plogging/features/plogging/presentation/providers/sessions_provider.dart';
import 'package:meta_plogging/features/plogging/presentation/providers/tracking_provider.dart';
import 'package:meta_plogging/features/plogging/presentation/widgets/end_session_sheet.dart';
import 'package:meta_plogging/features/profile/presentation/providers/profile_provider.dart';

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
        notifier.clearError();
      }
    });

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Column(
          children: [
            // ── 지도 영역 ─────────────────────────────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // NaverMap
                  NaverMap(
                    options: NaverMapViewOptions(
                      initialCameraPosition: NCameraPosition(
                        target:
                            state.currentPosition ??
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
                  _MapOverlayUpdater(controller: _mapController, state: state),

                  // ── 오른쪽 중앙 컨트롤 버튼 (세로) ──────────
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _GhostButton(
                              icon: state.isPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              label: state.isPaused ? '재개' : '일시정지',
                              onTap: state.isPaused
                                  ? notifier.resumeSession
                                  : notifier.pauseSession,
                            ),
                            const SizedBox(height: 4),
                            _GhostButton(
                              icon: Icons.delete_forever_rounded,
                              label: '삭제',
                              onTap: () => _confirmDiscard(context, notifier),
                              isDestructive: true,
                            ),
                            const SizedBox(height: 4),
                            _GhostButton(
                              icon: Icons.check_rounded,
                              label: '저장',
                              onTap: () =>
                                  _showEndSheet(context, state, notifier),
                              isPrimary: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── 내 위치 따라가기 버튼 ──────────────────
                  if (!_isFollowing)
                    Positioned(
                      bottom: 80,
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

                  // ── 사진 촬영 버튼 (하단 중앙) ──────────────
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 24,
                    child: Center(
                      child: _CaptureButton(
                        count: state.photoCount,
                        onTap: () => _capturePhoto(context, notifier),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── 하단: 통계 바 ─────────────────────────────────
            _StatsBar(state: state, isDark: isDark),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDiscard(
    BuildContext ctx,
    TrackingNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('GPS 기록 삭제'),
        content: const Text('현재 플로깅의 GPS 기록을 삭제할까요?\n촬영한 사진은 사진 기록에 저장됩니다.'),
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
    if (confirmed != true) return;
    final result = await notifier.discardSession();
    if (!ctx.mounted) return;
    if (!result.success) return;
    if (result.postId != null) {
      ref.read(feedProvider.notifier).refresh();
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('${result.photoCount}장의 사진이 사진 기록에 저장됐어요'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    Navigator.of(ctx, rootNavigator: true).pop();
  }

  Future<void> _capturePhoto(
    BuildContext ctx,
    TrackingNotifier notifier,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => const _SourcePickerSheet(),
    );
    if (source == null) return;

    // 앨범은 압축 시 EXIF가 제거되므로 원본 그대로(quality null) 가져온다.
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: source == ImageSource.camera ? 85 : null,
    );
    if (picked == null) return;

    // 카메라: 현재 위치·시각을 메타데이터로 저장.
    // 앨범: EXIF에서 촬영 위치·일시 추출 (없으면 null).
    final double? lat;
    final double? lng;
    final DateTime? takenAt;
    if (source == ImageSource.camera) {
      final pos = ref.read(trackingProvider).currentPosition;
      lat = pos?.latitude;
      lng = pos?.longitude;
      takenAt = DateTime.now();
    } else {
      final meta = await readPhotoMetadata(File(picked.path));
      lat = meta.lat;
      lng = meta.lng;
      takenAt = meta.takenAt;
    }
    final ok = await notifier.addPhoto(
      File(picked.path),
      lat: lat,
      lng: lng,
      takenAt: takenAt,
    );
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(ok ? '사진이 추가됐어요' : '사진 업로드에 실패했어요'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? AppColors.primary : Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showEndSheet(
    BuildContext ctx,
    TrackingState state,
    TrackingNotifier notifier,
  ) {
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => EndSessionSheet(
        distanceKm: state.distanceKm.toStringAsFixed(2),
        duration: state.formattedTime,
        onConfirm: ({required trashItems, required locationDescription}) async {
          await notifier.endSession(
            trashItems: trashItems,
            locationDescription: locationDescription,
          );
          // 세션이 종료(성공) 또는 이미 완료(409)된 경우 → 바텀시트 닫기
          if (!sheetCtx.mounted) return;
          if (!ref.read(trackingProvider).isRunning) {
            ref.read(completedSessionsProvider.notifier).refresh();
            ref.invalidate(recentSessionsProvider);
            Navigator.of(sheetCtx).pop(); // bottom sheet 닫기
          }
        },
      ),
    ).then((_) {
      // 바텀시트가 닫힌 후 세션이 종료됐으면 TrackingPage도 닫기
      if (ctx.mounted && !ref.read(trackingProvider).isRunning) {
        Navigator.of(ctx, rootNavigator: true).pop();
      }
    });
  }
}

// ── Ghost 버튼 (지도 위 투명 배경) ────────────────────────────
class _GhostButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isDestructive;

  const _GhostButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color iconColor;
    final Color bgColor;

    if (isPrimary) {
      iconColor = cs.primary;
      bgColor = Colors.white.withValues(alpha: 0.85);
    } else if (isDestructive) {
      iconColor = cs.error;
      bgColor = Colors.white.withValues(alpha: 0.85);
    } else {
      iconColor = Colors.white;
      bgColor = Colors.black.withValues(alpha: 0.35);
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 사진 촬영 버튼 (하단 중앙 + 카운트 뱃지) ──────────────────
class _CaptureButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _CaptureButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          if (count > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 사진 소스 선택 시트 (큰 정사각형 버튼 2개) ────────────────
class _SourcePickerSheet extends StatelessWidget {
  const _SourcePickerSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1410) : cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('사진 추가', style: theme.textTheme.titleLarge),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SourceOptionButton(
                      isDark: isDark,
                      icon: Icons.camera_alt_rounded,
                      label: '카메라로 촬영',
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceOptionButton(
                      isDark: isDark,
                      icon: Icons.photo_library_rounded,
                      label: '앨범에서 선택',
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceOptionButton extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOptionButton({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: AppColors.primary),
                ),
                const SizedBox(height: 14),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
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
  ConsumerState<_MapOverlayUpdater> createState() => _MapOverlayUpdaterState();
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
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1410) : Colors.white,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

    _scale = Tween<double>(
      begin: 1.0,
      end: 2.4,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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
