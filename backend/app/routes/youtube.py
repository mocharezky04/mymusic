import secrets
import time
from html import escape
from urllib.parse import quote

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import HTMLResponse, RedirectResponse

from ..account_store import (
    delete_account,
    get_account,
    list_accounts,
    update_profile,
    upsert_account,
)
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
    DisconnectRequest,
    YoutubeAccount,
    YoutubeAccountsResponse,
    YoutubePlaylist,
    YoutubePlaylistsResponse,
    YoutubeTracksResponse,
)
from ..ytdlp import YtDlpError, extract_mix

router = APIRouter(tags=["youtube"])

_PENDING_TTL = 600
pending_flows: dict[str, dict] = {}
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


def _resolve_account(email: str) -> dict:
    account = get_account(email)
    if account is None:
        raise HTTPException(status_code=404, detail="Akun YouTube tidak ditemukan")
    return account


def _prune_pending() -> None:
    now = time.monotonic()
    expired = [s for s, f in pending_flows.items() if now - f["created"] > _PENDING_TTL]
    for state in expired:
        pending_flows.pop(state, None)


async def _access_token(account: dict) -> str:
    now = time.monotonic()
    cached = _token_cache.get(account["email"])
    if cached and cached[1] > now + 30:
        return cached[0]
    try:
        tokens = await refresh_access_token(account["refresh_token"])
    except GoogleApiError as exc:
        raise HTTPException(
            status_code=502,
            detail="Gagal memperbarui izin akun. Copot lalu sambungkan ulang.",
        ) from exc
    access_token = tokens.get("access_token", "")
    expires_in = int(tokens.get("expires_in", 3600))
    _token_cache[account["email"]] = (access_token, now + expires_in)
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
    _prune_pending()
    state = secrets.token_urlsafe(18)
    verifier = new_code_verifier()
    challenge = code_challenge(verifier)
    pending_flows[state] = {"verifier": verifier, "created": time.monotonic()}
    return RedirectResponse(build_auth_url(state, challenge), status_code=302)


@router.get("/youtube/callback", response_class=HTMLResponse)
async def callback(code: str, state: str) -> HTMLResponse:
    _require_config()
    flow = pending_flows.pop(state, None)
    if flow is None:
        return _page(
            "Sesi kedaluwarsa",
            "Tautan login tidak valid atau sudah kedaluwarsa. Buka ulang fitur Tambah akun di app.",
            False,
        )
    try:
        tokens = await exchange_code(code, flow["verifier"])
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
    upsert_account(
        email,
        info["channel_id"],
        info["channel_title"],
        info["avatar_url"],
        refresh_token,
    )
    deep_link = f"mymusic://youtube-connected?email={quote(email)}&name={quote(info['channel_title'])}"
    return _page(
        "Akun terhubung",
        f"@{email} berhasil ditautkan. MyMusic akan terbuka dalam beberapa detik.",
        True,
        deep_link,
    )


@router.post("/youtube/profiles/refresh", response_model=YoutubeAccount)
async def refresh_profile(payload: DisconnectRequest) -> YoutubeAccount:
    _require_config()
    acc = _resolve_account(payload.account)
    token = await _access_token(acc)
    try:
        info = await fetch_profile(token)
    except GoogleApiError as exc:
        raise HTTPException(
            status_code=502,
            detail="Gagal mengambil profil dari YouTube. Coba lagi.",
        ) from exc
    update_profile(payload.account, info["channel_id"], info["channel_title"], info["avatar_url"])
    return YoutubeAccount(
        email=payload.account,
        channel_id=info["channel_id"],
        channel_title=info["channel_title"],
        avatar_url=info["avatar_url"],
    )


@router.get("/youtube/me", response_model=YoutubeAccountsResponse)
async def me() -> YoutubeAccountsResponse:
    _require_config()
    return YoutubeAccountsResponse(
        accounts=[YoutubeAccount(**a) for a in list_accounts()]
    )


@router.get("/youtube/playlists", response_model=YoutubePlaylistsResponse)
async def playlists(
    account: str = Query(min_length=3, max_length=320),
) -> YoutubePlaylistsResponse:
    _require_config()
    acc = _resolve_account(account)
    if not acc["channel_id"]:
        return YoutubePlaylistsResponse(account=account, playlists=[])
    token = await _access_token(acc)
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
            owner=acc["channel_title"],
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
    account: str = Query(min_length=3, max_length=320),
    page_token: str | None = None,
) -> YoutubeTracksResponse:
    _require_config()
    acc = _resolve_account(account)
    token = await _access_token(acc)
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
    mix_id: str = Query(min_length=3, max_length=64),
    account: str = Query(min_length=3, max_length=320),
) -> YoutubeTracksResponse:
    _require_config()
    _resolve_account(account)
    cache_key = f"mix:{mix_id}"
    cached = await cache.get(cache_key)
    if cached:
        import json as _json
        tracks_data = _json.loads(cached)
        from ..models import Track
        tracks = [Track(**t) for t in tracks_data]
        return YoutubeTracksResponse(
            account=account, playlist_id=mix_id, tracks=tracks
        )
    try:
        entries = await extract_mix(mix_id)
    except YtDlpError as exc:
        raise HTTPException(status_code=502, detail=f"Gagal mengambil mix: {exc}") from exc
    import json as _json
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
    await cache.set(cache_key, _json.dumps([t.model_dump() for t in tracks]))
    return YoutubeTracksResponse(
        account=account, playlist_id=mix_id, tracks=tracks
    )


@router.post("/youtube/disconnect")
async def disconnect(payload: DisconnectRequest) -> dict:
    _require_config()
    deleted = delete_account(payload.account)
    if not deleted:
        raise HTTPException(status_code=404, detail="Akun YouTube tidak ditemukan")
    _token_cache.pop(payload.account, None)
    return {"ok": True}