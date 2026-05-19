import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/features/plogging/data/datasources/session_photos_datasource.dart';
import 'package:meta_plogging/features/plogging/domain/entities/session_photo_entity.dart';
import 'package:meta_plogging/features/plogging/domain/repositories/session_photos_repository.dart';

final sessionPhotosRepositoryProvider = Provider<SessionPhotosRepository>(
  (ref) => SessionPhotosRepositoryImpl(
    ref.watch(sessionPhotosDatasourceProvider),
  ),
);

class SessionPhotosRepositoryImpl implements SessionPhotosRepository {
  final SessionPhotosDatasource _datasource;

  SessionPhotosRepositoryImpl(this._datasource);

  @override
  Future<SessionPhotoEntity> uploadPhoto(
    String sessionId,
    File file, {
    double? lat,
    double? lng,
    DateTime? takenAt,
  }) =>
      _datasource.uploadPhoto(sessionId, file,
          lat: lat, lng: lng, takenAt: takenAt);

  @override
  Future<List<SessionPhotoEntity>> getPhotos(String sessionId) =>
      _datasource.getPhotos(sessionId);

  @override
  Future<void> deletePhoto(String sessionId, String photoId) =>
      _datasource.deletePhoto(sessionId, photoId);
}
