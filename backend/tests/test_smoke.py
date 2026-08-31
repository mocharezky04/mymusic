from fastapi.testclient import TestClient

from app.main import app


def test_health():
    with TestClient(app) as client:
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json() == {"status": "ok"}


def test_unknown_route_returns_404():
    with TestClient(app) as client:
        response = client.get("/nope")
        assert response.status_code == 404