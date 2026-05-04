import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum SocialLoginType { google, kakao }

class SocialLoginButton extends StatelessWidget {
  final SocialLoginType type;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      SocialLoginType.google => _buildGoogleButton(),
      SocialLoginType.kakao => _buildKakaoButton(),
    };
  }

  Widget _buildGoogleButton() {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFFFFFFFF),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFFDDDDDD)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: isLoading
          ? const _LoadingIndicator(color: Color(0xFF80868B))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'lib/shared/assets/google_logo.svg',
                  width: 22,
                  height: 22,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Google로 계속하기',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF80868B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildKakaoButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFEE500),
        foregroundColor: const Color(0xD9000000),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: isLoading
          ? const _LoadingIndicator(color: Color(0xD9000000))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'lib/shared/assets/kakao_logo.svg',
                  width: 22,
                  height: 22,
                ),
                const SizedBox(width: 12),
                const Text(
                  '카카오로 계속하기',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xD9000000),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  final Color color;

  const _LoadingIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
    );
  }
}
