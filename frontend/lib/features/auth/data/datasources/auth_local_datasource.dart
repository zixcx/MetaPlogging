import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meta_plogging/core/network/dio_client.dart';
import 'package:meta_plogging/features/auth/data/models/auth_token_model.dart';
import 'package:meta_plogging/features/auth/data/models/user_model.dart';

const _accessTokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';
const _userKey = 'user';

final authLocalDatasourceProvider = Provider<AuthLocalDatasource>(
  (ref) => AuthLocalDatasourceImpl(ref.watch(secureStorageProvider)),
);

abstract interface class AuthLocalDatasource {
  Future<void> saveTokens(AuthTokenModel tokenModel);
  Future<String?> getAccessToken();
  Future<UserModel?> getUser();
  Future<void> clearAll();
}

class AuthLocalDatasourceImpl implements AuthLocalDatasource {
  final FlutterSecureStorage _storage;

  AuthLocalDatasourceImpl(this._storage);

  @override
  Future<void> saveTokens(AuthTokenModel tokenModel) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: tokenModel.accessToken),
      _storage.write(key: _refreshTokenKey, value: tokenModel.refreshToken),
      _storage.write(
        key: _userKey,
        value: jsonEncode(tokenModel.user.toJson()),
      ),
    ]);
  }

  @override
  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<UserModel?> getUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> clearAll() => _storage.deleteAll();
}
