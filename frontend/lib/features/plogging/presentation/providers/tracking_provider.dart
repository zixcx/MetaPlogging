import 'dart:async';

import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meta_plogging/features/plogging/data/repositories/tracking_repository_impl.dart';
import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';
import 'package:meta_plogging/features/plogging/domain/repositories/tracking_repository.dart';

// ── State ──────────────────────────────────────────────────────

class TrackingState {
  final TrackingSessionEntity? session;
  final List<NLatLng> path;
  final NLatLng? currentPosition;
  final int elapsedSeconds;
  final bool isLoading;
  final String? error;

  const TrackingState({
    this.session,
    this.path = const [],
    this.currentPosition,
    this.elapsedSeconds = 0,
    this.isLoading = false,
    this.error,
  });

  bool get isActive => session?.status == TrackingStatus.active;
  bool get isPaused => session?.status == TrackingStatus.paused;
  bool get isRunning => isActive || isPaused;

  double get distanceKm => (session?.distanceMeters ?? 0) / 1000;

  int get photoCount => session?.photos.length ?? 0;

  String get formattedTime {
    final s = elapsedSeconds;
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  TrackingState copyWith({
    TrackingSessionEntity? session,
    List<NLatLng>? path,
    NLatLng? currentPosition,
    int? elapsedSeconds,
    bool? isLoading,
    String? error,
  }) =>
      TrackingState(
        session: session ?? this.session,
        path: path ?? this.path,
        currentPosition: currentPosition ?? this.currentPosition,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Notifier ───────────────────────────────────────────────────

class TrackingNotifier extends Notifier<TrackingState> {
  StreamSubscription<Position>? _locationSub;
  Timer? _timer;
  Timer? _pointTimer;

  TrackingRepository get _repo => ref.read(trackingRepositoryProvider);

  @override
  TrackingState build() {
    ref.onDispose(_stopLocalTimerAndGps);
    Future.microtask(_checkActiveSession);
    return const TrackingState();
  }

  Future<void> _checkActiveSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final session = await _repo.getActiveSession();
      if (session != null) {
        state = state.copyWith(
          session: session,
          path: session.path,
          elapsedSeconds: session.durationSeconds,
          isLoading: false,
        );
        if (session.status == TrackingStatus.active) {
          _startLocalTimerAndGps();
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> _requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> startSession() async {
    final granted = await _requestPermission();
    if (!granted) {
      state = state.copyWith(error: '위치 권한이 필요합니다.');
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final session = await _repo.startSession();
      state = state.copyWith(
        session: session,
        path: [],
        elapsedSeconds: 0,
        isLoading: false,
      );
      _startLocalTimerAndGps();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> pauseSession() async {
    final id = state.session?.id;
    if (id == null) return;
    _stopLocalTimerAndGps();
    try {
      final session = await _repo.pauseSession(id);
      state = state.copyWith(session: session);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      _startLocalTimerAndGps();
    }
  }

  Future<void> resumeSession() async {
    final id = state.session?.id;
    if (id == null) return;
    try {
      final session = await _repo.resumeSession(id);
      state = state.copyWith(session: session);
      _startLocalTimerAndGps();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<TrackingSessionEntity?> endSession({
    List<TrashItem>? trashItems,
    String? locationDescription,
  }) async {
    final id = state.session?.id;
    if (id == null) return null;
    _stopLocalTimerAndGps();
    state = state.copyWith(isLoading: true);
    try {
      final session = await _repo.endSession(
        id,
        trashItems: trashItems,
        locationDescription: locationDescription,
      );
      state = const TrackingState();
      return session;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void _startLocalTimerAndGps() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isActive) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });

    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);

    _pointTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final pos = state.currentPosition;
      final id = state.session?.id;
      if (pos != null && id != null && state.isActive) {
        _repo.addPoint(id, pos.latitude, pos.longitude).catchError((_) {});
      }
    });
  }

  void _stopLocalTimerAndGps() {
    _timer?.cancel();
    _timer = null;
    _locationSub?.cancel();
    _locationSub = null;
    _pointTimer?.cancel();
    _pointTimer = null;
  }

  void _onPosition(Position pos) {
    final latLng = NLatLng(pos.latitude, pos.longitude);
    state = state.copyWith(
      currentPosition: latLng,
      path: [...state.path, latLng],
    );
  }

  Future<bool> discardSession() async {
    final id = state.session?.id;
    if (id == null) return false;
    _stopLocalTimerAndGps();
    state = state.copyWith(isLoading: true);
    try {
      await _repo.deleteSession(id);
      state = const TrackingState();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final trackingProvider =
    NotifierProvider<TrackingNotifier, TrackingState>(TrackingNotifier.new);
