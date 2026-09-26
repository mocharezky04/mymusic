import asyncio
import logging
from urllib.parse import quote

import httpx

from .config import get_settings
from .models import Track
from .ytdlp import _extract_info, normalize_entry, search

logger = logging.getLogger(__name__)


async def search_youtube(query: str, limit: int) -> list[Track]:
    entries = await search(query, limit, "ytsearch")
    tracks = []
    for entry in entries:
        normalized = normalize_entry(entry, "youtube")
        if normalized:
            tracks.append(Track(source="youtube", **normalized))
    return tracks


# Diperiksa dari data production (2026-09): search music.youtube.com lewat
# yt-dlp flat extract menghasilkan tiga bentuk id:
#   - 11 karakter, awalan acak ("tEXYfT_G0W0", "MX7FSAnRPug") = video biasa
#   - "VLPL..." (contoh VLPLPNKnwlz-OnZcgTuCwVCcqx-1BdW2xDm1) = radio/mix.
#     Field title dari flat extract kosong untuk entri ini, jadi tidak bisa
#     dibedakan dari album; /youtube/mix (extract_mix) menangani keduanya lewat
#     playlist?list=, jadi VLPL diklasifikasikan "mix".
#   - id lawas "RD...", "OLAK...", "UC..." kadang muncul tapi jarang di search
MIX_ID_PREFIXES = ("VLPL", "RD", "RDLM")
ALBUM_ID_PREFIXES = ("OLAK", "MPRE")
CHANNEL_ID_PREFIXES = ("UC",)


def classify_entry(entry: dict) -> tuple[str, str] | None:
    """Petakan entri flat yt-dlp menjadi (kind, id) atau None kalau tidak
    bisa dipakai app."""
    video_id = str(entry.get("id") or "").strip()
    if not video_id:
        return None

    raw = str(entry.get("ie_key") or "")
    is_playlist = "playlist" in raw

    if video_id.startswith(MIX_ID_PREFIXES):
        return "mix", video_id
    if video_id.startswith(CHANNEL_ID_PREFIXES):
        return "channel", video_id
    if video_id.startswith(ALBUM_ID_PREFIXES):
        return "album", video_id
    if is_playlist:
        return "mix", video_id
    return "video", video_id


def _first_thumb(entry: dict) -> str:
    thumbs = entry.get("thumbnails") or []
    if not thumbs:
        return ""
    best = max(
        thumbs,
        key=lambda t: (t.get("preference") or 0, t.get("width") or 0),
    )
    return best.get("url") or ""


async def search_ytmusic(query: str, limit: int) -> list[Track]:
    data = await _extract_info(
        f"https://music.youtube.com/search?q={quote(query)}",
        {"extract_flat": True},
    )
    tracks = []
    for entry in data.get("entries") or []:
        classified = classify_entry(entry)
        if classified is None:
            continue
        kind, video_id = classified
        if kind not in ("video", "mix"):
            # Album & channel tidak bisa diputar sebagai satu lagu; buang
            # diam-diam supaya tidak memenuhi hasil.
            continue
        tracks.append(
            Track(
                id=video_id,
                source="ytmusic",
                kind=kind,
                title=entry.get("title") or "",
                artist=(entry.get("artist") or entry.get("uploader") or ""),
                uploader=entry.get("uploader") or "",
                duration=int(entry.get("duration") or 0),
                thumb=_first_thumb(entry),
                url=(
                    f"https://music.youtube.com/watch?v={video_id}"
                    if kind == "video"
                    else f"https://music.youtube.com/playlist?list={video_id}"
                ),
            )
        )
    return tracks


async def search_soundcloud(query: str, limit: int) -> list[Track]:
    client_id = get_settings().soundcloud_client_id
    if not client_id:
        return []
    params = {"q": query, "client_id": client_id, "limit": str(limit)}
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get("https://api-v2.soundcloud.com/search/tracks", params=params)
        resp.raise_for_status()
        data = resp.json()
    return [
        Track(
            id=str(item["id"]),
            source="soundcloud",
            title=item.get("title", ""),
            artist=(item.get("user") or {}).get("username", ""),
            duration=(item.get("duration") or 0) // 1000,
            thumb=(item.get("artwork_url")) or "",
            url=item.get("permalink_url", ""),
        )
        for item in data.get("collection", [])
    ]


async def search_spotify(query: str, limit: int) -> list[Track]:
    settings = get_settings()
    if not settings.spotify_client_id or not settings.spotify_client_secret:
        return []
    token = await _spotify_token()
    if not token:
        return []
    headers = {"Authorization": f"Bearer {token}"}
    params = {"q": query, "type": "track", "limit": str(limit)}
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get("https://api.spotify.com/v1/search", headers=headers, params=params)
        if resp.status_code != 200:
            logger.warning("spotify search failed: %s", resp.status_code)
            return []
        data = resp.json()
    tracks = []
    for item in data.get("tracks", {}).get("items", []):
        images = item.get("album", {}).get("images") or []
        tracks.append(
            Track(
                id=item["id"],
                source="spotify",
                title=item.get("name", ""),
                artist=", ".join(a.get("name", "") for a in item.get("artists", [])),
                duration=(item.get("duration_ms") or 0) // 1000,
                thumb=images[0]["url"] if images else "",
                url=item.get("external_urls", {}).get("spotify", ""),
            )
        )
    return tracks


async def _spotify_token() -> str | None:
    settings = get_settings()
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.post(
            "https://accounts.spotify.com/api/token",
            data={"grant_type": "client_credentials"},
            auth=(settings.spotify_client_id, settings.spotify_client_secret),
        )
        if resp.status_code != 200:
            logger.warning("spotify token failed: %s", resp.status_code)
            return None
        return resp.json().get("access_token")


async def enrich_with_lastfm(tracks: list[Track]) -> list[Track]:
    api_key = get_settings().lastfm_api_key
    if not api_key:
        return tracks
    async with httpx.AsyncClient(timeout=8) as client:
        for track in list(tracks):
            params = {
                "method": "track.getInfo",
                "api_key": api_key,
                "format": "json",
                "artist": track.artist,
                "track": track.title,
            }
            resp = await client.get("https://ws.audioscrobbler.com/2.0/", params=params)
            if resp.status_code != 200:
                continue
            info = resp.json().get("track")
            album = (info or {}).get("album") or {}
            art = album.get("image") or []
            if art and not track.thumb:
                track.thumb = art[-1].get("#text", "")
    return tracks


PROVIDERS = {
    "youtube": search_youtube,
    "ytmusic": search_ytmusic,
    "soundcloud": search_soundcloud,
    "spotify": search_spotify,
}


async def search_all(query: str, sources: list[str], limit: int) -> list[Track]:
    async def safe(source: str) -> list[Track]:
        fn = PROVIDERS.get(source)
        if fn is None:
            return []
        try:
            return await fn(query, limit)
        except Exception:
            logger.exception("provider %s failed", source)
            return []

    groups = await asyncio.gather(*(safe(src) for src in sources))
    merged: list[Track] = []
    seen: set[tuple[str, str]] = set()
    for group in groups:
        for track in group:
            key = (track.kind, track.id)
            if key in seen:
                continue
            seen.add(key)
            merged.append(track)
    return merged