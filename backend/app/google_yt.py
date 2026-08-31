import asyncio
import base64
import hashlib
import logging
import re
import secrets
from typing import Any
from urllib.parse import urlencode

import httpx

from .config import get_settings
from .models import Track

logger = logging.getLogger(__name__)

AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
TOKEN_URL = "https://oauth2.googleapis.com/token"
USERINFO_URL = "https://www.googleapis.com/oauth2/v2/userinfo"
YT_API = "https://www.googleapis.com/youtube/v3"
SCOPE = "openid email https://www.googleapis.com/auth/youtube.readonly"

_ISO8601_DURATION = re.compile(
    r"^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$"
)


class GoogleApiError(Exception):
    pass


def new_code_verifier() -> str:
    return secrets.token_urlsafe(64)


def code_challenge(verifier: str) -> str:
    digest = hashlib.sha256(verifier.encode()).digest()
    return base64.urlsafe_b64encode(digest).rstrip(b"=").decode()


def build_auth_url(state: str, challenge: str) -> str:
    settings = get_settings()
    params = {
        "client_id": settings.google_client_id,
        "redirect_uri": settings.youtube_callback_uri,
        "response_type": "code",
        "scope": SCOPE,
        "access_type": "offline",
        "prompt": "consent",
        "state": state,
        "code_challenge": challenge,
        "code_challenge_method": "S256",
    }
    return f"{AUTH_URL}?{urlencode(params)}"


async def _post_form(url: str, data: dict[str, str]) -> dict:
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.post(url, data=data)
    if resp.status_code != 200:
        logger.warning("google oauth request failed: %s %s", resp.status_code, resp.text[:200])
        raise GoogleApiError("google oauth request failed")
    return resp.json()


async def exchange_code(code: str, verifier: str) -> dict:
    settings = get_settings()
    return await _post_form(
        TOKEN_URL,
        {
            "client_id": settings.google_client_id,
            "client_secret": settings.google_client_secret,
            "code": code,
            "code_verifier": verifier,
            "grant_type": "authorization_code",
            "redirect_uri": settings.youtube_callback_uri,
        },
    )


async def refresh_access_token(refresh_token: str) -> dict:
    settings = get_settings()
    return await _post_form(
        TOKEN_URL,
        {
            "client_id": settings.google_client_id,
            "client_secret": settings.google_client_secret,
            "refresh_token": refresh_token,
            "grant_type": "refresh_token",
        },
    )


async def _google_get(access_token: str, url: str, params: dict[str, Any]) -> dict:
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get(
            url,
            params=params,
            headers={"Authorization": f"Bearer {access_token}"},
        )
    if resp.status_code != 200:
        detail = resp.text[:200]
        if resp.status_code == 401:
            logger.info("google token invalid: %s", detail)
            raise GoogleApiError("google token invalid")
        logger.warning("youtube api %s failed: %s %s", url, resp.status_code, detail)
        raise GoogleApiError(f"youtube api failed with {resp.status_code}")
    return resp.json()


async def _youtube_get(access_token: str, path: str, params: dict[str, Any]) -> dict:
    return await _google_get(access_token, f"{YT_API}/{path.lstrip('/')}", params)


async def fetch_email(access_token: str) -> str:
    data = await _google_get(access_token, USERINFO_URL, {})
    return data.get("email", "")


async def fetch_userinfo(access_token: str) -> dict:
    data = await _google_get(access_token, USERINFO_URL, {})
    return {
        "email": data.get("email", ""),
        "picture": data.get("picture", ""),
        "name": data.get("name", "") or data.get("email", ""),
    }


async def fetch_profile(access_token: str, retries: int = 2) -> dict:
    """Profil dari channel YouTube; jatuh ke userinfo Google bila akun
    belum punya channel yang bisa diakses (items: [])."""
    channel = await fetch_channel(access_token, retries)
    if channel["channel_id"]:
        return channel
    info = await fetch_userinfo(access_token)
    return {
        "channel_id": "",
        "channel_title": info["name"],
        "avatar_url": info["picture"],
    }


async def fetch_channel(access_token: str, retries: int = 2) -> dict:
    data = None
    last_error = None
    for attempt in range(retries + 1):
        try:
            data = await _youtube_get(access_token, "/channels", {"part": "snippet", "mine": "true"})
            if data.get("items"):
                break
        except GoogleApiError as exc:
            last_error = exc
        await asyncio.sleep(0.4 * (attempt + 1))
    if data is None and last_error is not None:
        raise last_error
    items = (data or {}).get("items") or []
    if not items:
        return {"channel_id": "", "channel_title": "", "avatar_url": ""}
    snippet = items[0].get("snippet") or {}
    thumbs = snippet.get("thumbnails") or {}
    avatar = (thumbs.get("default") or {}).get("url", "")
    return {
        "channel_id": items[0].get("id", ""),
        "channel_title": snippet.get("title", ""),
        "avatar_url": avatar,
    }


