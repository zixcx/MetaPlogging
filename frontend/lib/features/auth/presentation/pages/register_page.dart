import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meta_plogging/features/auth/presentation/providers/auth_provider.dart';
import 'package:meta_plogging/features/auth/presentation/widgets/social_login_button.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  bool _showEmailForm = false;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authProvider.notifier).register(
          username: _usernameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          name: _nameCtrl.text.trim(),
        );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (_, next) {
      if (next is AsyncError) _showError(next.error.toString());
    });

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_showEmailForm) {
              setState(() => _showEmailForm = false);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────
              Text(
                '계정 만들기',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '함께 플로깅으로 환경을 지켜나가요.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // ── OAuth buttons ────────────────────────────
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
              const SizedBox(height: 20),

              // ── Divider ──────────────────────────────────
              _OrDivider(),
              const SizedBox(height: 20),

              // ── Register form (animated) ─────────────────
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 280),
                crossFadeState: _showEmailForm
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: FilledButton(
                  onPressed: isLoading
                      ? null
                      : () => setState(() => _showEmailForm = true),
                  child: const Text('가입하기'),
                ),
                secondChild: _RegisterForm(
                  formKey: _formKey,
                  nameCtrl: _nameCtrl,
                  usernameCtrl: _usernameCtrl,
                  emailCtrl: _emailCtrl,
                  passwordCtrl: _passwordCtrl,
                  confirmPasswordCtrl: _confirmPasswordCtrl,
                  obscurePassword: _obscurePassword,
                  obscureConfirm: _obscureConfirm,
                  isLoading: isLoading,
                  onTogglePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onToggleConfirm: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  onSubmit: _register,
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: Text(
                  '가입 시 이용약관 및 개인정보처리방침에 동의합니다.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
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

// ── Register form ─────────────────────────────────────────────
class _RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController usernameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmPasswordCtrl;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;

  const _RegisterForm({
    required this.formKey,
    required this.nameCtrl,
    required this.usernameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmPasswordCtrl,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Field(
            controller: nameCtrl,
            label: '이름',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return '이름을 입력해주세요.';
              if (v.trim().length < 2) return '이름은 2자 이상이어야 합니다.';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _Field(
            controller: usernameCtrl,
            label: '아이디',
            icon: Icons.badge_outlined,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return '아이디를 입력해주세요.';
              if (v.trim().length < 3) return '아이디는 3자 이상이어야 합니다.';
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                return '영문, 숫자, 밑줄(_)만 사용할 수 있습니다.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _Field(
            controller: emailCtrl,
            label: '이메일',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return '이메일을 입력해주세요.';
              if (!v.contains('@')) return '올바른 이메일 형식이 아닙니다.';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _Field(
            controller: passwordCtrl,
            label: '비밀번호',
            icon: Icons.lock_outline_rounded,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.next,
            helperText: '영문, 숫자 포함 8자 이상',
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
              onPressed: onTogglePassword,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return '비밀번호를 입력해주세요.';
              if (v.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
              if (!v.contains(RegExp('[a-zA-Z]')) ||
                  !v.contains(RegExp('[0-9]'))) {
                return '영문과 숫자를 모두 포함해야 합니다.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _Field(
            controller: confirmPasswordCtrl,
            label: '비밀번호 확인',
            icon: Icons.lock_outline_rounded,
            obscureText: obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
              onPressed: onToggleConfirm,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return '비밀번호를 다시 입력해주세요.';
              if (v != passwordCtrl.text) return '비밀번호가 일치하지 않습니다.';
              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('가입하기'),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;
  final String? helperText;
  final FormFieldValidator<String>? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.helperText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon, size: 20, color: cs.onSurfaceVariant),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
