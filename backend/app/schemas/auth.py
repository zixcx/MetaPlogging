from typing import Optional

from pydantic import BaseModel, EmailStr


# ── Request schemas ────────────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    username: str
    email: EmailStr
    password: str
    name: Optional[str] = None


class LoginRequest(BaseModel):
    username: str
    password: str


class GoogleAuthRequest(BaseModel):
    id_token: str


class KakaoAuthRequest(BaseModel):
    access_token: str
    email: EmailStr
    name: Optional[str] = None
    profile_image_url: Optional[str] = None


class FindPasswordRequest(BaseModel):
    email: EmailStr


class RefreshRequest(BaseModel):
    refresh_token: str


# ── Response schemas ───────────────────────────────────────────────────────────

class UserResponse(BaseModel):
    id: str
    email: str
    name: Optional[str] = None
    profile_image_url: Optional[str] = None
    auth_provider: str

    class Config:
        from_attributes = True


class AuthTokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    user: UserResponse


class AccessTokenResponse(BaseModel):
    access_token: str
