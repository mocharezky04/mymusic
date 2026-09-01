import asyncio
import hashlib
import logging
import tempfile
from pathlib import Path

import yt_dlp
from yt_dlp.utils import DownloadError

from .config import get_settings

logger = logging.getLogger(__name__)

_COOKIE_FILENAME = "yt_cookies.txt"

_FORCED_CLIENTS = {"youtube": {"player_client": ["tv", "android_vr", "tv_simply"]}}


class YtDlpError(Exception):
    pass


def _cookiefile_path() -> str | None:
    settings = get_settings()
    raw = settings.youtube_cookies
    if not raw:
        return None
    content = raw.strip()
    if not content:
        return None
    dest = Path(tempfile.gettempdir()) / _COOKIE_FILENAME
    new_hash = hashlib.sha256(content.encode()).hexdigest()
    if dest.exists():
        existing_hash = hashlib.sha256(dest.read_bytes()).hexdigest()
        if existing_hash == new_hash:
            return str(dest)
    dest.write_text(content, encoding="utf-8")
    return str(dest)


def _is_storyboard(f: dict) -> bool:
    if (f.get("ext") or "").lower() == "mhtml":
        return True
    return (f.get("protocol") or "").startswith("mhtml")


def _pick_audio_format(formats: list[dict], max_abr: int | None = None) -> dict:
    playable = [f for f in formats if f.get("url") and not _is_storyboard(f)]

    def _audio_only(pool: list[dict]) -> list[dict]:
        return [
            f for f in pool
            if f.get("acodec") not in (None, "none", "")
            and f.get("vcodec") in (None, "none", "")
        ]

    def _muxed(pool: list[dict]) -> list[dict]:
        return [
            f for f in pool
            if f.get("acodec") not in (None, "none", "")
            and f.get("vcodec") not in (None, "none", "")
        ]

    def _best(pool: list[dict]) -> dict | None:
        if not pool:
            return None
        pool.sort(key=lambda f: f.get("abr") or 0, reverse=True)
        if max_abr is not None:
            filtered = [f for f in pool if (f.get("abr") or 0) <= max_abr]
            if filtered:
                pool = filtered
        m4a = [f for f in pool if f.get("ext") == "m4a"]
        return m4a[0] if m4a else pool[0]

    result = _best(_audio_only(playable))
    if result:
        return result
    result = _best(_muxed(playable))
    if result:
        return result
    raise YtDlpError("no playable audio format extracted")


def _stream_variants() -> list[dict]:
    settings = get_settings()
    cookie_path = _cookiefile_path()
    has_cookies = cookie_path is not None
    variants: list[dict] = []
    if has_cookies:
        variants.append({
            "label": "forced-clients+cookies",
            "extractor_args": _FORCED_CLIENTS,
            "cookiefile": cookie_path,
        })
        variants.append({
            "label": "default-clients+cookies",
            "cookiefile": cookie_path,
        })
        variants.append({
            "label": "forced-clients-no-cookie",
            "extractor_args": _FORCED_CLIENTS,
        })
    else:
        variants.append({
            "label": "forced-clients",
            "extractor_args": _FORCED_CLIENTS,
        })
        variants.append({
            "label": "default-clients",
        })
    return variants


async def _extract_info(url: str, opts: dict) -> dict:
    settings = get_settings()
    base = {
        "quiet": True,
        "no_warnings": True,
        "no_call_home": True,
        "cachedir": settings.ytdlp_cache_dir,
    }
    merged = {**base, **opts}

    def _work():
        with yt_dlp.YoutubeDL(merged) as ydl:
            info = ydl.extract_info(url, download=False)
            return ydl.sanitize_info(info)

    try:
        return await asyncio.to_thread(_work)
    except DownloadError as exc:
        msg = str(exc)[-500:] or "yt-dlp extraction failed"
        if "Sign in to confirm" in msg:
            msg = (
                "YouTube bot-check: cookies belum dipasang / kedaluwarsa "
                "(set YOUTUBE_COOKIES di env)"
            )
        raise YtDlpError(msg) from exc


async def search(query: str, limit: int, prefix: str) -> list[dict]:
    info = await _extract_info(
        f"{prefix}{limit}:{query}",
        {"extract_flat": True},
    )
    return list(info.get("entries") or [])


async def extract_stream(video_id: str, quality: str) -> dict:
    url = f"https://www.youtube.com/watch?v={video_id}"
    max_abr = _parse_abr(quality)
    errors: list[str] = []
    for variant in _stream_variants():
        label = variant.pop("label")
        opts = {"format": "b*", "noplaylist": True, **variant}
        try:
            info = await _extract_info(url, opts)
            fmt = _pick_audio_format(info.get("formats") or [], max_abr=max_abr)
            stream_url = fmt.get("url")
            if not stream_url:
                raise YtDlpError("no playable url in chosen format")
            logger.info("stream[%s] %s succeeded", label, video_id)
            return {
                "url": stream_url,
                "ext": fmt.get("ext", ""),
                "abr": fmt.get("abr"),
                "title": info.get("title", ""),
            }
        except YtDlpError as exc:
            err_msg = f"{label}: {str(exc)[-200:]}"
            logger.warning("stream[%s] %s failed: %s", label, video_id, str(exc)[-200:])
            errors.append(err_msg)
    raise YtDlpError(" | ".join(errors))


async def extract_mix(mix_id: str) -> list[dict]:
    info = await _extract_info(
        f"https://www.youtube.com/playlist?list={mix_id}",
        {"extract_flat": True},
    )
    results = []
    for e in info.get("entries") or []:
        normalized = normalize_entry(e, "youtube")
        if normalized:
            results.append(normalized)
    return results


def normalize_entry(entry: dict, source: str) -> dict | None:
    video_id = entry.get("id")
    if not video_id:
        return None
    return {
        "id": video_id,
        "duration": int(entry.get("duration") or 0),
        "title": entry.get("title") or "",
        "artist": (entry.get("artist") or entry.get("uploader") or ""),
        "uploader": entry.get("uploader") or "",
        "thumb": _thumbnail(entry),
        "url": f"https://www.youtube.com/watch?v={video_id}",
    }


def _thumbnail(entry: dict) -> str:
    thumbs = entry.get("thumbnails") or []
    if thumbs:
        return thumbs[-1].get("url", "")
    return ""


def _parse_abr(quality: str) -> int | None:
    digits = "".join(c for c in quality if c.isdigit())
    return int(digits) if digits else None
