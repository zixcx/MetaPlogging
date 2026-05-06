from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.tracking import SESSION_STATUS_COMPLETED, TrackingSession
from app.models.user import User
from app.schemas.tracking import UserStatsResponse

router = APIRouter(prefix="/users", tags=["users"])


# level → 대표값 (data-model.md 명세)
TRASH_LEVEL_VALUES = {
    "little": 5,
    "moderate": 20,
    "a_lot": 40,
}


def _trash_count(items: list | None) -> int:
    if not items:
        return 0
    total = 0
    for item in items:
        amount = (item or {}).get("amount") or {}
        count = amount.get("count")
        if count is not None:
            total += int(count)
            continue
        level = amount.get("level")
        if level in TRASH_LEVEL_VALUES:
            total += TRASH_LEVEL_VALUES[level]
    return total


@router.get("/me/stats", response_model=UserStatsResponse)
def get_my_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    base = db.query(TrackingSession).filter(
        TrackingSession.user_id == current_user.id,
        TrackingSession.status == SESSION_STATUS_COMPLETED,
    )

    agg = base.with_entities(
        func.coalesce(func.sum(TrackingSession.distance_meters), 0),
        func.coalesce(func.sum(TrackingSession.duration_seconds), 0),
        func.count(TrackingSession.id),
    ).one()
    total_distance, total_duration, total_sessions = agg

    trash_total = 0
    for (items,) in base.with_entities(TrackingSession.trash_items).all():
        trash_total += _trash_count(items)

    return UserStatsResponse(
        total_distance_meters=int(total_distance or 0),
        total_duration_seconds=int(total_duration or 0),
        total_sessions=int(total_sessions or 0),
        total_trash_count=trash_total,
    )
