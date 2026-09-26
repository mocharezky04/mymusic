
import asyncio
import logging
from urllib.parse import quote

import httpx
from fastapi import APIRouter, HTTPException, Query

from ..config import get_settings
from ..models import SearchResponse, SuggestResponse
from ..providers import enrich_with_lastfm, search_all

logger = logging.getLogger(__name__)

router = APIRouter(tags=["search"])

_QUERY_MAX = 200

_SUGGEST_URL = "https://suggestqueries.google.com/complete/search"
_SUGGEST_UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) "
    "Gecko/20100101 Firefox/124.0"
)


@router.get("/search", response_model=SearchResponse)
async def search(
    q: str = Query(min_length=1, max_length=_QUERY_MAX),
    sources: str = "youtube,ytmusic",
) -> SearchResponse:
    source_list = [s.strip().lower() for s in sources.split(",") if s.strip()]
    if not source_list:
        raise HTTPException(status_code=400, detail="no sources specified")
    limit = get_settings().search_limit
    tracks = await search_all(q, source_list, limit)
    tracks = await enrich_with_lastfm(tracks)
    return SearchResponse(query=q, results=tracks)


@router.get("/suggest", response_model=SuggestResponse)
async def suggest(q: str = Query(min_length=1, max_length=_QUERY_MAX)) -> SuggestResponse:
    """Saran pencarian ala YouTube. Gagal atau timeout sengaja dibalas daftar
    kosong, bukan 500, supaya mengetik di kolom cari tidak menampilkan error."""
    params = {"client": "firefox", "ds": "yt", "q": q}
    try:
        async with httpx.AsyncClient(timeout=4.0) as client:
            resp = await client.get(
                _SUGGEST_URL,
                params=params,
                headers={"User-Agent": _SUGGEST_UA},
            )
        if resp.status_code != 200:
            logger.warning("suggest upstream status %s", resp.status_code)
            return SuggestResponse(suggestions=[])
        payload = resp.json()
    except (httpx.HTTPError, ValueError, asyncio.TimeoutError) as exc:
        logger.warning("suggest gagal: %s", exc)
        return SuggestResponse(suggestions=[])

    items = payload[1] if isinstance(payload, list) and len(payload) > 1 else []
    suggestions: list[str] = []
    if isinstance(items, list):
        for item in items:
            if isinstance(item, str) and item.strip():
                suggestions.append(item.strip())
    return SuggestResponse(suggestions=suggestions[:10])
