import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl =>
      dotenv.env['BACKEND_BASE_URL'] ?? 'http://localhost:3000/api';

  // Auth
  static const String loginEmail = '/auth/login';
  static const String loginGoogle = '/auth/google';
  static const String loginKakao = '/auth/kakao';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String findPassword = '/auth/find-password';
  static const String refreshToken = '/auth/refresh';
  static const String me = '/auth/me';
}
