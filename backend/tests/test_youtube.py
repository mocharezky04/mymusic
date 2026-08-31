import pytest
from fastapi.testclient import TestClient

from app import account_store
from app.main import app


class FakeSettings:
    google_client_id = "client-id"
    google_client_secret = "client-secret"
    youtube_callback_uri = "http://127.0.0.1:8000/youtube/callback"


class DisabledSettings(FakeSettings):
    google_client_id = None
    google_client_secret = None


@pytest.fixture()
def client(tmp_path):
    store_settings = FakeSettings()
    store_settings.data_dir = str(tmp_path)
    import app.routes.youtube as yt_route

    old_store = account_store.get_settings
    old_route = yt_route.get_settings
    account_store.get_settings = lambda: store_settings
    yt_route.get_settings = lambda: store_settings
    with TestClient(app) as test_client:
        yield test_client
    account_store.get_settings = old_store
    yt_route.get_settings = old_route


def test_store_upsert_keeps_multiple_accounts(tmp_path):
    db = tmp_path / "accounts.db"
    account_store.upsert_account("a@mail.com", "ch1", "A", "", "tok-a", db)
    account_store.upsert_account("b@mail.com", "ch2", "B", "", "tok-b", db)
    assert {a["email"] for a in account_store.list_accounts(db)} == {
        "a@mail.com",
        "b@mail.com",
    }


def test_store_upsert_updates_existing_without_duplicate(tmp_path):
    db = tmp_path / "accounts.db"
    account_store.upsert_account("a@mail.com", "ch1", "A", "", "tok-1", db)
    account_store.upsert_account("a@mail.com", "ch1", "A2", "", "tok-2", db)
    rows = account_store.list_accounts(db)
    assert len(rows) == 1
    assert account_store.get_account("a@mail.com", db)["refresh_token"] == "tok-2"


def test_store_delete_only_target_account(tmp_path):
    db = tmp_path / "accounts.db"
    account_store.upsert_account("a@mail.com", "ch1", "A", "", "tok-a", db)
    account_store.upsert_account("b@mail.com", "ch2", "B", "", "tok-b", db)
    assert account_store.delete_account("a@mail.com", db) is True
    assert [a["email"] for a in account_store.list_accounts(db)] == ["b@mail.com"]


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


def test_playlists_unknown_account_returns_404(client):
    response = client.get("/youtube/playlists", params={"account": "nobody@mail.com"})
    assert response.status_code == 404


def test_disconnect_unknown_account_returns_404(client):
    response = client.post("/youtube/disconnect", json={"account": "nobody@mail.com"})
    assert response.status_code == 404


def test_disconnect_existing_account(client, tmp_path):
    db = tmp_path / "accounts.db"
    account_store.upsert_account("a@mail.com", "ch1", "A", "", "tok-a", db)
    response = client.post("/youtube/disconnect", json={"account": "a@mail.com"})
    assert response.status_code == 200
    assert account_store.get_account("a@mail.com", db) is None


def test_me_returns_empty_when_no_account(client):
    response = client.get("/youtube/me")
    assert response.status_code == 200
    assert response.json() == {"accounts": []}


def test_auth_start_redirects_to_google(client):
    response = client.get("/youtube/auth/start", follow_redirects=False)
    assert response.status_code == 302
    location = response.headers["location"]
    assert location.startswith("https://accounts.google.com/")
    assert "prompt=consent" in location
    assert "youtube.readonly" in location
    assert "code_challenge" in location


def test_callback_unknown_state_returns_html(client):
    response = client.get("/youtube/callback", params={"code": "x", "state": "nope"})
    assert response.status_code == 200
    assert "text/html" in response.headers["content-type"]
    assert "Sesi kedaluwarsa" in response.text


async def _fake_exchange(*_):
    return {"refresh_token": "refresh", "access_token": "access"}


async def _fake_email(*_):
    return "a@mail.com"


async def _fake_channel(*_):
    return {"channel_id": "ch1", "channel_title": "A", "avatar_url": "u"}


async def _fake_empty_channel(*_):
    return {"channel_id": "", "channel_title": "", "avatar_url": ""}


async def _fake_userinfo(*_):
    return {
        "email": "a@mail.com",
        "picture": "pic",
        "name": "a@mail.com",
    }


async def _fake_token(*_):
    return {"access_token": "access", "expires_in": 3600}


def test_callback_success_saves_account(client, monkeypatch):
    import app.routes.youtube as yt_route

    yt_route.pending_flows["state"] = {
        "verifier": "verifier",
        "created": __import__("time").monotonic(),
    }
    monkeypatch.setattr(yt_route, "exchange_code", _fake_exchange)
    monkeypatch.setattr(yt_route, "fetch_email", _fake_email)
    monkeypatch.setattr(yt_route, "fetch_profile", _fake_channel)
    response = client.get("/youtube/callback", params={"code": "c", "state": "state"})
    assert response.status_code == 200
    assert "Akun terhubung" in response.text
    assert yt_route.get_account("a@mail.com")["channel_id"] == "ch1"


async def _fake_profile_from_userinfo(*_):
    channel = await _fake_empty_channel()
    if not channel["channel_id"]:
        return {
            "channel_id": "",
            "channel_title": "a@mail.com",
            "avatar_url": "pic",
        }
    return channel


def test_callback_falls_back_to_userinfo_when_no_channel(client, monkeypatch):
    import app.routes.youtube as yt_route

    yt_route.pending_flows["state"] = {
        "verifier": "verifier",
        "created": __import__("time").monotonic(),
    }
    monkeypatch.setattr(yt_route, "exchange_code", _fake_exchange)
    monkeypatch.setattr(yt_route, "fetch_email", _fake_email)
    monkeypatch.setattr(yt_route, "fetch_profile", _fake_profile_from_userinfo)
    response = client.get("/youtube/callback", params={"code": "c", "state": "state"})
    assert response.status_code == 200
    assert "Akun terhubung" in response.text
    stored = yt_route.get_account("a@mail.com")
    assert stored["channel_title"] == "a@mail.com"
    assert stored["avatar_url"] == "pic"


def test_refresh_profile_unknown_account_returns_404(client):
    response = client.post("/youtube/profiles/refresh", json={"account": "nobody@mail.com"})
    assert response.status_code == 404


def test_refresh_profile_fixes_empty_account(client, tmp_path, monkeypatch):
    import app.routes.youtube as yt_route

    db = tmp_path / "accounts.db"
    account_store.upsert_account("a@mail.com", "", "", "", "tok-a", db)
    monkeypatch.setattr(yt_route, "refresh_access_token", _fake_token)
    monkeypatch.setattr(yt_route, "fetch_profile", _fake_channel)
    response = client.post("/youtube/profiles/refresh", json={"account": "a@mail.com"})
    assert response.status_code == 200
    assert response.json() == {
        "email": "a@mail.com",
        "channel_id": "ch1",
        "channel_title": "A",
        "avatar_url": "u",
    }
    stored = account_store.get_account("a@mail.com", db)
    assert stored["channel_id"] == "ch1"
    assert stored["refresh_token"] == "tok-a"


_YT_API = "https://www.googleapis.com/youtube/v3"


def test_fetch_liked_count_does_not_send_id_and_mine_together(monkeypatch):
    """Regression: playlists.list with both id= and mine= returns 400.
    fetch_liked_count must only use 'id', never combine with 'mine'."""
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
    """Regression: playlists.list for user playlists must only use 'mine', not 'id'."""
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
    """Regression: channels.list for liked playlist ID must only use 'mine'."""
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