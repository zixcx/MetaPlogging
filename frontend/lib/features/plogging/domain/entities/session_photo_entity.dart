class SessionPhotoEntity {
  final String id;
  final String url;
  final double? lat;
  final double? lng;
  final DateTime? takenAt;
  final DateTime createdAt;

  const SessionPhotoEntity({
    required this.id,
    required this.url,
    this.lat,
    this.lng,
    this.takenAt,
    required this.createdAt,
  });
}
