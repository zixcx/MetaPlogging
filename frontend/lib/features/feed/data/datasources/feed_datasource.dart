import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/core/network/api_endpoints.dart';
import 'package:meta_plogging/core/network/dio_client.dart';
import 'package:meta_plogging/features/feed/data/models/post_model.dart';
import 'package:meta_plogging/features/feed/domain/entities/post_entity.dart';

final feedDatasourceProvider = Provider<FeedDatasource>(
  (ref) => FeedDatasource(ref.watch(dioClientProvider)),
);

class FeedDatasource {
  final Dio _dio;

  FeedDatasource(this._dio);

  Future<List<PostEntity>> getPosts({int limit = 20, int offset = 0}) async {
    final res = await _dio.get(
      ApiEndpoints.posts,
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final items = (res.data['items'] as List<dynamic>? ?? []);
    return items
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PostEntity> createPost({
    required String caption,
    List<String>? images,
    String? trackingId,
  }) async {
    final body = <String, dynamic>{
      'caption': caption,
      if (images != null && images.isNotEmpty) 'images': images,
      'tracking_id': trackingId,
    };
    final res = await _dio.post(ApiEndpoints.posts, data: body);
    return PostModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> likePost(String id) async {
    await _dio.post(ApiEndpoints.postLike(id));
  }

  Future<void> unlikePost(String id) async {
    await _dio.delete(ApiEndpoints.postLike(id));
  }

  Future<String> uploadImage(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });
    final res = await _dio.post(ApiEndpoints.imageUpload, data: formData);
    final data = res.data as Map<String, dynamic>;
    final url = data['url'] as String?;
    if (url == null) throw Exception('이미지 업로드 응답에 url 필드 없음: $data');
    return url;
  }
}
