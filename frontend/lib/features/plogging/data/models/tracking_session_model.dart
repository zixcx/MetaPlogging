import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';

class TrackingSessionModel {
  static TrackingSessionEntity fromJson(Map<String, dynamic> json) {
    final pathList = (json['path'] as List<dynamic>? ?? [])
        .map((p) => NLatLng(
              (p['lat'] as num).toDouble(),
              (p['lng'] as num).toDouble(),
            ))
        .toList();

    final trashList = (json['trash_items'] as List<dynamic>? ?? [])
        .map((t) => TrashItem.fromJson(t as Map<String, dynamic>))
        .toList();

    return TrackingSessionEntity(
      id: json['id'] as String,
      status: _parseStatus(json['status'] as String),
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      distanceMeters: (json['distance_meters'] as num?)?.toInt() ?? 0,
      path: pathList,
      locationLandmarkId: json['location_landmark_id'] as String?,
      locationLandmarkName: json['location_landmark_name'] as String?,
      locationDescription: json['location_description'] as String?,
      trashItems: trashList,
      pauseDurationSeconds:
          (json['pause_duration_seconds'] as num?)?.toInt() ?? 0,
    );
  }

  static TrackingStatus _parseStatus(String value) {
    switch (value) {
      case 'active':
        return TrackingStatus.active;
      case 'paused':
        return TrackingStatus.paused;
      case 'completed':
        return TrackingStatus.completed;
      default:
        return TrackingStatus.expired;
    }
  }
}
