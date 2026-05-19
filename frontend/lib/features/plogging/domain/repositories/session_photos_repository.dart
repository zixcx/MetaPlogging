import 'dart:io';

import 'package:meta_plogging/features/plogging/domain/entities/session_photo_entity.dart';

abstract class SessionPhotosRepository {
  Future<SessionPhotoEntity> uploadPhoto(
    String sessionId,
    File file, {
    double? lat,
    double? lng,
    DateTime? takenAt,
  });

  Future<List<SessionPhotoEntity>> getPhotos(String sessionId);

  Future<void> deletePhoto(String sessionId, String photoId);
}
