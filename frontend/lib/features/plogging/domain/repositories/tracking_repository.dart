import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';

abstract class TrackingRepository {
  Future<TrackingSessionEntity> startSession();
  Future<TrackingSessionEntity?> getActiveSession();
  Future<void> addPoint(String sessionId, double lat, double lng);
  Future<TrackingSessionEntity> pauseSession(String sessionId);
  Future<TrackingSessionEntity> resumeSession(String sessionId);
  Future<TrackingSessionEntity> endSession(
    String sessionId, {
    List<TrashItem>? trashItems,
    String? locationLandmarkId,
    String? locationLandmarkName,
    String? locationDescription,
  });
  Future<List<TrackingSessionEntity>> getSessions({int limit, int offset});
  Future<TrackingSessionEntity> getSession(String sessionId);
  Future<void> deleteSession(String sessionId);
}
