from datetime import datetime, timedelta
from typing import List, Optional
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.deps import get_current_user
from app.core.geo import haversine_meters, total_path_meters
from app.models.place import Place
from app.models.tracking import (
    SESSION_STATUS_ACTIVE,
    SESSION_STATUS_COMPLETED,
    SESSION_STATUS_EXPIRED,
    SESSION_STATUS_PAUSED,
    TrackingPoint,
    TrackingSession,
    TrashPoint,
)
from app.models.user import User
from app.schemas.place import PlaceInput
from app.schemas.tracking import (
    AddPointsRequest,
    AddPointsResponse,
    EndSessionRequest,
    StartSessionRequest,
    TrackingSessionDetail,
    TrackingSessionSummary,
    TrashPointInput,
    TrashPointResponse,
    UpdateSessionRequest,
)

router = APIRouter(prefix="/tracking", tags=["tracking"])

KST = ZoneInfo("Asia/Seoul")


# ── Helpers ────────────────────────────────────────────────────────────────────

def _now() -> datetime:
    return datetime.now(KST)


def _aware(dt: datetime) -> datetime:
    return dt if dt.tzinfo is not None else dt.replace(tzinfo=KST)


def _expire_if_stale(session: TrackingSession, db: Session) -> None:
    """active/paused 세션이 timeout 을 초과하면 expired 로 자동 전환."""
    if session.status not in (SESSION_STATUS_ACTIVE, SESSION_STATUS_PAUSED):
        return
    timeout = timedelta(minutes=settings.TRACKING_SESSION_TIMEOUT_MINUTES)
    started = _aware(session.started_at)
    if _now() - started > timeout:
        # 만료 시점에 paused 상태였다면 그 일시정지 구간도 누적
        if session.status == SESSION_STATUS_PAUSED and session.paused_at is not None:
            paused_at = _aware(session.paused_at)
            session.pause_duration_seconds = int(
                session.pause_duration_seconds + (started + timeout - paused_at).total_seconds()
            )
            session.paused_at = None
        session.status = SESSION_STATUS_EXPIRED
        session.ended_at = started + timeout
        db.add(session)
        db.commit()
        db.refresh(session)


def _get_owned_session(session_id: str, user: User, db: Session) -> TrackingSession:
    session = db.query(TrackingSession).filter(TrackingSession.id == session_id).first()
    if session is None:
        raise HTTPException(status_code=404, detail="Tracking session not found")
    if session.user_id != user.id:
        raise HTTPException(status_code=403, detail="Not authorized for this session")
    return session


def _upsert_place(payload: PlaceInput, db: Session) -> Place:
    place = (
        db.query(Place)
        .filter(Place.naver_place_id == payload.naver_place_id)
        .first()
    )
    if place is not None:
        return place
    place = Place(
        naver_place_id=payload.naver_place_id,
        name=payload.name,
        category=payload.category,
        address=payload.address,
        road_address=payload.road_address,
        lat=payload.lat,
        lng=payload.lng,
    )
    db.add(place)
    db.commit()
    db.refresh(place)
    return place


def _recalc_distance(session: TrackingSession, db: Session) -> int:
    """세션 포인트 기반으로 distance_meters 재계산."""
    points = (
        db.query(TrackingPoint)
        .filter(TrackingPoint.session_id == session.id)
        .order_by(TrackingPoint.recorded_at.asc())
        .all()
    )
    coords = [(p.lat, p.lng) for p in points]
    distance = int(round(total_path_meters(coords)))
    session.distance_meters = distance
    return distance


# ── Routes ─────────────────────────────────────────────────────────────────────

