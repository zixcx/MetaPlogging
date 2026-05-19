import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/features/profile/data/datasources/profile_datasource.dart';
import 'package:meta_plogging/features/profile/domain/entities/user_stats_entity.dart';
import 'package:meta_plogging/features/profile/domain/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(profileDatasourceProvider)),
);

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDatasource _datasource;

  ProfileRepositoryImpl(this._datasource);

  @override
  Future<UserStatsEntity> getUserStats() => _datasource.getUserStats();
}
