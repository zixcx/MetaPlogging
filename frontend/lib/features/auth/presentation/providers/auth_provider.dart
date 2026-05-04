import 'package:meta_plogging/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:meta_plogging/features/auth/domain/entities/user_entity.dart';
import 'package:meta_plogging/features/auth/domain/usecases/find_password_usecase.dart';
import 'package:meta_plogging/features/auth/domain/usecases/login_email_usecase.dart';
import 'package:meta_plogging/features/auth/domain/usecases/login_google_usecase.dart';
import 'package:meta_plogging/features/auth/domain/usecases/login_kakao_usecase.dart';
import 'package:meta_plogging/features/auth/domain/usecases/logout_usecase.dart';
import 'package:meta_plogging/features/auth/domain/usecases/register_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

/// 앱 전역에서 현재 사용자 상태를 구독하는 핵심 provider.
/// - null: 미로그인
/// - UserEntity: 로그인 완료
/// - AsyncLoading: 로딩 중
/// - AsyncError: 오류
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<UserEntity?> build() async {
    final repo = ref.read(authRepositoryProvider);
    return repo.getCurrentUser();
  }

  Future<void> loginWithUsername({
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => LoginEmailUsecase(ref.read(authRepositoryProvider))
          .execute(username: username, password: password),
    );
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => LoginGoogleUsecase(ref.read(authRepositoryProvider)).execute(),
    );
  }

  Future<void> loginWithKakao() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => LoginKakaoUsecase(ref.read(authRepositoryProvider)).execute(),
    );
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => RegisterUsecase(ref.read(authRepositoryProvider))
          .execute(username: username, email: email, password: password, name: name),
    );
  }

  Future<void> logout() async {
    await AsyncValue.guard(
      () => LogoutUsecase(ref.read(authRepositoryProvider)).execute(),
    );
    state = const AsyncData(null);
  }

  Future<bool> findPassword(String email) async {
    try {
      await FindPasswordUsecase(ref.read(authRepositoryProvider))
          .execute(email);
      return true;
    } catch (_) {
      return false;
    }
  }
}
