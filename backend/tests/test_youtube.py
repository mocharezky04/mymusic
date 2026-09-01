import base64
import hashlib
import hmac
import json
import time

import pytest
from fastapi.testclient import TestClient

from app import account_store
from app.main import app


class FakeSettings:
    google_client_id = "client-id"
    google_client_secret = "client-secret"
    youtube_callback_uri = "http://127.0.0.1:8000/youtube/callback"
    api_key = "test-secret-key-for-hmac"


class DisabledSettings(FakeSettings):
    google_client_id = None
    google_client_secret = None


def _make_state(verifier: str = "test-verifier", age: int = 0) -> str:
    payload = base64.urlsafe_b64encode(
        json.dumps({"v": verifier, "t": int(time.time()) - age}).encode()
    ).decode().rstrip("=")
    secret = FakeSettings.api_key.encode()
    sig = hmac.new(secret, payload.encode(), hashlib.sha256).hexdigest()[:32]
    return f"{payload}.{sig}"


@pytest.fixture()
def client(tmp_path):
    import app.routes.youtube as yt_route

    old_route = yt_route.get_settings
    yt_route.get_settings = lambda: FakeSettings()
    with TestClient(app) as test_client:
        yield test_client
    yt_route.get_settings = old_route


def test_youtube_returns_503_when_not_configured():
    import app.routes.youtube as yt_route

    old = yt_route.get_settings
    yt_route.get_settings = lambda: DisabledSettings()
    try:
        with TestClient(app) as test_client:
            assert test_client.get("/youtube/me").status_code == 503
            assert test_client.get("/youtube/auth/start").status_code == 503
    finally:
        yt_route.get_settings = old


def test_me_returns_empty_always(client):
    response = client.get("/youtube/me")
    assert response.status_code == 200
    assert response.json() == {"accounts": []}


def test_disconnect_returns_ok_always(client):
    response = client.post("/youtube/disconnect", json={"account": "anyone@mail.com"})
    assert response.status_code == 200
    assert response.json() == {"ok": True}


def test_auth_start_redirects_to_google(client):
    response = client.get("/youtube/auth/start", follow_redirects=False)
    assert response.status_code == 302
    location = response.headers["location"]
    assert location.startswith("https://accounts.google.com/")
    assert "prompt=consent" in location
    assert "youtube.readonly" in location
    assert "code_challenge" in location


def test_auth_start_state_has_valid_hmac(client):
    response = client.get("/youtube/auth/start", follow_redirects=False)
    location = response.headers["location"]
    state = location.split("state=")[1].split("&")[0]
    payload_b64, sig = state.split(".", 1)
    secret = FakeSettings.api_key.encode()
    expected = hmac.new(secret, payload_b64.encode(), hashlib.sha256).hexdigest()[:32]
    assert hmac.compare_digest(sig, expected)
    padded = payload_b64 + "=" * (-len(payload_b64) % 4)
    payload = json.loads(base64.urlsafe_b64decode(padded))
    assert "v" in payload
    assert "t" in payload


def test_callback_unknown_state_returns_html(client):
    response = client.get("/youtube/callback", params={"code": "x", "state": "invalid.abc"})
    assert response.status_code == 200
    assert "text/html" in response.headers["content-type"]
    assert "Sesi kedaluwarsa" in response.text


def test_callback_expired_state_returns_html(client):
    state = _make_state(age=1000)
    response = client.get("/youtube/callback", params={"code": "x", "state": state})
    assert response.status_code == 200
    assert "Sesi kedaluwarsa" in response.text


async def _fake_exchange(*_):
    return {"refresh_token": "refresh", "access_token": "access"}


async def _fake_email(*_):
    return "a@mail.com"


async def _fake_channel(*_):
    return {"channel_id": "ch1", "channel_title": "A", "avatar_url": "u"}


async def _fake_empty_channel(*_):
    return {"channel_id": "", "channel_title": "", "avatar_url": ""}


def test_callback_valid_state_contains_deep_link_with_refresh_token(client, monkeypatch):
    import app.routes.youtube as yt_route

    state = _make_state()
    monkeypatch.setattr(yt_route, "exchange_code", _fake_exchange)
    monkeypatch.setattr(yt_route, "fetch_email", _fake_email)
    monkeypatch.setattr(yt_route, "fetch_profile", _fake_channel)
    response = client.get("/youtube/callback", params={"code": "c", "state": state})
    assert response.status_code == 200
    assert "Akun terhubung" in response.text
    assert "mymusic://oauth/callback" in response.text
    assert "refresh_token=refresh" in response.text
    assert "email=a%40mail.com" in response.text
    assert "channel_id=ch1" in response.text


