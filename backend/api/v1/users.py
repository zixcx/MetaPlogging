from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.tracking import (
    SESSION_STATUS_ACTIVE,
    SESSION_STATUS_COMPLETED,
    SESSION_STATUS_PAUSED,
    TrackingSession,
)
from app.models.user import User
from app.schemas.tracking import (
    PlatformStatsResponse,
    UserStatsEntry,
    UserStatsListResponse,
    UserStatsResponse,
)

KST = ZoneInfo("Asia/Seoul")

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


@router.get("/stats/summary", response_model=PlatformStatsResponse)
def get_platform_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    today_kst = datetime.now(KST).date()
    today_start = datetime(today_kst.year, today_kst.month, today_kst.day)
    today_end = today_start + timedelta(days=1)

    total_users = db.query(func.count(User.id)).scalar() or 0

    today_plogging_users = (
        db.query(func.count(func.distinct(TrackingSession.user_id)))
        .filter(
            TrackingSession.started_at >= today_start,
            TrackingSession.started_at < today_end,
            TrackingSession.status.in_([SESSION_STATUS_COMPLETED, SESSION_STATUS_ACTIVE, SESSION_STATUS_PAUSED]),
        )
        .scalar()
        or 0
    )

    completed_base = db.query(TrackingSession).filter(
        TrackingSession.status == SESSION_STATUS_COMPLETED,
    )
    agg = completed_base.with_entities(
        func.coalesce(func.sum(TrackingSession.distance_meters), 0),
        func.count(TrackingSession.id),
    ).one()
    total_distance, total_sessions = agg

    trash_total = 0
    for (items,) in completed_base.with_entities(TrackingSession.trash_items).all():
        trash_total += _trash_count(items)

    return PlatformStatsResponse(
        total_users=int(total_users),
        today_plogging_users=int(today_plogging_users),
        total_sessions=int(total_sessions),
        total_distance_meters=int(total_distance),
        total_trash_count=trash_total,
    )


_SORT_COLS = {
    "distance": func.coalesce(func.sum(TrackingSession.distance_meters), 0),
    "sessions": func.count(TrackingSession.id),
    "duration": func.coalesce(func.sum(TrackingSession.duration_seconds), 0),
}


@router.get("/stats/leaderboard", response_model=UserStatsListResponse)
def get_leaderboard(
    sort_by: str = Query("distance", pattern="^(distance|sessions|duration)$"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    sort_col = _SORT_COLS[sort_by]

    total = (
        db.query(func.count(func.distinct(TrackingSession.user_id)))
        .filter(TrackingSession.status == SESSION_STATUS_COMPLETED)
        .scalar()
        or 0
    )

    rows = (
        db.query(
            TrackingSession.user_id,
            func.coalesce(func.sum(TrackingSession.distance_meters), 0).label("total_distance"),
            func.coalesce(func.sum(TrackingSession.duration_seconds), 0).label("total_duration"),
            func.count(TrackingSession.id).label("total_sessions"),
        )
        .filter(TrackingSession.status == SESSION_STATUS_COMPLETED)
        .group_by(TrackingSession.user_id)
        .order_by(sort_col.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    if not rows:
        return UserStatsListResponse(items=[], total=int(total))

    user_ids = [r.user_id for r in rows]
    users = {u.id: u for u in db.query(User).filter(User.id.in_(user_ids)).all()}

    trash_map: dict[str, int] = {}
    for uid, items in (
        db.query(TrackingSession.user_id, TrackingSession.trash_items)
        .filter(
            TrackingSession.user_id.in_(user_ids),
            TrackingSession.status == SESSION_STATUS_COMPLETED,
        )
        .all()
    ):
        trash_map[uid] = trash_map.get(uid, 0) + _trash_count(items)

    items = []
    for r in rows:
        u = users.get(r.user_id)
        items.append(
            UserStatsEntry(
                user_id=r.user_id,
                username=u.username if u else None,
                name=u.name if u else None,
                profile_image_url=u.profile_image_url if u else None,
                total_distance_meters=int(r.total_distance),
                total_duration_seconds=int(r.total_duration),
                total_sessions=int(r.total_sessions),
                total_trash_count=trash_map.get(r.user_id, 0),
            )
        )

    return UserStatsListResponse(items=items, total=int(total))


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


@router.get("/{user_id}/stats", response_model=UserStatsResponse)
def get_user_stats(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not db.query(User).filter(User.id == user_id).first():
        raise HTTPException(status_code=404, detail="User not found")

    base = db.query(TrackingSession).filter(
        TrackingSession.user_id == user_id,
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
