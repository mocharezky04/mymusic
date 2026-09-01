from pathlib import Path

from app.config import Settings
from app.ytdlp import _base_opts, _cookiefile_path

MOCK_COOKIES = (
    "# Netscape HTTP Cookie File\n"
    ".youtube\tTRUE\t/\tTRUE\t0\tVISITOR_INFO1_LIVE\tabc123\n"
)


def test_cookiefile_path_writes_when_settings_has_cookies(tmp_path, monkeypatch):
    monkeypatch.setenv("YOUTUBE_COOKIES", MOCK_COOKIES)
    monkeypatch.setattr("app.ytdlp.get_settings", lambda: Settings())
    path = _cookiefile_path()
    assert path is not None
    assert Path(path).name == "yt_cookies.txt"
    content = Path(path).read_text(encoding="utf-8")
    assert "VISITOR_INFO1_LIVE" in content


def test_cookiefile_path_none_when_no_cookies(monkeypatch):
    monkeypatch.delenv("YOUTUBE_COOKIES", raising=False)
    monkeypatch.setattr("app.ytdlp.get_settings", lambda: Settings())
    assert _cookiefile_path() is None


def test_base_opts_includes_cookiefile_when_cookies_set(monkeypatch):
    monkeypatch.setenv("YOUTUBE_COOKIES", MOCK_COOKIES)
    monkeypatch.setattr("app.ytdlp.get_settings", lambda: Settings())
    opts = _base_opts()
    assert "cookiefile" in opts
    assert Path(opts["cookiefile"]).exists()


def test_base_opts_no_cookiefile_when_empty(monkeypatch):
    monkeypatch.delenv("YOUTUBE_COOKIES", raising=False)
    monkeypatch.setattr("app.ytdlp.get_settings", lambda: Settings())
    opts = _base_opts()
    assert "cookiefile" not in opts


def test_base_opts_has_player_client(monkeypatch):
    monkeypatch.delenv("YOUTUBE_COOKIES", raising=False)
    monkeypatch.setattr("app.ytdlp.get_settings", lambda: Settings())
    opts = _base_opts()
    pc = opts["extractor_args"]["youtube"]["player_client"]
    assert pc[0] == "tv_simply"
    assert "android_vr" in pc
    assert "ios" in pc
