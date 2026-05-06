# Backend

FastAPI 기반 MetaPlogging 백엔드 서버입니다.

## 기술 스택

| 항목 | 내용 |
|------|------|
| 언어 | Python 3.13+ |
| 프레임워크 | FastAPI |
| DB | SQLite (SQLAlchemy ORM) |
| 인증 | JWT (Access 30분 / Refresh 30일) |
| 패키지 관리 | uv |

## 실행 방법

### 1. 환경 변수 설정

```bash
cd backend
cp .env.example .env
```

`.env` 파일을 열고 값을 채웁니다.

```env
SECRET_KEY=길고-랜덤한-문자열
DATABASE_URL=sqlite:///./metaplogging.db
GOOGLE_CLIENT_ID=구글-클라이언트-ID  # Google 로그인 미사용 시 생략 가능
```

### 2. 의존성 설치 및 서버 실행

```bash
uv sync
uv run uvicorn app.main:app --host 0.0.0.0 --port 3000 --reload
```

서버가 뜨면 `http://localhost:3000` 에서 접근 가능합니다.

## 확인

- 헬스 체크: `GET http://localhost:3000/health`
- API 문서 (Swagger): `http://localhost:3000/docs`
- API 명세서: [`docs/API.md`](./API.md)
