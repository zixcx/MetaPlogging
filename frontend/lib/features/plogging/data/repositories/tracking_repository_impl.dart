import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/features/plogging/data/datasources/tracking_datasource.dart';
import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';
import 'package:meta_plogging/features/plogging/domain/entities/trash_point_entity.dart';
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
  Future<List<TrackingSessionEntity>> getSessions({int page = 1}) =>
      _datasource.getSessions(page: page);

  @override
  Future<TrackingSessionEntity> getSession(String sessionId) =>
      _datasource.getSession(sessionId);

  @override
  Future<TrashPointEntity> addTrashPoint(
    String sessionId, {
    required double lat,
    required double lng,
    required TrashCategory category,
    String? note,
  }) =>
      _datasource.addTrashPoint(
        sessionId,
        lat: lat,
        lng: lng,
        category: category,
        note: note,
      );

  @override
  Future<List<TrashPointEntity>> getTrashPoints(String sessionId) =>
      _datasource.getTrashPoints(sessionId);
}
