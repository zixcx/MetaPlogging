import 'package:meta_plogging/core/network/api_endpoints.dart';
import 'package:meta_plogging/features/plogging/domain/entities/session_photo_entity.dart';

class SessionPhotoModel {
  static SessionPhotoEntity fromJson(Map<String, dynamic> json) {
    final rawUrl = json['url'] as String;
    final baseUrl = ApiEndpoints.baseUrl.replaceAll('/api', '');
    final url = rawUrl.startsWith('http') ? rawUrl : '$baseUrl$rawUrl';

    return SessionPhotoEntity(
      id: json['id'] as String,
      url: url,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      takenAt: json['taken_at'] != null
          ? DateTime.parse(json['taken_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
