# MetaPlogging — 기능별 데이터 요구사항 문서

> 현재 구현된 각 페이지의 데이터 구조, 상태 관리, 외부 의존성, API 연결 계획을 정리합니다.
> 분석 기준일: 2026-05-05

---

## 폴더 구조

```
docs/features_data/
├── README.md                     ← 이 파일 (전체 개요)
├── _shared/
│   ├── user_entity.md            ← UserEntity / UserModel
│   ├── auth_provider.md          ← AuthNotifier (전역 인증 상태)
│   └── feed_provider.md          ← FeedNotifier (전역 피드 상태)
├── auth/
│   ├── landing_page.md
│   ├── login_page.md
│   ├── register_page.md
│   └── find_account_page.md
├── home/
│   └── home_page.md
├── feed/
│   ├── feed_page.md
│   ├── post_entity.md            ← PostEntity / PostActivityStats
│   ├── post_card.md
│   └── create_post_sheet.md
├── plogging/
│   └── plogging_page.md
└── profile/
    └── profile_page.md
```

---

## 현황 요약

| 기능 | 페이지 | 구현 상태 | 데이터 상태 | API 필요 |
|------|--------|-----------|-------------|---------|
| 랜딩 | LandingPage | ✅ 완성 | 정적 | 없음 |
| 로그인 | LoginPage | ✅ 완성 | 폼 입력 | ✅ 필요 |
| 회원가입 | RegisterPage | ✅ 완성 | 폼 입력 | ✅ 필요 |
| 비밀번호 찾기 | FindAccountPage | ⚠️ 스텁 | 없음 | ✅ 필요 |
| 홈 | HomePage | ✅ 완성 | 모의 데이터 | ✅ 필요 |
| 피드 | FeedPage | ✅ 완성 | 모의 데이터 | ✅ 필요 |
| 플로깅 | PloggingPage | ⚠️ 부분 구현 | 모의 데이터 | ✅ 필요 |
| 프로필 | ProfilePage | ✅ 완성 | 모의 데이터 | ✅ 필요 |

---

## 전역 데이터 흐름

```
┌──────────────────────────────────────────────────────────┐
│                    authProvider                          │
│         AsyncValue<UserEntity?>  (Riverpod 전역)         │
│                                                          │
│  null = 미로그인 → /auth/landing 리다이렉트              │
│  UserEntity = 로그인됨 → / (홈) 접근 가능                │
└─────────────────────────┬────────────────────────────────┘
                          │ UserEntity
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
      HomePage        ProfilePage     (전체 탭)
    (사용자명 등)     (프로필 표시)   (인증 게이팅)

┌──────────────────────────────────────────────────────────┐
│                    feedProvider                          │
│         List<PostEntity>  (Riverpod 전역)                │
│                                                          │
│  초기값: kMockPosts (5개)                                │
│  toggleLike / toggleBookmark / addPost                   │
└─────────────────────────┬────────────────────────────────┘
                          │
                    FeedPage → PostCard
                          │
                    CreatePostSheet (addPost 호출)
```

---

## 현재 모의(Mock) 데이터 목록

| 위치 | 데이터 | 대체 필요 API |
|------|--------|---------------|
| `homepage.dart` | 총 거리, 수거량, 활동 횟수, 주간 차트, 최근 활동 3개 | `GET /users/{id}/stats`, `GET /activities?limit=3` |
| `post_entity.dart` | kMockPosts (5개 게시글) | `GET /posts?feed` |
| `profile_page.dart` | 닉네임, 이메일, 통계, 레벨/XP, 배지 | `GET /users/{id}/profile` |
| `create_post_sheet.dart` | 최근 활동 1개 (하드코딩) | `GET /activities?limit=5` |
| `plogging_page.dart` | 지도 플레이스홀더, 실시간 통계 0 | GPS API, `POST /activities` |
