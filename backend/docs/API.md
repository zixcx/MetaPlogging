# MetaPlogging API 명세서

**버전**: 1.0.0  
**최종 업데이트**: 2026-05-07  
**Base URL**: `http://<host>:3000`

---

## 목차

1. [공통](#공통)
2. [헬스체크](#헬스체크)
3. [인증 API](#인증-api-apiauth)
4. [트래킹 API](#트래킹-api-apitracking)
5. [장소 검색 API](#장소-검색-api-apiplaces)
6. [피드/포스트 API](#피드포스트-api-apiposts)
7. [댓글 API](#댓글-api-apicomments)
8. [이미지 업로드 API](#이미지-업로드-api-apiimages)
9. [사용자 API](#사용자-api-apiusers)
10. [응답 스키마](#응답-스키마)
11. [엔드포인트 요약](#엔드포인트-요약)

---

## 공통

### 인증 헤더

인증이 필요한 엔드포인트는 요청 헤더에 Access Token을 포함해야 합니다.

```
Authorization: Bearer <access_token>
```

### 토큰 정보

| 토큰 종류 | 유효 기간 | 알고리즘 |
|-----------|-----------|----------|
| Access Token | 30분 | HS256 (JWT) |
| Refresh Token | 30일 | HS256 (JWT) |

### 공통 오류 응답

| HTTP 상태 코드 | 의미 |
|----------------|------|
| `400` | Bad Request — 잘못된 요청 파라미터 |
| `401` | Unauthorized — 인증 실패 또는 토큰 만료 |
| `403` | Forbidden — 권한 없음 (타인 리소스 접근) |
| `404` | Not Found — 리소스 없음 |
| `409` | Conflict — 상태 충돌 (중복, 이미 완료됨 등) |
| `415` | Unsupported Media Type — 지원하지 않는 파일 형식 |
| `422` | Unprocessable Entity — 유효성 검사 실패 |
| `503` | Service Unavailable — 서버 내부 오류 |

```json
{ "detail": "오류 메시지" }
```

---

## 헬스체크

### `GET /health`

서버 및 DB 상태를 확인합니다. 인증 불필요.

**응답 (200 OK)**
```json
{
  "status": "ok",
  "timestamp": "2026-05-07T12:00:00.000000+09:00",
  "version": "1.0.0",
  "checks": { "database": { "status": "ok" } }
}
```

**응답 (503 Service Unavailable)**
```json
{
  "status": "degraded",
  "timestamp": "2026-05-07T12:00:00.000000+09:00",
  "version": "1.0.0",
  "checks": { "database": { "status": "error", "error": "오류 내용" } }
}
```

---

## 인증 API `/api/auth`

### `POST /api/auth/register` — 회원가입

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
|------|------|:----:|------|
| `username` | string | O | 아이디 (중복 불가) |
| `email` | string | O | 이메일 (중복 불가) |
| `password` | string | O | 비밀번호 |
| `name` | string | X | 표시 이름 |

**비밀번호 조건**: 8자 이상, 대문자·소문자·숫자·특수문자 각 1자 이상

**응답 (201 Created)** → `AuthTokenResponse`

| 오류 | 원인 |
|------|------|
| `400 Username already taken` | 아이디 중복 |
| `400 Email already registered` | 이메일 중복 |
| `422 비밀번호 조건 미충족` | 비밀번호 형식 불충족 |

---

### `POST /api/auth/login` — 로그인

**인증 불필요**

```json
{ "username": "string", "password": "string" }
```

**응답 (200 OK)** → `AuthTokenResponse`

| 오류 | 원인 |
|------|------|
| `401 Invalid credentials` | 아이디/비밀번호 불일치 |

---

### `POST /api/auth/google` — Google 소셜 로그인

**인증 불필요**

```json
{ "id_token": "string" }
```

**응답 (200 OK)** → `AuthTokenResponse`

---

### `POST /api/auth/kakao` — Kakao 소셜 로그인

**인증 불필요**

```json
{
  "access_token": "string",
  "email": "user@kakao.com",
  "name": "string",
  "profile_image_url": "string"
}
```

**응답 (200 OK)** → `AuthTokenResponse`

---

### `POST /api/auth/logout` — 로그아웃

**인증 필요**

**응답 (200 OK)**
```json
{ "detail": "Logged out successfully" }
```

---

### `POST /api/auth/find-password` — 비밀번호 찾기

**인증 불필요** | 이메일 존재 여부 무관하게 항상 200 반환

```json
{ "email": "user@example.com" }
```

**응답 (200 OK)**
```json
{ "detail": "If that email is registered, a reset link will be sent" }
```

---

### `POST /api/auth/refresh` — 토큰 갱신

**인증 불필요**

```json
{ "refresh_token": "eyJ..." }
```

**응답 (200 OK)** → `AccessTokenResponse`

---

### `GET /api/auth/me` — 내 정보 조회

**인증 필요**

**응답 (200 OK)** → `UserResponse`

---

## 트래킹 API `/api/tracking`

### 세션 상태 흐름

```
active ──pause──▶ paused ──resume──▶ active ──end──▶ completed
  │                  │
  └──────────────────┴── (1시간 초과) ──▶ expired
```

### `POST /api/tracking/sessions` — 세션 시작

**인증 필요**

```json
{
  "start_lat": 37.5,
  "start_lng": 127.0
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `start_lat` | float | X | 시작 위도 |
| `start_lng` | float | X | 시작 경도 |

**응답 (201 Created)** → `TrackingSessionDetail`

| 오류 | 원인 |
|------|------|
| `409 An ongoing tracking session already exists` | 이미 진행 중인 세션 있음 |

---

### `GET /api/tracking/sessions/active` — 진행 중 세션 조회

**인증 필요**

앱 재시작 시 이어하기 팝업 여부를 판단하는 엔드포인트.  
진행 중 세션이 없으면 `null` 반환.

**응답 (200 OK)** → `TrackingSessionDetail | null`

---

### `POST /api/tracking/sessions/{session_id}/points` — GPS 포인트 추가

**인증 필요** | active 상태에서만 허용 (paused 시 409)

```json
{
  "points": [
    { "lat": 37.5001, "lng": 127.0001, "recorded_at": "2026-05-07T10:00:05+09:00" }
  ]
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `points` | array | O | GPS 포인트 목록 (1개 이상) |
| `points[].lat` | float | O | 위도 |
| `points[].lng` | float | O | 경도 |
| `points[].recorded_at` | datetime | O | 클라이언트 측정 시각 |

**응답 (200 OK)**
```json
{ "accepted": 3, "distance_meters": 207 }
```

| 오류 | 원인 |
|------|------|
| `409` | 세션이 active 상태가 아님 |

---

### `POST /api/tracking/sessions/{session_id}/end` — 세션 종료

**인증 필요** | active 또는 paused 상태에서 허용

```json
{
  "trash_items": [
    { "category": "cigarette", "amount": { "level": "moderate", "count": null } },
    { "category": "bottle_can", "amount": { "level": null, "count": 7 } }
  ],
  "place": {
    "naver_place_id": "naver:12345",
    "name": "한강공원 반포지구",
    "category": "공원",
    "address": "서울 서초구 반포동",
    "road_address": "서울 서초구 신반포로11길",
    "lat": 37.5097,
    "lng": 126.9983
  },
  "description": "한강 반포지구 플로깅",
  "end_lat": 37.5097,
  "end_lng": 126.9983,
  "final_points": []
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `trash_items` | array | X | 쓰레기 수거 목록 |
| `place` | object | X | 선택한 장소 (네이버 검색 결과) |
| `description` | string | X | 활동 설명 |
| `end_lat`, `end_lng` | float | X | 종료 위치 (없으면 마지막 포인트 사용) |
| `final_points` | array | X | 종료 직전 마지막 포인트 일괄 전송 |

**TrashItem 구조**

| 필드 | 값 | 설명 |
|------|-----|------|
| `category` | `cigarette` \| `bottle_can` \| `plastic_bag` \| `large_waste` \| `other` | 쓰레기 카테고리 |
| `amount.level` | `little` \| `moderate` \| `a_lot` \| null | 정도 선택 |
| `amount.count` | integer \| null | 직접 입력 개수 |

> `level`과 `count`는 동시에 사용 불가. 하나만 입력.

**duration 계산**: `전체 경과 시간 - 누적 pause_duration_seconds`

**응답 (200 OK)** → `TrackingSessionDetail`

---

### `GET /api/tracking/sessions` — 내 세션 목록

**인증 필요**

| 쿼리 파라미터 | 타입 | 기본값 | 설명 |
|--------------|------|--------|------|
| `limit` | int | 20 | 최대 반환 수 (1~100) |
| `offset` | int | 0 | 시작 위치 |
| `status` | string | - | 필터 (active/paused/completed/expired) |

**응답 (200 OK)** → `TrackingSessionSummary[]`

---

### `GET /api/tracking/sessions/{session_id}` — 세션 상세

**인증 필요**

**응답 (200 OK)** → `TrackingSessionDetail` (GPS 포인트 전체 포함)

---

### `PATCH /api/tracking/sessions/{session_id}` — 세션 편집

**인증 필요** | completed 상태에서만 허용

```json
{
  "place": { "naver_place_id": "...", "name": "...", "lat": 37.5, "lng": 127.0 },
  "description": "수정된 설명"
}
```

**응답 (200 OK)** → `TrackingSessionDetail`

---

### `DELETE /api/tracking/sessions/{session_id}` — 세션 삭제

**인증 필요**

**응답 (204 No Content)**

---

### `POST /api/tracking/sessions/{session_id}/pause` — 일시정지

**인증 필요** | active 상태에서만 허용

**응답 (200 OK)** → `TrackingSessionDetail`  
`status: "paused"`, `paused_at` 기록됨

---

### `POST /api/tracking/sessions/{session_id}/resume` — 재개

**인증 필요** | paused 상태에서만 허용

**응답 (200 OK)** → `TrackingSessionDetail`  
`status: "active"`, `pause_duration_seconds` 누적됨

---

### `POST /api/tracking/sessions/{session_id}/trash-points` — 실시간 쓰레기 마킹

**인증 필요** | active 또는 paused 상태에서 허용

```json
{
  "lat": 37.5005,
  "lng": 127.0008,
  "category": "cigarette",
  "note": "화단 옆"
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `lat`, `lng` | float | O | 수거 위치 |
| `category` | string | O | 쓰레기 카테고리 |
| `note` | string | X | 메모 |

**응답 (201 Created)**
```json
{
  "id": 1,
  "lat": 37.5005,
  "lng": 127.0008,
  "category": "cigarette",
  "note": "화단 옆",
  "recorded_at": "2026-05-07T10:05:00.000000"
}
```

---

### `GET /api/tracking/sessions/{session_id}/trash-points` — 쓰레기 마커 목록

**인증 필요**

**응답 (200 OK)** → `TrashPointResponse[]`

---

## 장소 검색 API `/api/places`

### `GET /api/places/search` — 네이버 지역 검색

**인증 필요**

> 네이버 지역 검색 API 프록시. `.env`에 `NAVER_CLIENT_ID`, `NAVER_CLIENT_SECRET` 설정 필요.

| 쿼리 파라미터 | 타입 | 필수 | 설명 |
|--------------|------|:----:|------|
| `query` | string | O | 검색어 |
| `display` | int | X | 결과 수 (1~5, 기본 5) |
| `sort` | string | X | `random`(정확도순) \| `comment`(리뷰수순), 기본 `random` |

**응답 (200 OK)**
```json
{
  "query": "한강공원",
  "items": [
    {
      "naver_place_id": "naver:12345",
      "name": "한강공원 반포지구",
      "category": "공원",
      "address": "서울 서초구 반포동",
      "road_address": "서울 서초구 신반포로11길",
      "lat": 37.5097,
      "lng": 126.9983,
      "description": "한강을 따라 조성된 공원",
      "telephone": "02-1234-5678",
      "link": "https://m.place.naver.com/place/12345"
    }
  ]
}
```

| 오류 | 원인 |
|------|------|
| `503 Naver API credentials are not configured` | 환경변수 미설정 |
| `502` | 네이버 API 호출 실패 |

---

## 피드/포스트 API `/api/posts`

### 포스트 타입

| 타입 | images | tracking_id | is_verified | 인증 배지 |
|------|:------:|:-----------:|:-----------:|----------|
| A | ✅ | ✅ | `true` | 🌿 인증 |
| B | ❌ | ✅ | `true` | 🌿 인증 |
| C | ✅ | ❌ | `false` | 없음 |

> `images`와 `tracking_id` 중 하나 이상 필수. 둘 다 없으면 `422`.

### `POST /api/posts` — 포스트 생성

**인증 필요**

```json
{
  "caption": "오늘도 한강 플로깅! 💚",
  "tags": ["플로깅", "환경보호", "한강"],
  "images": ["/uploads/abc123.jpg", "/uploads/def456.jpg"],
  "tracking_id": "2c387795-07ea-4fcb-a8a4-fe6ae3450095"
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `caption` | string | O | 본문 (1~2000자) |
| `tags` | string[] | X | 해시태그 목록 (최대 20개) |
| `images` | string[] | X | 업로드된 이미지 URL 목록 |
| `tracking_id` | string (UUID) | X | 연결할 트래킹 세션 ID |

> `tracking_id`는 본인 소유의 `completed` 세션만 허용.  
> 포스트 생성 시 해당 `TrackingSession.post_id`가 자동으로 설정됩니다.

**응답 (201 Created)** → `PostResponse`

| 오류 | 원인 |
|------|------|
| `404 Tracking session not found` | 세션 없음 또는 타인 소유 |
| `409 트래킹 세션이 아직 완료되지 않았습니다` | completed 아닌 세션 연결 시도 |
| `422` | images, tracking_id 둘 다 없음 |

---

### `GET /api/posts` — 피드 목록

**인증 필요**

| 쿼리 파라미터 | 타입 | 기본값 | 설명 |
|--------------|------|--------|------|
| `limit` | int | 20 | 반환 수 (1~100) |
| `offset` | int | 0 | 시작 위치 |

**응답 (200 OK)**
```json
{
  "items": [ /* PostResponse[] */ ],
  "total": 42,
  "limit": 20,
  "offset": 0
}
```

---

### `GET /api/posts/{post_id}` — 포스트 상세

**인증 필요**

**응답 (200 OK)** → `PostResponse`

---

### `PATCH /api/posts/{post_id}` — 포스트 편집

**인증 필요** | 본인 포스트만

```json
{
  "caption": "수정된 본문",
  "tags": ["플로깅"]
}
```

**응답 (200 OK)** → `PostResponse`

---

### `DELETE /api/posts/{post_id}` — 포스트 삭제

**인증 필요** | 본인 포스트만  
삭제 시 연결된 `TrackingSession.post_id`도 자동 초기화.

**응답 (204 No Content)**

---

### `POST /api/posts/{post_id}/like` — 좋아요

**인증 필요**

**응답 (200 OK)**
```json
{ "liked": true, "like_count": 5 }
```

| 오류 | 원인 |
|------|------|
| `409 이미 좋아요를 눌렀습니다` | 중복 좋아요 |

---

### `DELETE /api/posts/{post_id}/like` — 좋아요 취소

**인증 필요**

**응답 (200 OK)**
```json
{ "liked": false, "like_count": 4 }
```

---

### `GET /api/posts/{post_id}/comments` — 댓글 목록

**인증 필요**

| 쿼리 파라미터 | 기본값 | 설명 |
|---|---|---|
| `limit` | 50 | 최대 수 (1~100) |
| `offset` | 0 | 시작 위치 |

**응답 (200 OK)** → `CommentResponse[]` (오래된 순)

---

### `POST /api/posts/{post_id}/comments` — 댓글 작성

**인증 필요**

```json
{ "content": "멋진 플로깅이네요!" }
```

**응답 (201 Created)** → `CommentResponse`

---

## 댓글 API `/api/comments`

### `PATCH /api/comments/{comment_id}` — 댓글 편집

**인증 필요** | 본인 댓글만

```json
{ "content": "수정된 댓글" }
```

**응답 (200 OK)** → `CommentResponse`

---

### `DELETE /api/comments/{comment_id}` — 댓글 삭제

**인증 필요** | 본인 댓글만  
삭제 시 포스트의 `comment_count` 자동 감소.

**응답 (204 No Content)**

---

## 이미지 업로드 API `/api/images`

### `POST /api/images/upload` — 이미지 업로드

**인증 필요** | `multipart/form-data`

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `file` | file | O | 이미지 파일 |

**지원 포맷**: `jpg`, `jpeg`, `png`, `heic`, `heif`, `webp`

**응답 (201 Created)**
```json
{
  "url": "/uploads/b79831ee-3cc5-4ae2-a36f-20c8be0bc20e.jpg",
  "filename": "b79831ee-3cc5-4ae2-a36f-20c8be0bc20e.jpg"
}
```

> 반환된 `url`을 포스트 생성 시 `images` 배열에 넣어 사용.

| 오류 | 원인 |
|------|------|
| `415` | 지원하지 않는 파일 형식 |
| `400 빈 파일은 업로드할 수 없습니다` | 빈 파일 |

### `GET /uploads/{filename}` — 정적 이미지 서빙

**인증 불필요**

---

## 사용자 API `/api/users`

### `GET /api/users/me/stats` — 내 누적 통계

**인증 필요**

**응답 (200 OK)**
```json
{
  "total_distance_meters": 12500,
  "total_duration_seconds": 5400,
  "total_sessions": 8,
  "total_trash_count": 147
}
```

| 필드 | 설명 |
|------|------|
| `total_distance_meters` | 누적 이동 거리 (미터) |
| `total_duration_seconds` | 누적 활동 시간 (초, pause 제외) |
| `total_sessions` | 완료된 세션 수 |
| `total_trash_count` | 누적 쓰레기 수거 수 (`little`=5, `moderate`=20, `a_lot`=40, `count` 직접값) |

> `completed` 상태 세션만 집계합니다.

---

## 응답 스키마

### UserResponse

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string (UUID) | 사용자 ID |
| `email` | string | 이메일 |
| `name` | string \| null | 표시 이름 |
| `profile_image_url` | string \| null | 프로필 이미지 URL |
| `auth_provider` | string | `email` \| `google` \| `kakao` |

### AuthTokenResponse

| 필드 | 타입 | 설명 |
|------|------|------|
| `access_token` | string | JWT Access Token |
| `refresh_token` | string | JWT Refresh Token |
| `user` | UserResponse | 사용자 정보 |

### TrackingSessionSummary

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string (UUID) | 세션 ID |
| `user_id` | string | 사용자 ID |
| `status` | string | `active` \| `paused` \| `completed` \| `expired` |
| `started_at` | datetime | 시작 시각 |
| `ended_at` | datetime \| null | 종료 시각 |
| `duration_seconds` | int \| null | 순수 활동 시간(초) |
| `paused_at` | datetime \| null | 현재 일시정지 시작 시각 |
| `pause_duration_seconds` | int | 누적 일시정지 시간(초) |
| `distance_meters` | int | 이동 거리(미터) |
| `description` | string \| null | 활동 설명 |
| `place` | PlaceResponse \| null | 활동 장소 |
| `post_id` | string \| null | 연결된 포스트 ID |
| `trash_items` | TrashItem[] | 쓰레기 수거 목록 |
| `created_at` | datetime | 생성 시각 |
| `updated_at` | datetime | 수정 시각 |

### TrackingSessionDetail (`TrackingSessionSummary` 확장)

| 추가 필드 | 타입 | 설명 |
|----------|------|------|
| `start_lat`, `start_lng` | float \| null | 시작 좌표 |
| `end_lat`, `end_lng` | float \| null | 종료 좌표 |
| `points` | TrackingPointResponse[] | GPS 포인트 전체 |

### TrackingPointResponse

| 필드 | 타입 | 설명 |
|------|------|------|
| `lat` | float | 위도 |
| `lng` | float | 경도 |
| `recorded_at` | datetime | 기록 시각 |

### PlaceResponse

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string (UUID) | 내부 장소 ID |
| `naver_place_id` | string | 네이버 장소 ID |
| `name` | string | 장소명 |
| `category` | string \| null | 카테고리 |
| `address` | string \| null | 지번 주소 |
| `road_address` | string \| null | 도로명 주소 |
| `lat`, `lng` | float | 좌표 |

### PostResponse

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string (UUID) | 포스트 ID |
| `user_id` | string | 작성자 ID |
| `caption` | string | 본문 |
| `tags` | string[] | 해시태그 목록 |
| `images` | string[] \| null | 이미지 URL 목록 |
| `tracking_id` | string \| null | 연결된 트래킹 세션 ID |
| `is_verified` | boolean | 트래킹 연결 여부 (인증 배지) |
| `like_count` | int | 좋아요 수 |
| `comment_count` | int | 댓글 수 |
| `share_count` | int | 공유 수 |
| `author` | UserResponse | 작성자 정보 |
| `created_at` | datetime | 작성 시각 |
| `updated_at` | datetime | 수정 시각 |

### CommentResponse

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string (UUID) | 댓글 ID |
| `post_id` | string | 포스트 ID |
| `user_id` | string | 작성자 ID |
| `content` | string | 내용 |
| `author` | UserResponse | 작성자 정보 |
| `created_at` | datetime | 작성 시각 |
| `updated_at` | datetime | 수정 시각 |

---

## 엔드포인트 요약

| 메서드 | 경로 | 인증 | 설명 |
|--------|------|:----:|------|
| `GET` | `/health` | - | 서버 헬스 체크 |
| **Auth** |
| `POST` | `/api/auth/register` | - | 회원가입 |
| `POST` | `/api/auth/login` | - | 로그인 |
| `POST` | `/api/auth/google` | - | Google 로그인 |
| `POST` | `/api/auth/kakao` | - | Kakao 로그인 |
| `POST` | `/api/auth/logout` | O | 로그아웃 |
| `POST` | `/api/auth/find-password` | - | 비밀번호 찾기 |
| `POST` | `/api/auth/refresh` | - | 토큰 갱신 |
| `GET` | `/api/auth/me` | O | 내 정보 조회 |
| **트래킹** |
| `POST` | `/api/tracking/sessions` | O | 세션 시작 |
| `GET` | `/api/tracking/sessions/active` | O | 진행 중 세션 조회 |
| `POST` | `/api/tracking/sessions/{id}/points` | O | GPS 포인트 추가 |
| `POST` | `/api/tracking/sessions/{id}/end` | O | 세션 종료 |
| `GET` | `/api/tracking/sessions` | O | 내 세션 목록 |
| `GET` | `/api/tracking/sessions/{id}` | O | 세션 상세 |
| `PATCH` | `/api/tracking/sessions/{id}` | O | 세션 편집 |
| `DELETE` | `/api/tracking/sessions/{id}` | O | 세션 삭제 |
| `POST` | `/api/tracking/sessions/{id}/pause` | O | 일시정지 |
| `POST` | `/api/tracking/sessions/{id}/resume` | O | 재개 |
| `POST` | `/api/tracking/sessions/{id}/trash-points` | O | 쓰레기 마킹 |
| `GET` | `/api/tracking/sessions/{id}/trash-points` | O | 쓰레기 마커 목록 |
| **장소** |
| `GET` | `/api/places/search` | O | 네이버 지역 검색 |
| **피드/포스트** |
| `POST` | `/api/posts` | O | 포스트 생성 |
| `GET` | `/api/posts` | O | 피드 목록 |
| `GET` | `/api/posts/{id}` | O | 포스트 상세 |
| `PATCH` | `/api/posts/{id}` | O | 포스트 편집 |
| `DELETE` | `/api/posts/{id}` | O | 포스트 삭제 |
| `POST` | `/api/posts/{id}/like` | O | 좋아요 |
| `DELETE` | `/api/posts/{id}/like` | O | 좋아요 취소 |
| `GET` | `/api/posts/{id}/comments` | O | 댓글 목록 |
| `POST` | `/api/posts/{id}/comments` | O | 댓글 작성 |
| **댓글** |
| `PATCH` | `/api/comments/{id}` | O | 댓글 편집 |
| `DELETE` | `/api/comments/{id}` | O | 댓글 삭제 |
| **이미지** |
| `POST` | `/api/images/upload` | O | 이미지 업로드 |
| `GET` | `/uploads/{filename}` | - | 이미지 파일 서빙 |
| **사용자** |
| `GET` | `/api/users/me/stats` | O | 누적 통계 조회 |