@router.post(
    "/sessions",
    response_model=TrackingSessionDetail,
    status_code=status.HTTP_201_CREATED,
)
def start_session(
    body: StartSessionRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # 이미 진행 중(active/paused) 세션이 있으면 거부 (만료된 건 자동 expired 로 정리)
    existing = (
        db.query(TrackingSession)
        .filter(
            TrackingSession.user_id == current_user.id,
            TrackingSession.status.in_([SESSION_STATUS_ACTIVE, SESSION_STATUS_PAUSED]),
        )
        .first()
    )
    if existing is not None:
        _expire_if_stale(existing, db)
        if existing.status in (SESSION_STATUS_ACTIVE, SESSION_STATUS_PAUSED):
            raise HTTPException(
                status_code=409,
                detail="An ongoing tracking session already exists",
            )

    session = TrackingSession(
        user_id=current_user.id,
        status=SESSION_STATUS_ACTIVE,
        started_at=_now(),
        start_lat=body.start_lat,
        start_lng=body.start_lng,
        distance_meters=0,
        trash_items=[],
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


@router.get("/sessions/active", response_model=Optional[TrackingSessionDetail])
def get_active_session(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = (
        db.query(TrackingSession)
        .filter(
            TrackingSession.user_id == current_user.id,
            TrackingSession.status.in_([SESSION_STATUS_ACTIVE, SESSION_STATUS_PAUSED]),
        )
        .order_by(TrackingSession.started_at.desc())
        .first()
    )
    if session is None:
        return None
    _expire_if_stale(session, db)
    if session.status not in (SESSION_STATUS_ACTIVE, SESSION_STATUS_PAUSED):
        return None
    return session


@router.post("/sessions/{session_id}/points", response_model=AddPointsResponse)
def add_points(
    session_id: str,
    body: AddPointsRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = _get_owned_session(session_id, current_user, db)
    _expire_if_stale(session, db)
    if session.status != SESSION_STATUS_ACTIVE:
        raise HTTPException(
            status_code=409,
            detail=f"Session is {session.status}; points can only be appended when active",
        )

    # 기존 마지막 포인트 (거리 계산 시작점)
    last = (
        db.query(TrackingPoint)
        .filter(TrackingPoint.session_id == session.id)
        .order_by(TrackingPoint.recorded_at.desc())
        .first()
    )
    prev_lat = last.lat if last else None
    prev_lng = last.lng if last else None

    incoming = sorted(body.points, key=lambda p: p.recorded_at)
    added_distance = 0.0
    new_points: List[TrackingPoint] = []
    for p in incoming:
        if prev_lat is not None:
            added_distance += haversine_meters(prev_lat, prev_lng, p.lat, p.lng)
        new_points.append(
            TrackingPoint(
                session_id=session.id,
                lat=p.lat,
                lng=p.lng,
                recorded_at=p.recorded_at,
            )
        )
        prev_lat, prev_lng = p.lat, p.lng

    db.add_all(new_points)
    session.distance_meters = int(session.distance_meters + round(added_distance))
    db.add(session)
    db.commit()
    db.refresh(session)

    return AddPointsResponse(
        accepted=len(new_points),
        distance_meters=session.distance_meters,
    )


@router.post("/sessions/{session_id}/end", response_model=TrackingSessionDetail)
def end_session(
    session_id: str,
    body: EndSessionRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = _get_owned_session(session_id, current_user, db)
    _expire_if_stale(session, db)
    if session.status == SESSION_STATUS_COMPLETED:
        raise HTTPException(status_code=409, detail="Session already completed")
    if session.status == SESSION_STATUS_EXPIRED:
        raise HTTPException(status_code=409, detail="Session expired")

    # 종료 직전 포인트 일괄 추가 (선택)
    if body.final_points:
        ordered = sorted(body.final_points, key=lambda p: p.recorded_at)
        db.add_all(
            [
                TrackingPoint(
                    session_id=session.id,
                    lat=p.lat,
                    lng=p.lng,
                    recorded_at=p.recorded_at,
                )
                for p in ordered
            ]
        )
        db.flush()

    # 거리 재계산 (안전하게 전체 재계산)
    _recalc_distance(session, db)

    # 종료 위치
    if body.end_lat is not None and body.end_lng is not None:
        session.end_lat = body.end_lat
        session.end_lng = body.end_lng
    else:
        last = (
            db.query(TrackingPoint)
            .filter(TrackingPoint.session_id == session.id)
            .order_by(TrackingPoint.recorded_at.desc())
            .first()
        )
        if last is not None:
            session.end_lat = last.lat
            session.end_lng = last.lng

    # 시작 위치 보정 (start_lat/lng 가 비어있으면 첫 포인트로)
    if session.start_lat is None or session.start_lng is None:
        first = (
            db.query(TrackingPoint)
            .filter(TrackingPoint.session_id == session.id)
            .order_by(TrackingPoint.recorded_at.asc())
            .first()
        )
        if first is not None:
            session.start_lat = first.lat
            session.start_lng = first.lng

    # 장소
    if body.place is not None:
        place = _upsert_place(body.place, db)
        session.place_id = place.id

    if body.description is not None:
        session.description = body.description

    # 쓰레기 항목
    session.trash_items = [item.model_dump(mode="json") for item in body.trash_items]

    # 종료 시점에 일시정지 중이라면, 현재 일시정지 구간을 누적시키고 정리
    if session.paused_at is not None:
        paused_at = _aware(session.paused_at)
        session.pause_duration_seconds = int(
            session.pause_duration_seconds + (_now() - paused_at).total_seconds()
        )
        session.paused_at = None

    # 종료 시각/지속 시간 (전체 경과 - 일시정지 누적)
    ended = _now()
    session.ended_at = ended
    started = _aware(session.started_at)
    elapsed = int((ended - started).total_seconds())
    session.duration_seconds = max(0, elapsed - int(session.pause_duration_seconds or 0))
    session.status = SESSION_STATUS_COMPLETED

    db.add(session)
    db.commit()
    db.refresh(session)
    return session


@router.get("/sessions", response_model=List[TrackingSessionSummary])
def list_sessions(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    status_filter: Optional[str] = Query(None, alias="status"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    q = db.query(TrackingSession).filter(TrackingSession.user_id == current_user.id)
    if status_filter:
        q = q.filter(TrackingSession.status == status_filter)
    sessions = (
        q.order_by(TrackingSession.started_at.desc()).offset(offset).limit(limit).all()
    )
    return sessions


@router.get("/sessions/{session_id}", response_model=TrackingSessionDetail)
def get_session(
    session_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = _get_owned_session(session_id, current_user, db)
    return session


@router.patch("/sessions/{session_id}", response_model=TrackingSessionDetail)
def update_session(
    session_id: str,
    body: UpdateSessionRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = _get_owned_session(session_id, current_user, db)
    if session.status != SESSION_STATUS_COMPLETED:
        raise HTTPException(
            status_code=409,
            detail="Only completed sessions can be edited",
        )

    if body.place is not None:
        place = _upsert_place(body.place, db)
        session.place_id = place.id
    if body.description is not None:
        session.description = body.description

    db.add(session)
    db.commit()
    db.refresh(session)
    return session


@router.delete("/sessions/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_session(
    session_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = _get_owned_session(session_id, current_user, db)
    db.delete(session)
    db.commit()
    return None


# ── Pause / Resume ─────────────────────────────────────────────────────────────

@router.post("/sessions/{session_id}/pause", response_model=TrackingSessionDetail)
def pause_session(
    session_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = _get_owned_session(session_id, current_user, db)
    _expire_if_stale(session, db)
    if session.status != SESSION_STATUS_ACTIVE:
        raise HTTPException(
            status_code=409,
            detail=f"Session is {session.status}; only active sessions can be paused",
        )
    session.status = SESSION_STATUS_PAUSED
    session.paused_at = _now()
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


@router.post("/sessions/{session_id}/resume", response_model=TrackingSessionDetail)
def resume_session(
    session_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = _get_owned_session(session_id, current_user, db)
    _expire_if_stale(session, db)
    if session.status != SESSION_STATUS_PAUSED:
        raise HTTPException(
            status_code=409,
            detail=f"Session is {session.status}; only paused sessions can be resumed",
        )
    if session.paused_at is not None:
        paused_at = _aware(session.paused_at)
        session.pause_duration_seconds = int(
            session.pause_duration_seconds + (_now() - paused_at).total_seconds()
        )
    session.paused_at = None
    session.status = SESSION_STATUS_ACTIVE
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


# ── Trash points (real-time markers) ──────────────────────────────────────────

@router.post(
    "/sessions/{session_id}/trash-points",
    response_model=TrashPointResponse,
    status_code=status.HTTP_201_CREATED,
)
def add_trash_point(
    session_id: str,
    body: TrashPointInput,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = _get_owned_session(session_id, current_user, db)
    _expire_if_stale(session, db)
    if session.status not in (SESSION_STATUS_ACTIVE, SESSION_STATUS_PAUSED):
        raise HTTPException(
            status_code=409,
            detail=f"Session is {session.status}; trash points can only be added during tracking",
        )
    point = TrashPoint(
        session_id=session.id,
        lat=body.lat,
        lng=body.lng,
        category=body.category.value,
        note=body.note,
        recorded_at=_now(),
    )
    db.add(point)
    db.commit()
    db.refresh(point)
    return point


@router.get(
    "/sessions/{session_id}/trash-points",
    response_model=List[TrashPointResponse],
)
def list_trash_points(
    session_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = _get_owned_session(session_id, current_user, db)
    points = (
        db.query(TrashPoint)
        .filter(TrashPoint.session_id == session.id)
        .order_by(TrashPoint.recorded_at.asc())
        .all()
    )
    return points
