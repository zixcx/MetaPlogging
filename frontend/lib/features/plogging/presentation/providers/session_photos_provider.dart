import 'dart:io';

import 'package:meta_plogging/features/plogging/data/repositories/session_photos_repository_impl.dart';
import 'package:meta_plogging/features/plogging/domain/entities/session_photo_entity.dart';
import 'package:meta_plogging/features/plogging/domain/repositories/session_photos_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_photos_provider.g.dart';

@riverpod
class SessionPhotos extends _$SessionPhotos {
  SessionPhotosRepository get _repo =>
      ref.read(sessionPhotosRepositoryProvider);

  @override
  Future<List<SessionPhotoEntity>> build(String sessionId) =>
      _repo.getPhotos(sessionId);

  Future<void> uploadPhoto(
    File file, {
    double? lat,
    double? lng,
    DateTime? takenAt,
  }) async {
    final prev = state.asData?.value ?? [];
    try {
      final photo = await _repo.uploadPhoto(
        sessionId,
        file,
        lat: lat,
        lng: lng,
        takenAt: takenAt,
      );
      state = AsyncData([...prev, photo]);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deletePhoto(String photoId) async {
    final prev = state.asData?.value ?? [];
    state = AsyncData(prev.where((p) => p.id != photoId).toList());
    try {
      await _repo.deletePhoto(sessionId, photoId);
    } catch (e) {
      state = AsyncData(prev);
    }
  }
}
