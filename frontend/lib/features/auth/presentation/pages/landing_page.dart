import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meta_plogging/core/router/app_router.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage>
    with TickerProviderStateMixin {
  late final AnimationController _heroCtrl;
  late final AnimationController _ctaCtrl;

  // Hero animations (staggered)
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoOffset;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleOffset;
  late final Animation<double> _featuresOpacity;
  late final Animation<Offset> _featuresOffset;

  // CTA slide-up
  late final Animation<double> _ctaOpacity;
  late final Animation<Offset> _ctaOffset;

  @override
  void initState() {
    super.initState();

    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _ctaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Logo: enters from below, fades in 0→55%
    _logoOpacity = CurvedAnimation(
      parent: _heroCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _logoOffset = Tween<Offset>(begin: const Offset(0, 0.28), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _heroCtrl,
            curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
          ),
        );

    // Title: 20→75%
    _titleOpacity = CurvedAnimation(
      parent: _heroCtrl,
      curve: const Interval(0.2, 0.75, curve: Curves.easeOut),
    );
    _titleOffset = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _heroCtrl,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    // Features: 40→100%
    _featuresOpacity = CurvedAnimation(
      parent: _heroCtrl,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _featuresOffset =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _heroCtrl,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    // CTA
    _ctaOpacity = CurvedAnimation(
      parent: _ctaCtrl,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );
    _ctaOffset = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _ctaCtrl,
            curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
          ),
        );

    _heroCtrl.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _ctaCtrl.forward();
    });
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _ctaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          // ── Deep forest gradient background ──────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A1A0E),
                    Color(0xFF183A25),
                    Color(0xFF2D6A4F),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // ── Decorative ambient blobs ──────────────────────
          Positioned(
            top: -size.width * 0.3,
            right: -size.width * 0.2,
            child: _AmbientBlob(
              size: size.width * 0.75,
              color: AppColors.secondary.withValues(alpha: 0.07),
            ),
          ),
          Positioned(
            top: size.height * 0.22,
            left: -size.width * 0.28,
            child: _AmbientBlob(
              size: size.width * 0.55,
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            bottom: size.height * 0.32,
            right: -size.width * 0.15,
            child: _AmbientBlob(
              size: size.width * 0.42,
              color: AppColors.accent.withValues(alpha: 0.05),
            ),
          ),

          // ── Main layout ───────────────────────────────────
          Column(
            children: [
              // Hero — fills all space above CTA
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),

                        // 3D illustration (no circles)
                        FadeTransition(
                          opacity: _logoOpacity,
                          child: SlideTransition(
                            position: _logoOffset,
                            child: _Illustration(),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // App name + tagline
                        FadeTransition(
                          opacity: _titleOpacity,
                          child: SlideTransition(
                            position: _titleOffset,
                            child: Column(
                              children: [
                                Text(
                                  'MetaPlogging',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1.0,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '걷고, 줍고, 기록하다.\n우리가 만드는 더 깨끗한 환경.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xBFFFFFFF),
                                    fontSize: 15,
                                    height: 1.65,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Feature row (3 items, always one line)
                        FadeTransition(
                          opacity: _featuresOpacity,
                          child: SlideTransition(
                            position: _featuresOffset,
                            child: const _FeatureRow(),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),

              // CTA sheet — slides up from bottom
              FadeTransition(
                opacity: _ctaOpacity,
                child: SlideTransition(
                  position: _ctaOffset,
                  child: _CtaSheet(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 3D illustration (no circle wrapper) ──────────────────────
class _Illustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'lib/shared/assets/ploggin_logo.png',
      width: 170,
      height: 170,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

// ── Feature row — 3 items, guaranteed single line ─────────────
class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FeatureItem(icon: Icons.eco_rounded, label: '환경 기여'),
        _FeatureDivider(),
        _FeatureItem(icon: Icons.photo_camera_outlined, label: '사진 기록'),
        _FeatureDivider(),
        _FeatureItem(icon: Icons.map_outlined, label: '활동 지도'),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 22, color: AppColors.secondary),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xCCFFFFFF),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FeatureDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

// ── CTA bottom sheet ──────────────────────────────────────────
class _CtaSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '지금 시작하세요',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '플로깅으로 환경을 지키고 건강도 챙기세요.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // 회원가입
              FilledButton(
                onPressed: () => context.push(AppRoutes.register),
                child: const Text('함께 플로깅 시작하기'),
              ),
              const SizedBox(height: 10),

              // 로그인
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.login),
                child: const Text('이미 계정이 있어요'),
              ),

              const SizedBox(height: 12),
              Center(
                child: Text(
                  '가입 시 이용약관 및 개인정보처리방침에 동의합니다.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ambient decorative blob ───────────────────────────────────
class _AmbientBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
