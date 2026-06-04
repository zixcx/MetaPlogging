# 서버 운영 가이드

## 구성

| 항목 | 내용 |
|------|------|
| 앱 서버 | FastAPI (uvicorn), 포트 8000 |
| DB | PostgreSQL 17 (Docker 컨테이너) |
| 프로세스 관리 | systemd |
| 데이터 저장 | `/data/projects/MetaPlogging/backend/postgres-data/` |

---

## 최초 설치 (서버 세팅 시 1회)

```bash
# 1. 서비스 파일 등록
sudo cp /data/projects/MetaPlogging/backend/metaplogging.service /etc/systemd/system/

# 2. systemd 리로드
sudo systemctl daemon-reload

# 3. 부팅 시 자동 시작 활성화
sudo systemctl enable metaplogging

# 4. 서비스 시작
sudo systemctl start metaplogging
```

---

## 서버 관리

```bash
# 시작
sudo systemctl start metaplogging

# 중지
sudo systemctl stop metaplogging

# 재시작
sudo systemctl restart metaplogging

# 상태 확인
sudo systemctl status metaplogging
```

---

## 로그

```bash
# 실시간 로그 스트리밍
journalctl -u metaplogging -f

# 최근 100줄
journalctl -u metaplogging -n 100

# 오늘 로그
journalctl -u metaplogging --since today

# 특정 시간 이후 로그
journalctl -u metaplogging --since "2026-05-21 00:00:00"
```

---

## DB 관리

```bash
# PostgreSQL 컨테이너 상태 확인
docker compose ps

# PostgreSQL 접속 (psql)
docker compose exec db psql -U metaplogging

# DB 백업
docker compose exec db pg_dump -U metaplogging metaplogging > backup_$(date +%Y%m%d).sql

# DB 복원
docker compose exec -T db psql -U metaplogging metaplogging < backup_20260521.sql
```

---

## 코드 배포

```bash
cd /data/projects/MetaPlogging/backend

# 코드 Pull
git pull

# 의존성 변경이 있을 때
uv sync

# 서버 재시작
sudo systemctl restart metaplogging
```

---

## 트러블슈팅

### 서비스가 시작되지 않을 때
```bash
# 상세 오류 확인
journalctl -u metaplogging -n 50 --no-pager
```

### PostgreSQL 연결 실패 시
```bash
# 컨테이너 상태 확인
docker compose ps

# 컨테이너 재시작
docker compose restart db
sudo systemctl restart metaplogging
```

### 포트 충돌 시
```bash
# 8000 포트 사용 프로세스 확인
ss -tlnp | grep 8000
```
