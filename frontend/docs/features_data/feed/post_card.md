# PostCard (게시글 카드 위젯)

---

## 파일 위치

`lib/features/feed/presentation/widgets/post_card.dart`

---

## 위젯 계층

```
PostCard (StatefulWidget)
├── _AuthorRow (StatelessWidget)
├── _ImageCarousel (StatefulWidget) — 이미지 있을 때만
│   ├── PageView.builder
│   │   └── _MockImageWidget (StatelessWidget)
│   └── Row(_PageDot × n) — 2장 이상일 때만
├── _ActivityPills (StatelessWidget) — activityStats 있을 때만
│   └── _Pill × 3
├── _Caption (StatelessWidget) — caption 있을 때만
└── _ActionBar (StatelessWidget)
```

---

## PostCard Props

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|:----:|------|
| `post` | `PostEntity` | ✅ | 렌더링할 게시글 |
| `onLike` | `VoidCallback` | ✅ | 좋아요 버튼 탭 콜백 |
| `onComment` | `VoidCallback` | ✅ | 댓글 버튼 탭 콜백 |
| `onBookmark` | `VoidCallback` | ✅ | 북마크 버튼 탭 콜백 |

---

## 로컬 UI 상태 (`_PostCardState`)

| 변수 | 타입 | 초기값 | 설명 |
|------|------|--------|------|
| `_isExpanded` | `bool` | `false` | 캡션 더보기 펼침 여부 |
| `_heartController` | `AnimationController` | - | 좋아요 하트 바운스 애니메이션 컨트롤러 |
| `_heartScale` | `Animation<double>` | - | TweenSequence: 1.0→1.35→1.0 (180ms) |

---

## _AuthorRow 표시 데이터

| 데이터 | 출처 | 표시 형태 |
|--------|------|-----------|
| 아바타 | `post.authorEmoji` | 40×40 원형 그래디언트 컨테이너 안 이모지 |
| 작성자명 | `post.authorName` | `titleSmall`, fontWeight w700 |
| 작성 시각 | `post.createdAt` | `_timeAgo()` 변환 (분/시간/일/주 전) |
| 위치 | `post.locationName` | null이면 미표시, 있으면 `·` 구분자로 표시 |
| 더보기 메뉴 | - | `Icons.more_horiz_rounded` (미구현, `() {}`) |

### `_timeAgo()` 변환 규칙

| 조건 | 출력 |
|------|------|
| 60분 미만 | `N분 전` |
| 24시간 미만 | `N시간 전` |
| 7일 미만 | `N일 전` |
| 7일 이상 | `N주 전` |

---

## _ImageCarousel 표시 데이터

| 데이터 | 출처 | 설명 |
|--------|------|------|
| 이미지 목록 | `post.imageMocks` | mock 키 목록, `kMockImageStyles` 매핑으로 렌더링 |
| 현재 페이지 | `_currentPage` (로컬) | 페이지 닷 강조 표시용 |

### 레이아웃

- `AspectRatio: 4/3`
- 가로 패딩 없음 (edge-to-edge)
- 라운딩 없음 (`ClipRRect` 미적용)
- 2장 이상 시 하단 페이지 닷 표시

### _PageDot 상태

| 상태 | 너비 | 색상 |
|------|------|------|
| 활성 | 16px | `AppColors.primary` |
| 비활성 | 6px | `0xFFCDD6D0` |
| 전환 | `AnimatedContainer` 200ms | - |

### _MockImageWidget 렌더링 (API 연결 전)

- `kMockImageStyles[mockKey]`에서 `colors`, `icon`, `label` 조회
- `LinearGradient` 배경 + 반투명 아이콘(alpha 0.15) + 좌하단 레이블 칩

---

## _ActivityPills 표시 데이터

`post.activityStats`가 null이 아닐 때만 렌더링:

| 필 | 아이콘 | 출처 필드 | 색상 |
|----|--------|-----------|------|
| 거리 | `route_rounded` | `stats.distanceKm` → `"Xkm"` | `AppColors.primary` |
| 수거량 | `delete_outline_rounded` | `stats.trashCount` → `"X개 수거"` | `AppColors.secondary` |
| 소요 시간 | `timer_outlined` | `stats.durationMinutes` → `"X분"` | `AppColors.accent` |

---

## _Caption 표시 데이터

`post.caption`이 null이 아닐 때만 렌더링:

| 상태 | 동작 |
|------|------|
| 3줄 이하 or `_isExpanded == true` | 전체 텍스트 표시 |
| 3줄 초과 (`_isExpanded == false`) | 3줄 + `...` + `"더보기"` 버튼 |

**오버플로 감지**: `LayoutBuilder` + `TextPainter.didExceedMaxLines` (maxLines: 3)

---

## _ActionBar 표시 데이터

| 버튼 | 아이콘 | 카운트 출처 | 활성 색상 | 비활성 색상 |
|------|--------|------------|----------|------------|
| 좋아요 | `favorite_rounded` / `favorite_border_rounded` | `post.likeCount` | `0xFFFF4757` | `onSurfaceVariant` |
| 댓글 | `chat_bubble_outline_rounded` | `post.commentCount` | - | `onSurfaceVariant` |
| 공유 | `ios_share_rounded` | `post.shareCount` | - | `onSurfaceVariant` |
| 북마크 | `bookmark_rounded` / `bookmark_border_rounded` | - (카운트 없음) | `AppColors.primary` | `onSurfaceVariant` |

### 좋아요 애니메이션

- `_handleLike()` → `_heartController.forward(from: 0)`
- `ScaleTransition` 으로 아이콘 1.0 → 1.35 → 1.0 (180ms)
- 실제 상태 변경은 `widget.onLike()` 콜백 (FeedNotifier)

---

## PostEntity 필드 → 렌더링 매핑 요약

| PostEntity 필드 | 사용 위젯 | 렌더링 |
|----------------|-----------|--------|
| `authorEmoji` | `_AuthorRow` | 아바타 이모지 |
| `authorName` | `_AuthorRow` | 작성자명 |
| `createdAt` | `_AuthorRow` | 상대 시각 |
| `locationName` | `_AuthorRow` | 위치 태그 (null 허용) |
| `imageMocks` | `_ImageCarousel` | 이미지 배경 (mock 키) |
| `activityStats` | `_ActivityPills` | 거리/수거/시간 필 |
| `caption` | `_Caption` | 본문 텍스트 |
| `likeCount` | `_ActionBar` | 좋아요 수 |
| `commentCount` | `_ActionBar` | 댓글 수 |
| `shareCount` | `_ActionBar` | 공유 수 |
| `isLiked` | `_ActionBar` | 하트 아이콘 상태/색상 |
| `isBookmarked` | `_ActionBar` | 북마크 아이콘 상태/색상 |

---

## API 연결 시 변경 사항

| 현재 | 연결 후 |
|------|---------|
| `authorEmoji` → 이모지 아바타 | `authorAvatarUrl` → `Image.network()` 또는 `CachedNetworkImage` |
| `imageMocks` (mock 키) → gradient | `imageUrls` (https URL) → `Image.network()` |
| `_timeAgo()` 로컬 계산 | 서버 `created_at` 기반 동일 로직 유지 |
| 공유 버튼 미구현 (`() {}`) | 실제 공유 기능 구현 필요 |
| 더보기 메뉴 미구현 (`() {}`) | 신고/삭제/수정 바텀시트 |
