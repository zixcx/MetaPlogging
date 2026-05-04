import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';

class FindAccountPage extends ConsumerWidget {
  const FindAccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '비밀번호 찾기',
          style: theme.textTheme.titleMedium,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Coming soon illustration ──────────────────
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon badge
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardDark
                            : const Color(0xFFEFF8F1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2A4035)
                              : const Color(0xFFD0ECE0),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.construction_rounded,
                        size: 44,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 28),

                    Text(
                      '기능 준비 중이에요',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '비밀번호 찾기 기능은 현재 개발 중입니다.\n곧 업데이트될 예정이에요.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Notice card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '비밀번호를 잊으셨다면 앱 문의를 통해 도움을 받으실 수 있어요.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Back button ───────────────────────────────
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('로그인으로 돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
