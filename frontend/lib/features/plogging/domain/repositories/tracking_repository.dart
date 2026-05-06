import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';
import 'package:meta_plogging/features/plogging/domain/entities/trash_point_entity.dart';

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
  Future<List<TrackingSessionEntity>> getSessions({int page = 1});
  Future<TrackingSessionEntity> getSession(String sessionId);
  Future<TrashPointEntity> addTrashPoint(
    String sessionId, {
    required double lat,
    required double lng,
    required TrashCategory category,
    String? note,
  });
  Future<List<TrashPointEntity>> getTrashPoints(String sessionId);
}
