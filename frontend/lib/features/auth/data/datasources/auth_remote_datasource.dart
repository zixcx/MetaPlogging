import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:meta_plogging/core/network/api_endpoints.dart';
import 'package:meta_plogging/core/network/dio_client.dart';
import 'package:meta_plogging/features/auth/data/models/auth_token_model.dart';

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>(
  (ref) => AuthRemoteDatasourceImpl(ref.watch(dioClientProvider)),
);

abstract interface class AuthRemoteDatasource {
  Future<AuthTokenModel> loginWithUsername({
    required String username,
    required String password,
  });

  Future<AuthTokenModel> loginWithGoogle();

  Future<AuthTokenModel> loginWithKakao();

  Future<AuthTokenModel> register({
    required String username,
    required String email,
    required String password,
    required String name,
  });

  Future<void> logout();

  Future<void> findPassword(String email);
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final Dio _dio;

  // google_sign_in: email + profile 기본 스코프
  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  AuthRemoteDatasourceImpl(this._dio);

  @override
  Future<AuthTokenModel> loginWithUsername({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.loginEmail,
      data: {'username': username, 'password': password},
    );
    return AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AuthTokenModel> loginWithGoogle() async {
    // 1. Google OAuth — idToken을 백엔드로 전송
    final account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Google 로그인이 취소되었습니다.');

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) throw Exception('Google ID Token을 가져올 수 없습니다.');

    // 2. 백엔드에 idToken 전달 → 백엔드에서 검증 후 JWT 발급
    final response = await _dio.post(
      ApiEndpoints.loginGoogle,
      data: {'id_token': idToken},
    );
    return AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AuthTokenModel> loginWithKakao() async {
    // 1. 카카오톡 설치 여부 확인 후 분기
    // 공식 문서 권장 방식: 카카오톡 설치 → KakaoTalk 로그인, 미설치 → 카카오계정 로그인
    OAuthToken token;
    final talkInstalled = await isKakaoTalkInstalled();

    if (talkInstalled) {
      try {
        token = await UserApi.instance.loginWithKakaoTalk();
      } catch (e) {
        // 사용자가 직접 취소한 경우(CANCELED)는 계정 로그인 시도 안 함
        if (e is PlatformException && e.code == 'CANCELED') rethrow;
        // 카카오톡에 연결된 계정이 없는 경우 → 카카오계정으로 fallback
        token = await UserApi.instance.loginWithKakaoAccount();
      }
    } else {
      token = await UserApi.instance.loginWithKakaoAccount();
    }

    // 2. 카카오 사용자 정보 조회
    final kakaoUser = await UserApi.instance.me();

    // 이메일: 필수 동의 항목 — null이면 카카오 미동의 or 이메일 미인증
    final email = kakaoUser.kakaoAccount?.email;

    // 닉네임/프로필사진: 선택 동의 항목 — 미동의 시 null로 전달
    // 백엔드에서 null 수신 시 기본값(랜덤 닉네임 등) 처리
    final profile = kakaoUser.kakaoAccount?.profile;
    final nickname = profile?.nickname;           // 미동의 → null
    final profileImage = profile?.profileImageUrl; // 미동의 or 기본 이미지 → null

    // 3. 백엔드에 accessToken + 사용자 정보 전달
    final response = await _dio.post(
      ApiEndpoints.loginKakao,
      data: {
        'access_token': token.accessToken,
        'email': email,
        'name': nickname,
        'profile_image_url': profileImage,
      },
    );
    return AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AuthTokenModel> register({
    required String username,
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: {
        'username': username,
        'email': email,
        'password': password,
        'name': name,
      },
    );
    return AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    await _dio.post(ApiEndpoints.logout);
    // 카카오 로그아웃 처리
    try {
      await UserApi.instance.logout();
    } catch (_) {}
    // 구글 로그아웃 처리
    await _googleSignIn.signOut();
  }

  @override
  Future<void> findPassword(String email) async {
    await _dio.post(
      ApiEndpoints.findPassword,
      data: {'email': email},
    );
  }
}
