# CreatePostSheet (게시글 작성 시트)

---

## 파일 위치

`lib/features/feed/presentation/widgets/create_post_sheet.dart`

---

## 진입 경로

```
FeedPage FAB (✏️)
  └── showModalBottomSheet
        ├── isScrollControlled: true
        ├── useSafeArea: true
        └── CreatePostSheet
```

---

## 로컬 UI 상태

| 변수 | 타입 | 초기값 | 설명 |
|------|------|--------|------|
| `_captionController` | `TextEditingController` | `""` | 본문 텍스트 입력 |
| `_selectedImages` | `List<String>` | `[]` | 선택된 이미지 mock 키 목록 (최대 3개) |
| `_attachActivity` | `bool` | `false` | 최근 활동 연결 여부 |
| `_isPosting` | `bool` | `false` | 게시 진행 중 (CircularProgressIndicator 표시) |

### 게시 버튼 활성화 조건

```dart
canPost = _captionController.text.isNotEmpty || _selectedImages.isNotEmpty
```

---

## 화면 구성

### 헤더

| UI 요소 | 설명 |
|---------|------|
| 드래그 핸들 | 36×4px 회색 바 |
| "취소" 버튼 | `Navigator.pop()` |
| 제목 | `"새 게시글"` (정적) |
| "게시" 버튼 | `canPost && !_isPosting`일 때만 활성화 |

### 본문 작성 영역

| UI 요소 | 설명 |
|---------|------|
| 아바타 | 40×40 그래디언트 원형, 이모지 `'🌿'` (하드코딩) |
| 작성자명 | `'플로깅 러너'` (하드코딩) |
| 텍스트 필드 | `hintText: "오늘 어떤 플로깅을 했나요?"`, `maxLines: null`, `autofocus: true` |

### 이미지 선택 영역

| 상태 | UI |
|------|-----|
| 이미지 없음 | `_AddImageButton` (80×80 점선 박스) 단독 표시 |
| 이미지 있음 | 선택된 이미지 썸네일(80×80) + `_AddImageButton` 수평 리스트 |
| 3장 선택 시 | `_showImagePicker()` 호출 차단 (max 3) |

#### 이미지 삭제

- 썸네일 우상단 20×20 반투명 검정 원에 `Icons.close`
- 탭 시 `_selectedImages.removeAt(i)`

### 최근 활동 연결 (`_ActivityAttachTile`)

> 현재 **하드코딩된** 단일 활동 데이터 표시

| 필드 | 현재 값 | 타입 |
|------|---------|------|
| 날짜/위치 | `'오늘 07:32 · 한강 반포지구'` | `String` (정적) |
| 통계 요약 | `'3.2km · 24개 수거 · 42분'` | `String` (정적) |
| 아이콘 | `Icons.directions_run_rounded` | - |
| 연결 상태 | `_attachActivity` | `bool` |

#### 연결 상태별 UI 변화

| 상태 | 배경 | 테두리 | 아이콘 |
|------|------|--------|--------|
| `false` | 연한 그린 | 회색 테두리 | `radio_button_unchecked_rounded` |
| `true` | `AppColors.primary × 0.06` | `AppColors.primary × 0.4` | `check_circle_rounded` |

---

## 이미지 선택 흐름 (`_showImagePicker`)

```
_AddImageButton 탭
  └── showModalBottomSheet
        └── _ImagePickerSheet
              ├── GridView(crossAxisCount: 3) — kMockImageStyles (6개)
              └── 탭 → onSelect(key) → Navigator.pop → _selectedImages.add(key)
```

---

## 게시 처리 (`_handlePost`)

### 검증 조건

```dart
if (_captionController.text.isEmpty && _selectedImages.isEmpty) return;
```

### 생성되는 PostEntity

| 필드 | 값 |
|------|-----|
| `id` | `DateTime.now().millisecondsSinceEpoch.toString()` |
| `authorName` | `'플로깅 러너'` (하드코딩) |
| `authorEmoji` | `'🌿'` (하드코딩) |
| `imageMocks` | `List.from(_selectedImages)` |
| `caption` | `_captionController.text` (빈 경우 `null`) |
| `activityStats` | `_attachActivity ? PostActivityStats(3.2, 24, 42) : null` |
| `likeCount` | `0` |
| `commentCount` | `0` |
| `shareCount` | `0` |
| `createdAt` | `DateTime.now()` |
| `locationName` | `_attachActivity ? '한강 반포지구' : null` |

### 게시 후 처리

```dart
ref.read(feedProvider.notifier).addPost(post);
Navigator.pop(context);  // 시트 닫기
```

---

## 전역 상태 의존성

| Provider | 읽기 방식 | 사용 목적 |
|---------|---------|---------|
| `feedProvider.notifier` | `ref.read()` | `addPost(post)` 호출 |

---

## API 연결 시 변경 사항

### 현재 → 연결 후

| 현재 | 연결 후 |
|------|---------|
| `authorName`, `authorEmoji` 하드코딩 | `authProvider`에서 현재 사용자 정보 읽기 |
| `imageMocks` (mock 키) | 실제 이미지 파일 선택 (`image_picker` 패키지) + `POST /media/upload` |
| 활동 데이터 하드코딩 | `GET /activities?limit=5` 로 최근 활동 목록 로드 |
| `id` = timestamp | 서버 응답의 `post.id` 사용 |
| `Future.delayed(400ms)` mock 딜레이 | `POST /posts` 실제 API 호출 |

### 필요한 API

| API | 메서드 | 설명 |
|-----|--------|------|
| `POST /posts` | POST | 게시글 생성 |
| `POST /media/upload` | POST | 이미지 업로드 → `image_url` 반환 |
| `GET /activities?limit=5` | GET | 최근 활동 목록 (활동 연결 UI용) |

#### POST /posts 요청 스키마

```json
{
  "caption": "string | null",
  "image_urls": ["https://..."],
  "activity_id": "act_001 | null",
  "location_name": "string | null"
}
```
