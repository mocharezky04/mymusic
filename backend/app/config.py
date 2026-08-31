


from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "mymusic-backend"
    cors_origins: str = "*"

    stream_cache_ttl: int = 6 * 60 * 60
    search_limit: int = 10

    redis_url: str | None = None
    ytdlp_cache_dir: str = str(BASE_DIR / ".cache")
    data_dir: str = str(BASE_DIR / "data")

    lastfm_api_key: str | None = None
    soundcloud_client_id: str | None = None
    spotify_client_id: str | None = None
    spotify_client_secret: str | None = None

    google_client_id: str | None = None
    google_client_secret: str | None = None
    youtube_callback_uri: str = "http://127.0.0.1:8000/youtube/callback"

    api_key: str | None = None

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()