import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meta_plogging/core/router/app_router.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';
import 'package:meta_plogging/features/auth/presentation/providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final authState = ref.watch(authProvider);
    final userName = authState.when(
      data: (user) => user?.name,
      loading: () => null,
      error: (e, s) => null,
    );

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: cs.surface,
            scrolledUnderElevation: 0,
            title: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'MetaPlogging',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: cs.onSurface,
                ),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting ──────────────────────────────
                  _GreetingCard(isDark: isDark, userName: userName),
                  const SizedBox(height: 24),

                  // ── Stats card ────────────────────────────
                  Text(
                    '나의 활동 통계',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _StatsCard(isDark: isDark),
                  const SizedBox(height: 24),

                  // ── Quick actions ─────────────────────────
                  Text(
                    '바로 시작하기',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _QuickActions(isDark: isDark),
                  const SizedBox(height: 24),

                  // ── Weekly chart ──────────────────────────
                  Text(
                    '이번 주 활동',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _WeeklyChart(isDark: isDark),
                  const SizedBox(height: 24),

                  // ── Recent activity ───────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('최근 플로깅', style: theme.textTheme.titleLarge),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.plogging),
                        child: const Text('전체 보기'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _RecentActivity(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Greeting card ─────────────────────────────────────────────
class _GreetingCard extends StatelessWidget {
  final bool isDark;
  final String? userName;

  const _GreetingCard({required this.isDark, required this.userName});

  // TODO: API 연결 시 GET /stats/community/today 로 교체
  static const int _mockCommunityCount = 312;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = userName != null ? '안녕하세요, $userName님! 🌿' : '안녕하세요! 🌿';

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '오늘 $_mockCommunityCount명이\n함께 달리고 있어요',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.plogging),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.directions_run_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '플로깅 시작',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Decorative circles
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats card (unified) ──────────────────────────────────────
class _StatsCard extends StatelessWidget {
  final bool isDark;

  const _StatsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A4035) : const Color(0xFFE5F0E8),
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                label: '총 거리',
                value: '24.8',
                unit: 'km',
                icon: Icons.route_rounded,
                color: AppColors.primary,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: isDark ? const Color(0xFF2A4035) : const Color(0xFFE5F0E8),
            ),
            Expanded(
              child: _StatItem(
                label: '수거량',
                value: '156',
                unit: '개',
                icon: Icons.delete_outline_rounded,
                color: AppColors.secondary,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: isDark ? const Color(0xFF2A4035) : const Color(0xFFE5F0E8),
            ),
            Expanded(
              child: _StatItem(
                label: '활동 횟수',
                value: '12',
                unit: '회',
                icon: Icons.local_fire_department_rounded,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

// ── Quick actions (2 buttons) ─────────────────────────────────
class _QuickActions extends StatelessWidget {
  final bool isDark;

  const _QuickActions({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        isDark ? const Color(0xFF2A4035) : const Color(0xFFE5F0E8);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // 기록하기 — flex 3
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '기록하기',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // 활동지도 — flex 1
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 22,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '활동지도',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}

// ── Weekly chart ──────────────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  final bool isDark;

  const _WeeklyChart({required this.isDark});

  static const _days = ['월', '화', '수', '목', '금', '토', '일'];
  static const _values = [0.4, 0.7, 0.3, 1.0, 0.6, 0.85, 0.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A4035)
              : const Color(0xFFE5F0E8),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '이번 주 3.2 km',
                style: theme.textTheme.titleMedium,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '+12%',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final isToday = i == 3; // Thursday highlighted
                final val = _values[i];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: val == 0 ? 0.08 : val,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isToday
                                    ? AppColors.primary
                                    : val == 0
                                        ? (isDark
                                            ? const Color(0xFF2A4035)
                                            : const Color(0xFFE5F0E8))
                                        : AppColors.primary
                                            .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _days[i],
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isToday
                                ? AppColors.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent activity ───────────────────────────────────────────
class _RecentActivity extends StatelessWidget {
  static const _activities = [
    _ActivityData(
      title: '한강 공원 플로깅',
      date: '오늘 07:32',
      distance: '3.2 km',
      trash: '24개',
      duration: '42분',
    ),
    _ActivityData(
      title: '올림픽공원 산책',
      date: '어제 06:15',
      distance: '2.8 km',
      trash: '18개',
      duration: '38분',
    ),
    _ActivityData(
      title: '여의도 한강변',
      date: '3일 전',
      distance: '4.1 km',
      trash: '31개',
      duration: '55분',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _activities
          .map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActivityCard(data: a),
              ))
          .toList(),
    );
  }
}

class _ActivityData {
  final String title;
  final String date;
  final String distance;
  final String trash;
  final String duration;

  const _ActivityData({
    required this.title,
    required this.date,
    required this.distance,
    required this.trash,
    required this.duration,
  });
}

class _ActivityCard extends StatelessWidget {
  final _ActivityData data;

  const _ActivityCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A4035)
              : const Color(0xFFE5F0E8),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.directions_run_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(data.date, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MiniStat(
                icon: Icons.route_rounded,
                value: data.distance,
                color: cs.primary,
              ),
              const SizedBox(height: 2),
              _MiniStat(
                icon: Icons.delete_outline_rounded,
                value: data.trash,
                color: AppColors.secondary,
              ),
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