async def fetch_playlists(access_token: str, max_total: int = 200) -> list[dict]:
    """Ambil semua playlist 'Pribadi' (mine=true) dengan paginasi penuh.
    YouTube Data API v3 tidak menyediakan playlist tersimpan milik channel lain
    lewat mine=true — lihat docs/youtube-account.md untuk keterbatasannya.
    Batas aman max_total=200 untuk mencegah loop tanpa akhir."""
    playlists: list[dict] = []
    page_token: str | None = None
    while True:
        params: dict[str, Any] = {
            "part": "snippet,contentDetails",
            "mine": "true",
            "maxResults": "50",
        }
        if page_token:
            params["pageToken"] = page_token
        data = await _youtube_get(access_token, "/playlists", params)
        for item in data.get("items") or []:
            snippet = item.get("snippet") or {}
            thumbs = snippet.get("thumbnails") or {}
            thumb = (
                (thumbs.get("medium") or thumbs.get("high") or thumbs.get("default") or {})
                .get("url", "")
            )
            playlists.append(
                {
                    "id": item.get("id", ""),
                    "title": snippet.get("title", ""),
                    "count": int((item.get("contentDetails") or {}).get("itemCount", 0)),
                    "thumb": thumb,
                    "owner": snippet.get("channelTitle", ""),
                }
            )
            if len(playlists) >= max_total:
                return playlists
        page_token = data.get("nextPageToken")
        if not page_token:
            break
    return playlists


async def fetch_liked_count(access_token: str) -> int:
    """itemCount playlist 'Liked videos' (id LL), 0 jika tak terakses.
    Hanya kirim 'id' tanpa 'mine' — keduanya saling eksklusif di YouTube API."""
    try:
        data = await _youtube_get(
            access_token,
            "/playlists",
            {"part": "contentDetails", "id": "LL"},
        )
    except GoogleApiError:
        return 0
    items = data.get("items") or []
    if not items:
        return 0
    return int((items[0].get("contentDetails") or {}).get("itemCount", 0))


async def fetch_liked_playlist_id(access_token: str) -> str | None:
    """Resolve the actual playlist ID for 'Liked Videos' via channels.list.
    Returns the real playlist ID (not 'LL') or None if not accessible."""
    try:
        data = await _youtube_get(
            access_token,
            "/channels",
            {"part": "contentDetails", "mine": "true"},
        )
    except GoogleApiError:
        return None
    items = data.get("items") or []
    if not items:
        return None
    related = (items[0].get("contentDetails") or {}).get("relatedPlaylists") or {}
    return related.get("likes")


async def fetch_liked_tracks(
    access_token: str,
    page_token: str | None,
) -> tuple[list[Track], str | None]:
    """Fetch tracks from the 'Liked Videos' playlist using the real playlist ID."""
    playlist_id = await fetch_liked_playlist_id(access_token)
    if not playlist_id:
        return [], None
    return await fetch_playlist_tracks(access_token, playlist_id, page_token)


async def fetch_playlist_tracks(
    access_token: str,
    playlist_id: str,
    page_token: str | None,
) -> tuple[list[Track], str | None]:
    params: dict[str, Any] = {
        "part": "snippet",
        "playlistId": playlist_id,
        "maxResults": "50",
    }
    if page_token:
        params["pageToken"] = page_token
    data = await _youtube_get(access_token, "/playlistItems", params)

    pending: list[dict] = []
    for item in data.get("items") or []:
        snippet = item.get("snippet") or {}
        resource = snippet.get("resourceId") or {}
        video_id = resource.get("videoId")
        if not video_id:
            continue
        thumbs = snippet.get("thumbnails") or {}
        thumb = (
            (thumbs.get("medium") or thumbs.get("high") or thumbs.get("default") or {})
            .get("url", "")
        )
        pending.append(
            {
                "id": video_id,
                "title": snippet.get("title", ""),
                "uploader": snippet.get("channelTitle", ""),
                "thumb": thumb,
            }
        )

    durations = await _fetch_durations(access_token, [p["id"] for p in pending])
    tracks = [
        Track(
            id=p["id"],
            source="youtube",
            title=p["title"],
            artist=p["uploader"],
            uploader=p["uploader"],
            thumb=p["thumb"],
            duration=durations.get(p["id"], 0),
            url=f"https://www.youtube.com/watch?v={p['id']}",
        )
        for p in pending
    ]
    next_page_token = data.get("nextPageToken")
    return tracks, next_page_token


async def _fetch_durations(access_token: str, ids: list[str]) -> dict[str, int]:
    result: dict[str, int] = {}
    for i in range(0, len(ids), 50):
        chunk = ids[i : i + 50]
        data = await _youtube_get(
            access_token,
            "/videos",
            {"part": "contentDetails", "id": ",".join(chunk), "maxResults": "50"},
        )
        for item in data.get("items") or []:
            duration_raw = (item.get("contentDetails") or {}).get("duration", "")
            result[item.get("id", "")] = _parse_iso8601(duration_raw)
    return result


def _parse_iso8601(value: str) -> int:
    match = _ISO8601_DURATION.fullmatch(value)
    if not match:
        return 0
    hours, minutes, seconds = (int(g) if g else 0 for g in match.groups())
    return hours * 3600 + minutes * 60 + seconds