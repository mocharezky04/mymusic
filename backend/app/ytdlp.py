import asyncio
import hashlib
import logging
import os
import shutil
import socket
import sys
import tempfile
import threading
import urllib.request
import zipfile
from pathlib import Path

import yt_dlp
from yt_dlp.utils import DownloadError

from .config import get_settings

logger = logging.getLogger(__name__)

_COOKIE_FILENAME = "yt_cookies.txt"

_FORCED_CLIENTS = {"youtube": {"player_client": ["tv", "android_vr", "tv_simply"]}}


_DENO_VERSION = "2.9.6"
_DENO_URL = (
    "https://github.com/denoland/deno/releases/download/"
    f"v{_DENO_VERSION}/deno-x86_64-unknown-linux-gnu.zip"
)

_deno_lock = threading.Lock()
_deno_ready = False


def _deno_candidates() -> list[Path]:
    return [
        Path(os.getcwd()) / "bin",
        Path(__file__).resolve().parent.parent / "bin",
        Path(tempfile.gettempdir()) / "deno-bin",
    ]


def _install_deno_runtime() -> Path | None:
    """Download deno into /tmp at runtime (Vercel does not bundle build-time
    files into the Python lambda, so buildCommand-installed deno is lost)."""
    dest = Path(tempfile.gettempdir()) / "deno-bin"
    zip_path = dest / "deno.zip"
    try:
        dest.mkdir(parents=True, exist_ok=True)
        logger.info("deno not found; downloading runtime copy to %s", dest)
        old_timeout = socket.getdefaulttimeout()
        socket.setdefaulttimeout(120)
        try:
            urllib.request.urlretrieve(_DENO_URL, zip_path)
        finally:
            socket.setdefaulttimeout(old_timeout)
        with zipfile.ZipFile(zip_path) as zf:
            zf.extractall(dest)
        deno = dest / "deno"
        deno.chmod(0o755)
        zip_path.unlink(missing_ok=True)
        logger.info("deno runtime installed at %s", deno)
        return dest
    except Exception:
        logger.exception("runtime deno install failed")
        return None


def _ensure_deno_on_path() -> None:
    global _deno_ready
    if _deno_ready:
        return
    with _deno_lock:
        if _deno_ready:
            return
        for cand in _deno_candidates():
            deno = cand / "deno"
            if deno.is_file():
                try:
                    deno.chmod(0o755)
                except OSError:
                    pass
                os.environ["PATH"] = str(cand) + os.pathsep + os.environ.get("PATH", "")
                _deno_ready = True
                logger.info("deno found at %s", deno)
                return
        if shutil.which("deno"):
            _deno_ready = True
            logger.info("deno found on system PATH")
            return
        if sys.platform.startswith("linux"):
            installed = _install_deno_runtime()
            if installed is not None:
                os.environ["PATH"] = (
                    str(installed) + os.pathsep + os.environ.get("PATH", "")
                )
        else:
            logger.info("skipping runtime deno install on %s", sys.platform)
        _deno_ready = True


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
    variants.append({"label": "default-no-cookie"})
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
        _ensure_deno_on_path()
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
    logger.info("JS runtimes: node=%s deno=%s bun=%s",
        shutil.which("node"), shutil.which("deno"), shutil.which("bun"))
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
