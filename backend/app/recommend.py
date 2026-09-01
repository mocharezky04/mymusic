from __future__ import annotations

import logging
from urllib.parse import quote

import httpx

from .config import get_settings
from .models import RecommendationRequest, RecommendationResponse, Track
from .providers import search_youtube

logger = logging.getLogger(__name__)


def _related_queries(seed: str) -> list[str]:
    s = seed.strip()
    if not s:
        return []
    return [
        f"{s} similar artists",
        f"{s} mix",
        f"{s} recommended",
        f"songs like {s}",
        f"artists like {s}",
    ]


async def _lastfm_similar_artists(seed: str, limit: int) -> list[str]:
    api_key = get_settings().lastfm_api_key
    if not api_key:
        return []
    try:
        async with httpx.AsyncClient(timeout=8) as client:
            resp = await client.get(
                "https://ws.audioscrobbler.com/2.0/",
                params={
                    "method": "artist.getSimilar",
                    "artist": seed,
                    "api_key": api_key,
                    "format": "json",
                    "limit": str(limit),
                },
            )
            if resp.status_code != 200:
                return []
            data = resp.json()
            similar = ((data or {}).get("similarartists") or {}).get("artist") or []
            return [a.get("name", "") for a in similar if a.get("name")]
    except Exception:
        logger.exception("lastfm similar artists failed")
        return []


async def _lastfm_similar_tracks(seed_artist: str, seed_title: str, limit: int) -> list[dict]:
    api_key = get_settings().lastfm_api_key
    if not api_key:
        return []
    try:
        async with httpx.AsyncClient(timeout=8) as client:
            resp = await client.get(
                "https://ws.audioscrobbler.com/2.0/",
                params={
                    "method": "track.getSimilar",
                    "artist": seed_artist,
                    "track": seed_title,
                    "api_key": api_key,
                    "format": "json",
                    "limit": str(limit),
                },
            )
            if resp.status_code != 200:
                return []
            data = resp.json()
            tracks = ((data or {}).get("similartracks") or {}).get("track") or []
            out = []
            for t in tracks:
                artist = ((t.get("artist") or {}).get("name")) or ""
                title = t.get("name") or ""
                if title:
                    out.append({"artist": artist, "title": title})
            return out
    except Exception:
        logger.exception("lastfm similar tracks failed")
        return []


async def _resolve_tracks(
    candidates: list[tuple[str, str]],
    limit: int,
    exclude_ids: set[str],
) -> list[Track]:
    out: list[Track] = []
    seen: set[str] = set()
    for artist, title in candidates:
        if len(out) >= limit:
            break
        query = f"{artist} {title}".strip() if artist else title
        if not query:
            continue
        try:
            results = await search_youtube(query, 3)
        except Exception:
            logger.exception("search_youtube failed during recommendation")
            continue
        for r in results:
            key = f"{r.id}::{r.source}"
            if key in seen:
                continue
            if r.id in exclude_ids:
                continue
            seen.add(key)
            out.append(r)
            if len(out) >= limit:
                break
    return out


def build_candidates(
    seeds: list[str],
    tracks: list[dict],
    *,
    similar_artists: list[str],
) -> list[tuple[str, str]]:
    candidates: list[tuple[str, str]] = []
    for t in tracks:
        artist = (t.get("artist") or "").strip()
        title = (t.get("title") or "").strip()
        if title:
            candidates.append((artist, title))
    for a in similar_artists:
        a = a.strip()
        if a:
            candidates.append((a, ""))
    for s in seeds:
        s = s.strip()
        if s:
            candidates.append((s, ""))
    return candidates


async def recommend(
    payload: RecommendationRequest,
) -> RecommendationResponse:
    seeds = [s.strip() for s in payload.seeds if s and s.strip()][:8]
    has_seeds = bool(seeds)
    has_seed_tracks = bool(payload.seed_tracks)
    if not has_seeds and not has_seed_tracks:
        return RecommendationResponse(recommendations=[])

    limit = max(1, min(payload.limit or 13, 25))
    exclude_ids = {e for e in payload.exclude_ids if e}

    similar_artists: list[str] = []
    if get_settings().lastfm_api_key:
        for s in seeds[:3]:
            similar_artists.extend(await _lastfm_similar_artists(s, 6))

    similar_tracks: list[dict] = []
    if get_settings().lastfm_api_key and payload.seed_tracks:
        for st in payload.seed_tracks[:3]:
            similar_tracks.extend(
                await _lastfm_similar_tracks(st.artist or "", st.title or "", 6)
            )

    if get_settings().lastfm_api_key:
        candidates = build_candidates(seeds, similar_tracks, similar_artists=similar_artists)
    else:
        candidates = []
        seen_artists: set[str] = set()
        for st in payload.seed_tracks:
            artist = (st.artist or "").strip()
            title = (st.title or "").strip()
            if title:
                candidates.append((artist, title))
            if artist and artist.lower() not in seen_artists:
                seen_artists.add(artist.lower())
        for artist in list(seen_artists)[:3]:
            for q in _related_queries(artist):
                candidates.append(("", q))
        for s in seeds:
            for q in _related_queries(s):
                candidates.append(("", q))

    tracks = await _resolve_tracks(candidates, limit, exclude_ids)
    return RecommendationResponse(recommendations=tracks[:limit])
