import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';
import 'package:meta_plogging/features/auth/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _scrollController = ScrollController();
  bool _appBarLight = false;

  // 그래디언트 헤더가 핀된 앱바 아래로 사라지는 대략적인 스크롤 오프셋
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

    return Scaffold(
      // 하단 오버스크롤 = surface(흰색). 상단은 Stack으로 별도 처리
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // 상단 오버스크롤 시 앱바·그래디언트와 색상 일치
          Container(height: 480, color: AppColors.primaryDark),
          CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── App bar ───────────────────────────────────────
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

          // ── Profile header ────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHeader(isDark: isDark),
          ),

          // ── Body content — 그래디언트 하단과 50px 겹쳐 모서리 틈 제거
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
              padding: const EdgeInsets.fromLTRB(20, 74, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Level badge ───────────────────────────
                  _LevelCard(isDark: isDark),
                  const SizedBox(height: 24),

                  // ── Stats grid ────────────────────────────
                  Text('활동 통계', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  _StatsGrid(isDark: isDark),
                  const SizedBox(height: 24),

                  // ── Badges ────────────────────────────────
                  Text('획득한 배지', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _BadgeRow(isDark: isDark),
                  const SizedBox(height: 24),

                  // ── Settings ──────────────────────────────
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
  final bool isDark;

  const _ProfileHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
          stops: const [0.0, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
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
                      colors: [
                        AppColors.secondary,
                        AppColors.primary,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '🌿',
                      style: TextStyle(fontSize: 36),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              '플로깅 러너',
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'runner@example.com',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),

            // Follow stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FollowStat(label: '활동 횟수', value: '12'),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _FollowStat(label: '팔로워', value: '28'),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _FollowStat(label: '팔로잉', value: '15'),
              ],
            ),
          ],
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

// ── Level card ────────────────────────────────────────────────
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
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

// ── Stats grid ────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final bool isDark;

  const _StatsGrid({required this.isDark});

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
          value: '24.8 km',
          icon: Icons.route_rounded,
          color: AppColors.primary,
          isDark: isDark,
        ),
        _GridStatCard(
          label: '수거한 쓰레기',
          value: '156개',
          icon: Icons.delete_outline_rounded,
          color: AppColors.secondary,
          isDark: isDark,
        ),
        _GridStatCard(
          label: '활동 시간',
          value: '8h 42m',
          icon: Icons.timer_outlined,
          color: AppColors.accent,
          isDark: isDark,
        ),
        _GridStatCard(
          label: '절약한 CO₂',
          value: '3.2 kg',
          icon: Icons.eco_rounded,
          color: AppColors.gold,
          isDark: isDark,
        ),
      ],
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
          color: isDark
              ? const Color(0xFF2A4035)
              : const Color(0xFFE5F0E8),
          width: 1,
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

// ── Badge row ─────────────────────────────────────────────────
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
        icon: Icons.emoji_events_rounded, label: '거리왕', color: AppColors.gold),
    _BadgeData(
        icon: Icons.camera_alt_rounded,
        label: '기록왕',
        color: AppColors.secondary),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _badges.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, i) =>
            _BadgeTile(badge: _badges[i], isDark: isDark),
      ),
    );
  }
}

class _BadgeData {
  final IconData icon;
  final String label;
  final Color color;

  const _BadgeData(
      {required this.icon, required this.label, required this.color});
}

class _BadgeTile extends StatelessWidget {
  final _BadgeData badge;
  final bool isDark;

  const _BadgeTile({required this.badge, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        Text(
          badge.label,
          style: theme.textTheme.labelSmall,
        ),
      ],
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
    return Container(
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
        children: [
          _SettingTile(
            icon: Icons.person_outline_rounded,
            label: '프로필 편집',
            onTap: () {},
          ),
          Divider(
            height: 1,
            color: isDark
                ? const Color(0xFF2A4035)
                : const Color(0xFFE5F0E8),
          ),
          _SettingTile(
            icon: Icons.notifications_none_rounded,
            label: '알림 설정',
            onTap: () {},
          ),
          Divider(
            height: 1,
            color: isDark
                ? const Color(0xFF2A4035)
                : const Color(0xFFE5F0E8),
          ),
          _SettingTile(
            icon: Icons.privacy_tip_outlined,
            label: '개인정보처리방침',
            onTap: () {},
          ),
          Divider(
            height: 1,
            color: isDark
                ? const Color(0xFF2A4035)
                : const Color(0xFFE5F0E8),
          ),
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
