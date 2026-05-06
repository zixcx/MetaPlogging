# MetaPlogging API 명세서

## 개요

| 항목 | 내용 |
|------|------|
| Base URL | `http://localhost:3000` |
| API 버전 | v1.0.0 |
| 인증 방식 | Bearer Token (JWT) |
| 응답 형식 | JSON |

---

## 공통

### 인증 헤더

인증이 필요한 엔드포인트는 요청 헤더에 Access Token을 포함해야 합니다.

```
Authorization: Bearer <access_token>
```

### 공통 오류 응답

| HTTP 상태 코드 | 의미 |
|----------------|------|
| `400` | Bad Request — 잘못된 요청 파라미터 |
| `401` | Unauthorized — 인증 실패 또는 토큰 만료 |
| `422` | Unprocessable Entity — 유효성 검사 실패 |
| `503` | Service Unavailable — 서버 내부 오류 (DB 장애 등) |

오류 응답 바디:
```json
{
  "detail": "오류 메시지"
}
```

---

## 토큰 정보

| 토큰 종류 | 유효 기간 | 알고리즘 |
|-----------|-----------|----------|
| Access Token | 30분 | HS256 (JWT) |
| Refresh Token | 30일 | HS256 (JWT) |

---

## 엔드포인트

### 헬스 체크

#### `GET /health`

서버 및 DB 상태를 확인합니다.

**인증 불필요**

**응답 예시 (200 OK)**
```json
{
  "status": "ok",
  "timestamp": "2026-05-05T12:00:00.000000+09:00",
  "version": "1.0.0",
  "checks": {
    "database": {
      "status": "ok"
    }
  }
}
```

**응답 예시 (503 Service Unavailable)**
```json
{
  "status": "degraded",
  "timestamp": "2026-05-05T12:00:00.000000+09:00",
  "version": "1.0.0",
  "checks": {
    "database": {
      "status": "error",
      "error": "오류 상세 내용"
    }
  }
}
```

---

## 인증 API (`/api/auth`)

### 회원가입

#### `POST /api/auth/register`

이메일/비밀번호로 새 계정을 생성합니다.

**인증 불필요**

**요청 바디**
```json
{
  "username": "string",
  "email": "user@example.com",
  "password": "string",
  "name": "string"
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `username` | string | O | 사용자 아이디 (중복 불가) |
| `email` | string (email) | O | 이메일 주소 (중복 불가) |
| `password` | string | O | 비밀번호 (아래 조건 참고) |
| `name` | string | X | 표시 이름 |

**비밀번호 조건**
- 8자 이상
- 대문자 1자 이상
- 소문자 1자 이상
- 숫자 1자 이상
- 특수문자(`!@#$%^&*()_+-=[]{}|;':",./<>?`) 1자 이상

