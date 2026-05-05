# HomePage (홈/대시보드 화면)

---

## 파일 위치

`lib/features/home/presentation/pages/home_page.dart`

---

## 화면 구성 및 데이터

### 앱바

| UI 요소 | 현재 값 | 대체 데이터 |
|---------|---------|-----------|
| 앱 로고 | 정적 이모지 아이콘 + `"MetaPlogging"` | 정적 유지 |
| 알림 아이콘 | `Icons.notifications_none_rounded` | 읽지 않은 알림 수 (badge) |

---

### 1. 인사 카드 (`_GreetingCard`)

| 필드 | 현재 값 | 타입 | 대체 데이터 |
|------|---------|------|-----------|
| 인사말 | `"안녕하세요! 🌿"` | `String` | 정적 유지 |
| 슬로건 | `"오늘도 지구를\n지켜볼까요?"` | `String` | 정적 유지 |
| 버튼 | `"플로깅 시작"` | `String` | 정적 유지 |

---

### 2. 나의 활동 통계 (`_StatsRow` → 3개 `_StatCard`)

> **전체 모의 데이터** — API 연결 필요

| 카드 | 필드명 | 현재 값 | 타입 | API 필드 |
|------|--------|---------|------|---------|
| 총 거리 | `value` | `"24.8"` | `String` | `total_distance_km: double` |
| 총 거리 | `unit` | `"km"` | `String` | 정적 |
| 수거량 | `value` | `"156"` | `String` | `total_trash_count: int` |
| 수거량 | `unit` | `"개"` | `String` | 정적 |
| 활동 횟수 | `value` | `"12"` | `String` | `activity_count: int` |
| 활동 횟수 | `unit` | `"회"` | `String` | 정적 |

**필요한 API:** `GET /users/{userId}/stats`

```json
// 응답
{
  "total_distance_km": 24.8,
  "total_trash_count": 156,
  "activity_count": 12,
  "total_duration_minutes": 522
}
```

---

### 3. 바로 시작하기 (`_QuickActionGrid` → 4개 `_QuickAction`)

| 항목 | 아이콘 | 레이블 | 현재 동작 | 구현 필요 |
|------|--------|--------|-----------|---------|
| 활동 지도 | `Icons.map_outlined` | `"활동 지도"` | `() {}` (미구현) | 지도 페이지 네비게이션 |
| 사진 기록 | `Icons.camera_alt_outlined` | `"사진 기록"` | `() {}` (미구현) | 카메라 또는 갤러리 |
| 챌린지 | `Icons.emoji_events_outlined` | `"챌린지"` | `() {}` (미구현) | 챌린지 페이지 |
| 커뮤니티 | `Icons.people_outline_rounded` | `"커뮤니티"` | `() {}` (미구현) | 피드 페이지 |

---

### 4. 이번 주 활동 (`_WeeklyChart`)

> **전체 모의 데이터** — API 연결 필요

| 필드 | 현재 값 | 타입 | API 필드 |
|------|---------|------|---------|
| 이번 주 총 거리 | `"이번 주 3.2 km"` | `String` | `weekly_distance_km: double` |
| 증감률 | `"+12%"` | `String` | `weekly_distance_change_pct: double` |
| 요일 데이터 | `[0.4, 0.7, 0.3, 1.0, 0.6, 0.85, 0.0]` | `List<double>` | `daily_values: List<double>` (7개, 0.0~1.0 정규화) |
| 요일 레이블 | `['월','화','수','목','금','토','일']` | `List<String>` | 정적 |
| 오늘 강조 | `i == 3` (하드코딩) | `int` | `today_index: int` (0=월 기준) |

**필요한 API:** `GET /users/{userId}/stats/weekly`

```json
// 응답
{
  "weekly_distance_km": 3.2,
  "weekly_distance_change_pct": 12.0,
  "daily_distances": [1.2, 2.1, 0.9, 3.2, 1.8, 2.5, 0.0],
  "today_index": 3
}
```

---

### 5. 최근 플로깅 (`_RecentActivity` → 3개 `_ActivityCard`)

> **전체 모의 데이터** — API 연결 필요

| 필드 | 현재 값 | 타입 | API 필드 |
|------|---------|------|---------|
| 제목 | `'한강 공원 플로깅'` 등 | `String` | `title: string` |
| 날짜/시간 | `'오늘 07:32'` 등 | `String` | `created_at: DateTime` → 포맷 변환 |
| 거리 | `'3.2 km'` 등 | `String` | `distance_km: double` |
| 수거량 | `'24개'` 등 | `String` | `trash_count: int` |
| 소요 시간 | `'42분'` 등 | `String` | `duration_minutes: int` |

**필요한 API:** `GET /activities?limit=3&sort=created_at:desc`

```json
// 응답
{
  "activities": [
    {
      "id": "act_001",
      "title": "한강 공원 플로깅",
      "created_at": "2026-05-05T07:32:00Z",
      "distance_km": 3.2,
      "trash_count": 24,
      "duration_minutes": 42,
      "location_name": "한강 반포지구"
    }
    // ...
  ]
}
```

---

## 사용자 액션

| 액션 | 컴포넌트 | 현재 동작 | 구현 필요 |
|------|---------|---------|---------|
| 탭 | 알림 아이콘 | `() {}` | 알림 목록 페이지 |
| 탭 | "플로깅 시작" 버튼 | `Navigator.pushNamed(AppRoutes.plogging)` | ✅ 동작 |
| 탭 | "전체 보기" | `context.go(AppRoutes.plogging)` | ✅ 동작 |
| 탭 | 활동 지도 | `() {}` | 지도 페이지 네비게이션 |
| 탭 | 사진 기록 | `() {}` | 카메라/갤러리 |
| 탭 | 챌린지 | `() {}` | 챌린지 페이지 |
| 탭 | 커뮤니티 | `() {}` | 피드 탭 이동 |

---

## 로컬 UI 상태

| 변수 | 타입 | 설명 |
|------|------|------|
| `isDark` | `bool` | 다크모드 여부 (ThemeOf 에서 읽음) |

이 페이지는 `ConsumerWidget`으로 추가 로컬 상태 없음.

---

## 전역 상태 의존성

| Provider | 현재 사용 | 필요한 추가 |
|---------|---------|---------|
| `authProvider` | ❌ 미사용 | 사용자명 표시용으로 필요 |
| `userStatsProvider` | ❌ 미구현 | 통계 카드 데이터 |
| `recentActivitiesProvider` | ❌ 미구현 | 최근 활동 리스트 |
| `weeklyStatsProvider` | ❌ 미구현 | 주간 차트 데이터 |

---

## 필요한 신규 Provider 목록

```dart
// 1. 사용자 통계
@riverpod
Future<UserStats> userStats(Ref ref) async { ... }

// 2. 최근 활동 목록
@riverpod
Future<List<Activity>> recentActivities(Ref ref) async { ... }

// 3. 주간 통계
@riverpod
Future<WeeklyStats> weeklyStats(Ref ref) async { ... }
```
