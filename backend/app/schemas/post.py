from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field, model_validator

from app.schemas.auth import UserResponse


# ── Comment ────────────────────────────────────────────────────────────────────

class CommentCreate(BaseModel):
    content: str = Field(..., min_length=1, max_length=500)


class CommentUpdate(BaseModel):
    content: str = Field(..., min_length=1, max_length=500)


class CommentResponse(BaseModel):
    id: str
    post_id: str
    user_id: str
    content: str
    author: Optional[UserResponse] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ── Post ───────────────────────────────────────────────────────────────────────

class PostCreate(BaseModel):
    caption: str = Field(..., min_length=1, max_length=2000)
    tags: List[str] = Field(default_factory=list, max_length=20)
    images: Optional[List[str]] = None          # 이미 업로드된 이미지 URL 목록
    tracking_id: Optional[str] = None

    @model_validator(mode="after")
    def _require_image_or_tracking(self) -> "PostCreate":
        if not self.images and self.tracking_id is None:
            raise ValueError("images 또는 tracking_id 중 하나 이상 필요합니다")
        return self


class PostUpdate(BaseModel):
    caption: Optional[str] = Field(default=None, min_length=1, max_length=2000)
    tags: Optional[List[str]] = Field(default=None, max_length=20)


class PostResponse(BaseModel):
    id: str
    user_id: str
    caption: str
    tags: List[str] = Field(default_factory=list)
    images: Optional[List[str]] = None
    tracking_id: Optional[str] = None
    is_verified: bool
    like_count: int
    comment_count: int
    share_count: int
    author: Optional[UserResponse] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

    @classmethod
    def from_orm_with_verified(cls, obj) -> "PostResponse":
        data = {
            "id": obj.id,
            "user_id": obj.user_id,
            "caption": obj.caption,
            "tags": obj.tags or [],
            "images": obj.images,
            "tracking_id": obj.tracking_id,
            "is_verified": obj.tracking_id is not None,
            "like_count": obj.like_count,
            "comment_count": obj.comment_count,
            "share_count": obj.share_count,
            "author": UserResponse.model_validate(obj.author) if obj.author else None,
            "created_at": obj.created_at,
            "updated_at": obj.updated_at,
        }
        return cls.model_validate(data)


class PostListResponse(BaseModel):
    items: List[PostResponse]
    total: int
    limit: int
    offset: int


# ── Like ───────────────────────────────────────────────────────────────────────

class LikeResponse(BaseModel):
    liked: bool
    like_count: int


# ── Image upload ───────────────────────────────────────────────────────────────

class ImageUploadResponse(BaseModel):
    url: str
    filename: str
