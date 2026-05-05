# FindAccountPage (비밀번호 찾기)

---

## 파일 위치

`lib/features/auth/presentation/pages/find_account_page.dart`

---

## 현재 구현 상태

> ⚠️ **스텁(Stub) 페이지** — 기능 미구현 안내 화면만 존재

---

## 화면 구성 데이터 (정적)

| UI 요소 | 값 |
|---------|----|
| 아이콘 | `Icons.construction_rounded` |
| 제목 | `"기능 준비 중이에요"` |
| 설명 | `"비밀번호 찾기 기능은 현재 개발 중입니다.\n곧 업데이트될 예정이에요."` |
| 안내 | `"비밀번호를 잊으셨다면 앱 문의를 통해 도움을 받으실 수 있어요."` |
| 버튼 | `"로그인으로 돌아가기"` |

---

## 사용자 액션

| 액션 | 컴포넌트 | 결과 |
|------|---------|------|
| 탭 | 뒤로가기 | `context.pop()` → LoginPage |
| 탭 | "로그인으로 돌아가기" | `context.pop()` → LoginPage |

---

## 로컬 UI 상태

없음 (순수 정적 화면)

---

## 외부 의존성

없음

---

## 구현 시 필요한 데이터

비밀번호 찾기 기능 구현 시 다음이 필요:

### 사용자 입력

| 필드 | 타입 | 검증 |
|------|------|------|
| 이메일 | `String` | 필수, `@` 포함, 가입된 이메일 |

### API 요구사항

#### POST /auth/find-password

```json
// 요청
{
  "email": "string"
}

// 응답 (성공)
{
  "message": "이메일로 재설정 링크를 발송했습니다."
}

// 응답 (실패 - 이메일 없음)
{
  "error": "email_not_found",
  "message": "가입되지 않은 이메일입니다."
}
```

### 필요한 로컬 UI 상태 (미래)

| 변수 | 타입 | 설명 |
|------|------|------|
| `_emailCtrl` | `TextEditingController` | 이메일 입력 |
| `_isSent` | `bool` | 이메일 발송 완료 여부 (완료 UI 전환) |
| `_isLoading` | `bool` | 요청 진행 중 |
| `_formKey` | `GlobalKey<FormState>` | 폼 검증 |

---

## 네비게이션 흐름

```
FindAccountPage
└── [뒤로] / "로그인으로 돌아가기" → LoginPage
```
