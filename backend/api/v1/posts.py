from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.post import Comment, Like, Post
from app.models.tracking import TrackingSession
from app.models.user import User
from app.schemas.post import (
    CommentCreate,
    CommentResponse,
    LikeResponse,
    PostCreate,
    PostListResponse,
    PostResponse,
    PostUpdate,
)

router = APIRouter(prefix="/posts", tags=["posts"])


# ── Helpers ────────────────────────────────────────────────────────────────────

def _get_post_or_404(post_id: str, db: Session) -> Post:
    post = db.query(Post).filter(Post.id == post_id).first()
    if post is None:
        raise HTTPException(status_code=404, detail="Post not found")
    return post


def _require_owner(post: Post, user: User) -> None:
    if post.user_id != user.id:
        raise HTTPException(status_code=403, detail="Not authorized")


# ── Post CRUD ──────────────────────────────────────────────────────────────────

@router.post("", response_model=PostResponse, status_code=status.HTTP_201_CREATED)
def create_post(
    body: PostCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # tracking_id 검증 — 본인 소유이고 completed 상태여야 함
    if body.tracking_id is not None:
        session = db.query(TrackingSession).filter(
            TrackingSession.id == body.tracking_id,
            TrackingSession.user_id == current_user.id,
        ).first()
        if session is None:
            raise HTTPException(status_code=404, detail="Tracking session not found")
        if session.status != "completed":
            raise HTTPException(
                status_code=409, detail="트래킹 세션이 아직 완료되지 않았습니다"
            )

    post = Post(
        user_id=current_user.id,
        caption=body.caption,
        tags=body.tags,
        images=body.images,
        tracking_id=body.tracking_id,
    )
    db.add(post)
    db.flush()  # post.id 확보

    # TrackingSession에 post_id 역참조 저장
    if body.tracking_id is not None:
        db.query(TrackingSession).filter(
            TrackingSession.id == body.tracking_id
        ).update({"post_id": post.id})

    db.commit()
    db.refresh(post)
    return PostResponse.from_orm_with_verified(post)


@router.get("", response_model=PostListResponse)
def list_posts(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    q = db.query(Post)
    total = q.count()
    posts = q.order_by(Post.created_at.desc()).offset(offset).limit(limit).all()
    return PostListResponse(
        items=[PostResponse.from_orm_with_verified(p) for p in posts],
        total=total,
        limit=limit,
        offset=offset,
    )


@router.get("/{post_id}", response_model=PostResponse)
def get_post(
    post_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    post = _get_post_or_404(post_id, db)
    return PostResponse.from_orm_with_verified(post)


@router.patch("/{post_id}", response_model=PostResponse)
def update_post(
    post_id: str,
    body: PostUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    post = _get_post_or_404(post_id, db)
    _require_owner(post, current_user)

    if body.caption is not None:
        post.caption = body.caption
    if body.tags is not None:
        post.tags = body.tags

    db.add(post)
    db.commit()
    db.refresh(post)
    return PostResponse.from_orm_with_verified(post)


@router.delete("/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_post(
    post_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    post = _get_post_or_404(post_id, db)
    _require_owner(post, current_user)

    # TrackingSession post_id 역참조 해제
    if post.tracking_id:
        db.query(TrackingSession).filter(
            TrackingSession.id == post.tracking_id
        ).update({"post_id": None})

    db.delete(post)
    db.commit()
    return None


# ── Like ───────────────────────────────────────────────────────────────────────

@router.post("/{post_id}/like", response_model=LikeResponse)
def like_post(
    post_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    post = _get_post_or_404(post_id, db)

    existing = db.query(Like).filter(
        Like.user_id == current_user.id, Like.post_id == post_id
    ).first()
    if existing:
        raise HTTPException(status_code=409, detail="이미 좋아요를 눌렀습니다")

    like = Like(user_id=current_user.id, post_id=post_id)
    db.add(like)
    post.like_count += 1
    db.add(post)
    db.commit()
    db.refresh(post)
    return LikeResponse(liked=True, like_count=post.like_count)


@router.delete("/{post_id}/like", response_model=LikeResponse)
def unlike_post(
    post_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    post = _get_post_or_404(post_id, db)

    like = db.query(Like).filter(
        Like.user_id == current_user.id, Like.post_id == post_id
    ).first()
    if like is None:
        raise HTTPException(status_code=404, detail="좋아요를 누르지 않았습니다")

    db.delete(like)
    post.like_count = max(0, post.like_count - 1)
    db.add(post)
    db.commit()
    db.refresh(post)
    return LikeResponse(liked=False, like_count=post.like_count)


# ── Comments ───────────────────────────────────────────────────────────────────

@router.get("/{post_id}/comments", response_model=List[CommentResponse])
def list_comments(
    post_id: str,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _get_post_or_404(post_id, db)
    comments = (
        db.query(Comment)
        .filter(Comment.post_id == post_id)
        .order_by(Comment.created_at.asc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return comments


@router.post(
    "/{post_id}/comments",
    response_model=CommentResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_comment(
    post_id: str,
    body: CommentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    post = _get_post_or_404(post_id, db)

    comment = Comment(
        post_id=post_id,
        user_id=current_user.id,
        content=body.content,
    )
    db.add(comment)
    post.comment_count += 1
    db.add(post)
    db.commit()
    db.refresh(comment)
    return comment
