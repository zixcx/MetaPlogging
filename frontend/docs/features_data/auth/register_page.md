# RegisterPage (회원가입 화면)

---

## 파일 위치

`lib/features/auth/presentation/pages/register_page.dart`

---

## 화면 구성 (2단계 UX)

이 페이지는 2단계 흐름으로 구성됨:

```
[1단계] 소셜 로그인 선택 화면  →  [2단계] 이메일 폼 (선택적)
```

### 1단계: 소셜/이메일 선택

| UI 요소 | 값 |
|---------|----|
| 제목 | `"계정 만들기"` |
| 설명 | `"함께 플로깅으로 환경을 지켜나가요."` |
| 이메일 가입 버튼 | `"가입하기"` |
| 구분선 | `"또는"` |
| Google 버튼 | `SocialLoginButton(type: google)` |
| Kakao 버튼 | `SocialLoginButton(type: kakao)` |

### 2단계: 이메일 폼 (`_showEmailForm == true`)

| UI 요소 | 값 |
|---------|----|
| 제목 | `"계정 만들기"` |
| 이름 필드 | 라벨: `"이름"` |
| 아이디 필드 | 라벨: `"아이디"` |
| 이메일 필드 | 라벨: `"이메일"` |
| 비밀번호 필드 | 라벨: `"비밀번호"` |
| 비밀번호 확인 필드 | 라벨: `"비밀번호 확인"` |
| 가입 버튼 | `"가입하기"` |
| 약관 안내 | `"가입 시 이용약관 및 개인정보처리방침에 동의합니다."` |

---

## 사용자 입력 데이터 (폼)

| 필드 | 컨트롤러 | 타입 | 검증 규칙 |
|------|---------|------|-----------|
| 이름 | `_nameCtrl` | `String` | 필수, 2자 이상 |
| 아이디 | `_usernameCtrl` | `String` | 필수, 3자 이상, `[a-zA-Z0-9_]`만 허용 |
| 이메일 | `_emailCtrl` | `String` | 필수, `@` 포함 |
| 비밀번호 | `_passwordCtrl` | `String` | 필수, 8자 이상, 영문+숫자 모두 포함 |
| 비밀번호 확인 | `_confirmPasswordCtrl` | `String` | 필수, 비밀번호와 일치 |

### 폼 제출 데이터

```dart
// authProvider.notifier.register() 호출 시
{
  username: _usernameCtrl.text,
  email: _emailCtrl.text,
  password: _passwordCtrl.text,
  name: _nameCtrl.text,
}
```

---

## 사용자 액션

| 단계 | 액션 | 컴포넌트 | 결과 |
|------|------|---------|------|
| 1 | 탭 | "가입하기" 버튼 | `_showEmailForm = true` |
| 1 | 탭 | Google 버튼 | `authProvider.notifier.loginWithGoogle()` |
| 1 | 탭 | Kakao 버튼 | `authProvider.notifier.loginWithKakao()` |
| 1 | 탭 | 뒤로가기 | `context.pop()` |
| 2 | 탭 | 뒤로가기 | `_showEmailForm = false` (1단계로 복귀) |
| 2 | 토글 | 비밀번호 보기 | `_obscurePassword` 반전 |
| 2 | 토글 | 비밀번호 확인 보기 | `_obscureConfirm` 반전 |
| 2 | 탭 | "가입하기" 제출 | `_formKey.currentState?.validate()` → `authProvider.notifier.register()` |

---

## 로컬 UI 상태

| 변수 | 타입 | 초기값 | 설명 |
|------|------|--------|------|
| `_showEmailForm` | `bool` | `false` | 이메일 폼 표시 여부 (2단계 여부) |
| `_nameCtrl` | `TextEditingController` | `""` | 이름 |
| `_usernameCtrl` | `TextEditingController` | `""` | 아이디 |
| `_emailCtrl` | `TextEditingController` | `""` | 이메일 |
| `_passwordCtrl` | `TextEditingController` | `""` | 비밀번호 |
| `_confirmPasswordCtrl` | `TextEditingController` | `""` | 비밀번호 확인 |
| `_obscurePassword` | `bool` | `true` | 비밀번호 마스킹 |
| `_obscureConfirm` | `bool` | `true` | 비밀번호 확인 마스킹 |
| `_formKey` | `GlobalKey<FormState>` | - | 폼 전체 검증 키 |

---

## 전역 상태 의존성

| Provider | 읽기 방식 | 사용 목적 |
|---------|---------|---------|
| `authProvider` | `ref.watch()` | 로딩 상태, 에러 표시 |
| `authProvider.notifier` | `ref.read()` | register, loginWithGoogle, loginWithKakao 호출 |

---

## API 요구사항

### POST /auth/register

```json
// 요청
{
  "username": "string",
  "email": "string",
  "password": "string",
  "name": "string"
}

// 응답 (성공) — 자동 로그인 포함
{
  "access_token": "string",
  "refresh_token": "string",
  "user": {
    "id": "string",
    "email": "string",
    "name": "string",
    "profile_image_url": null,
    "auth_provider": "email"
  }
}

// 응답 (실패 - 중복 아이디)
{
  "error": "username_taken",
  "message": "이미 사용 중인 아이디입니다."
}

// 응답 (실패 - 중복 이메일)
{
  "error": "email_taken",
  "message": "이미 가입된 이메일입니다."
}
```

---

## 네비게이션 흐름

```
RegisterPage
├── 1단계: [뒤로] → LandingPage
├── 1단계: Google/Kakao 성공 → / (홈) [AppRouter 리다이렉트]
├── 1단계: "가입하기" → 2단계 (인라인)
└── 2단계: "가입하기" 성공 → / (홈) [AppRouter 리다이렉트]
```
