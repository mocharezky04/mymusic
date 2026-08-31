import time

import redis.asyncio as aioredis

from .config import get_settings


class StreamCache:
    def __init__(self) -> None:
        settings = get_settings()
        self._ttl = settings.stream_cache_ttl
        self._mem: dict[str, tuple[float, str]] = {}
        self._redis: aioredis.Redis | None = None
        if settings.redis_url:
            self._redis = aioredis.from_url(settings.redis_url)

    async def close(self) -> None:
        if self._redis:
            await self._redis.aclose()

    async def get(self, key: str) -> str | None:
        if self._redis:
            value = await self._redis.get(key)
            return value.decode() if value else None
        item = self._mem.get(key)
        if item is None:
            return None
        expires, value = item
        if expires < time.monotonic():
            self._mem.pop(key, None)
            return None
        return value

    async def set(self, key: str, value: str) -> None:
        if self._redis:
            await self._redis.setex(key, self._ttl, value)
            return
        self._mem[key] = (time.monotonic() + self._ttl, value)


cache = StreamCache()