import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';

class PloggingPage extends ConsumerStatefulWidget {
  const PloggingPage({super.key});

  @override
  ConsumerState<PloggingPage> createState() => _PloggingPageState();
}

class _PloggingPageState extends ConsumerState<PloggingPage> {
  bool _isRunning = false;
  final int _elapsedSeconds = 0;

  String get _timeFormatted {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _togglePlogging() {
    setState(() => _isRunning = !_isRunning);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(
              '플로깅 기록',
              style: theme.textTheme.titleLarge,
            ),
            backgroundColor: cs.surface,
            scrolledUnderElevation: 0,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Map placeholder ──────────────────────
                  _MapPlaceholder(isDark: isDark),
                  const SizedBox(height: 20),

                  // ── Live stats ────────────────────────────
                  if (_isRunning) ...[
                    _LiveStats(
                      time: _timeFormatted,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Start/Stop button ─────────────────────
                  _PloggingCta(
                    isRunning: _isRunning,
                    onToggle: _togglePlogging,
                  ),
                  const SizedBox(height: 28),

                  // ── Tips ─────────────────────────────────
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

// ── Map placeholder ───────────────────────────────────────────
class _MapPlaceholder extends StatelessWidget {
  final bool isDark;

  const _MapPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A3028),
                    const Color(0xFF0F2018),
                  ]
                : [
                    const Color(0xFFD0ECE0),
                    const Color(0xFFB8DECC),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Grid pattern
            CustomPaint(
              size: const Size(double.infinity, 240),
              painter: _GridPainter(isDark: isDark),
            ),
            // Center pin
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      '내 위치',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Map label
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_rounded,
                        size: 13, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      '지도',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final bool isDark;

  const _GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : AppColors.primary)
          .withValues(alpha: 0.07)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Live stats ────────────────────────────────────────────────
class _LiveStats extends StatelessWidget {
  final String time;
  final bool isDark;

  const _LiveStats({required this.time, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          _LiveStatItem(
            label: '시간',
            value: time,
            icon: Icons.timer_outlined,
            color: AppColors.primary,
          ),
          _Divider(),
          _LiveStatItem(
            label: '거리',
            value: '0.0 km',
            icon: Icons.route_rounded,
            color: AppColors.secondary,
          ),
          _Divider(),
          _LiveStatItem(
            label: '수거',
            value: '0개',
            icon: Icons.delete_outline_rounded,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).dividerColor,
    );
  }
}

class _LiveStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _LiveStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
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

// ── Plogging CTA ──────────────────────────────────────────────
class _PloggingCta extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onToggle;

  const _PloggingCta({required this.isRunning, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isRunning) ...[
          // Stop button
          OutlinedButton.icon(
            onPressed: onToggle,
            icon: const Icon(Icons.stop_rounded),
            label: const Text('플로깅 종료'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: const Text('쓰레기 사진 촬영'),
          ),
        ] else ...[
          // Start button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FilledButton.icon(
              onPressed: onToggle,
              icon: const Icon(Icons.directions_run_rounded, size: 20),
              label: const Text('플로깅 시작하기'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Tip cards ─────────────────────────────────────────────────
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
          width: 1,
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