**응답 (201 Created)**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "name": "홍길동",
    "profile_image_url": null,
    "auth_provider": "email"
  }
}
```

**오류**
| 상태 코드 | detail | 원인 |
|-----------|--------|------|
| `400` | `Username already taken` | 아이디 중복 |
| `400` | `Email already registered` | 이메일 중복 |
| `422` | `비밀번호 조건 미충족: ...` | 비밀번호 조건 불충족 |

---

### 로그인

#### `POST /api/auth/login`

아이디/비밀번호로 로그인합니다.

**인증 불필요**

**요청 바디**
```json
{
  "username": "string",
  "password": "string"
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `username` | string | O | 사용자 아이디 |
| `password` | string | O | 비밀번호 |

**응답 (200 OK)**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "name": "홍길동",
    "profile_image_url": null,
    "auth_provider": "email"
  }
}
```

**오류**
| 상태 코드 | detail | 원인 |
|-----------|--------|------|
| `401` | `Invalid credentials` | 아이디 또는 비밀번호 불일치 |

---

### Google 소셜 로그인

#### `POST /api/auth/google`

Google OAuth2 ID Token으로 로그인 또는 자동 회원가입합니다.

**인증 불필요**

**요청 바디**
```json
{
  "id_token": "string"
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `id_token` | string | O | Google OAuth2 ID Token |

**응답 (200 OK)**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@gmail.com",
    "name": "홍길동",
    "profile_image_url": "https://lh3.googleusercontent.com/...",
    "auth_provider": "google"
  }
}
```

**오류**
| 상태 코드 | detail | 원인 |
|-----------|--------|------|
| `401` | `Invalid Google id_token: ...` | Google 토큰 검증 실패 |
| `400` | `Google token did not contain an email` | 토큰에 이메일 없음 |

---

### Kakao 소셜 로그인

#### `POST /api/auth/kakao`

Kakao 사용자 정보로 로그인 또는 자동 회원가입합니다.

**인증 불필요**

> 클라이언트에서 Kakao SDK를 통해 받은 사용자 정보를 직접 전달합니다.

**요청 바디**
```json
{
  "access_token": "string",
  "email": "user@kakao.com",
  "name": "string",
  "profile_image_url": "string"
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `access_token` | string | O | Kakao Access Token |
| `email` | string (email) | O | 카카오 계정 이메일 |
| `name` | string | X | 사용자 이름 |
| `profile_image_url` | string | X | 프로필 이미지 URL |

**응답 (200 OK)**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@kakao.com",
    "name": "홍길동",
    "profile_image_url": "https://k.kakaocdn.net/...",
    "auth_provider": "kakao"
  }
}
```

---

### 로그아웃

#### `POST /api/auth/logout`

현재 로그인한 사용자를 로그아웃합니다.

**인증 필요** (`Authorization: Bearer <access_token>`)

**요청 바디** 없음

**응답 (200 OK)**
```json
{
  "detail": "Logged out successfully"
}
```

**오류**
| 상태 코드 | detail | 원인 |
|-----------|--------|------|
| `401` | `Invalid or expired token` | 토큰 유효하지 않음 |
| `401` | `User not found` | 존재하지 않는 사용자 |

---

### 비밀번호 찾기

#### `POST /api/auth/find-password`

가입된 이메일로 비밀번호 재설정 링크를 발송합니다.

**인증 불필요**

> 이메일 존재 여부와 관계없이 항상 200을 반환합니다 (이메일 노출 방지).

**요청 바디**
```json
{
  "email": "user@example.com"
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `email` | string (email) | O | 가입 이메일 |

**응답 (200 OK)**
```json
{
  "detail": "If that email is registered, a reset link will be sent"
}
```

---

### 토큰 갱신

#### `POST /api/auth/refresh`

Refresh Token으로 새 Access Token을 발급합니다.

**인증 불필요**

**요청 바디**
```json
{
  "refresh_token": "eyJ..."
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `refresh_token` | string | O | 발급받은 Refresh Token |

**응답 (200 OK)**
```json
{
  "access_token": "eyJ..."
}
```

**오류**
| 상태 코드 | detail | 원인 |
|-----------|--------|------|
| `401` | `Invalid or expired refresh token` | 토큰 유효하지 않거나 만료됨 |
| `401` | `User not found` | 존재하지 않는 사용자 |

---

### 내 정보 조회

#### `GET /api/auth/me`

현재 로그인한 사용자의 정보를 반환합니다.

**인증 필요** (`Authorization: Bearer <access_token>`)

**요청 바디** 없음

**응답 (200 OK)**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "name": "홍길동",
  "profile_image_url": null,
  "auth_provider": "email"
}
```

**오류**
| 상태 코드 | detail | 원인 |
|-----------|--------|------|
| `401` | `Invalid or expired token` | 토큰 유효하지 않음 |
| `401` | `User not found` | 존재하지 않는 사용자 |

---

## 응답 스키마

### UserResponse

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string (UUID) | 사용자 고유 ID |
| `email` | string | 이메일 주소 |
| `name` | string \| null | 표시 이름 |
| `profile_image_url` | string \| null | 프로필 이미지 URL |
| `auth_provider` | string | 인증 수단 (`email` \| `google` \| `kakao`) |

### AuthTokenResponse

| 필드 | 타입 | 설명 |
|------|------|------|
| `access_token` | string | JWT Access Token (유효기간: 30분) |
| `refresh_token` | string | JWT Refresh Token (유효기간: 30일) |
| `user` | UserResponse | 사용자 정보 |

### AccessTokenResponse

| 필드 | 타입 | 설명 |
|------|------|------|
| `access_token` | string | JWT Access Token (유효기간: 30분) |

---

## 엔드포인트 요약

| 메서드 | 경로 | 인증 | 설명 |
|--------|------|------|------|
| `GET` | `/health` | X | 서버 헬스 체크 |
| `POST` | `/api/auth/register` | X | 이메일 회원가입 |
| `POST` | `/api/auth/login` | X | 이메일 로그인 |
| `POST` | `/api/auth/google` | X | Google 소셜 로그인 |
| `POST` | `/api/auth/kakao` | X | Kakao 소셜 로그인 |
| `POST` | `/api/auth/logout` | O | 로그아웃 |
| `POST` | `/api/auth/find-password` | X | 비밀번호 재설정 이메일 발송 |
| `POST` | `/api/auth/refresh` | X | Access Token 갱신 |
| `GET` | `/api/auth/me` | O | 내 정보 조회 |
