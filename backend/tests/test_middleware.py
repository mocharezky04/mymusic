import os

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.middleware import ApiKeyMiddleware


def _make_app(api_key: str | None = None) -> FastAPI:
    test_app = FastAPI()
    test_app.add_middleware(ApiKeyMiddleware, api_key=api_key)

    @test_app.get("/health")
    async def health():
        return {"status": "ok"}

    @test_app.get("/data")
    async def data():
        return {"data": "secret"}

    return test_app


def test_no_key_configured_allows_all():
    app = _make_app(api_key=None)
    with TestClient(app) as client:
        assert client.get("/health").status_code == 200
        assert client.get("/data").status_code == 200


def test_key_configured_allows_health_without_key():
    app = _make_app(api_key="secret-key")
    with TestClient(app) as client:
        assert client.get("/health").status_code == 200


def test_key_configured_blocks_data_without_key():
    app = _make_app(api_key="secret-key")
    with TestClient(app) as client:
        resp = client.get("/data")
        assert resp.status_code == 401
        assert resp.json()["detail"] == "Unauthorized"


def test_key_configured_allows_data_with_correct_key():
    app = _make_app(api_key="secret-key")
    with TestClient(app) as client:
        resp = client.get("/data", headers={"X-API-Key": "secret-key"})
        assert resp.status_code == 200
        assert resp.json() == {"data": "secret"}


def test_key_configured_blocks_data_with_wrong_key():
    app = _make_app(api_key="secret-key")
    with TestClient(app) as client:
        resp = client.get("/data", headers={"X-API-Key": "wrong-key"})
        assert resp.status_code == 401
