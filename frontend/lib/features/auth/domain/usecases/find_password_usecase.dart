import 'package:meta_plogging/features/auth/domain/repositories/auth_repository.dart';

class FindPasswordUsecase {
  final AuthRepository _repository;

  const FindPasswordUsecase(this._repository);

  Future<void> execute(String email) => _repository.findPassword(email);
}
