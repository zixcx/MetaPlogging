# LoginPage (로그인 화면)

---

## 파일 위치

`lib/features/auth/presentation/pages/login_page.dart`

---

## 화면 구성 데이터

### 정적 텍스트

| UI 요소 | 값 |
|---------|----|
| 제목 | `"다시 만나서\n반가워요!"` |
| 설명 | `"MetaPlogging 계정으로 로그인하세요."` |
| 아이디 라벨 | `"아이디"` |
| 비밀번호 라벨 | `"비밀번호"` |
| 비밀번호 찾기 | `"비밀번호를 잊으셨나요?"` |
| 구분선 텍스트 | `"또는"` |
| 로그인 버튼 | `"로그인"` |
| 계정 만들기 링크 | `"계정 만들기"` |
| 약관 안내 | `"가입 시 이용약관 및 개인정보처리방침에 동의합니다."` |

---

## 사용자 입력 데이터 (폼)

| 필드 | 컨트롤러 | 타입 | 검증 규칙 | 키보드 타입 |
|------|---------|------|-----------|------------|
| 아이디 | `_usernameCtrl` | `String` | 필수 입력 | `text` |
| 비밀번호 | `_passwordCtrl` | `String` | 필수 입력 | `text` (obscure) |

### 폼 제출 데이터

```dart
// authProvider.notifier.loginWithUsername() 호출 시
{
  username: _usernameCtrl.text,
  password: _passwordCtrl.text,
}
```

---

## 사용자 액션

| 액션 | 컴포넌트 | 결과 |
|------|---------|------|
| 탭 | 뒤로가기(X) 버튼 | `context.pop()` |
| 탭 | "비밀번호를 잊으셨나요?" | `context.push(AppRoutes.findAccount)` |
| 탭 | "로그인" | `authProvider.notifier.loginWithUsername(username, password)` |
| 탭 | "계정 만들기" | `context.push(AppRoutes.register)` |
| 탭 | Google 버튼 | `authProvider.notifier.loginWithGoogle()` |
| 탭 | Kakao 버튼 | `authProvider.notifier.loginWithKakao()` |
| 토글 | 비밀번호 보기 아이콘 | `_obscurePassword` 반전 |

---

## 로컬 UI 상태

| 변수 | 타입 | 초기값 | 설명 |
|------|------|--------|------|
| `_usernameCtrl` | `TextEditingController` | `""` | 아이디 입력값 |
| `_passwordCtrl` | `TextEditingController` | `""` | 비밀번호 입력값 |
| `_obscurePassword` | `bool` | `true` | 비밀번호 마스킹 여부 |
| `_formKey` | `GlobalKey<FormState>` | - | 폼 검증 키 |

---

## 전역 상태 의존성

| Provider | 읽기 방식 | 사용 목적 |
|---------|---------|---------|
| `authProvider` | `ref.watch()` | 로딩 중 버튼 비활성화, 에러 메시지 표시 |
| `authProvider.notifier` | `ref.read()` | 로그인 메서드 호출 |

### authProvider 상태에 따른 UI 변화

| 상태 | UI 동작 |
|------|---------|
| `AsyncLoading` | 로그인 버튼 → `CircularProgressIndicator` |
| `AsyncData(UserEntity)` | 자동으로 `/` (홈)으로 리다이렉트 (AppRouter 처리) |
| `AsyncError` | 에러 메시지 `SnackBar` 또는 인라인 표시 |

---

## 외부 의존성

| 의존성 | 종류 | 구현 상태 |
|--------|------|----------|
| `LoginEmailUsecase` | UseCase | ✅ 구현됨 |
| `LoginGoogleUsecase` | UseCase | ✅ 구현됨 |
| `LoginKakaoUsecase` | UseCase | ✅ 구현됨 |
| `SocialLoginButton` | 위젯 | ✅ 구현됨 |
| `google_sign_in` | 패키지 | ✅ 설치됨 |
| `kakao_flutter_sdk_user` | 패키지 | ✅ 설치됨 |

---

## API 요구사항

### POST /auth/login

```json
// 요청
{
  "username": "string",
  "password": "string"
}

// 응답 (성공)
{
  "access_token": "string",
  "refresh_token": "string",
  "user": {
    "id": "string",
    "email": "string",
    "name": "string",
    "profile_image_url": "string | null",
    "auth_provider": "email"
  }
}

// 응답 (실패)
{
  "error": "invalid_credentials",
  "message": "아이디 또는 비밀번호가 잘못되었습니다."
}
```

---

## 네비게이션 흐름

```
LoginPage
├── [뒤로] → LandingPage
├── "비밀번호 찾기" → FindAccountPage
├── "계정 만들기" → RegisterPage
└── 로그인 성공 → / (홈) [AppRouter 리다이렉트]
```
