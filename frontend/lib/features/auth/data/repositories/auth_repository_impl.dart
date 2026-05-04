import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:meta_plogging/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:meta_plogging/features/auth/data/models/user_model.dart';
import 'package:meta_plogging/features/auth/domain/entities/user_entity.dart';
import 'package:meta_plogging/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remote: ref.watch(authRemoteDatasourceProvider),
    local: ref.watch(authLocalDatasourceProvider),
  ),
);

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;
  final AuthLocalDatasource _local;

  AuthRepositoryImpl({
    required AuthRemoteDatasource remote,
    required AuthLocalDatasource local,
  })  : _remote = remote,
        _local = local;

  @override
  Future<UserEntity> loginWithUsername({
    required String username,
    required String password,
  }) async {
    final tokenModel = await _remote.loginWithUsername(
      username: username,
      password: password,
    );
    await _local.saveTokens(tokenModel);
    return tokenModel.user.toEntity();
  }

  @override
  Future<UserEntity> loginWithGoogle() async {
    final tokenModel = await _remote.loginWithGoogle();
    await _local.saveTokens(tokenModel);
    return tokenModel.user.toEntity();
  }

  @override
  Future<UserEntity> loginWithKakao() async {
    final tokenModel = await _remote.loginWithKakao();
    await _local.saveTokens(tokenModel);
    return tokenModel.user.toEntity();
  }

  @override
  Future<UserEntity> register({
    required String username,
    required String email,
    required String password,
    required String name,
  }) async {
    final tokenModel = await _remote.register(
      username: username,
      email: email,
      password: password,
      name: name,
    );
    await _local.saveTokens(tokenModel);
    return tokenModel.user.toEntity();
  }

  @override
  Future<void> logout() async {
    await _remote.logout();
    await _local.clearAll();
  }

  @override
  Future<void> findPassword(String email) => _remote.findPassword(email);

  @override
  Future<UserEntity?> getCurrentUser() async {
    final token = await _local.getAccessToken();
    if (token == null) return null;
    final userModel = await _local.getUser();
    return userModel?.toEntity();
  }
}
