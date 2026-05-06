import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';
import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';
import 'package:meta_plogging/features/plogging/presentation/pages/tracking_page.dart';
import 'package:meta_plogging/features/plogging/presentation/providers/tracking_provider.dart';

class PloggingPage extends ConsumerWidget {
  const PloggingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackingProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // 진행 중인 세션이 있으면 TrackingPage로 이동
    if (state.isRunning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const TrackingPage(),
            fullscreenDialog: true,
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text('플로깅 기록', style: theme.textTheme.titleLarge),
            backgroundColor: cs.surface,
            scrolledUnderElevation: 0,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 이어하기 배너 ──────────────────────────
                  if (state.session != null && !state.isRunning) ...[
                    _ResumeBanner(
                      session: state.session!,
                      onResume: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TrackingPage(),
                          fullscreenDialog: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── 시작 카드 ─────────────────────────────
                  _StartCard(
                    isDark: isDark,
                    isLoading: state.isLoading,
                    onStart: () async {
                      await ref
                          .read(trackingProvider.notifier)
                          .startSession();
                    },
                  ),
                  const SizedBox(height: 28),

                  // ── 최근 기록 ─────────────────────────────
                  Text('최근 플로깅', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _RecentSessionList(isDark: isDark),

                  const SizedBox(height: 28),

                  // ── 팁 ────────────────────────────────────
                  Text('플로깅 팁', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _TipCards(isDark: isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 이어하기 배너 ──────────────────────────────────────────────
class _ResumeBanner extends StatelessWidget {
  final TrackingSessionEntity session;
  final VoidCallback onResume;

  const _ResumeBanner({required this.session, required this.onResume});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onResume,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.pause_circle_outline_rounded,
                color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '중단된 플로깅이 있어요',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    '${session.distanceKm.toStringAsFixed(2)}km · ${session.formattedDuration} 진행됨',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.orange),
          ],
        ),
      ),
    );
  }
}

// ── 시작 카드 ──────────────────────────────────────────────────
class _StartCard extends StatelessWidget {
  final bool isDark;
  final bool isLoading;
  final VoidCallback onStart;

  const _StartCard({
    required this.isDark,
    required this.isLoading,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'GPS 트래킹',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '지금 바로\n플로깅 시작하기',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '경로와 수거량이 자동으로 기록됩니다',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onStart,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.directions_run_rounded, size: 18),
              label: Text(isLoading ? '준비 중...' : '플로깅 시작'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 최근 세션 목록 (mock) ──────────────────────────────────────
class _RecentSessionList extends StatelessWidget {
  final bool isDark;

  const _RecentSessionList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    // TODO: API 연동 후 실제 데이터로 교체
    return Column(
      children: [
        _SessionCard(
          isDark: isDark,
          title: '한강 반포지구',
          date: '오늘 07:32',
          distanceKm: '3.2',
          duration: '42:00',
          trashCount: 24,
        ),
        const SizedBox(height: 10),
        _SessionCard(
          isDark: isDark,
          title: '서울숲',
          date: '어제 06:15',
          distanceKm: '4.8',
          duration: '58:00',
          trashCount: 36,
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String date;
  final String distanceKm;
  final String duration;
  final int trashCount;

  const _SessionCard({
    required this.isDark,
    required this.title,
    required this.date,
    required this.distanceKm,
    required this.duration,
    required this.trashCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A4035)
              : const Color(0xFFE5F0E8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.directions_run_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(date, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MiniStat(
                  icon: Icons.route_rounded,
                  value: '${distanceKm}km',
                  color: AppColors.primary),
              const SizedBox(height: 2),
              _MiniStat(
                  icon: Icons.delete_outline_rounded,
                  value: '$trashCount개',
                  color: AppColors.secondary),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MiniStat(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

// ── 팁 카드 ────────────────────────────────────────────────────
class _TipCards extends StatelessWidget {
  final bool isDark;

  const _TipCards({required this.isDark});

  static const _tips = [
    _TipData(
      icon: Icons.backpack_outlined,
      title: '장갑과 봉투 지참',
      body: '위생 장갑과 재활용 봉투를 꼭 챙기세요.',
      color: AppColors.primary,
    ),
    _TipData(
      icon: Icons.wb_sunny_outlined,
      title: '적절한 시간대 선택',
      body: '이른 아침이나 저녁 시간대가 활동하기 좋아요.',
      color: AppColors.accent,
    ),
    _TipData(
      icon: Icons.camera_alt_outlined,
      title: '활동 기록 남기기',
      body: '수거 전후 사진을 찍어 기록을 남겨보세요.',
      color: AppColors.secondary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _tips
          .map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TipCard(tip: t, isDark: isDark),
              ))
          .toList(),
    );
  }
}

class _TipData {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _TipData({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
}

class _TipCard extends StatelessWidget {
  final _TipData tip;
  final bool isDark;

  const _TipCard({required this.tip, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A4035)
              : const Color(0xFFE5F0E8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tip.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tip.icon, size: 20, color: tip.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(tip.body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
