import pytest

from app.main import app
from app.models import RecommendationRequest


class FakeSettings:
    lastfm_api_key = None


@pytest.fixture()
def client(tmp_path):
    import app.recommend as rec_mod

    old = rec_mod.get_settings
    rec_mod.get_settings = lambda: FakeSettings()
    from fastapi.testclient import TestClient

    with TestClient(app) as c:
        yield c
    rec_mod.get_settings = old


async def _fake_search(query, limit):
    return []


def test_empty_seeds_and_empty_seed_tracks_returns_empty(client, monkeypatch):
    import app.recommend as rec_mod

    monkeypatch.setattr(rec_mod, "search_youtube", _fake_search)
    resp = client.post("/recommendations", json={"seeds": [], "seed_tracks": [], "limit": 5})
    assert resp.status_code == 200
    assert resp.json()["recommendations"] == []


def test_seed_tracks_only_not_empty(client, monkeypatch):
    import app.recommend as rec_mod

    from app.models import Track

    async def _stub_search(query, limit):
        return [
            Track(id="v1", source="youtube", title="Similar Song", artist="Artist A"),
            Track(id="v2", source="youtube", title="Another Track", artist="Artist B"),
        ]

    monkeypatch.setattr(rec_mod, "search_youtube", _stub_search)
    resp = client.post(
        "/recommendations",
        json={
            "seeds": [],
            "seed_tracks": [{"artist": "Artist X", "title": "Some Song"}],
            "limit": 5,
        },
    )
    assert resp.status_code == 200
    data = resp.json()["recommendations"]
    assert len(data) > 0
