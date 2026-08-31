
from fastapi import APIRouter, HTTPException, Query

from ..config import get_settings
from ..models import SearchResponse
from ..providers import enrich_with_lastfm, search_all

router = APIRouter(tags=["search"])

_QUERY_MAX = 200


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