from pydantic_settings import BaseSettings


_INSECURE_DEFAULT = "dev-secret-key-change-in-production"


class Settings(BaseSettings):
    SECRET_KEY: str = _INSECURE_DEFAULT
    DATABASE_URL: str = "sqlite:///./metaplogging.db"
    GOOGLE_CLIENT_ID: str = ""

    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    ALGORITHM: str = "HS256"

    NAVER_CLIENT_ID: str = ""
    NAVER_CLIENT_SECRET: str = ""

    TRACKING_SESSION_TIMEOUT_MINUTES: int = 60

    UPLOAD_DIR: str = "uploads"
    MAX_IMAGES_PER_POST: int = 20
    ALLOWED_IMAGE_EXTENSIONS: set = {"jpg", "jpeg", "png", "heic", "heif", "webp"}

    class Config:
        env_file = ".env"


settings = Settings()

if settings.SECRET_KEY == _INSECURE_DEFAULT:
    raise RuntimeError(
        "SECRET_KEY is set to the insecure default value. "
        "Set a strong SECRET_KEY in your .env file before starting the server."
    )
