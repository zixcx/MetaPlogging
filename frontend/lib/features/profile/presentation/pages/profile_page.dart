import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';
import 'package:meta_plogging/features/auth/presentation/providers/auth_provider.dart';
import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';
import 'package:meta_plogging/features/profile/domain/entities/user_stats_entity.dart';
import 'package:meta_plogging/features/profile/presentation/providers/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _scrollController = ScrollController();
  bool _appBarLight = false;

  static const _headerThreshold = 200.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final isLight = _scrollController.offset > _headerThreshold;
    if (isLight != _appBarLight) setState(() => _appBarLight = isLight);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final appBarBg = _appBarLight ? cs.surface : AppColors.primaryDark;
    final appBarFg = _appBarLight ? cs.onSurface : Colors.white;

    final statsAsync = ref.watch(userStatsProvider);
    final recentAsync = ref.watch(recentSessionsProvider);
    final authAsync = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          Container(height: 480, color: AppColors.primaryDark),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: appBarBg,
                foregroundColor: appBarFg,
                scrolledUnderElevation: 0,
                title: Text(
                  '프로필',
                  style:
                      theme.textTheme.titleLarge?.copyWith(color: appBarFg),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: appBarFg),
                    onPressed: () {},
                  ),
                ],
              ),

              // ── Profile header ─────────────────────────────
              SliverToBoxAdapter(
                child: authAsync.when(
                  data: (user) => statsAsync.when(
                    data: (stats) => _ProfileHeader(
                      name: user?.name ?? '플로깅 러너',
                      email: user?.email ?? '',
                      profileImageUrl: user?.profileImageUrl,
                      activityCount: stats.totalSessions,
                    ),
                    loading: () => _ProfileHeader(
                      name: user?.name ?? '플로깅 러너',
                      email: user?.email ?? '',
                      profileImageUrl: user?.profileImageUrl,
                      activityCount: null,
                    ),
                    error: (e, st) => _ProfileHeader(
                      name: user?.name ?? '플로깅 러너',
                      email: user?.email ?? '',
                      profileImageUrl: user?.profileImageUrl,
                      activityCount: null,
                    ),
                  ),
                  loading: () => const _ProfileHeaderSkeleton(),
                  error: (e, st) => _ProfileHeader(
                    name: '플로깅 러너',
                    email: '',
                    profileImageUrl: null,
                    activityCount: null,
                  ),
                ),
              ),

              // ── Body ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -50),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Stats grid ────────────────────
                        Text('활동 통계', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 10),
                        statsAsync.when(
                          data: (stats) => _StatsGrid(
                              stats: stats, isDark: isDark),
                          loading: () => _StatsGridSkeleton(isDark: isDark),
                          error: (e, _) => _ErrorCard(
                              message: '통계를 불러오지 못했습니다.',
                              onRetry: () => ref.invalidate(userStatsProvider)),
                        ),
                        const SizedBox(height: 24),

                        // ── Level card (목업) ─────────────
                        _LevelCard(isDark: isDark),
                        const SizedBox(height: 24),

                        // ── Badges (목업) ─────────────────
                        Text('획득한 배지', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 12),
                        _BadgeRow(isDark: isDark),
                        const SizedBox(height: 24),

                        // ── Recent sessions ───────────────
                        Text('최근 플로깅', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 10),
                        recentAsync.when(
                          data: (sessions) => sessions.isEmpty
                              ? _EmptyCard(
                                  message: '아직 완료된 플로깅 기록이 없어요.',
                                  isDark: isDark,
                                )
                              : _RecentSessionList(
                                  sessions: sessions.take(3).toList(),
                                  isDark: isDark,
                                ),
                          loading: () =>
                              _SessionListSkeleton(isDark: isDark),
                          error: (e, _) => _ErrorCard(
                              message: '기록을 불러오지 못했습니다.',
                              onRetry: () =>
                                  ref.invalidate(recentSessionsProvider)),
                        ),
                        const SizedBox(height: 24),

                        // ── Settings ──────────────────────
                        Text('설정', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 12),
                        _SettingsList(isDark: isDark, ref: ref),
                      ],
                    ),
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                fillOverscroll: true,
                child: ColoredBox(color: cs.surface),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

