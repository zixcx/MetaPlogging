# AuthProvider (전역 인증 상태)

> 앱 전체 인증 상태를 관리하는 Riverpod Notifier

---

## 파일 위치

| 파일 | 경로 |
|------|------|
| Provider | `lib/features/auth/presentation/providers/auth_provider.dart` |
| 생성 코드 | `lib/features/auth/presentation/providers/auth_provider.g.dart` |

---

## 상태 타입

```dart
AsyncValue<UserEntity?>
```

| 상태 | 의미 |
|------|------|
| `AsyncLoading` | 앱 시작 시 저장된 세션 복원 중 |
| `AsyncData(null)` | 미로그인 상태 |
| `AsyncData(UserEntity)` | 로그인 완료 |
| `AsyncError` | 로그인/가입 실패 |

---

## 메서드

### `loginWithUsername(String username, String password)`

| 항목 | 내용 |
|------|------|
| 입력 | 아이디(username), 비밀번호(password) |
| 성공 | 상태 → `AsyncData(UserEntity)` |
| 실패 | 상태 → `AsyncError` (에러 메시지 표시) |
| 호출 위치 | `LoginPage` |
| 내부 UseCase | `LoginEmailUsecase` |

### `loginWithGoogle()`

| 항목 | 내용 |
|------|------|
| 입력 | 없음 (Google 인증 팝업) |
| 성공 | 상태 → `AsyncData(UserEntity)` |
| 실패 | 상태 → `AsyncError` |
| 호출 위치 | `LoginPage`, `RegisterPage` |
| 내부 UseCase | `LoginGoogleUsecase` |
| 외부 의존성 | `google_sign_in` 패키지 |

### `loginWithKakao()`

| 항목 | 내용 |
|------|------|
| 입력 | 없음 (Kakao 인증 팝업) |
| 성공 | 상태 → `AsyncData(UserEntity)` |
| 실패 | 상태 → `AsyncError` |
| 호출 위치 | `LoginPage`, `RegisterPage` |
| 내부 UseCase | `LoginKakaoUsecase` |
| 외부 의존성 | `kakao_flutter_sdk_user` 패키지 |

### `register(String username, String email, String password, String name)`

| 항목 | 내용 |
|------|------|
| 입력 | 아이디, 이메일, 비밀번호, 이름 |
| 성공 | 상태 → `AsyncData(UserEntity)` (자동 로그인) |
| 실패 | 상태 → `AsyncError` |
| 호출 위치 | `RegisterPage` |
| 내부 UseCase | `RegisterUsecase` |

### `logout()`

| 항목 | 내용 |
|------|------|
| 입력 | 없음 |
| 결과 | 상태 → `AsyncData(null)` |
| 호출 위치 | `ProfilePage` (_SettingsList) |
| 내부 UseCase | `LogoutUsecase` |
| 사이드 이펙트 | `flutter_secure_storage` 토큰 삭제 |

### `findPassword(String email)`

| 항목 | 내용 |
|------|------|
| 입력 | 이메일 주소 |
| 반환 | `Future<bool>` |
| 구현 상태 | ⚠️ 미구현 (항상 false 반환) |
| 호출 위치 | `FindAccountPage` (현재 미연결) |

---

## 라우터 연동

`AppRouter`에서 `authProvider`를 watch하며 리다이렉트 제어:

```
미로그인(null) + /auth/* 아닌 경로  → /auth/landing 리다이렉트
로그인(UserEntity) + /auth/* 경로   → / (홈) 리다이렉트
```

---

## 내부 의존성 체인

```
authProvider (AuthNotifier)
├── authRepositoryProvider
│   └── AuthRepositoryImpl
│       ├── AuthRemoteDatasource  ← Dio HTTP 클라이언트
│       └── AuthLocalDatasource   ← flutter_secure_storage
├── LoginEmailUsecase
├── LoginGoogleUsecase
├── LoginKakaoUsecase
├── RegisterUsecase
├── LogoutUsecase
└── FindPasswordUsecase
```

---

## 토큰 저장 방식

| 항목 | 저장소 | 키 |
|------|--------|-----|
| Access Token | `flutter_secure_storage` | `access_token` |
| Refresh Token | `flutter_secure_storage` | `refresh_token` |
| 사용자 정보 | `shared_preferences` 또는 메모리 | - |
