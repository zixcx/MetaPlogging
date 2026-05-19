import 'dart:io';

import 'package:meta_plogging/features/feed/domain/entities/post_entity.dart';

abstract class FeedRepository {
  Future<List<PostEntity>> getPosts({int limit = 20, int offset = 0});

  Future<PostEntity> createPost({
    required String caption,
    List<String>? images,
    String? trackingId,
  });

  Future<void> toggleLike(String postId, bool isCurrentlyLiked);

  Future<String> uploadImage(File file);
}
