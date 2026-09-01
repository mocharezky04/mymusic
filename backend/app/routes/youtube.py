import base64
import hmac
import hashlib
import json
import time
from html import escape
from urllib.parse import quote

from fastapi import APIRouter, HTTPException, Query, Request
from fastapi.responses import HTMLResponse, RedirectResponse

from ..cache import cache
from ..config import get_settings
from ..google_yt import (
    GoogleApiError,
    build_auth_url,
    code_challenge,
    exchange_code,
    fetch_email,
    fetch_liked_count,
    fetch_liked_tracks,
    fetch_playlist_tracks,
    fetch_playlists,
    fetch_profile,
    new_code_verifier,
    refresh_access_token,
)
from ..models import (
    YoutubeAccount,
    YoutubeAccountsResponse,
    YoutubePlaylist,
    YoutubePlaylistsResponse,
    YoutubeTracksResponse,
)
from ..ytdlp import YtDlpError, extract_mix

router = APIRouter(tags=["youtube"])

_STATE_TTL = 900
_token_cache: dict[str, tuple[str, float]] = {}


def _config_ready() -> bool:
    settings = get_settings()
    return bool(settings.google_client_id and settings.google_client_secret)


def _require_config() -> None:
    if not _config_ready():
        raise HTTPException(
            status_code=503,
            detail="Fitur akun YouTube belum dikonfigurasi di backend. "
            "Isi GOOGLE_CLIENT_ID dan GOOGLE_CLIENT_SECRET di .env.",
        )


def _hmac_secret() -> bytes:
    settings = get_settings()
    key = settings.api_key or settings.google_client_secret or "mymusic-dev-fallback"
    return key.encode()


def _sign_state(payload_b64: str) -> str:
    sig = hmac.new(_hmac_secret(), payload_b64.encode(), hashlib.sha256).hexdigest()[:32]
    return f"{payload_b64}.{sig}"


def _verify_state(state: str) -> dict | None:
    try:
        payload_b64, sig = state.split(".", 1)
    except ValueError:
        return None
    expected = hmac.new(_hmac_secret(), payload_b64.encode(), hashlib.sha256).hexdigest()[:32]
    if not hmac.compare_digest(sig, expected):
        return None
    try:
        padded = payload_b64 + "=" * (-len(payload_b64) % 4)
        payload = json.loads(base64.urlsafe_b64decode(padded))
    except Exception:
        return None
    if time.time() - payload.get("t", 0) > _STATE_TTL:
        return None
    return payload


def _extract_refresh_token(request: Request) -> str | None:
    header = request.headers.get("x-refresh-token")
    if header:
        return header
    return request.query_params.get("token")


async def _access_token(refresh_token: str) -> str:
    cached = _token_cache.get(refresh_token)
    if cached and cached[1] > time.time() + 30:
        return cached[0]
    try:
        tokens = await refresh_access_token(refresh_token)
    except GoogleApiError as exc:
        raise HTTPException(
            status_code=502,
            detail="Gagal memperbarui izin akun. Copot lalu sambungkan ulang.",
        ) from exc
    access_token = tokens.get("access_token", "")
    expires_in = int(tokens.get("expires_in", 3600))
    _token_cache[refresh_token] = (access_token, time.time() + expires_in)
    return access_token


def _page(title: str, message: str, ok: bool, deep_link: str | None = None) -> HTMLResponse:
    color = "#2563eb" if ok else "#d97706"
    meta_refresh = (
        f'<meta http-equiv="refresh" content="3;url={escape(deep_link)}">'
        if deep_link
        else ""
    )
    button = (
        f'<a href="{escape(deep_link)}" style="display:inline-block;margin-top:24px;padding:12px 24px;'
        f'background:{color};color:#fff;border-radius:999px;text-decoration:none;font-weight:600;'
        f'font-size:14px">Buka MyMusic</a>'
        if deep_link
        else ""
    )
    body = f"""<!doctype html><html lang="id"><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
{meta_refresh}
<title>{title}</title>
<body style="margin:0;font-family:system-ui,-apple-system,Segoe UI,sans-serif;
background:#0b1220;color:#e2e8f0;display:flex;min-height:100vh;align-items:center;justify-content:center">
<div style="max-width:380px;padding:40px 28px;text-align:center">
<div style="width:56px;height:56px;margin:0 auto 20px;border-radius:50%;background:{color};opacity:.15"></div>
<h1 style="font-size:20px;margin:0 0 8px">{escape(title)}</h1>
<p style="margin:0;color:#94a3b8;font-size:15px;line-height:1.5">{escape(message)}</p>
{button}
</div></body></html>"""
    return HTMLResponse(content=body, status_code=200)


@router.get("/youtube/auth/start", response_class=RedirectResponse)
async def auth_start() -> RedirectResponse:
    _require_config()
    verifier = new_code_verifier()
    challenge = code_challenge(verifier)
    payload = base64.urlsafe_b64encode(
        json.dumps({"v": verifier, "t": int(time.time())}).encode()
    ).decode().rstrip("=")
    state = _sign_state(payload)
    return RedirectResponse(build_auth_url(state, challenge), status_code=302)


