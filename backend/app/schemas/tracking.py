from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field, model_validator

from app.schemas.place import PlaceInput, PlaceResponse


class TrashCategory(str, Enum):
    CIGARETTE = "cigarette"
    BOTTLE_CAN = "bottle_can"
    PLASTIC_BAG = "plastic_bag"
    LARGE_WASTE = "large_waste"
    OTHER = "other"


class TrashLevel(str, Enum):
    LITTLE = "little"
    MODERATE = "moderate"
    A_LOT = "a_lot"


class TrashAmount(BaseModel):
    level: Optional[TrashLevel] = None
    count: Optional[int] = Field(default=None, ge=0)

    @model_validator(mode="after")
    def _check_one_of(self) -> "TrashAmount":
        if self.level is None and self.count is None:
            raise ValueError("level 또는 count 중 하나는 입력해야 합니다")
        if self.level is not None and self.count is not None:
            raise ValueError("level 과 count 는 동시에 입력할 수 없습니다")
        return self


class TrashItem(BaseModel):
    category: TrashCategory
    amount: TrashAmount


# ── Tracking points ────────────────────────────────────────────────────────────

class TrackingPointInput(BaseModel):
    lat: float
    lng: float
    recorded_at: datetime


class TrackingPointResponse(BaseModel):
    lat: float
    lng: float
    recorded_at: datetime

    class Config:
        from_attributes = True


# ── Sessions ───────────────────────────────────────────────────────────────────

class StartSessionRequest(BaseModel):
    start_lat: Optional[float] = None
    start_lng: Optional[float] = None


class AddPointsRequest(BaseModel):
    points: List[TrackingPointInput] = Field(..., min_length=1)


class EndSessionRequest(BaseModel):
    trash_items: List[TrashItem] = Field(default_factory=list)
    place: Optional[PlaceInput] = None
    description: Optional[str] = None
    end_lat: Optional[float] = None
    end_lng: Optional[float] = None
    # 종료 직전 마지막 포인트들을 같이 보낼 수 있음 (선택)
    final_points: Optional[List[TrackingPointInput]] = None


class UpdateSessionRequest(BaseModel):
    place: Optional[PlaceInput] = None
    description: Optional[str] = None


class TrackingSessionSummary(BaseModel):
    id: str
    user_id: str
    status: str
    started_at: datetime
    ended_at: Optional[datetime] = None
    duration_seconds: Optional[int] = None
    paused_at: Optional[datetime] = None
    pause_duration_seconds: int = 0
    distance_meters: int
    description: Optional[str] = None
    place: Optional[PlaceResponse] = None
    post_id: Optional[str] = None
    trash_items: List[TrashItem] = Field(default_factory=list)
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class TrackingSessionDetail(TrackingSessionSummary):
    start_lat: Optional[float] = None
    start_lng: Optional[float] = None
    end_lat: Optional[float] = None
    end_lng: Optional[float] = None
    points: List[TrackingPointResponse] = Field(default_factory=list)


class AddPointsResponse(BaseModel):
    accepted: int
    distance_meters: int


# ── Trash points (real-time markers) ──────────────────────────────────────────

class TrashPointInput(BaseModel):
    lat: float
    lng: float
    category: TrashCategory
    note: Optional[str] = None


class TrashPointResponse(BaseModel):
    id: int
    lat: float
    lng: float
    category: TrashCategory
    note: Optional[str] = None
    recorded_at: datetime

    class Config:
        from_attributes = True


# ── User stats ─────────────────────────────────────────────────────────────────

class UserStatsResponse(BaseModel):
    total_distance_meters: int
    total_duration_seconds: int
    total_sessions: int
    total_trash_count: int
