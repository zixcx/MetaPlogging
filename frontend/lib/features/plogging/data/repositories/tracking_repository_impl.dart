import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/features/plogging/data/datasources/tracking_datasource.dart';
import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';
import 'package:meta_plogging/features/plogging/domain/repositories/tracking_repository.dart';

final trackingRepositoryProvider = Provider<TrackingRepository>(
  (ref) => TrackingRepositoryImpl(ref.watch(trackingDatasourceProvider)),
);

class TrackingRepositoryImpl implements TrackingRepository {
  final TrackingDatasource _datasource;

  TrackingRepositoryImpl(this._datasource);

  @override
  Future<TrackingSessionEntity> startSession() => _datasource.startSession();

  @override
  Future<TrackingSessionEntity?> getActiveSession() =>
      _datasource.getActiveSession();

  @override
  Future<void> addPoint(String sessionId, double lat, double lng) =>
      _datasource.addPoint(sessionId, lat, lng);

  @override
  Future<TrackingSessionEntity> pauseSession(String sessionId) =>
      _datasource.pauseSession(sessionId);

  @override
  Future<TrackingSessionEntity> resumeSession(String sessionId) =>
      _datasource.resumeSession(sessionId);

  @override
  Future<TrackingSessionEntity> endSession(
    String sessionId, {
    List<TrashItem>? trashItems,
    String? locationLandmarkId,
    String? locationLandmarkName,
    String? locationDescription,
  }) =>
      _datasource.endSession(
        sessionId,
        trashItems: trashItems,
        locationLandmarkId: locationLandmarkId,
        locationLandmarkName: locationLandmarkName,
        locationDescription: locationDescription,
      );

  @override
  Future<List<TrackingSessionEntity>> getSessions({
    int limit = 20,
    int offset = 0,
  }) =>
      _datasource.getSessions(limit: limit, offset: offset);

  @override
  Future<TrackingSessionEntity> getSession(String sessionId) =>
      _datasource.getSession(sessionId);

  @override
  Future<void> deleteSession(String sessionId) =>
      _datasource.deleteSession(sessionId);
}
