# MetaPlogging 데이터 모델 정의

## 1. 트래킹 세션 (TrackingSession)

플로깅 활동 1회를 나타내는 핵심 데이터.

```
TrackingSession {
  id: string

  // 시간
  started_at: datetime
  ended_at:   datetime
  duration_seconds: int

  // 경로
  distance_meters: int
  path: [
    { lat: float, lng: float, timestamp: datetime }
    ...
  ]
  start_lat: float
  start_lng: float
  end_lat:   float
  end_lng:   float

  // 위치
  location: {
    landmark_id:   string | null   // 랜드마크 DB ID (예: "hangang_banpo")
    landmark_name: string | null   // 표시명 (예: "한강 반포지구")
    description:   string | null   // 사용자 입력 or 자동 생성 (예: "한강 반포지구 산책로")
  }

  // 쓰레기 수거
  trash_items: [TrashItem]

  // 관계
  user_id: string
  post_id: string | null   // 피드 공유 시 연결
}
```

---

## 2. 쓰레기 수거 항목 (TrashItem)

TrackingSession 내 쓰레기 카테고리별 수거 기록.

```
TrashItem {
  category: enum TrashCategory
  amount:   TrashAmount
}

TrashAmount {
  level:  enum('little' | 'moderate' | 'a_lot') | null  // 정도 선택
  count:  int | null                                     // 직접 입력 (개수)
}
// level 또는 count 중 하나만 사용
```

### TrashCategory

| 값 | 표시명 |
|---|---|
| `cigarette` | 담배꽁초 |
| `bottle_can` | 페트병/캔 |
| `plastic_bag` | 비닐/포장지 |
| `large_waste` | 대형 쓰레기 |
| `other` | 기타 |

### 입력 UX 흐름

```
1. 카테고리 선택 (복수 가능)
   [담배꽁초] [페트병/캔] [비닐/포장지] [대형 쓰레기] [기타]

2. 선택한 카테고리마다 수량 입력
   [담배꽁초]    → [조금] [보통] [많이]  /  [개수 직접 입력]
   [페트병/캔]   → [조금] [보통] [많이]  /  [개수 직접 입력]
   ...

   * 정도 선택이 기본 (빠른 입력)
   * '개수 직접 입력' 선택 시 숫자 필드 표시
   * 둘 중 하나만 저장
```

### TrashAmount level 기준 (내부 참고)

| level | 설명 |
|---|---|
| `little` | 1~10개 수준 |
| `moderate` | 11~30개 수준 |
| `a_lot` | 31개 이상 |

> 통계 집계 시 level → 대표값(5 / 20 / 40)으로 변환해 계산

---

## 3. 위치 정보 처리 방식

### 자동 감지 + 사용자 확인 (혼합)

```
트래킹 종료
    ↓
시작/종료 좌표 기반 reverse geocoding
    ↓
주변 랜드마크 감지
    ↓
"한강공원 반포지구 근방에서 활동하셨나요?" [확인] [변경]
    ↓
사용자 확인 or 직접 선택
    ↓
설명 자동 생성: "{landmark_name} 플로깅"
사용자가 편집 가능
```

### 랜드마크 DB (Landmark)

```
Landmark {
  id:       string
  name:     string       // "한강 반포지구"
  category: string       // "river" | "park" | "forest" | "urban" | ...
  lat:      float
  lng:      float
  radius_meters: int     // 해당 랜드마크 감지 반경
}
```

---

## 4. 포스트 (Post)

피드에 공유되는 게시글. 3가지 타입 존재.

```
Post {
  id: string
  user_id: string
  created_at: datetime

  caption: string                  // 글 (필수)
  tags: [string]                   // 해시태그

  images: [string] | null          // 이미지 URL 배열 (선택)
  tracking_id: string | null       // TrackingSession ID (선택)

  // 통계
  like_count:    int
  comment_count: int
  share_count:   int

  // 인증 여부 (tracking_id 존재 여부)
  is_verified: bool  // tracking_id != null
}
```

### 포스트 타입 정의

| 타입 | images | tracking_id | 인증 배지 |
|---|---|---|---|
| A | ✅ | ✅ | 🌿 인증 |
| B | ❌ | ✅ | 🌿 인증 |
| C | ✅ | ❌ | 없음 |

> 글(caption)은 모든 타입에서 필수.
> images와 tracking_id 중 하나는 반드시 존재해야 함.

---

## 5. 사용자 (User)

```
User {
  id:           string
  name:         string
  email:        string
  profile_emoji: string
  created_at:   datetime

  // 게이미피케이션
  level:       int
  total_xp:    int
  badges:      [Badge]

  // 누적 통계 (TrackingSession 집계)
  stats: {
    total_distance_meters: int
    total_duration_seconds: int
    total_sessions: int
    total_trash_count: int   // level 기반 대표값 + count 합산
  }
}
```

---

## 6. CRUD 요약

| 리소스 | Create | Read | Update | Delete |
|---|---|---|---|---|
| TrackingSession | 트래킹 종료 시 | 내 기록 조회, 피드 연결 | 위치/설명 편집 | 삭제 |
| Post | 공유 시 | 피드, 프로필 | 글/태그 편집 | 삭제 |
| User | 회원가입 | 프로필 | 이름/이모지 편집 | 탈퇴 |
| Landmark | (관리자) | 트래킹 종료 시 감지용 | (관리자) | (관리자) |
| Comment | 댓글 작성 | 포스트 상세 | 편집 | 삭제 |
| Like | 좋아요 | - | - | 좋아요 취소 |
