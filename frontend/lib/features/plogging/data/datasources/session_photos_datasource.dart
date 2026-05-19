import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/core/network/api_endpoints.dart';
import 'package:meta_plogging/core/network/dio_client.dart';
import 'package:meta_plogging/features/plogging/data/models/session_photo_model.dart';
import 'package:meta_plogging/features/plogging/domain/entities/session_photo_entity.dart';

final sessionPhotosDatasourceProvider = Provider<SessionPhotosDatasource>(
  (ref) => SessionPhotosDatasource(ref.watch(dioClientProvider)),
);

class SessionPhotosDatasource {
  final Dio _dio;

  SessionPhotosDatasource(this._dio);

  Future<SessionPhotoEntity> uploadPhoto(
    String sessionId,
    File file, {
    double? lat,
    double? lng,
    DateTime? takenAt,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
      if (lat != null) 'lat': lat.toString(),
      if (lng != null) 'lng': lng.toString(),
      if (takenAt != null) 'taken_at': takenAt.toUtc().toIso8601String(),
    });
    final res = await _dio.post(
      ApiEndpoints.sessionPhotos(sessionId),
      data: formData,
    );
    return SessionPhotoModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<SessionPhotoEntity>> getPhotos(String sessionId) async {
    final res = await _dio.get(ApiEndpoints.sessionPhotos(sessionId));
    final items = res.data as List<dynamic>? ?? [];
    return items
        .map((e) => SessionPhotoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deletePhoto(String sessionId, String photoId) async {
    await _dio.delete(ApiEndpoints.sessionPhoto(sessionId, photoId));
  }
}
