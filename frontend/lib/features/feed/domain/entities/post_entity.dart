import 'package:flutter/material.dart';

class PostActivityStats {
  final double distanceKm;
  final int trashCount;
  final int durationMinutes;

  const PostActivityStats({
    required this.distanceKm,
    required this.trashCount,
    required this.durationMinutes,
  });
}

class PostEntity {
  final String id;
  final String authorName;
  final String authorEmoji;
  final List<String> imageMocks;
  final String? caption;
  final PostActivityStats? activityStats;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLiked;
  final bool isBookmarked;
  final DateTime createdAt;
  final String? locationName;
  final List<String> tags;

  const PostEntity({
    required this.id,
    required this.authorName,
    required this.authorEmoji,
    this.imageMocks = const [],
    this.caption,
    this.activityStats,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    required this.createdAt,
    this.locationName,
    this.tags = const [],
  });

  PostEntity copyWith({
    bool? isLiked,
    bool? isBookmarked,
    int? likeCount,
    int? commentCount,
  }) =>
      PostEntity(
        id: id,
        authorName: authorName,
        authorEmoji: authorEmoji,
        imageMocks: imageMocks,
        caption: caption,
        activityStats: activityStats,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        shareCount: shareCount,
        isLiked: isLiked ?? this.isLiked,
        isBookmarked: isBookmarked ?? this.isBookmarked,
        createdAt: createdAt,
        locationName: locationName,
        tags: tags,
      );
}

// ── Mock image catalogue ──────────────────────────────────────
class MockImageStyle {
  final List<Color> colors;
  final IconData icon;
  final String label;

  const MockImageStyle({
    required this.colors,
    required this.icon,
    required this.label,
  });
}

const kMockImageStyles = <String, MockImageStyle>{
  'mock:river': MockImageStyle(
    colors: [Color(0xFF74B9FF), Color(0xFF0984E3)],
    icon: Icons.water_rounded,
    label: '한강',
  ),
  'mock:park': MockImageStyle(
    colors: [Color(0xFF55EFC4), Color(0xFF00B894)],
    icon: Icons.park_rounded,
    label: '공원',
  ),
  'mock:forest': MockImageStyle(
    colors: [Color(0xFF52B788), Color(0xFF1B4332)],
    icon: Icons.forest_rounded,
    label: '숲길',
  ),
  'mock:sunset': MockImageStyle(
    colors: [Color(0xFFFF7675), Color(0xFFE17055)],
    icon: Icons.wb_twilight_rounded,
    label: '저녁',
  ),
  'mock:mountain': MockImageStyle(
    colors: [Color(0xFF6C5CE7), Color(0xFF2D6A4F)],
    icon: Icons.landscape_rounded,
    label: '산길',
  ),
  'mock:urban': MockImageStyle(
    colors: [Color(0xFF636E72), Color(0xFF2D3436)],
    icon: Icons.location_city_rounded,
    label: '도심',
  ),
};

// ── Mock feed data ────────────────────────────────────────────
final kMockPosts = <PostEntity>[
  PostEntity(
    id: '1',
    authorName: '초록달리기',
    authorEmoji: '🌿',
    imageMocks: ['mock:river', 'mock:park'],
    caption: '오늘 한강 공원에서 플로깅 완료! 날씨도 맑고 공기도 상쾌했어요. 쓰레기 봉투 두 개 가득 채웠습니다 💪 혼자지만 전혀 외롭지 않았어요.',
    tags: ['한강공원', '플로깅', '환경보호'],
    activityStats: PostActivityStats(
        distanceKm: 3.2, trashCount: 24, durationMinutes: 42),
    likeCount: 48,
    commentCount: 12,
    shareCount: 5,
    isLiked: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    locationName: '한강 반포지구',
  ),
  PostEntity(
    id: '2',
    authorName: '에코조거',
    authorEmoji: '🏃',
    imageMocks: ['mock:forest'],
    caption: '서울숲 아침 플로깅. 이른 아침의 숲길은 정말 달라요. 맑은 공기, 새소리, 그리고 깨끗해진 길까지.',
    tags: ['서울숲', '아침달리기'],
    activityStats: PostActivityStats(
        distanceKm: 4.8, trashCount: 36, durationMinutes: 58),
    likeCount: 72,
    commentCount: 8,
    shareCount: 11,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    locationName: '서울숲',
  ),
  PostEntity(
    id: '3',
    authorName: '숲속러너',
    authorEmoji: '🌲',
    imageMocks: ['mock:park', 'mock:sunset', 'mock:river'],
    caption: '올림픽공원 주말 플로깅 기록 📸',
    tags: ['올림픽공원', '주말플로깅'],
    likeCount: 31,
    commentCount: 4,
    shareCount: 2,
    createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    locationName: '올림픽공원',
  ),
  PostEntity(
    id: '4',
    authorName: '강변워커',
    authorEmoji: '🚶',
    imageMocks: ['mock:sunset'],
    caption: '여의도 저녁 플로깅. 노을이 너무 예뻐서 잠깐 멈췄어요. 이런 순간이 계속 달리게 만드는 이유인 것 같아요.',
    activityStats: PostActivityStats(
        distanceKm: 2.1, trashCount: 18, durationMinutes: 28),
    likeCount: 94,
    commentCount: 17,
    shareCount: 8,
    isLiked: true,
    isBookmarked: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    locationName: '여의도 한강공원',
  ),
  PostEntity(
    id: '5',
    authorName: '플로러',
    authorEmoji: '⛰️',
    imageMocks: ['mock:mountain', 'mock:forest'],
    caption: '북한산 등산로 플로깅 도전! 경사진 길에서 쓰레기 줍는 게 쉽지 않았지만 정상에서 보는 경치는 언제나 최고. 다음 주에 또 올 것 같아요.',
    tags: ['북한산', '등산플로깅', '챌린지'],
    activityStats: PostActivityStats(
        distanceKm: 6.4, trashCount: 52, durationMinutes: 95),
    likeCount: 156,
    commentCount: 29,
    shareCount: 22,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    locationName: '북한산 등산로',
  ),
];
