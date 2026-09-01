from pathlib import Path

from app.config import Settings
from app.ytdlp import _cookiefile_path, _stream_variants

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


def test_variants_with_cookies(monkeypatch):
    monkeypatch.setenv("YOUTUBE_COOKIES", MOCK_COOKIES)
    monkeypatch.setattr("app.ytdlp.get_settings", lambda: Settings())
    vs = _stream_variants()
    labels = [v["label"] for v in vs]
    assert "forced-clients+cookies" in labels
    assert "default-clients+cookies" in labels
    assert "forced-clients-no-cookie" in labels


def test_variants_without_cookies(monkeypatch):
    monkeypatch.delenv("YOUTUBE_COOKIES", raising=False)
    monkeypatch.setattr("app.ytdlp.get_settings", lambda: Settings())
    vs = _stream_variants()
    labels = [v["label"] for v in vs]
    assert "forced-clients" in labels
    assert "default-clients" in labels


def test_variants_default_clients_has_no_extractor_args(monkeypatch):
    monkeypatch.delenv("YOUTUBE_COOKIES", raising=False)
    monkeypatch.setattr("app.ytdlp.get_settings", lambda: Settings())
    vs = _stream_variants()
    default = [v for v in vs if v["label"] == "default-clients"][0]
    assert "extractor_args" not in default
