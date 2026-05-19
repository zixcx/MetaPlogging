import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/core/network/api_endpoints.dart';
import 'package:meta_plogging/core/network/dio_client.dart';
import 'package:meta_plogging/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:meta_plogging/features/profile/domain/entities/user_stats_entity.dart';
import 'package:meta_plogging/features/plogging/data/repositories/tracking_repository_impl.dart';
import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';

final userStatsProvider = FutureProvider<UserStatsEntity>((ref) {
  return ref.watch(profileRepositoryProvider).getUserStats();
});

final recentSessionsProvider =
    FutureProvider<List<TrackingSessionEntity>>((ref) {
  return ref.watch(trackingRepositoryProvider).getSessions();
});

final platformSummaryProvider = FutureProvider<int>((ref) async {
  final dio = ref.watch(dioClientProvider);
  final res = await dio.get(ApiEndpoints.platformSummary);
  final data = res.data as Map<String, dynamic>;
  return (data['today_plogging_users'] as num?)?.toInt() ?? 0;
});
