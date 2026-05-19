import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/core/network/api_endpoints.dart';
import 'package:meta_plogging/core/network/dio_client.dart';
import 'package:meta_plogging/features/profile/data/models/user_stats_model.dart';
import 'package:meta_plogging/features/profile/domain/entities/user_stats_entity.dart';

final profileDatasourceProvider = Provider<ProfileDatasource>(
  (ref) => ProfileDatasource(ref.watch(dioClientProvider)),
);

class ProfileDatasource {
  final Dio _dio;

  ProfileDatasource(this._dio);

  Future<UserStatsEntity> getUserStats() async {
    final res = await _dio.get(ApiEndpoints.userStats);
    return UserStatsModel.fromJson(res.data as Map<String, dynamic>);
  }
}
