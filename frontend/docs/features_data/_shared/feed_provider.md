# FeedProvider (전역 피드 상태)

> 피드 게시글 목록 및 상호작용 상태를 관리하는 Riverpod Notifier

---

## 파일 위치

| 파일 | 경로 |
|------|------|
| Provider | `lib/features/feed/presentation/providers/feed_provider.dart` |
| 생성 코드 | `lib/features/feed/presentation/providers/feed_provider.g.dart` |

---

## 상태 타입

```dart
List<PostEntity>
```

- 초기값: `kMockPosts` (5개 샘플 게시글)
- `AutoDispose`: 탭에서 벗어나도 상태 유지 (AutoDispose 적용 중 — 탭 재진입 시 초기화됨)

> ⚠️ 현재 `@riverpod`의 기본 `autoDispose: true`가 적용되어 있음.  
> 피드 상태를 영속적으로 유지하려면 `@Riverpod(keepAlive: true)`로 변경 필요.

---

## 메서드

### `toggleLike(String postId)`

| 항목 | 내용 |
|------|------|
| 입력 | `postId` — 게시글 고유 ID |
| 동작 | `isLiked` 토글, `likeCount` ±1 |
| 상태 업데이트 | 불변 리스트 재생성 (for-if comprehension) |
| 호출 위치 | `FeedPage` → `PostCard.onLike` 콜백 |
| 서버 동기화 | ❌ 미구현 (로컬만) |

### `toggleBookmark(String postId)`

| 항목 | 내용 |
|------|------|
| 입력 | `postId` |
| 동작 | `isBookmarked` 토글 |
| 호출 위치 | `FeedPage` → `PostCard.onBookmark` 콜백 |
| 서버 동기화 | ❌ 미구현 |

### `addPost(PostEntity post)`

| 항목 | 내용 |
|------|------|
| 입력 | 새로 생성된 `PostEntity` |
| 동작 | 리스트 맨 앞에 삽입 (최신 순) |
| 호출 위치 | `CreatePostSheet` 게시 버튼 |
| 서버 동기화 | ❌ 미구현 (로컬만) |

---

## 상태 업데이트 패턴

```dart
// 불변 업데이트 (Dart collection-if)
state = [
  for (final post in state)
    if (post.id == targetId)
      post.copyWith(/* 변경값 */)
    else
      post,
];
```

---

## API 연결 계획

| 현재 | 연결 후 |
|------|---------|
| `kMockPosts` 정적 초기화 | `GET /posts?type=feed&page=1` 페이지네이션 |
| `toggleLike` 로컬만 | `POST /posts/{id}/like` + 낙관적 업데이트 |
| `toggleBookmark` 로컬만 | `POST /posts/{id}/bookmark` |
| `addPost` 로컬만 | `POST /posts` 업로드 후 응답으로 추가 |

---

## 추가로 필요한 메서드 (미구현)

| 메서드 | 설명 |
|--------|------|
| `loadMore()` | 무한 스크롤 페이지네이션 |
| `refresh()` | 피드 새로고침 (pull-to-refresh) |
| `deletePost(postId)` | 내 게시글 삭제 |
| `reportPost(postId)` | 게시글 신고 |
