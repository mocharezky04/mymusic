import asyncio
import json
import sys

from .config import get_settings


class YtDlpError(Exception):
    pass


async def _run(args: list[str], timeout: float = 90.0) -> str:
    ytdlp_cache = get_settings().ytdlp_cache_dir
    cmd = [
        sys.executable,
        "-m",
        "yt_dlp",
        "--no-warnings",
        "--no-call-home",
        "--cache-dir",
        ytdlp_cache,
        *args,
    ]
    proc = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    try:
        stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout)
    except TimeoutError:
        proc.kill()
        await proc.communicate()
        raise YtDlpError("yt-dlp timed out") from None
    if proc.returncode != 0:
        detail = stderr.decode(errors="replace").strip()
        raise YtDlpError(detail[-500:] or f"yt-dlp exited with {proc.returncode}")
    return stdout.decode(errors="replace")


async def search(query: str, limit: int, prefix: str) -> list[dict]:
    out = await _run(["--flat-playlist", "-J", f"{prefix}{limit}:{query}"])
    data = json.loads(out)
    return list(data.get("entries") or [])


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


async def extract_stream(video_id: str, format_spec: str) -> dict:
    out = await _run(
        [
            "-J",
            "--no-playlist",
            "-f",
            format_spec,
            f"https://www.youtube.com/watch?v={video_id}",
        ],
        timeout=120.0,
    )
    data = json.loads(out)
    url = data.get("url")
    if not url:
        raise YtDlpError("no playable url extracted")
    return {
        "url": url,
        "ext": data.get("ext", ""),
        "abr": data.get("abr"),
        "title": data.get("title", ""),
    }


async def extract_mix(mix_id: str) -> list[dict]:
    out = await _run(
        ["--flat-playlist", "-J", f"https://www.youtube.com/playlist?list={mix_id}"],
        timeout=60.0,
    )
    data = json.loads(out)
    entries = list(data.get("entries") or [])
    results = []
    for e in entries:
        normalized = normalize_entry(e, "youtube")
        if normalized:
            results.append(normalized)
    return results


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