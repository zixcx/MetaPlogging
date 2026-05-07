from contextlib import asynccontextmanager
from datetime import datetime
from zoneinfo import ZoneInfo

KST = ZoneInfo("Asia/Seoul")

from pathlib import Path

import uvicorn
from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text

from app.core.database import Base, SessionLocal, engine
from app.core.config import settings
# Import models so Base.metadata.create_all picks them up
from app.models import user as _user_model  # noqa: F401
from app.models import place as _place_model  # noqa: F401
from app.models import tracking as _tracking_model  # noqa: F401
from app.models import post as _post_model  # noqa: F401
from api.v1.auth import router as auth_router
from api.v1.tracking import router as tracking_router
from api.v1.places import router as places_router
from api.v1.users import router as users_router
from api.v1.posts import router as posts_router
from api.v1.comments import router as comments_router
from api.v1.images import router as images_router


def _run_lightweight_migrations() -> None:
    """SQLAlchemy create_all 이 처리하지 못하는 컬럼 추가를 보강한다 (SQLite 한정)."""
    pending = [
        ("tracking_sessions", "paused_at", "DATETIME"),
        ("tracking_sessions", "pause_duration_seconds", "INTEGER NOT NULL DEFAULT 0"),
        ("tracking_sessions", "post_id", "VARCHAR"),
    ]
    with engine.begin() as conn:
        for table, column, ddl in pending:
            existing = {row[1] for row in conn.exec_driver_sql(f"PRAGMA table_info({table})")}
            if column not in existing:
                conn.exec_driver_sql(f"ALTER TABLE {table} ADD COLUMN {column} {ddl}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    Path(settings.UPLOAD_DIR).mkdir(parents=True, exist_ok=True)
    Base.metadata.create_all(bind=engine)
    _run_lightweight_migrations()
    yield


app = FastAPI(
    title="MetaPlogging API",
    version="1.0.0",
    description="Backend API for the MetaPlogging plogging application",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/api")
app.include_router(tracking_router, prefix="/api")
app.include_router(places_router, prefix="/api")
app.include_router(users_router, prefix="/api")
app.include_router(posts_router, prefix="/api")
app.include_router(comments_router, prefix="/api")
app.include_router(images_router, prefix="/api")

# uploads 디렉토리가 없으면 미리 생성 (StaticFiles mount 는 디렉토리 존재 필요)
Path(settings.UPLOAD_DIR).mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")


@app.get("/health", tags=["health"])
def health_check():
    db_status = "ok"
    db_error: str | None = None
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
    except Exception as exc:
        db_status = "error"
        db_error = str(exc)

    overall = "ok" if db_status == "ok" else "degraded"
    payload = {
        "status": overall,
        "timestamp": datetime.now(KST).isoformat(),
        "version": app.version,
        "checks": {
            "database": {"status": db_status, **({"error": db_error} if db_error else {})},
        },
    }
    http_status = status.HTTP_200_OK if overall == "ok" else status.HTTP_503_SERVICE_UNAVAILABLE
    return JSONResponse(content=payload, status_code=http_status)


if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=3000, reload=True)