@router.get("/youtube/callback", response_class=HTMLResponse)
async def callback(code: str, state: str) -> HTMLResponse:
    _require_config()
    payload = _verify_state(state)
    if payload is None:
        return _page(
            "Sesi kedaluwarsa",
            "Tautan login tidak valid atau sudah kedaluwarsa. Buka ulang fitur Tambah akun di app.",
            False,
        )
    try:
        tokens = await exchange_code(code, payload["v"])
        access_token = tokens.get("access_token", "")
        refresh_token = tokens.get("refresh_token", "")
        if not refresh_token:
            return _page(
                "Gagal menghubungkan akun",
                "Google tidak memberikan izin perpanjangan. Coba buka ulang Tambah akun dan ulangi.",
                False,
            )
        email = await fetch_email(access_token)
        info = await fetch_profile(access_token)
    except GoogleApiError:
        return _page(
            "Gagal menghubungkan akun",
            "Terjadi kesalahan saat bertukar izin dengan Google. Coba lagi.",
            False,
        )
    deep_link = (
        f"mymusic://oauth/callback"
        f"?email={quote(email)}"
        f"&channel_id={quote(info.get('channel_id', ''))}"
        f"&channel_title={quote(info.get('channel_title', ''))}"
        f"&avatar_url={quote(info.get('avatar_url', ''))}"
        f"&refresh_token={quote(refresh_token)}"
        f"&state={quote(state)}"
    )
    return _page(
        "Akun terhubung",
        f"@{email} berhasil ditautkan. MyMusic akan terbuka dalam beberapa detik.",
        True,
        deep_link,
    )


@router.get("/youtube/me", response_model=YoutubeAccountsResponse)
async def me() -> YoutubeAccountsResponse:
    _require_config()
    return YoutubeAccountsResponse(accounts=[])


@router.get("/youtube/playlists", response_model=YoutubePlaylistsResponse)
async def playlists(
    request: Request,
    account: str = Query(default="", max_length=320),
) -> YoutubePlaylistsResponse:
    _require_config()
    refresh_token = _extract_refresh_token(request)
    if not refresh_token:
        raise HTTPException(status_code=401, detail="X-Refresh-Token header required")
    token = await _access_token(refresh_token)
    try:
        items = await fetch_playlists(token)
        liked_count = await fetch_liked_count(token)
    except GoogleApiError as exc:
        raise HTTPException(status_code=502, detail="Gagal mengambil playlist dari YouTube") from exc
    result = [
        YoutubePlaylist(
            id="LL",
            title="Punya saya",
            count=liked_count,
            owner="",
        )
    ]
    result.extend(
        YoutubePlaylist(
            id=item["id"],
            title=item["title"],
            count=item["count"],
            thumb=item["thumb"],
            owner=item["owner"],
        )
        for item in items
    )
    return YoutubePlaylistsResponse(account=account, playlists=result)


@router.get("/youtube/playlists/{playlist_id}/tracks", response_model=YoutubeTracksResponse)
async def playlist_tracks(
    playlist_id: str,
    request: Request,
    account: str = Query(default="", max_length=320),
    page_token: str | None = None,
) -> YoutubeTracksResponse:
    _require_config()
    refresh_token = _extract_refresh_token(request)
    if not refresh_token:
        raise HTTPException(status_code=401, detail="X-Refresh-Token header required")
    token = await _access_token(refresh_token)
    try:
        if playlist_id == "LL":
            tracks, next_page_token = await fetch_liked_tracks(token, page_token)
        else:
            tracks, next_page_token = await fetch_playlist_tracks(token, playlist_id, page_token)
    except GoogleApiError as exc:
        raise HTTPException(status_code=502, detail="Gagal mengambil lagu dari YouTube") from exc
    return YoutubeTracksResponse(
        account=account,
        playlist_id=playlist_id,
        tracks=tracks,
        next_page_token=next_page_token,
    )


@router.get("/youtube/mix", response_model=YoutubeTracksResponse)
async def youtube_mix(
    request: Request,
    mix_id: str = Query(min_length=3, max_length=64),
    account: str = Query(default="", max_length=320),
) -> YoutubeTracksResponse:
    _require_config()
    cache_key = f"mix:{mix_id}"
    cached = await cache.get(cache_key)
    if cached:
        tracks_data = json.loads(cached)
        from ..models import Track
        tracks = [Track(**t) for t in tracks_data]
        return YoutubeTracksResponse(
            account=account, playlist_id=mix_id, tracks=tracks
        )
    try:
        entries = await extract_mix(mix_id)
    except YtDlpError as exc:
        raise HTTPException(status_code=502, detail=f"Gagal mengambil mix: {exc}") from exc
    from ..models import Track
    tracks = [
        Track(
            id=e["id"],
            source="youtube",
            title=e.get("title", ""),
            artist=e.get("artist", ""),
            uploader=e.get("uploader", ""),
            thumb=e.get("thumb", ""),
            duration=e.get("duration", 0),
            url=e.get("url", ""),
        )
        for e in entries
    ]
    await cache.set(cache_key, json.dumps([t.model_dump() for t in tracks]))
    return YoutubeTracksResponse(
        account=account, playlist_id=mix_id, tracks=tracks
    )


@router.post("/youtube/profiles/refresh")
async def refresh_profile(request: Request) -> YoutubeAccount:
    _require_config()
    refresh_token = _extract_refresh_token(request)
    if not refresh_token:
        raise HTTPException(status_code=401, detail="X-Refresh-Token header required")
    token = await _access_token(refresh_token)
    try:
        info = await fetch_profile(token)
    except GoogleApiError as exc:
        raise HTTPException(
            status_code=502,
            detail="Gagal mengambil profil dari YouTube. Coba lagi.",
        ) from exc
    return YoutubeAccount(
        email="",
        channel_id=info["channel_id"],
        channel_title=info["channel_title"],
        avatar_url=info["avatar_url"],
    )


@router.post("/youtube/disconnect")
async def disconnect() -> dict:
    return {"ok": True}
