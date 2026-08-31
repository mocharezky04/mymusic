# mymusic-backend

Backend FastAPI untuk MyMusic: pencarian lagu multi-sumber, resolusi URL stream lewat yt-dlp, dan lirik. Detail setup ada di README bagian root repo.

## Endpoint

- `GET /health` — pengecekan ketersediaan
- `GET /search?q=...&limit=...` — cari lagu
- `GET /stream?id=...&source=...` — URL stream untuk sebuah track
- `GET /lyrics?track=...&artist=...` — lirik (plain atau LRC synced)

## Menjalankan

```sh
uv sync
uv run uvicorn --app-dir . app.main:app --host 0.0.0.0 --port 8000
```

Atau via Docker Compose (ikut Redis):

```sh
docker compose up -d --build
```

## Development

```sh
uv sync --group dev
uv run ruff check app tests
uv run pytest
```