import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthExpiredNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void expire() => state++;
}

// dio_client.dart의 _AuthInterceptor가 토큰 갱신 실패 시 expire()를 호출한다.
// auth_provider.dart가 watch해서 자동으로 rebuild → null 반환 → GoRouter가 로그인으로 리다이렉트.
final authExpiredProvider =
    NotifierProvider<AuthExpiredNotifier, int>(AuthExpiredNotifier.new);