// ── Profile header ────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? profileImageUrl;
  final int? activityCount;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.profileImageUrl,
    required this.activityCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Avatar
          Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.secondary, AppColors.primary],
                  ),
                ),
                child: profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, e, st) => const Center(
                              child: Text('🌿',
                                  style: TextStyle(fontSize: 36))),
                        ),
                      )
                    : const Center(
                        child: Text('🌿', style: TextStyle(fontSize: 36))),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            name,
            style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          if (email.isNotEmpty)
            Text(
              email,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
            ),
          const SizedBox(height: 16),

          // Activity count
          _FollowStat(
            label: '활동 횟수',
            value: activityCount != null ? '$activityCount' : '-',
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderSkeleton extends StatelessWidget {
  const _ProfileHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

class _FollowStat extends StatelessWidget {
  final String label;
  final String value;

  const _FollowStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Stats grid ────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final UserStatsEntity stats;
  final bool isDark;

  const _StatsGrid({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _GridStatCard(
          label: '총 거리',
          value: '${stats.totalDistanceKm.toStringAsFixed(1)} km',
          icon: Icons.route_rounded,
          color: AppColors.primary,
          isDark: isDark,
        ),
        _GridStatCard(
          label: '수거한 쓰레기',
          value: '${stats.totalTrashCount}개',
          icon: Icons.delete_outline_rounded,
          color: AppColors.secondary,
          isDark: isDark,
        ),
        _GridStatCard(
          label: '활동 시간',
          value: stats.formattedDuration,
          icon: Icons.timer_outlined,
          color: AppColors.accent,
          isDark: isDark,
        ),
        _GridStatCard(
          label: '절약한 CO₂',
          value: '${stats.co2SavedKg.toStringAsFixed(1)} kg',
          icon: Icons.eco_rounded,
          color: AppColors.gold,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _StatsGridSkeleton extends StatelessWidget {
  final bool isDark;
  const _StatsGridSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cardDark
                : const Color(0xFFE5F0E8),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _GridStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _GridStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
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
          color:
              isDark ? const Color(0xFF2A4035) : const Color(0xFFE5F0E8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

// ── Level card (목업) ─────────────────────────────────────────
class _LevelCard extends StatelessWidget {
  final bool isDark;

  const _LevelCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A4035) : const Color(0xFFE5F0E8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Text(
                      'Level 3',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '420 / 600 XP',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '에코 러너',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '다음 레벨까지 180 XP 남았어요!',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: 420 / 600,
              minHeight: 8,
              backgroundColor: isDark
                  ? const Color(0xFF2A4035)
                  : const Color(0xFFE5F0E8),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge row (목업) ──────────────────────────────────────────
class _BadgeData {
  final IconData icon;
  final String label;
  final Color color;

  const _BadgeData(
      {required this.icon, required this.label, required this.color});
}

class _BadgeRow extends StatelessWidget {
  final bool isDark;

  const _BadgeRow({required this.isDark});

  static const _badges = [
    _BadgeData(
        icon: Icons.eco_rounded, label: '첫 플로깅', color: AppColors.primary),
    _BadgeData(
        icon: Icons.local_fire_department_rounded,
        label: '5연속',
        color: AppColors.accent),
    _BadgeData(
        icon: Icons.emoji_events_rounded,
        label: '거리왕',
        color: AppColors.gold),
    _BadgeData(
        icon: Icons.camera_alt_rounded,
        label: '기록왕',
        color: AppColors.secondary),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _badges.length,
        separatorBuilder: (context, i) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final badge = _badges[i];
          return Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: badge.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: badge.color.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(badge.icon, size: 26, color: badge.color),
              ),
              const SizedBox(height: 6),
              Text(badge.label, style: theme.textTheme.labelSmall),
            ],
          );
        },
      ),
    );
  }
}

// ── Recent sessions list ──────────────────────────────────────
class _RecentSessionList extends StatelessWidget {
  final List<TrackingSessionEntity> sessions;
  final bool isDark;

  const _RecentSessionList(
      {required this.sessions, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: sessions
          .map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SessionCard(session: s, isDark: isDark),
              ))
          .toList(),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final TrackingSessionEntity session;
  final bool isDark;

  const _SessionCard({required this.session, required this.isDark});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return '오늘 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return '어제';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = session.locationDescription ??
        session.locationLandmarkName ??
        '플로깅 기록';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDark ? const Color(0xFF2A4035) : const Color(0xFFE5F0E8),
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
                Text(_formatDate(session.startedAt),
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MiniStat(
                icon: Icons.route_rounded,
                value:
                    '${session.distanceKm.toStringAsFixed(2)}km',
                color: AppColors.primary,
              ),
              const SizedBox(height: 2),
              _MiniStat(
                icon: Icons.delete_outline_rounded,
                value: '${session.totalTrashCount}개',
                color: AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionListSkeleton extends StatelessWidget {
  final bool isDark;
  const _SessionListSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardDark
                  : const Color(0xFFE5F0E8),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
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

// ── Empty / Error cards ───────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  final String message;
  final bool isDark;

  const _EmptyCard({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDark ? const Color(0xFF2A4035) : const Color(0xFFE5F0E8),
        ),
      ),
      child: Center(
        child: Text(message,
            style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(message,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.accent)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              '다시 시도',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings list ─────────────────────────────────────────────
class _SettingsList extends StatelessWidget {
  final bool isDark;
  final WidgetRef ref;

  const _SettingsList({required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    final divColor =
        isDark ? const Color(0xFF2A4035) : const Color(0xFFE5F0E8);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: divColor),
      ),
      child: Column(
        children: [
          _SettingTile(
            icon: Icons.person_outline_rounded,
            label: '프로필 편집',
            onTap: () {},
          ),
          Divider(height: 1, color: divColor),
          _SettingTile(
            icon: Icons.notifications_none_rounded,
            label: '알림 설정',
            onTap: () {},
          ),
          Divider(height: 1, color: divColor),
          _SettingTile(
            icon: Icons.privacy_tip_outlined,
            label: '개인정보처리방침',
            onTap: () {},
          ),
          Divider(height: 1, color: divColor),
          _SettingTile(
            icon: Icons.logout_rounded,
            label: '로그아웃',
            color: AppColors.accent,
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tileColor = color ?? theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: tileColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: tileColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
