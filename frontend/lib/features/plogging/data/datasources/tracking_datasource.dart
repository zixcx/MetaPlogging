import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/core/network/api_endpoints.dart';
import 'package:meta_plogging/core/network/dio_client.dart';
import 'package:meta_plogging/features/plogging/data/models/tracking_session_model.dart';
import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';

final trackingDatasourceProvider = Provider<TrackingDatasource>(
  (ref) => TrackingDatasource(ref.watch(dioClientProvider)),
);

class TrackingDatasource {
  final Dio _dio;

  TrackingDatasource(this._dio);

  Future<TrackingSessionEntity> startSession() async {
    // StartSessionRequest: start_lat/start_lng 모두 optional이지만
    // FastAPI는 body 파라미터가 있으면 JSON body가 필요함
    final res = await _dio.post(
      ApiEndpoints.trackingSessions,
      data: <String, dynamic>{},
    );
    return TrackingSessionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TrackingSessionEntity?> getActiveSession() async {
    try {
      final res = await _dio.get(ApiEndpoints.trackingActive);
      return TrackingSessionModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> addPoint(String id, double lat, double lng) async {
    // 백엔드: AddPointsRequest { points: [{lat, lng, recorded_at}] }
    await _dio.post(
      ApiEndpoints.trackingPoints(id),
      data: {
        'points': [
          {
            'lat': lat,
            'lng': lng,
            'recorded_at': DateTime.now().toUtc().toIso8601String(),
          }
        ],
      },
    );
  }

  Future<TrackingSessionEntity> pauseSession(String id) async {
    final res = await _dio.post(ApiEndpoints.trackingPause(id));
    return TrackingSessionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TrackingSessionEntity> resumeSession(String id) async {
    final res = await _dio.post(ApiEndpoints.trackingResume(id));
    return TrackingSessionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TrackingSessionEntity> endSession(
    String id, {
    List<TrashItem>? trashItems,
    String? locationLandmarkId,
    String? locationLandmarkName,
    String? locationDescription,
  }) async {
    // 백엔드: EndSessionRequest { trash_items, place?, description?, end_lat?, end_lng? }
    // trash_items: [{category, amount: {level?, count?}}]
    final res = await _dio.post(
      ApiEndpoints.trackingEnd(id),
      data: {
        'trash_items': trashItems?.map((t) => t.toJson()).toList() ?? [],
        'description': locationDescription,
        if (locationLandmarkId != null && locationLandmarkName != null)
          'place': {
            'naver_place_id': locationLandmarkId,
            'name': locationLandmarkName,
            'lat': 0.0,
            'lng': 0.0,
          },
      },
    );
    return TrackingSessionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<TrackingSessionEntity>> getSessions({
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      ApiEndpoints.trackingSessions,
      queryParameters: {
        'limit': limit,
        'offset': offset,
        'status': 'completed',
      },
    );
    final items = res.data as List<dynamic>? ?? [];
    return items
        .map((e) => TrackingSessionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TrackingSessionEntity> getSession(String id) async {
    final res = await _dio.get(ApiEndpoints.trackingSession(id));
    return TrackingSessionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteSession(String id) async {
    await _dio.delete(ApiEndpoints.trackingSession(id));
  }
}
