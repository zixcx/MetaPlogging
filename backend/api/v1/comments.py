from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.post import Comment, Post
from app.models.user import User
from app.schemas.post import CommentResponse, CommentUpdate

router = APIRouter(prefix="/comments", tags=["comments"])


@router.patch("/{comment_id}", response_model=CommentResponse)
def update_comment(
    comment_id: str,
    body: CommentUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    comment = db.query(Comment).filter(Comment.id == comment_id).first()
    if comment is None:
        raise HTTPException(status_code=404, detail="Comment not found")
    if comment.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    comment.content = body.content
    db.add(comment)
    db.commit()
    db.refresh(comment)
    return comment


@router.delete("/{comment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_comment(
    comment_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    comment = db.query(Comment).filter(Comment.id == comment_id).first()
    if comment is None:
        raise HTTPException(status_code=404, detail="Comment not found")
    if comment.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    post = db.query(Post).filter(Post.id == comment.post_id).first()
    if post:
        post.comment_count = max(0, post.comment_count - 1)
        db.add(post)

    db.delete(comment)
    db.commit()
    return None
