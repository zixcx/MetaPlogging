import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/features/feed/data/datasources/feed_datasource.dart';
import 'package:meta_plogging/features/feed/domain/entities/post_entity.dart';
import 'package:meta_plogging/features/feed/domain/repositories/feed_repository.dart';

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FeedRepositoryImpl(ref.watch(feedDatasourceProvider)),
);

class FeedRepositoryImpl implements FeedRepository {
  final FeedDatasource _datasource;

  FeedRepositoryImpl(this._datasource);

  @override
  Future<List<PostEntity>> getPosts({int limit = 20, int offset = 0}) =>
      _datasource.getPosts(limit: limit, offset: offset);

  @override
  Future<PostEntity> createPost({
    required String caption,
    List<String>? images,
    String? trackingId,
  }) =>
      _datasource.createPost(
        caption: caption,
        images: images,
        trackingId: trackingId,
      );

  @override
  Future<void> toggleLike(String postId, bool isCurrentlyLiked) async {
    if (isCurrentlyLiked) {
      await _datasource.unlikePost(postId);
    } else {
      await _datasource.likePost(postId);
    }
  }

  @override
  Future<String> uploadImage(File file) => _datasource.uploadImage(file);
}
