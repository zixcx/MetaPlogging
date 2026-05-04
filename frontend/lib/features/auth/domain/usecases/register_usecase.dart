import 'package:meta_plogging/features/auth/domain/entities/user_entity.dart';
import 'package:meta_plogging/features/auth/domain/repositories/auth_repository.dart';

class RegisterUsecase {
  final AuthRepository _repository;

  const RegisterUsecase(this._repository);

  Future<UserEntity> execute({
    required String username,
    required String email,
    required String password,
    required String name,
  }) =>
      _repository.register(
        username: username,
        email: email,
        password: password,
        name: name,
      );
}
