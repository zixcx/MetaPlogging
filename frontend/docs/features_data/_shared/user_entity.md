# UserEntity / UserModel

> 사용자 도메인 엔티티 및 API 응답 모델

---

## 파일 위치

| 파일 | 경로 |
|------|------|
| 도메인 엔티티 | `lib/features/auth/domain/entities/user_entity.dart` |
| 데이터 모델 | `lib/features/auth/data/models/user_model.dart` |

---

## UserEntity (도메인 계층)

외부 프레임워크 의존성 없는 순수 Dart 클래스.

### 필드

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|:----:|------|
| `id` | `String` | ✅ | 사용자 고유 ID (서버 발급) |
| `email` | `String` | ✅ | 로그인/식별에 사용되는 이메일 |
| `name` | `String?` | ❌ | 표시 이름 (닉네임). 소셜 로그인 시 자동 설정 |
| `profileImageUrl` | `String?` | ❌ | 프로필 이미지 URL. null이면 이모지 아바타 표시 |
| `authProvider` | `AuthProvider` | ✅ | 가입/로그인 방식 |

### AuthProvider 열거형

```dart
enum AuthProvider {
  email,   // 이메일+비밀번호 가입
  google,  // Google OAuth
  kakao,   // Kakao OAuth
}
```

### 사용 페이지

| 페이지 | 사용 방식 |
|--------|----------|
| `ProfilePage` | `authProvider`에서 읽어 닉네임, 이메일 표시 (현재 모의 데이터로 대체) |
| `LoginPage` | 로그인 성공 시 authProvider 상태에 저장됨 |
| `RegisterPage` | 가입 성공 시 authProvider 상태에 저장됨 |
| `AppRouter` (리다이렉트) | `null` 여부로 로그인 게이팅 판단 |

---

## UserModel (데이터 계층)

`@freezed` + `@JsonSerializable` 적용. API 응답 JSON ↔ 객체 변환 담당.

### 필드 (JSON 매핑)

| 필드명 | 타입 | JSON 키 | 설명 |
|--------|------|---------|------|
| `id` | `String` | `"id"` | 사용자 고유 ID |
| `email` | `String` | `"email"` | 이메일 주소 |
| `name` | `String?` | `"name"` | 표시 이름 |
| `profileImageUrl` | `String?` | `"profile_image_url"` | 프로필 이미지 URL |
| `authProvider` | `String` | `"auth_provider"` | `"email"` / `"google"` / `"kakao"` |

### 예상 API 응답 JSON

```json
{
  "id": "usr_abc123",
  "email": "runner@example.com",
  "name": "플로깅 러너",
  "profile_image_url": null,
  "auth_provider": "email"
}
```

### 변환 메서드

```dart
// JSON → UserModel
UserModel.fromJson(Map<String, dynamic> json)

// UserModel → UserEntity (도메인에서 사용)
UserEntity toEntity()
```

---

## 현재 갭 (Gap Analysis)

| 항목 | 현재 | 필요 |
|------|------|------|
| ProfilePage의 닉네임 | 하드코딩 `'플로깅 러너'` | `authProvider.value?.name` |
| ProfilePage의 이메일 | 하드코딩 `'runner@example.com'` | `authProvider.value?.email` |
| ProfilePage의 아바타 | 하드코딩 이모지 🌿 | `profileImageUrl` 기반 이미지 or 이니셜 |
| CreatePostSheet의 작성자 | 하드코딩 `'플로깅 러너'`, `'🌿'` | `authProvider.value?.name` |

---

## 추가로 필요한 사용자 데이터 (미정의)

현재 `UserEntity`에 없지만 ProfilePage에서 표시하는 데이터:

| 필드 | 설명 | 추가 위치 제안 |
|------|------|---------------|
| `level` | 레벨 번호 (현재 3) | `UserStatsEntity` (별도 엔티티) |
| `levelName` | 레벨명 (현재 `'에코 러너'`) | `UserStatsEntity` |
| `currentXp` | 현재 XP (현재 420) | `UserStatsEntity` |
| `maxXp` | 레벨업 목표 XP (현재 600) | `UserStatsEntity` |
| `followingCount` | 팔로잉 수 | `UserEntity` 또는 별도 API |
| `followerCount` | 팔로워 수 | `UserEntity` 또는 별도 API |
| `activityCount` | 활동 횟수 (현재 12) | `UserStatsEntity` |
