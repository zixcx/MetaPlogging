from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class PlaceInput(BaseModel):
    naver_place_id: str
    name: str
    category: Optional[str] = None
    address: Optional[str] = None
    road_address: Optional[str] = None
    lat: float
    lng: float


class PlaceResponse(BaseModel):
    id: str
    naver_place_id: str
    name: str
    category: Optional[str] = None
    address: Optional[str] = None
    road_address: Optional[str] = None
    lat: float
    lng: float
    created_at: datetime

    class Config:
        from_attributes = True


class NaverPlaceSearchItem(BaseModel):
    naver_place_id: str
    name: str
    category: Optional[str] = None
    address: Optional[str] = None
    road_address: Optional[str] = None
    lat: float
    lng: float
    description: Optional[str] = None
    telephone: Optional[str] = None
    link: Optional[str] = None


class NaverPlaceSearchResponse(BaseModel):
    query: str
    items: list[NaverPlaceSearchItem]
