import uuid
from datetime import datetime
from zoneinfo import ZoneInfo

from sqlalchemy import (
    JSON,
    Column,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
)
from sqlalchemy.orm import relationship

from app.core.database import Base

KST = ZoneInfo("Asia/Seoul")


SESSION_STATUS_ACTIVE = "active"
SESSION_STATUS_PAUSED = "paused"
SESSION_STATUS_COMPLETED = "completed"
SESSION_STATUS_EXPIRED = "expired"


class TrackingSession(Base):
    __tablename__ = "tracking_sessions"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)

    status = Column(String, nullable=False, default=SESSION_STATUS_ACTIVE, index=True)

    started_at = Column(DateTime, nullable=False, default=lambda: datetime.now(KST))
    ended_at = Column(DateTime, nullable=True)
    duration_seconds = Column(Integer, nullable=True)

    paused_at = Column(DateTime, nullable=True)
    pause_duration_seconds = Column(Integer, nullable=False, default=0)

    distance_meters = Column(Integer, nullable=False, default=0)

    start_lat = Column(Float, nullable=True)
    start_lng = Column(Float, nullable=True)
    end_lat = Column(Float, nullable=True)
    end_lng = Column(Float, nullable=True)

    place_id = Column(String, ForeignKey("places.id"), nullable=True)
    description = Column(String, nullable=True)

    # 쓰레기 수거 항목 — 카테고리별 amount(level/count) 리스트
    # [{"category": "cigarette", "amount": {"level": "moderate", "count": null}}, ...]
    trash_items = Column(JSON, nullable=False, default=list)

    # 피드 공유 시 연결되는 post id (FK 없이 문자열만 저장, 순환 참조 방지)
    post_id = Column(String, nullable=True)

    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(KST))
    updated_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(KST),
        onupdate=lambda: datetime.now(KST),
    )

    place = relationship("Place", lazy="joined")
    points = relationship(
        "TrackingPoint",
        back_populates="session",
        cascade="all, delete-orphan",
        order_by="TrackingPoint.recorded_at",
    )
    trash_points = relationship(
        "TrashPoint",
        back_populates="session",
        cascade="all, delete-orphan",
        order_by="TrashPoint.recorded_at",
    )


class TrackingPoint(Base):
    __tablename__ = "tracking_points"

    id = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(
        String,
        ForeignKey("tracking_sessions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    recorded_at = Column(DateTime, nullable=False)

    session = relationship("TrackingSession", back_populates="points")


class TrashPoint(Base):
    __tablename__ = "trash_points"

    id = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(
        String,
        ForeignKey("tracking_sessions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    category = Column(String, nullable=False)
    note = Column(String, nullable=True)
    recorded_at = Column(DateTime, nullable=False, default=lambda: datetime.now(KST))

    session = relationship("TrackingSession", back_populates="trash_points")
