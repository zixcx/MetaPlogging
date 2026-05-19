import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';

class TrashPointEntity {
  final String id;
  final double lat;
  final double lng;
  final TrashCategory category;
  final String? note;
  final DateTime createdAt;

  const TrashPointEntity({
    required this.id,
    required this.lat,
    required this.lng,
    required this.category,
    this.note,
    required this.createdAt,
  });
}
