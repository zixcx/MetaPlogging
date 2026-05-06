import hashlib
import re
from typing import Optional
from urllib.parse import urlparse

import httpx
from fastapi import APIRouter, Depends, HTTPException, Query

from app.core.config import settings
from app.core.deps import get_current_user
from app.models.user import User
from app.schemas.place import NaverPlaceSearchItem, NaverPlaceSearchResponse

router = APIRouter(prefix="/places", tags=["places"])

NAVER_LOCAL_SEARCH_URL = "https://openapi.naver.com/v1/search/local.json"
HTML_TAG_PATTERN = re.compile(r"<[^>]+>")
PLACE_LINK_PATTERN = re.compile(r"/(?:place|restaurant)/(\d+)")


def _strip_tags(text: Optional[str]) -> Optional[str]:
    if text is None:
        return None
    return HTML_TAG_PATTERN.sub("", text)


def _decode_coord(raw: Optional[str | int | float]) -> Optional[float]:
    """네이버 mapx/mapy(WGS84 × 10^7 정수)를 위경도(float)로 변환."""
    if raw is None or raw == "":
        return None
    try:
        value = float(raw)
    except (TypeError, ValueError):
        return None
    # 모던 응답: lng/lat × 10^7 정수
    if abs(value) > 1_000:
        return value / 10_000_000.0
    return value


def _resolve_place_id(item: dict, name: str, lat: float, lng: float) -> str:
    """네이버 응답에는 명시적 place id 가 없어 link 또는 해시로 합성."""
    link = item.get("link") or ""
    match = PLACE_LINK_PATTERN.search(link)
    if match:
        return f"naver:{match.group(1)}"
    parsed = urlparse(link)
    if parsed.path:
        last_segment = parsed.path.rstrip("/").rsplit("/", 1)[-1]
        if last_segment.isdigit():
            return f"naver:{last_segment}"

    digest_input = f"{name}|{lat:.6f}|{lng:.6f}".encode("utf-8")
    digest = hashlib.sha1(digest_input).hexdigest()[:16]
    return f"local:{digest}"


@router.get("/search", response_model=NaverPlaceSearchResponse)
async def search_places(
    query: str = Query(..., min_length=1, description="검색어"),
    display: int = Query(5, ge=1, le=5, description="표시 개수 (네이버 제한 1~5)"),
    sort: str = Query("random", pattern="^(random|comment)$"),
    current_user: User = Depends(get_current_user),
):
    if not settings.NAVER_CLIENT_ID or not settings.NAVER_CLIENT_SECRET:
        raise HTTPException(
            status_code=503,
            detail="Naver API credentials are not configured",
        )

    headers = {
        "X-Naver-Client-Id": settings.NAVER_CLIENT_ID,
        "X-Naver-Client-Secret": settings.NAVER_CLIENT_SECRET,
    }
    params = {"query": query, "display": display, "sort": sort}

    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(NAVER_LOCAL_SEARCH_URL, headers=headers, params=params)
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=502, detail=f"Naver API request failed: {exc}")

    if resp.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"Naver API returned {resp.status_code}: {resp.text[:200]}",
        )

    payload = resp.json()
    items: list[NaverPlaceSearchItem] = []
    for raw in payload.get("items", []):
        name = _strip_tags(raw.get("title")) or ""
        lat = _decode_coord(raw.get("mapy"))
        lng = _decode_coord(raw.get("mapx"))
        if lat is None or lng is None:
            continue
        items.append(
            NaverPlaceSearchItem(
                naver_place_id=_resolve_place_id(raw, name, lat, lng),
                name=name,
                category=raw.get("category") or None,
                address=raw.get("address") or None,
                road_address=raw.get("roadAddress") or None,
                lat=lat,
                lng=lng,
                description=_strip_tags(raw.get("description")),
                telephone=raw.get("telephone") or None,
                link=raw.get("link") or None,
            )
        )

    return NaverPlaceSearchResponse(query=query, items=items)
