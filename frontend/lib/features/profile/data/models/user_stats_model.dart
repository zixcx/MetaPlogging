import 'package:meta_plogging/features/profile/domain/entities/user_stats_entity.dart';

class UserStatsModel {
  static UserStatsEntity fromJson(Map<String, dynamic> json) {
    return UserStatsEntity(
      totalDistanceMeters:
          (json['total_distance_meters'] as num?)?.toInt() ?? 0,
      totalDurationSeconds:
          (json['total_duration_seconds'] as num?)?.toInt() ?? 0,
      totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
      totalTrashCount: (json['total_trash_count'] as num?)?.toInt() ?? 0,
    );
  }
}
