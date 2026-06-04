import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meta_plogging/features/plogging/data/datasources/session_photos_datasource.dart';
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
  final bool isRestoredSession;

  const TrackingState({
    this.session,
    this.path = const [],
    this.currentPosition,
    this.elapsedSeconds = 0,
    this.isLoading = false,
    this.error,
    this.isRestoredSession = false,
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
    bool? isRestoredSession,
  }) =>
      TrackingState(
        session: session ?? this.session,
        path: path ?? this.path,
        currentPosition: currentPosition ?? this.currentPosition,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isRestoredSession: isRestoredSession ?? this.isRestoredSession,
      );
}

// ── Notifier ───────────────────────────────────────────────────

class TrackingNotifier extends Notifier<TrackingState> {
  StreamSubscription<Position>? _locationSub;
  Timer? _timer;
  Timer? _pointTimer;
  bool _isOperating = false;

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
          elapsedSeconds: _elapsedFor(session),
          isLoading: false,
          isRestoredSession: true,
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
    if (state.isRunning) return;
    final granted = await _requestPermission();
    if (!granted) {
      state = state.copyWith(error: '위치 권한이 필요합니다.');
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final session = await _repo.startSession();
      debugPrint(
        '[Tracking] startSession id=${session.id} status=${session.status}',
      );
      if (session.status != TrackingStatus.active) {
        state = state.copyWith(
          isLoading: false,
          error: '세션이 정상적으로 시작되지 않았습니다 (status=${session.status.name})',
        );
        return;
      }
      state = state.copyWith(
        session: session,
        path: [],
        elapsedSeconds: 0,
        isLoading: false,
      );
      _startLocalTimerAndGps();
    } catch (e) {
      if (_is409(e)) {
        // 서버에 이미 활성 세션 → 복원 후 복구 다이얼로그 표시
        debugPrint('[Tracking] startSession 409: restoring existing session');
        state = state.copyWith(isLoading: true);
        try {
          final session = await _repo.getActiveSession();
          if (session != null) {
            state = state.copyWith(
              session: session,
              path: session.path,
              elapsedSeconds: _elapsedFor(session),
              isLoading: false,
              isRestoredSession: true,
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
        return;
      }
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> pauseSession() async {
    if (_isOperating) {
      debugPrint('[Tracking] pauseSession skipped: already operating');
      return;
    }
    if (!state.isActive) {
      debugPrint(
        '[Tracking] pauseSession skipped: status=${state.session?.status}',
      );
      return;
    }
    final id = state.session!.id;
    _isOperating = true;
    _stopLocalTimerAndGps();
    try {
      final session = await _repo.pauseSession(id);
      state = state.copyWith(session: session);
    } catch (e) {
      if (_is409(e)) {
        await _refreshSession();
      } else if (_is404(e)) {
        // 서버에 세션이 없음(이미 삭제됨) → 로컬 완전 초기화
        state = const TrackingState();
      } else {
        state = state.copyWith(error: _friendlyError(e));
        _startLocalTimerAndGps();
      }
    } finally {
      _isOperating = false;
    }
  }

  Future<void> resumeSession() async {
    if (_isOperating) {
      debugPrint('[Tracking] resumeSession skipped: already operating');
      return;
    }
    if (!state.isPaused) {
      debugPrint(
        '[Tracking] resumeSession skipped: status=${state.session?.status}',
      );
      return;
    }
    final id = state.session!.id;
    _isOperating = true;
    try {
      final session = await _repo.resumeSession(id);
      state = state.copyWith(session: session);
      _startLocalTimerAndGps();
    } catch (e) {
      if (_is409(e)) {
        await _refreshSession();
      } else if (_is404(e)) {
        // 서버에 세션이 없음(이미 삭제됨) → 로컬 완전 초기화
        _stopLocalTimerAndGps();
        state = const TrackingState();
      } else {
        state = state.copyWith(error: _friendlyError(e));
      }
    } finally {
      _isOperating = false;
    }
  }

  // 서버에서 현재 세션 상태를 가져와 로컬 상태 동기화
  Future<void> _refreshSession() async {
    final id = state.session?.id;
    if (id == null) return;
    try {
      final session = await _repo.getSession(id);
      debugPrint(
        '[Tracking] refreshSession id=${session.id} status=${session.status}',
      );
      state = state.copyWith(session: session);
      final isNowActive = session.status == TrackingStatus.active;
      if (isNowActive && _timer == null) {
        _startLocalTimerAndGps();
      } else if (!isNowActive) {
        _stopLocalTimerAndGps();
      }
    } catch (e) {
      debugPrint('[Tracking] refreshSession failed: $e');
    }
  }

  Future<TrackingSessionEntity?> endSession({
    List<TrashItem>? trashItems,
    String? locationDescription,
  }) async {
    if (_isOperating) {
      debugPrint('[Tracking] endSession skipped: already operating');
      return null;
    }
    final id = state.session?.id;
    if (id == null) {
      debugPrint('[Tracking] endSession skipped: no session');
      return null;
    }
    debugPrint(
      '[Tracking] endSession id=$id status=${state.session?.status}',
    );
    _isOperating = true;
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
    } on Exception catch (e) {
      if (_is404(e)) {
        // 세션이 서버에 없음(이미 삭제됨) → 로컬 초기화
        state = const TrackingState();
        return null;
      }
      // 409 포함 나머지 오류: 저장 실패 → 상태 유지하여 사용자가 재시도 가능
      state = state.copyWith(isLoading: false, error: '저장에 실패했습니다. 다시 시도해주세요.');
      return null;
    } finally {
      _isOperating = false;
    }
  }

  void _startLocalTimerAndGps() {
    _stopLocalTimerAndGps();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = state.session;
      if (session != null && state.isActive) {
        // 로컬 카운터가 아닌 startedAt 벽시계 기준으로 계산
        // (앱 재실행/백그라운드 시간도 포함 → 서버 duration과 일치)
        state = state.copyWith(elapsedSeconds: _elapsedFor(session));
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
      if (pos == null || id == null || !state.isActive) return;
      _repo.addPoint(id, pos.latitude, pos.longitude).catchError((Object e) {
        // 서버에 세션이 없음 → 타이머 중단 + 상태 초기화
        if (_is404(e)) {
          _stopLocalTimerAndGps();
          state = const TrackingState();
        }
      });
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

  // 세션의 경과 시간을 벽시계 기준으로 계산. 서버의 duration_seconds 산식과 동일.
  // - active: (현재 - 시작) - 누적 일시정지
  // - paused: (일시정지 시점 - 시작) - 누적 일시정지  → 멈춘 값으로 고정
  int _elapsedFor(TrackingSessionEntity session) {
    final until = session.status == TrackingStatus.paused
        ? (session.pausedAt ?? DateTime.now())
        : DateTime.now();
    final elapsed = until.toUtc().difference(session.startedAt.toUtc()).inSeconds -
        session.pauseDurationSeconds;
    return elapsed < 0 ? 0 : elapsed;
  }

  void _onPosition(Position pos) {
    final latLng = NLatLng(pos.latitude, pos.longitude);
    state = state.copyWith(
      currentPosition: latLng,
      path: [...state.path, latLng],
    );
  }

  Future<({bool success, String? postId, int photoCount})>
      discardSession() async {
    if (_isOperating) return (success: false, postId: null, photoCount: 0);
    final id = state.session?.id;
    if (id == null) return (success: false, postId: null, photoCount: 0);
    _isOperating = true;
    _stopLocalTimerAndGps();
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repo.discardSession(id);
      state = const TrackingState();
      return (
        success: true,
        postId: result.postId,
        photoCount: result.photoCount,
      );
    } catch (e) {
      // 404: 서버에 이미 없음 → 로컬도 초기화 (성공으로 간주, 사진 없음)
      if (_is404(e)) {
        state = const TrackingState();
        return (success: true, postId: null, photoCount: 0);
      }
      // 409 등 기타 오류: 에러 표시 후 실패 반환
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
      return (success: false, postId: null, photoCount: 0);
    } finally {
      _isOperating = false;
    }
  }

  // 진행 중 세션에 사진 업로드 후 로컬 photos에 즉시 반영(카운트 갱신).
  Future<bool> addPhoto(
    File file, {
    double? lat,
    double? lng,
    DateTime? takenAt,
  }) async {
    final session = state.session;
    if (session == null || !state.isRunning) return false;
    try {
      final photo = await ref.read(sessionPhotosDatasourceProvider).uploadPhoto(
            session.id,
            file,
            lat: lat,
            lng: lng,
            takenAt: takenAt,
          );
      state = state.copyWith(
        session: session.copyWith(photos: [...session.photos, photo]),
      );
      return true;
    } catch (e) {
      debugPrint('[Tracking] addPhoto failed: $e');
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);

  bool _is409(Object e) {
    final s = e.toString();
    return s.contains('409');
  }

  bool _is404(Object e) {
    final s = e.toString();
    return s.contains('404');
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    debugPrint('[Tracking] error: $s');
    final match = RegExp(r'status code of (\d+)').firstMatch(s);
    if (match != null) return '요청 실패 (${match.group(1)})';
    return '오류가 발생했습니다';
  }
}

final trackingProvider =
    NotifierProvider<TrackingNotifier, TrackingState>(TrackingNotifier.new);
