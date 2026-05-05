# LandingPage (랜딩 화면)

> 앱 최초 진입 시 표시되는 온보딩/소개 화면

---

## 파일 위치

`lib/features/auth/presentation/pages/landing_page.dart`

---

## 화면 구성 데이터

### 정적 텍스트

| UI 요소 | 값 | 비고 |
|---------|----|------|
| 앱 이름 | `"MetaPlogging"` | 로고 이미지 + 텍스트 |
| 메인 태그라인 | `"걷고, 줍고, 기록하다.\n우리가 만드는 더 깨끗한 환경."` | - |
| 특징 1 | `"환경 기여"` | Icons.eco_rounded |
| 특징 2 | `"사진 기록"` | Icons.camera_alt_rounded |
| 특징 3 | `"활동 지도"` | Icons.map_rounded |
| CTA 제목 | `"지금 시작하세요"` | - |
| CTA 설명 | `"플로깅으로 환경을 지키고 건강도 챙기세요."` | - |
| 약관 안내 | `"가입 시 이용약관 및 개인정보처리방침에 동의합니다."` | - |

### 에셋

| 에셋 | 경로 | 용도 |
|------|------|------|
| 로고 이미지 | `lib/shared/assets/ploggin_logo.png` | 히어로 섹션 상단 |

---

## 사용자 액션

| 액션 | 컴포넌트 | 결과 |
|------|---------|------|
| 탭 | "함께 플로깅 시작하기" (FilledButton) | `context.push(AppRoutes.register)` |
| 탭 | "이미 계정이 있어요" (TextButton) | `context.push(AppRoutes.login)` |

---

## 로컬 UI 상태

| 상태 변수 | 타입 | 설명 |
|-----------|------|------|
| `_heroCtrl` | `AnimationController` | 히어로 섹션 진입 애니메이션 (800ms) |
| `_ctaCtrl` | `AnimationController` | CTA 섹션 진입 애니메이션 (600ms, 300ms delay) |
| `_logoOpacity` | `Animation<double>` | 로고 페이드인 |
| `_logoOffset` | `Animation<Offset>` | 로고 슬라이드업 |
| `_titleOpacity` | `Animation<double>` | 타이틀 페이드인 |
| `_titleOffset` | `Animation<Offset>` | 타이틀 슬라이드업 |
| `_featuresOpacity` | `Animation<double>` | 특징 목록 페이드인 |
| `_featuresOffset` | `Animation<Offset>` | 특징 목록 슬라이드업 |
| `_ctaOpacity` | `Animation<double>` | CTA 버튼 페이드인 |
| `_ctaOffset` | `Animation<Offset>` | CTA 버튼 슬라이드업 |

---

## 외부 의존성

| 의존성 | 종류 | 구현 상태 |
|--------|------|----------|
| `authProvider` | Riverpod | 리다이렉트 용도 (AppRouter에서 처리) |
| `GoRouter` | 라이브러리 | 페이지 네비게이션 |
| `ploggin_logo.png` | 에셋 | ✅ 존재 |

---

## 네비게이션 흐름

```
LandingPage
├── "함께 플로깅 시작하기" → RegisterPage
└── "이미 계정이 있어요" → LoginPage
```

---

## 필요한 추가 데이터 (없음)

이 페이지는 완전한 정적 페이지로 추가 데이터 필요 없음.
