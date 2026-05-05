# PostEntity / PostActivityStats

> 피드 게시글 도메인 엔티티

---

## 파일 위치

`lib/features/feed/domain/entities/post_entity.dart`

---

## PostEntity 필드

| 필드명 | 타입 | 필수 | 기본값 | 설명 |
|--------|------|:----:|--------|------|
| `id` | `String` | ✅ | - | 게시글 고유 ID |
| `authorName` | `String` | ✅ | - | 게시자 표시 이름 |
| `authorEmoji` | `String` | ✅ | - | 게시자 아바타 이모지 (임시. 추후 `authorAvatarUrl`로 교체) |
| `imageMocks` | `List<String>` | ❌ | `[]` | 이미지 키 목록. 현재 `"mock:river"` 형식, 추후 실제 URL |
| `caption` | `String?` | ❌ | `null` | 게시글 본문 텍스트 |
| `activityStats` | `PostActivityStats?` | ❌ | `null` | 첨부된 플로깅 통계 |
| `likeCount` | `int` | ❌ | `0` | 좋아요 수 |
| `commentCount` | `int` | ❌ | `0` | 댓글 수 |
| `shareCount` | `int` | ❌ | `0` | 공유 수 |
| `isLiked` | `bool` | ❌ | `false` | 현재 사용자의 좋아요 여부 (로컬 상태) |
| `isBookmarked` | `bool` | ❌ | `false` | 현재 사용자의 북마크 여부 (로컬 상태) |
| `createdAt` | `DateTime` | ✅ | - | 게시 시각 |
| `locationName` | `String?` | ❌ | `null` | 위치명 (예: `"한강 반포지구"`) |

---

## PostActivityStats 필드

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|:----:|------|
| `distanceKm` | `double` | ✅ | 거리 (km 단위) |
| `trashCount` | `int` | ✅ | 수거한 쓰레기 수 |
| `durationMinutes` | `int` | ✅ | 소요 시간 (분) |

---

## copyWith 지원 필드

```dart
PostEntity copyWith({
  bool? isLiked,
  bool? isBookmarked,
  int? likeCount,
  int? commentCount,
})
```

> ⚠️ `imageMocks`, `caption`, `activityStats`, `locationName`은 불변.
> 이 값들을 수정하는 기능이 필요하면 `copyWith` 확장 필요.

---

## 목업 이미지 시스템 (`kMockImageStyles`)

현재 실제 이미지 URL 없이 그래디언트 컨테이너로 렌더링하는 키-스타일 매핑:

| 키 | 색상 | 아이콘 | 레이블 | 용도 |
|----|------|--------|--------|------|
| `mock:river` | 파란계열 | water | `"한강"` | 강변 활동 |
| `mock:park` | 민트계열 | park | `"공원"` | 공원 활동 |
| `mock:forest` | 녹색계열 | forest | `"숲길"` | 숲 트레일 |
| `mock:sunset` | 주황/빨강 | wb_twilight | `"저녁"` | 저녁 활동 |
| `mock:mountain` | 보라/녹색 | landscape | `"산길"` | 등산 활동 |
| `mock:urban` | 회색계열 | location_city | `"도심"` | 도심 활동 |

---

## Mock 피드 데이터 (`kMockPosts`)

| 게시글 | 작성자 | 이미지 수 | 활동 통계 | 위치 | isLiked |
|--------|--------|:---------:|:---------:|------|:-------:|
| 1 | 초록달리기 🌿 | 2 | ✅ 3.2km/24개/42분 | 한강 반포지구 | ✅ |
| 2 | 에코조거 🏃 | 1 | ✅ 4.8km/36개/58분 | 서울숲 | ❌ |
| 3 | 숲속러너 🌲 | 3 | ❌ 없음 | 올림픽공원 | ❌ |
| 4 | 강변워커 🚶 | 1 | ✅ 2.1km/18개/28분 | 여의도 한강공원 | ✅ |
| 5 | 플로러 ⛰️ | 2 | ✅ 6.4km/52개/95분 | 북한산 등산로 | ❌ |

---

## 실제 API 연결 시 변경 사항

### 현재 → 교체 대상

| 현재 필드 | 교체 필드 | 설명 |
|-----------|-----------|------|
| `authorEmoji: String` | `authorId: String` + `authorAvatarUrl: String?` | 실제 사용자 참조 |
| `imageMocks: List<String>` (mock:키) | `imageUrls: List<String>` (https:// URL) | 실제 이미지 URL |

### 필요한 추가 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `authorId` | `String` | 작성자 사용자 ID |
| `authorAvatarUrl` | `String?` | 작성자 프로필 이미지 URL |
| `tags` | `List<String>` | 해시태그 목록 (`["한강공원", "플로깅"]`) |
| `activityId` | `String?` | 연결된 플로깅 활동 ID |

### 예상 API 응답 JSON

```json
{
  "id": "post_abc123",
  "author": {
    "id": "usr_001",
    "name": "초록달리기",
    "avatar_url": "https://cdn.example.com/avatars/usr_001.jpg"
  },
  "image_urls": [
    "https://cdn.example.com/posts/img1.jpg",
    "https://cdn.example.com/posts/img2.jpg"
  ],
  "caption": "오늘 한강 공원에서 플로깅 완료!",
  "activity": {
    "id": "act_001",
    "distance_km": 3.2,
    "trash_count": 24,
    "duration_minutes": 42,
    "location_name": "한강 반포지구"
  },
  "like_count": 48,
  "comment_count": 12,
  "share_count": 5,
  "is_liked": true,
  "is_bookmarked": false,
  "created_at": "2026-05-05T07:32:00Z",
  "tags": ["한강공원", "플로깅", "환경보호"]
}
```
