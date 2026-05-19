import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta_plogging/features/plogging/data/repositories/tracking_repository_impl.dart';
import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';

final completedSessionsProvider =
    AsyncNotifierProvider<CompletedSessionsNotifier, List<TrackingSessionEntity>>(
  CompletedSessionsNotifier.new,
);

class CompletedSessionsNotifier
    extends AsyncNotifier<List<TrackingSessionEntity>> {
  @override
  Future<List<TrackingSessionEntity>> build() =>
      ref.read(trackingRepositoryProvider).getSessions();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(trackingRepositoryProvider).getSessions(),
    );
  }
}
