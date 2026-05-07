import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File

from app.core.config import settings
from app.core.deps import get_current_user
from app.models.user import User
from app.schemas.post import ImageUploadResponse

router = APIRouter(prefix="/images", tags=["images"])


def _get_upload_dir() -> Path:
    path = Path(settings.UPLOAD_DIR)
    path.mkdir(parents=True, exist_ok=True)
    return path


def _ext(filename: str) -> str:
    return filename.rsplit(".", 1)[-1].lower() if "." in filename else ""


@router.post("/upload", response_model=ImageUploadResponse, status_code=201)
async def upload_image(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    ext = _ext(file.filename or "")
    if ext not in settings.ALLOWED_IMAGE_EXTENSIONS:
        raise HTTPException(
            status_code=415,
            detail=f"지원하지 않는 파일 형식입니다. 허용: {', '.join(sorted(settings.ALLOWED_IMAGE_EXTENSIONS))}",
        )

    saved_name = f"{uuid.uuid4()}.{ext}"
    dest = _get_upload_dir() / saved_name

    content = await file.read()
    if len(content) == 0:
        raise HTTPException(status_code=400, detail="빈 파일은 업로드할 수 없습니다")

    dest.write_bytes(content)

    return ImageUploadResponse(
        url=f"/uploads/{saved_name}",
        filename=saved_name,
    )
