class UserStatsEntity {
  final int totalDistanceMeters;
  final int totalDurationSeconds;
  final int totalSessions;
  final int totalTrashCount;

  const UserStatsEntity({
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.totalSessions,
    required this.totalTrashCount,
  });

  double get totalDistanceKm => totalDistanceMeters / 1000;

  // 1km 걷기 ≈ 0.13kg CO₂ 절감 (대략적 수치)
  double get co2SavedKg => totalDistanceKm * 0.13;

  String get formattedDuration {
    final hours = totalDurationSeconds ~/ 3600;
    final minutes = (totalDurationSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
