import 'package:flutter_naver_map/flutter_naver_map.dart';

enum TrackingStatus { active, paused, completed, expired }

enum TrashCategory {
  cigarette,
  bottleCan,
  plasticBag,
  largeWaste,
  other;

  String get label {
    switch (this) {
      case cigarette:
        return '담배꽁초';
      case bottleCan:
        return '페트병/캔';
      case plasticBag:
        return '비닐/포장지';
      case largeWaste:
        return '대형 쓰레기';
      case other:
        return '기타';
    }
  }

  String get apiValue {
    switch (this) {
      case cigarette:
        return 'cigarette';
      case bottleCan:
        return 'bottle_can';
      case plasticBag:
        return 'plastic_bag';
      case largeWaste:
        return 'large_waste';
      case other:
        return 'other';
    }
  }

  static TrashCategory fromApi(String value) {
    switch (value) {
      case 'cigarette':
        return cigarette;
      case 'bottle_can':
        return bottleCan;
      case 'plastic_bag':
        return plasticBag;
      case 'large_waste':
        return largeWaste;
      default:
        return other;
    }
  }
}

enum TrashAmountLevel {
  little,
  moderate,
  aLot;

  String get label {
    switch (this) {
      case little:
        return '조금';
      case moderate:
        return '보통';
      case aLot:
        return '많이';
    }
  }

  int get representativeCount {
    switch (this) {
      case little:
        return 5;
      case moderate:
        return 20;
      case aLot:
        return 40;
    }
  }

  String get apiValue {
    switch (this) {
      case little:
        return 'little';
      case moderate:
        return 'moderate';
      case aLot:
        return 'a_lot';
    }
  }

  static TrashAmountLevel fromApi(String value) {
    switch (value) {
      case 'little':
        return little;
      case 'moderate':
        return moderate;
      default:
        return aLot;
    }
  }
}

class TrashItem {
  final TrashCategory category;
  final TrashAmountLevel? level;
  final int? count;

  const TrashItem({
    required this.category,
    this.level,
    this.count,
  }) : assert(level != null || count != null,
            'level 또는 count 중 하나는 필수');

  int get estimatedCount => count ?? level?.representativeCount ?? 0;

  Map<String, dynamic> toJson() => {
        'category': category.apiValue,
        if (level != null) 'level': level!.apiValue,
        if (count != null) 'count': count,
      };

  factory TrashItem.fromJson(Map<String, dynamic> json) => TrashItem(
        category: TrashCategory.fromApi(json['category'] as String),
        level: json['level'] != null
            ? TrashAmountLevel.fromApi(json['level'] as String)
            : null,
        count: json['count'] as int?,
      );
}

class TrackingSessionEntity {
  final String id;
  final TrackingStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final int distanceMeters;
  final List<NLatLng> path;
  final String? locationLandmarkId;
  final String? locationLandmarkName;
  final String? locationDescription;
  final List<TrashItem> trashItems;
  final int pauseDurationSeconds;

  const TrackingSessionEntity({
    required this.id,
    required this.status,
    required this.startedAt,
    this.endedAt,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.path,
    this.locationLandmarkId,
    this.locationLandmarkName,
    this.locationDescription,
    required this.trashItems,
    this.pauseDurationSeconds = 0,
  });

  double get distanceKm => distanceMeters / 1000;

  int get totalTrashCount =>
      trashItems.fold(0, (sum, item) => sum + item.estimatedCount);

  String get formattedDuration {
    final m = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
