import json
import re

from fastapi import APIRouter, HTTPException, Query

from ..cache import cache
from ..models import StreamInfo
from ..ytdlp import YtDlpError, extract_stream, format_for

router = APIRouter(tags=["stream"])

_VIDEO_ID_RE = re.compile(r"^[A-Za-z0-9_-]{6,20}$")


@router.get("/stream", response_model=StreamInfo)
async def stream(
    video_id: str = Query(min_length=6, max_length=20),
    quality: str = "128k",
) -> StreamInfo:
    if not _VIDEO_ID_RE.fullmatch(video_id):
        raise HTTPException(status_code=400, detail="invalid video id")

    key = f"stream:{video_id}:{quality}"
    cached = await cache.get(key)
    if cached:
        return StreamInfo(**json.loads(cached))

    try:
        info = await extract_stream(video_id, format_for(quality))
    except YtDlpError as exc:
        raise HTTPException(status_code=502, detail="stream extraction failed") from exc

    payload = StreamInfo(video_id=video_id, **info)
    await cache.set(key, payload.model_dump_json())
    return payload