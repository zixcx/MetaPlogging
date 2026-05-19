import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meta_plogging/core/router/app_router.dart';
import 'package:meta_plogging/features/auth/presentation/providers/auth_provider.dart';
import 'package:meta_plogging/features/auth/presentation/widgets/social_login_button.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginWithUsername() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _errorMessage = null);
    await ref.read(authProvider.notifier).loginWithUsername(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  String _parseError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final detail = error.response?.data?['detail'];

      if (status == 401) {
        return '아이디 또는 비밀번호가 올바르지 않습니다.';
      }
      if (status == 422) {
        return '입력 형식이 올바르지 않습니다.';
      }
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return '서버 연결 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return '서버에 연결할 수 없습니다. 네트워크를 확인해주세요.';
      }
    }
    return '로그인 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (prev, next) {
      if (next is AsyncError) {
        setState(() => _errorMessage = _parseError(next.error ?? '알 수 없는 오류'));
      } else if (next is AsyncLoading) {
        setState(() => _errorMessage = null);
      }
    });

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.landing),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────
                _LoginHeader(),
                const SizedBox(height: 36),

                // ── Username ──────────────────────────────────
                _AuthField(
                  controller: _usernameCtrl,
                  label: '아이디',
                  icon: Icons.badge_outlined,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  validator: (v) {
                    if (v == null || v.isEmpty) return '아이디를 입력해주세요.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ── Password ─────────────────────────────────
                _AuthField(
                  controller: _passwordCtrl,
                  label: '비밀번호',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _loginWithUsername(),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '비밀번호를 입력해주세요.';
                    return null;
                  },
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.findAccount),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                    ),
                    child: Text(
                      '비밀번호를 잊으셨나요?',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // ── 에러 메시지 박스 ─────────────────────────
                if (_errorMessage != null) ...[
                  _ErrorBox(message: _errorMessage!),
                  const SizedBox(height: 12),
                ] else
                  const SizedBox(height: 8),

                // ── Login button ─────────────────────────────
                FilledButton(
                  onPressed: isLoading ? null : _loginWithUsername,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('로그인'),
                ),
                const SizedBox(height: 10),

                OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => context.push(AppRoutes.register),
                  child: const Text('계정 만들기'),
                ),
                const SizedBox(height: 32),

                // ── Social login ─────────────────────────────
                _OrDivider(),
                const SizedBox(height: 20),

                SocialLoginButton(
                  type: SocialLoginType.google,
                  isLoading: isLoading,
                  onPressed: () =>
                      ref.read(authProvider.notifier).loginWithGoogle(),
                ),
                const SizedBox(height: 10),
                SocialLoginButton(
                  type: SocialLoginType.kakao,
                  isLoading: isLoading,
                  onPressed: () =>
                      ref.read(authProvider.notifier).loginWithKakao(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 에러 박스 ─────────────────────────────────────────────────
class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4757).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF4757).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFF4757),
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFF4757),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Login header ──────────────────────────────────────────────
class _LoginHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '다시 만나서\n반가워요!',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'MetaPlogging 계정으로 로그인하세요.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

// ── Shared auth input field ───────────────────────────────────
class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      validator: validator,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: cs.onSurfaceVariant),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

// ── Or divider ────────────────────────────────────────────────
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: Divider(color: cs.outlineVariant)),
        Container(
          color: cs.surface,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            '또는',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(child: Divider(color: cs.outlineVariant)),
      ],
    );
  }
}