def test_callback_falls_back_to_userinfo_when_no_channel(client, monkeypatch):
    import app.routes.youtube as yt_route

    state = _make_state()
    monkeypatch.setattr(yt_route, "exchange_code", _fake_exchange)
    monkeypatch.setattr(yt_route, "fetch_email", _fake_email)

    async def _fake_profile_from_userinfo(*_):
        channel = await _fake_empty_channel()
        if not channel["channel_id"]:
            return {"channel_id": "", "channel_title": "a@mail.com", "avatar_url": "pic"}
        return channel

    monkeypatch.setattr(yt_route, "fetch_profile", _fake_profile_from_userinfo)
    response = client.get("/youtube/callback", params={"code": "c", "state": state})
    assert response.status_code == 200
    assert "mymusic://oauth/callback" in response.text
    assert "refresh_token=refresh" in response.text


def test_playlists_without_token_returns_401(client):
    response = client.get("/youtube/playlists", params={"account": "x"})
    assert response.status_code == 401
    assert "X-Refresh-Token" in response.json()["detail"]


def test_playlists_with_fake_token_tries_exchange(client, monkeypatch):
    import app.routes.youtube as yt_route
    from app.google_yt import GoogleApiError

    async def _fail_refresh(_):
        raise GoogleApiError("token invalid")

    monkeypatch.setattr(yt_route, "refresh_access_token", _fail_refresh)
    response = client.get(
        "/youtube/playlists",
        params={"account": "x"},
        headers={"X-Refresh-Token": "fake-token"},
    )
    assert response.status_code == 502


def test_playlists_tracks_without_token_returns_401(client):
    response = client.get("/youtube/playlists/PL123/tracks", params={"account": "x"})
    assert response.status_code == 401


def test_playlists_tracks_with_fake_token_tries_exchange(client, monkeypatch):
    import app.routes.youtube as yt_route
    from app.google_yt import GoogleApiError

    async def _fail_refresh(_):
        raise GoogleApiError("token invalid")

    monkeypatch.setattr(yt_route, "refresh_access_token", _fail_refresh)
    response = client.get(
        "/youtube/playlists/PL123/tracks",
        params={"account": "x"},
        headers={"X-Refresh-Token": "fake-token"},
    )
    assert response.status_code == 502


_YT_API = "https://www.googleapis.com/youtube/v3"


def test_fetch_liked_count_does_not_send_id_and_mine_together(monkeypatch):
    import app.google_yt as google_yt

    captured_params: list[dict] = []

    async def _mock_youtube_get(access_token, path, params):
        captured_params.append(params)
        return {"items": []}

    monkeypatch.setattr(google_yt, "_youtube_get", _mock_youtube_get)

    import asyncio

    asyncio.get_event_loop().run_until_complete(
        google_yt.fetch_liked_count("fake-token")
    )

    assert len(captured_params) >= 1
    params = captured_params[0]
    assert "id" in params or "mine" in params
    assert not ("id" in params and "mine" in params), (
        f"playlists.list must not have both 'id' and 'mine': {params}"
    )


def test_fetch_playlists_only_uses_mine(monkeypatch):
    import app.google_yt as google_yt

    captured_params: list[dict] = []

    async def _mock_youtube_get(access_token, path, params):
        captured_params.append(params)
        return {"items": []}

    monkeypatch.setattr(google_yt, "_youtube_get", _mock_youtube_get)

    import asyncio

    asyncio.get_event_loop().run_until_complete(
        google_yt.fetch_playlists("fake-token")
    )

    for params in captured_params:
        assert not ("id" in params and "mine" in params), (
            f"playlists.list must not have both 'id' and 'mine': {params}"
        )


def test_fetch_liked_playlist_id_only_uses_mine(monkeypatch):
    import app.google_yt as google_yt

    captured_params: list[dict] = []

    async def _mock_youtube_get(access_token, path, params):
        captured_params.append(params)
        return {"items": [{"contentDetails": {"relatedPlaylists": {"likes": "PLxxx"}}}]}

    monkeypatch.setattr(google_yt, "_youtube_get", _mock_youtube_get)

    import asyncio

    asyncio.get_event_loop().run_until_complete(
        google_yt.fetch_liked_playlist_id("fake-token")
    )

    assert len(captured_params) >= 1
    for params in captured_params:
        assert "id" not in params or "mine" not in params, (
            f"channels.list must not have both 'id' and 'mine': {params}"
        )
