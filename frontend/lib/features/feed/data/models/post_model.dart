import 'package:meta_plogging/core/network/api_endpoints.dart';
import 'package:meta_plogging/features/feed/domain/entities/post_entity.dart';

class PostModel {
  static PostEntity fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>? ?? {};

    // images: ["url1", "url2"] — URL 문자열 배열
    final rawImages = json['images'] as List<dynamic>? ?? [];
    final root = _serverRoot;
    final imageUrls = rawImages.map((url) {
      final s = url.toString();
      return s.startsWith('http') ? s : '$root$s';
    }).toList();

    // tags: ["tag1", "tag2"] — 문자열 배열
    final rawTags = json['tags'] as List<dynamic>? ?? [];
    final tags = rawTags.map((t) => t.toString()).toList();

    // tracking_session 객체가 응답에 포함된 경우 파싱
    final ts = json['tracking_session'] as Map<String, dynamic>?;
    final activityStats = ts != null
        ? PostActivityStats(
            distanceKm:
                ((ts['distance_meters'] as num?)?.toDouble() ?? 0) / 1000,
            trashCount: (ts['photo_count'] as num?)?.toInt() ?? 0,
            durationMinutes:
                ((ts['duration_seconds'] as num?)?.toInt() ?? 0) ~/ 60,
          )
        : null;

    return PostEntity(
      id: json['id'] as String,
      authorName: author['name'] as String? ?? '플로깅 러너',
      authorEmoji: '🌿',
      imageUrls: imageUrls,
      trackingSessionId: json['tracking_id'] as String?,
      caption: json['caption'] as String?,
      activityStats: activityStats,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      shareCount: (json['share_count'] as num?)?.toInt() ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      tags: tags,
    );
  }

  static String get _serverRoot {
    final base = ApiEndpoints.baseUrl;
    return base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
  }
}
