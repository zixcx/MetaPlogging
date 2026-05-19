import 'package:meta_plogging/features/profile/domain/entities/user_stats_entity.dart';

abstract interface class ProfileRepository {
  Future<UserStatsEntity> getUserStats();
}
