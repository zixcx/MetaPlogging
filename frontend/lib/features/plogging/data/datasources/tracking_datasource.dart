import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/core/network/api_endpoints.dart';
import 'package:meta_plogging/core/network/dio_client.dart';
import 'package:meta_plogging/features/plogging/data/models/tracking_session_model.dart';
import 'package:meta_plogging/features/plogging/data/models/trash_point_model.dart';
import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';
import 'package:meta_plogging/features/plogging/domain/entities/trash_point_entity.dart';

final trackingDatasourceProvider = Provider<TrackingDatasource>(
  (ref) => TrackingDatasource(ref.watch(dioClientProvider)),
);

class TrackingDatasource {
  final Dio _dio;

  TrackingDatasource(this._dio);

  Future<TrackingSessionEntity> startSession() async {
    final res = await _dio.post(ApiEndpoints.trackingSessions);
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
    await _dio.post(
      ApiEndpoints.trackingPoints(id),
      data: {'lat': lat, 'lng': lng},
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
    final res = await _dio.post(
      ApiEndpoints.trackingEnd(id),
      data: {
        'trash_items':
            trashItems?.map((t) => t.toJson()).toList() ?? [],
        'location_landmark_id': locationLandmarkId,
        'location_landmark_name': locationLandmarkName,
        'location_description': locationDescription,
      },
    );
    return TrackingSessionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<TrackingSessionEntity>> getSessions({int page = 1}) async {
    final res = await _dio.get(
      ApiEndpoints.trackingSessions,
      queryParameters: {'page': page, 'status': 'completed'},
    );
    final items = res.data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => TrackingSessionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TrackingSessionEntity> getSession(String id) async {
    final res = await _dio.get(ApiEndpoints.trackingSession(id));
    return TrackingSessionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TrashPointEntity> addTrashPoint(
    String id, {
    required double lat,
    required double lng,
    required TrashCategory category,
    String? note,
  }) async {
    final res = await _dio.post(
      ApiEndpoints.trackingTrashPoints(id),
      data: {
        'lat': lat,
        'lng': lng,
        'category': category.apiValue,
        'note': note,
      },
    );
    return TrashPointModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<TrashPointEntity>> getTrashPoints(String id) async {
    final res = await _dio.get(ApiEndpoints.trackingTrashPoints(id));
    final items = res.data as List<dynamic>? ?? [];
    return items
        .map((e) => TrashPointModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
