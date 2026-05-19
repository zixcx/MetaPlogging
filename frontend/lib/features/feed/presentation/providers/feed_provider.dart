import 'dart:io';

import 'package:meta_plogging/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:meta_plogging/features/feed/domain/entities/post_entity.dart';
import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_provider.g.dart';

@riverpod
class FeedNotifier extends _$FeedNotifier {
  @override
  Future<List<PostEntity>> build() async {
    return ref.read(feedRepositoryProvider).getPosts();
  }

  // ── Like 토글 (낙관적 업데이트) ────────────────────────────
  void toggleLike(String postId, bool isCurrentlyLiked) {
    final posts = state.asData?.value;
    if (posts == null) return;

    state = AsyncData(_mapPost(posts, postId, (p) => p.copyWith(
      isLiked: !isCurrentlyLiked,
      likeCount: isCurrentlyLiked ? p.likeCount - 1 : p.likeCount + 1,
    )));

    _commitLike(postId, isCurrentlyLiked, posts);
  }

  Future<void> _commitLike(
    String postId,
    bool wasLiked,
    List<PostEntity> prev,
  ) async {
    try {
      await ref.read(feedRepositoryProvider).toggleLike(postId, wasLiked);
    } catch (_) {
      state = AsyncData(prev);
    }
  }

  // ── 북마크 토글 (로컬) ─────────────────────────────────────
  void toggleBookmark(String postId) {
    final posts = state.asData?.value;
    if (posts == null) return;
    state = AsyncData(_mapPost(
      posts,
      postId,
      (p) => p.copyWith(isBookmarked: !p.isBookmarked),
    ));
  }

  // ── 게시글 맨 앞에 추가 ────────────────────────────────────
  void prepend(PostEntity post) {
    final posts = state.asData?.value ?? [];
    state = AsyncData([post, ...posts]);
  }

  // ── 게시글 생성 (이미지 업로드 → POST /posts) ──────────────
  Future<PostEntity> createPost({
    required String caption,
    List<File> imageFiles = const [],
    TrackingSessionEntity? session,
  }) async {
    final repo = ref.read(feedRepositoryProvider);

    final imageUrls = await Future.wait(
      imageFiles.map((f) => repo.uploadImage(f)),
    );

    final post = await repo.createPost(
      caption: caption,
      images: imageUrls.isEmpty ? null : imageUrls,
      trackingId: session?.id,
    );

    // 생성한 게시글에 세션 통계 보강 (응답에 없으므로 로컬에서 채움)
    final enriched = session == null
        ? post
        : PostEntity(
            id: post.id,
            authorName: post.authorName,
            authorEmoji: post.authorEmoji,
            imageUrls: post.imageUrls,
            trackingSessionId: post.trackingSessionId,
            caption: post.caption,
            activityStats: PostActivityStats(
              distanceKm: session.distanceKm,
              trashCount: session.totalTrashCount,
              durationMinutes: session.durationSeconds ~/ 60,
            ),
            likeCount: post.likeCount,
            commentCount: post.commentCount,
            shareCount: post.shareCount,
            isLiked: post.isLiked,
            createdAt: post.createdAt,
            locationName: session.locationLandmarkName ??
                session.locationDescription,
            tags: post.tags,
          );

    prepend(enriched);
    return enriched;
  }

  // ── 새로고침 ───────────────────────────────────────────────
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(feedRepositoryProvider).getPosts(),
    );
  }

  // ── 헬퍼 ──────────────────────────────────────────────────
  static List<PostEntity> _mapPost(
    List<PostEntity> posts,
    String id,
    PostEntity Function(PostEntity) fn,
  ) =>
      [for (final p in posts) if (p.id == id) fn(p) else p];
}
