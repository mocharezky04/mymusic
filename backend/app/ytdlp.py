import asyncio
import tempfile

import yt_dlp
from yt_dlp.utils import DownloadError

from .config import get_settings


class YtDlpError(Exception):
    pass


def _base_opts() -> dict:
    return {
        "quiet": True,
        "no_warnings": True,
        "no_call_home": True,
        "cachedir": tempfile.gettempdir(),
    }


async def _extract_info(url: str, opts: dict) -> dict:
    settings = get_settings()
    merged = {**_base_opts(), "cachedir": settings.ytdlp_cache_dir, **opts}

    def _work():
        with yt_dlp.YoutubeDL(merged) as ydl:
            info = ydl.extract_info(url, download=False)
            return ydl.sanitize_info(info)

    try:
        return await asyncio.to_thread(_work)
    except DownloadError as exc:
        raise YtDlpError(str(exc)[-500:] or "yt-dlp extraction failed") from exc


async def search(query: str, limit: int, prefix: str) -> list[dict]:
    info = await _extract_info(
        f"{prefix}{limit}:{query}",
        {"extract_flat": True},
    )
    return list(info.get("entries") or [])


async def extract_stream(video_id: str, format_spec: str) -> dict:
    url = f"https://www.youtube.com/watch?v={video_id}"
    info = await _extract_info(
        url,
        {"format": format_spec, "noplaylist": True},
    )
    stream_url = info.get("url")
    if not stream_url:
        raise YtDlpError("no playable url extracted")
    return {
        "url": stream_url,
        "ext": info.get("ext", ""),
        "abr": info.get("abr"),
        "title": info.get("title", ""),
    }


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


def format_for(quality: str) -> str:
    abr = _parse_abr(quality)
    if abr is None:
        return "bestaudio[ext=m4a]/bestaudio[acodec!=opus]/bestaudio"
    return (
        f"bestaudio[ext=m4a][abr<={abr}]"
        f"/bestaudio[abr<={abr}]"
        f"/bestaudio[ext=m4a]"
        f"/bestaudio[acodec!=opus]"
        f"/bestaudio"
    )


def _parse_abr(quality: str) -> int | None:
    digits = "".join(c for c in quality if c.isdigit())
    return int(digits) if digits else None
