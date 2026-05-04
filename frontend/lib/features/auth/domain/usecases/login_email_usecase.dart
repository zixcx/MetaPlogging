import 'package:meta_plogging/features/auth/domain/entities/user_entity.dart';
import 'package:meta_plogging/features/auth/domain/repositories/auth_repository.dart';

class LoginEmailUsecase {
  final AuthRepository _repository;

  const LoginEmailUsecase(this._repository);

  Future<UserEntity> execute({
    required String username,
    required String password,
  }) =>
      _repository.loginWithUsername(username: username, password: password);
}
