# ProfilePage (프로필 화면)

---

## 파일 위치

`lib/features/profile/presentation/pages/profile_page.dart`

---

## 화면 구성

### 앱바

| UI 요소 | 현재 값 |
|---------|---------|
| 제목 | `"프로필"` |
| 동작 | `pinned: true` (고정) |
| 배경 | `AppColors.primaryDark` |
| 글자 색 | `Colors.white` |
| 우측 버튼 | `Icons.settings_outlined` (`() {}` 미구현) |

---

### 1. 프로필 헤더 (`_ProfileHeader`)

> 전체 하드코딩 — API 연결 필요

| 필드 | 현재 값 | 타입 | API 필드 |
|------|---------|------|---------|
| 아바타 이모지 | `'🌿'` | `String` | `profile_image_url: String?` |
| 사용자명 | `'플로깅 러너'` | `String` | `name: String` |
| 이메일 | `'runner@example.com'` | `String` | `email: String` |
| 활동 횟수 | `'12'` | `String` | `activity_count: int` |
| 팔로워 수 | `'28'` | `String` | `follower_count: int` |
| 팔로잉 수 | `'15'` | `String` | `following_count: int` |

#### 레이아웃 특징

- 배경: `LinearGradient(primaryDark → primary)` (stops: 0.0 → 1.0)
- 하단 패딩: `56px` (흰색 영역과 오버랩 효과)
- 카메라 편집 버튼: 아바타 우하단 26×26 원형 (`AppColors.accent`), 현재 미구현

---

### 2. 레벨 카드 (`_LevelCard`)

> 전체 하드코딩 — API 연결 필요

| 필드 | 현재 값 | 타입 | API 필드 |
|------|---------|------|---------|
| 레벨 | `3` | `int` | `level: int` |
| 레벨명 | `'에코 러너'` | `String` | `level_name: String` |
| 현재 XP | `420` | `int` | `current_xp: int` |
| 다음 레벨 XP | `600` | `int` | `next_level_xp: int` |
| 진행률 | `420 / 600 = 0.7` | `double` | 계산: `current_xp / next_level_xp` |
| 안내 문구 | `'다음 레벨까지 180 XP 남았어요!'` | `String` | 계산: `next_level_xp - current_xp` |

**필요한 API:** `GET /users/{userId}/level`

```json
{
  "level": 3,
  "level_name": "에코 러너",
  "current_xp": 420,
  "next_level_xp": 600
}
```

---

### 3. 활동 통계 그리드 (`_StatsGrid`)

> 전체 하드코딩 — API 연결 필요 (4개 `_GridStatCard`)

| 카드 | 현재 값 | 아이콘 | 색상 | API 필드 |
|------|---------|--------|------|---------|
| 총 거리 | `'24.8 km'` | `route_rounded` | `AppColors.primary` | `total_distance_km: double` |
| 수거한 쓰레기 | `'156개'` | `delete_outline_rounded` | `AppColors.secondary` | `total_trash_count: int` |
| 활동 시간 | `'8h 42m'` | `timer_outlined` | `AppColors.accent` | `total_duration_minutes: int` |
| 절약한 CO₂ | `'3.2 kg'` | `eco_rounded` | `AppColors.gold` | `co2_saved_kg: double` |

**필요한 API:** `GET /users/{userId}/stats` (home_page의 동일 API 재사용 가능)

---

### 4. 배지 행 (`_BadgeRow`)

> 전체 하드코딩 — API 연결 필요

| 배지 | 아이콘 | 색상 |
|------|--------|------|
| 첫 플로깅 | `eco_rounded` | `AppColors.primary` |
| 5연속 | `local_fire_department_rounded` | `AppColors.accent` |
| 거리왕 | `emoji_events_rounded` | `AppColors.gold` |
| 기록왕 | `camera_alt_rounded` | `AppColors.secondary` |

**필요한 API:** `GET /users/{userId}/badges`

```json
{
  "badges": [
    {
      "id": "first_plogging",
      "name": "첫 플로깅",
      "icon": "eco",
      "color": "primary",
      "earned_at": "2026-04-01T00:00:00Z"
    }
  ]
}
```

---

### 5. 설정 목록 (`_SettingsList`)

| 항목 | 아이콘 | 현재 동작 | 구현 필요 |
|------|--------|-----------|---------|
| 프로필 편집 | `person_outline_rounded` | `() {}` | 프로필 편집 페이지/시트 |
| 알림 설정 | `notifications_none_rounded` | `() {}` | 알림 설정 페이지 |
| 개인정보처리방침 | `privacy_tip_outlined` | `() {}` | WebView 또는 외부 URL |
| 로그아웃 | `logout_rounded` | `authProvider.notifier.logout()` | ✅ 구현됨 |

#### 로그아웃 동작

```dart
ref.read(authProvider.notifier).logout()
// → AuthNotifier.logout() 호출
// → 토큰 삭제 + state = null
// → AppRouter redirect → /landing
```

---

## 로컬 UI 상태

| 변수 | 타입 | 출처 |
|------|------|------|
| `isDark` | `bool` | `Theme.of(context).brightness` |

이 페이지는 `ConsumerWidget`으로 추가 로컬 상태 없음.

---

## 전역 상태 의존성

| Provider | 읽기 방식 | 사용 목적 |
|---------|---------|---------|
| `authProvider` | ❌ 미사용 (import만) | 사용자 정보 표시에 필요 |
| `authProvider.notifier` | `ref.read()` | 로그아웃 |

---

## 사용자 액션

| 액션 | 컴포넌트 | 현재 동작 |
|------|---------|---------|
| 탭 | 설정 아이콘 (앱바) | `() {}` 미구현 |
| 탭 | 카메라 편집 버튼 | `() {}` 미구현 |
| 탭 | 프로필 편집 | `() {}` 미구현 |
| 탭 | 알림 설정 | `() {}` 미구현 |
| 탭 | 개인정보처리방침 | `() {}` 미구현 |
| 탭 | 로그아웃 | `authProvider.notifier.logout()` ✅ |

---

## API 연결 시 전체 변경 사항

### 필요한 신규 Provider

```dart
// 사용자 프로필
@riverpod
Future<UserProfile> userProfile(Ref ref) async { ... }

// 레벨/XP
@riverpod
Future<UserLevel> userLevel(Ref ref) async { ... }

// 배지 목록
@riverpod
Future<List<Badge>> userBadges(Ref ref) async { ... }
```

### 필요한 API 목록

| API | 메서드 | 설명 |
|-----|--------|------|
| `GET /users/me` | GET | 현재 사용자 프로필 |
| `GET /users/{id}/stats` | GET | 활동 통계 (home과 공유) |
| `GET /users/{id}/level` | GET | 레벨/XP 정보 |
| `GET /users/{id}/badges` | GET | 획득 배지 목록 |
| `PUT /users/me` | PUT | 프로필 편집 |
| `POST /media/avatar` | POST | 프로필 이미지 업로드 |

### ProfileEntity (미래)

```dart
class ProfileEntity {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final int activityCount;
  final int followerCount;
  final int followingCount;
}
```
