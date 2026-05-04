import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.models.user import User
from app.schemas.auth import (
    AccessTokenResponse,
    AuthTokenResponse,
    FindPasswordRequest,
    GoogleAuthRequest,
    KakaoAuthRequest,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    UserResponse,
)

router = APIRouter(prefix="/auth", tags=["auth"])
bearer_scheme = HTTPBearer()


# ── Helpers ────────────────────────────────────────────────────────────────────

def _build_auth_response(user: User) -> AuthTokenResponse:
    return AuthTokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
        user=UserResponse.model_validate(user),
    )


def _get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    token = credentials.credentials
    payload = decode_token(token)
    if payload is None or payload.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )
    user_id: str = payload.get("sub")
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )
    return user


# ── Routes ─────────────────────────────────────────────────────────────────────

@router.post("/register", response_model=AuthTokenResponse, status_code=status.HTTP_201_CREATED)
def register(body: RegisterRequest, db: Session = Depends(get_db)):
    if db.query(User).filter(User.username == body.username).first():
        raise HTTPException(status_code=400, detail="Username already taken")
    if db.query(User).filter(User.email == body.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(
        id=str(uuid.uuid4()),
        username=body.username,
        email=body.email,
        password_hash=hash_password(body.password),
        name=body.name,
        auth_provider="email",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return _build_auth_response(user)


@router.post("/login", response_model=AuthTokenResponse)
def login(body: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == body.username).first()
    if user is None or user.password_hash is None:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return _build_auth_response(user)


@router.post("/google", response_model=AuthTokenResponse)
def google_auth(body: GoogleAuthRequest, db: Session = Depends(get_db)):
    from app.core.config import settings
    from google.auth.transport import requests as google_requests
    from google.oauth2 import id_token as google_id_token

    try:
        request = google_requests.Request()
        id_info = google_id_token.verify_oauth2_token(
            body.id_token,
            request,
            settings.GOOGLE_CLIENT_ID if settings.GOOGLE_CLIENT_ID else None,
        )
    except Exception as exc:
        raise HTTPException(status_code=401, detail=f"Invalid Google id_token: {exc}")

    email: str = id_info.get("email", "")
    name: str = id_info.get("name")
    picture: str = id_info.get("picture")

    if not email:
        raise HTTPException(status_code=400, detail="Google token did not contain an email")

    user = db.query(User).filter(User.email == email).first()
    if user is None:
        user = User(
            id=str(uuid.uuid4()),
            email=email,
            name=name,
            profile_image_url=picture,
            auth_provider="google",
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    return _build_auth_response(user)


@router.post("/kakao", response_model=AuthTokenResponse)
def kakao_auth(body: KakaoAuthRequest, db: Session = Depends(get_db)):
    # Trust the data sent by the client (validated on the app side via Kakao SDK)
    user = db.query(User).filter(User.email == body.email).first()
    if user is None:
        user = User(
            id=str(uuid.uuid4()),
            email=body.email,
            name=body.name,
            profile_image_url=body.profile_image_url,
            auth_provider="kakao",
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    return _build_auth_response(user)


@router.post("/logout", status_code=status.HTTP_200_OK)
def logout(current_user: User = Depends(_get_current_user)):
    # Token invalidation would require a blocklist / Redis in production.
    # For now, acknowledge the request and let the client discard the token.
    return {"detail": "Logged out successfully"}


@router.post("/find-password", status_code=status.HTTP_200_OK)
def find_password(body: FindPasswordRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == body.email).first()
    if user:
        # Stub: in production, send a password-reset email here
        print(f"Would send password reset email to {body.email}")
    # Always return 200 — do not leak whether the email exists
    return {"detail": "If that email is registered, a reset link will be sent"}


@router.post("/refresh", response_model=AccessTokenResponse)
def refresh_token(body: RefreshRequest, db: Session = Depends(get_db)):
    payload = decode_token(body.refresh_token)
    if payload is None or payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

    user_id: str = payload.get("sub")
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")

    return AccessTokenResponse(access_token=create_access_token(user.id))


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(_get_current_user)):
    return UserResponse.model_validate(current_user)
