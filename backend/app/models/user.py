import uuid
from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, String

from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    username = Column(String, unique=True, index=True, nullable=True)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=True)
    name = Column(String, nullable=True)
    profile_image_url = Column(String, nullable=True)
    auth_provider = Column(String, nullable=False, default="email")  # "email" | "google" | "kakao"
    created_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
