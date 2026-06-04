import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';
import 'package:meta_plogging/features/auth/presentation/providers/auth_provider.dart';
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
                  style: theme.textTheme.titleLarge?.copyWith(color: appBarFg),
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
                          data: (stats) =>
                              _StatsGrid(stats: stats, isDark: isDark),
                          loading: () => _StatsGridSkeleton(isDark: isDark),
                          error: (e, _) => _ErrorCard(
                            message: '통계를 불러오지 못했습니다.',
                            onRetry: () => ref.invalidate(userStatsProvider),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Level ─────────────────────────
                        Text('레벨', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 10),
                        _LevelCard(isDark: isDark),
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
                            child: Text('🌿', style: TextStyle(fontSize: 36)),
                          ),
                        ),
                      )
                    : const Center(
                        child: Text('🌿', style: TextStyle(fontSize: 36)),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            name,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          if (email.isNotEmpty)
            Text(
              email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
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
    return Column(
      spacing: 10,
      children: [
        _GridStatCard(
          label: '활동 횟수',
          value: '${stats.totalSessions}회',
          icon: Icons.directions_run_rounded,
          color: AppColors.primary,
          isDark: isDark,
        ),
        _GridStatCard(
          label: '총 촬영 수',
          value: '${stats.totalTrashCount}개',
          icon: Icons.camera_alt_rounded,
          color: AppColors.secondary,
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
    return Column(
      spacing: 10,
      children: List.generate(
        2,
        (_) => Container(
          height: 80,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : const Color(0xFFE5F0E8),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A4035) : const Color(0xFFE5F0E8),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppColors.gold,
                    ),
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text('다음 레벨까지 180 XP 남았어요!', style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: 420 / 600,
              minHeight: 8,
              backgroundColor: isDark
                  ? const Color(0xFF2A4035)
                  : const Color(0xFFE5F0E8),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error card ────────────────────────────────────────────────
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
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.accent),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              '다시 시도',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
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

  void _showPrivacyPolicy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('개인정보처리방침'),
        content: const SingleChildScrollView(
          child: Text(
            '수집 항목: 이메일, 닉네임, 위치 정보(플로깅 중), 촬영 사진\n\n'
            '수집 목적: 회원 관리, 플로깅 기록 저장 및 통계 제공\n\n'
            '보유 기간: 회원 탈퇴 시까지\n\n'
            '위치 정보는 플로깅 세션 중에만 수집되며, 세션 종료 후 경로 데이터로만 저장됩니다.\n\n'
            '문의: 2401836@kunsan.ac.kr',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final divColor = isDark ? const Color(0xFF2A4035) : const Color(0xFFE5F0E8);

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
            label: '이름 바꾸기',
            onTap: () {},
          ),
          Divider(height: 1, color: divColor),
          _SettingTile(
            icon: Icons.privacy_tip_outlined,
            label: '개인정보처리방침',
            onTap: () => _showPrivacyPolicy(context),
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
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
