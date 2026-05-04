import 'package:meta_plogging/features/auth/domain/entities/user_entity.dart';

abstract interface class AuthRepository {
  Future<UserEntity> loginWithUsername({
    required String username,
    required String password,
  });

  Future<UserEntity> loginWithGoogle();

  Future<UserEntity> loginWithKakao();

  Future<UserEntity> register({
    required String username,
    required String email,
    required String password,
    required String name,
  });

  Future<void> logout();

  Future<void> findPassword(String email);

  Future<UserEntity?> getCurrentUser();
}
