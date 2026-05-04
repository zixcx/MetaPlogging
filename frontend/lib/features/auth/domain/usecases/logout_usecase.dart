import 'package:meta_plogging/features/auth/domain/repositories/auth_repository.dart';

class LogoutUsecase {
  final AuthRepository _repository;

  const LogoutUsecase(this._repository);

  Future<void> execute() => _repository.logout();
}
