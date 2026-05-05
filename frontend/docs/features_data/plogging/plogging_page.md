# PloggingPage (플로깅 기록 화면)

---

## 파일 위치

`lib/features/plogging/presentation/pages/plogging_page.dart`

---

## 화면 구성

### 앱바

| UI 요소 | 현재 값 |
|---------|---------|
| 제목 | `"플로깅 기록"` |
| 동작 | `pinned: true` (고정) |
| 배경 | `colorScheme.surface` |

---

### 1. 지도 플레이스홀더 (`_MapPlaceholder`)

> 실제 지도 미구현 — 가상 그리드 배경 컨테이너

| UI 요소 | 현재 값 | 연결 후 |
|---------|---------|---------|
| 높이 | `240px` | 지도 높이 동일 유지 |
| 배경 | `LinearGradient` (밝은 그린 계열, 다크 지원) | `google_maps_flutter` 또는 `flutter_naver_map` |
| 그리드 패턴 | `_GridPainter` (32px 간격, 반투명) | 제거 |
| 중앙 핀 | `Icons.my_location_rounded` + `"내 위치"` | GPS 현재 좌표로 이동 |
| 우상단 레이블 | `"지도"` 정적 텍스트 | 지도 타입 전환 버튼 |

---

### 2. 실시간 통계 (`_LiveStats`) — `_isRunning == true` 일 때만 표시

| 통계 항목 | 현재 값 | 타입 | 연결 후 |
|----------|---------|------|---------|
| 시간 | `_timeFormatted` (`MM:SS`) | `String` | 실시간 `Timer` 기반 |
| 거리 | `"0.0 km"` (하드코딩) | `String` | GPS 위치 스트림 계산 |
| 수거 | `"0개"` (하드코딩) | `String` | 사진 촬영 시 +1 |

---

### 3. 시작/종료 버튼 (`_PloggingCta`)

| 상태 | 버튼 | 동작 |
|------|------|------|
| `_isRunning == false` | "플로깅 시작하기" (`FilledButton.icon`) | `_togglePlogging()` → `_isRunning = true` |
| `_isRunning == true` | "플로깅 종료" (`OutlinedButton.icon`) | `_togglePlogging()` → `_isRunning = false` |
| `_isRunning == true` | "쓰레기 사진 촬영" (`OutlinedButton.icon`) | `() {}` (미구현) |

---

### 4. 플로깅 팁 (`_TipCards`)

> 정적 데이터 — API 연결 불필요

| 팁 | 아이콘 | 색상 |
|----|--------|------|
| 장갑과 봉투 지참 | `backpack_outlined` | `AppColors.primary` |
| 적절한 시간대 선택 | `wb_sunny_outlined` | `AppColors.accent` |
| 활동 기록 남기기 | `camera_alt_outlined` | `AppColors.secondary` |

---

## 로컬 UI 상태

| 변수 | 타입 | 초기값 | 설명 |
|------|------|--------|------|
| `_isRunning` | `bool` | `false` | 플로깅 진행 중 여부 |
| `_elapsedSeconds` | `int` (final) | `0` | 경과 시간 (초) — **현재 증가하지 않음** |

> ⚠️ `_elapsedSeconds`는 `final`로 선언되어 실제로 타이머가 동작하지 않음. 타이머 연동 구현 필요.

### `_timeFormatted` getter

```dart
MM:SS 형식 (padLeft 2, '0')
```

---

## 전역 상태 의존성

| Provider | 사용 여부 | 설명 |
|---------|---------|------|
| 없음 | ❌ | 현재 순수 로컬 상태만 사용 |

---

## 사용자 액션

| 액션 | 컴포넌트 | 결과 |
|------|---------|------|
| 탭 | "플로깅 시작하기" | `_isRunning = true`, `_LiveStats` 표시 |
| 탭 | "플로깅 종료" | `_isRunning = false`, `_LiveStats` 숨김 |
| 탭 | "쓰레기 사진 촬영" | `() {}` 미구현 |

---

## API 연결 시 전체 구현 계획

### 필요한 권한

| 권한 | 플랫폼 | 설명 |
|------|--------|------|
| `location` (항상) | iOS/Android | GPS 실시간 위치 추적 |
| `camera` | iOS/Android | 쓰레기 사진 촬영 |

### 필요한 패키지

| 패키지 | 용도 |
|--------|------|
| `geolocator` | GPS 위치 스트림 |
| `google_maps_flutter` 또는 `flutter_naver_map` | 지도 렌더링 |
| `image_picker` | 카메라/갤러리 |
| `dio` | API 호출 |

### 필요한 로컬 상태 추가 (미래)

| 변수 | 타입 | 설명 |
|------|------|------|
| `_timer` | `Timer?` | 경과 시간 증가용 |
| `_positions` | `List<LatLng>` | GPS 경로 포인트 |
| `_trashPhotos` | `List<File>` | 수거한 쓰레기 사진 |
| `_currentPosition` | `LatLng?` | 현재 위치 |
| `_distanceMeters` | `double` | 계산된 이동 거리 |

### 필요한 API

| API | 메서드 | 설명 |
|-----|--------|------|
| `POST /activities` | POST | 플로깅 활동 저장 |
| `POST /activities/{id}/trash` | POST | 수거 사진 업로드 |
| `GET /activities` | GET | 활동 기록 목록 |

#### POST /activities 요청 스키마

```json
{
  "started_at": "2026-05-05T07:30:00Z",
  "ended_at": "2026-05-05T08:12:00Z",
  "distance_km": 3.2,
  "duration_minutes": 42,
  "trash_count": 24,
  "location_name": "한강 반포지구",
  "route_points": [
    {"lat": 37.5, "lng": 126.9},
    {"lat": 37.51, "lng": 126.91}
  ]
}
```

#### POST /activities 응답

```json
{
  "id": "act_001",
  "title": "한강 공원 플로깅",
  "distance_km": 3.2,
  "trash_count": 24,
  "duration_minutes": 42,
  "created_at": "2026-05-05T07:30:00Z"
}
```

---

## 네비게이션 흐름

```
HomePage "플로깅 시작" 버튼
  └── Navigator.pushNamed(AppRoutes.plogging)

HomePage "전체 보기"
  └── context.go(AppRoutes.plogging)
```
