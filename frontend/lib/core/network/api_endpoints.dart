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

  // Tracking
  static const String trackingSessions = '/tracking/sessions';
  static const String trackingActive = '/tracking/sessions/active';
  static String trackingPoints(String id) => '/tracking/sessions/$id/points';
  static String trackingPause(String id) => '/tracking/sessions/$id/pause';
  static String trackingResume(String id) => '/tracking/sessions/$id/resume';
  static String trackingEnd(String id) => '/tracking/sessions/$id/end';
  static String trackingSession(String id) => '/tracking/sessions/$id';
  static String sessionPhotos(String id) => '/tracking/sessions/$id/photos';
  static String sessionPhoto(String id, String photoId) =>
      '/tracking/sessions/$id/photos/$photoId';

  // Places
  static const String placesSearch = '/places/search';

  // Users
  static const String userStats = '/users/me/stats';
  static const String platformSummary = '/users/stats/summary';

  // Feed / Posts
  static const String posts = '/posts';
  static String postDetail(String id) => '/posts/$id';
  static String postLike(String id) => '/posts/$id/like';
  static String postComments(String id) => '/posts/$id/comments';
  static const String imageUpload = '/images/upload';
}
