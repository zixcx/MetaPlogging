# FeedPage (피드 화면)

---

## 파일 위치

`lib/features/feed/presentation/pages/feed_page.dart`

---

## 화면 구성 및 데이터

### 앱바

| UI 요소 | 현재 값 | 대체 데이터 |
|---------|---------|-----------|
| 로고 아이콘 | 정적 그린 그래디언트 컨테이너 | 정적 유지 |
| 제목 | `"피드"` | 정적 유지 |
| 검색 아이콘 | `Icons.search_rounded` | 검색 페이지 네비게이션 |

---

### 피드 리스트

| 데이터 | 출처 | 타입 |
|--------|------|------|
| 게시글 목록 | `feedProvider` (Riverpod) | `List<PostEntity>` |
| 초기 데이터 | `kMockPosts` (5개) | 정적 모의 데이터 |

각 `PostEntity`의 상세 필드는 [`post_entity.md`](./post_entity.md) 참조.

---

## 사용자 액션

| 액션 | 컴포넌트 | 결과 |
|------|---------|------|
| 탭 | 검색 아이콘 | `() {}` (미구현) |
| 탭 | 좋아요 | `feedProvider.notifier.toggleLike(post.id)` |
| 탭 | 댓글 | `SnackBar("댓글 기능은 준비 중입니다")` 표시 |
| 탭 | 북마크 | `feedProvider.notifier.toggleBookmark(post.id)` |
| 탭 | FAB (✏️) | `CreatePostSheet` 모달 표시 |
| 스크롤 아래 | 리스트 | `_isFabVisible = false` (FAB 숨김) |
| 스크롤 위 | 리스트 | `_isFabVisible = true` (FAB 표시) |

---

## 로컬 UI 상태

| 변수 | 타입 | 초기값 | 설명 |
|------|------|--------|------|
| `_isFabVisible` | `bool` | `true` | FAB 표시 여부 |
| `_scrollController` | `ScrollController` | - | 스크롤 방향 감지용 |

### FAB 표시 로직

```dart
_scrollController.addListener(() {
  final dir = _scrollController.position.userScrollDirection;
  if (dir == ScrollDirection.reverse)  → _isFabVisible = false
  if (dir == ScrollDirection.forward)  → _isFabVisible = true
});
```

FAB 애니메이션: `AnimatedSlide` + `AnimatedOpacity` (220ms)

---

## 전역 상태 의존성

| Provider | 읽기 방식 | 사용 목적 |
|---------|---------|---------|
| `feedProvider` | `ref.watch()` | 게시글 리스트 구독 |
| `feedProvider.notifier` | `ref.read()` | toggleLike, toggleBookmark 호출 |

---

## 모달 흐름

```
FAB 탭
  └── showModalBottomSheet
        ├── isScrollControlled: true
        ├── useSafeArea: true
        └── CreatePostSheet
              └── 게시 완료 → feedProvider.notifier.addPost(post)
```

---

## API 연결 시 필요한 변경

| 현재 | 연결 후 |
|------|---------|
| `kMockPosts` 정적 초기화 | `GET /posts?feed&page=1` 비동기 로드 |
| 무한 스크롤 없음 | `loadMore()` + `AsyncValue` 상태 관리 |
| pull-to-refresh 없음 | `RefreshIndicator` + `refresh()` 메서드 |

### 필요한 추가 API

| API | 메서드 | 설명 |
|-----|--------|------|
| `GET /posts?feed` | GET | 피드 게시글 목록 (페이지네이션) |
| `POST /posts/{id}/like` | POST | 좋아요 토글 |
| `DELETE /posts/{id}/like` | DELETE | 좋아요 취소 |
| `POST /posts/{id}/bookmark` | POST | 북마크 추가 |
| `DELETE /posts/{id}/bookmark` | DELETE | 북마크 취소 |
