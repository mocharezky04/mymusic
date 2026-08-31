FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS base

RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY pyproject.toml uv.lock ./
RUN uv sync --no-dev

COPY app ./app
COPY README.md ./

ENV PATH="/app/.venv/bin:$PATH" \
    YTDLP_CACHE_DIR=/app/.cache

EXPOSE 8000

CMD uvicorn --app-dir . app.main:app --host 0.0.0.0 --port ${PORT:-8000}