import json

import httpx
from fastapi import APIRouter, HTTPException, Query

from ..cache import cache
from ..models import LyricsResponse

router = APIRouter(tags=["lyrics"])

LRCLIB_GET = "https://lrclib.net/api/get"


@router.get("/lyrics", response_model=LyricsResponse)
async def lyrics(
    track: str = Query(min_length=1, max_length=200),
    artist: str = Query(default="", max_length=200),
) -> LyricsResponse:
    key = f"lyrics:{artist}:{track}".lower()
    cached = await cache.get(key)
    if cached:
        return LyricsResponse(**json.loads(cached))

    params = {"track_name": track, "artist_name": artist}
    try:
        async with httpx.AsyncClient(timeout=8) as client:
            resp = await client.get(LRCLIB_GET, params=params)
    except httpx.HTTPError:
        raise HTTPException(status_code=502, detail="lyrics service unavailable") from None

    if resp.status_code == 404:
        return LyricsResponse(found=False)

    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail="lyrics service unavailable")

    data = resp.json()
    result = LyricsResponse(
        found=True,
        synced=bool(data.get("syncedLyrics")),
        plain=data.get("plainLyrics") or None,
        lrc=data.get("syncedLyrics") or None,
    )
    await cache.set(key, result.model_dump_json())
    return result