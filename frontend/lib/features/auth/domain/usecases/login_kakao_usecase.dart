import 'package:meta_plogging/features/auth/domain/entities/user_entity.dart';
import 'package:meta_plogging/features/auth/domain/repositories/auth_repository.dart';

class LoginKakaoUsecase {
  final AuthRepository _repository;

  const LoginKakaoUsecase(this._repository);

  Future<UserEntity> execute() => _repository.loginWithKakao();
}
