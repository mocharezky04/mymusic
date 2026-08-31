from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .cache import cache
from .config import get_settings
from .middleware import ApiKeyMiddleware
from .routes import lyrics, recommend, search, stream, youtube


@asynccontextmanager
async def lifespan(_: FastAPI):
    yield
    await cache.close()


settings = get_settings()

app = FastAPI(title=settings.app_name, version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_methods=["*"],
    allow_headers=["*"],
)

if settings.api_key:
    app.add_middleware(ApiKeyMiddleware, api_key=settings.api_key)

app.include_router(search.router)
app.include_router(stream.router)
app.include_router(lyrics.router)
app.include_router(youtube.router)
app.include_router(recommend.router)


@app.get("/health", tags=["meta"])
async def health() -> dict[str, str]:
    return {"status": "ok"}