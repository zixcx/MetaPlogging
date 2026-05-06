import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';
import 'package:meta_plogging/features/plogging/domain/entities/trash_point_entity.dart';

class TrashPointModel {
  static TrashPointEntity fromJson(Map<String, dynamic> json) =>
      TrashPointEntity(
        id: json['id'] as String,
        sessionId: json['session_id'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        category: TrashCategory.fromApi(json['category'] as String),
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
