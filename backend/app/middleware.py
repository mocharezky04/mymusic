from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse


class ApiKeyMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, api_key: str | None = None) -> None:
        super().__init__(app)
        self._api_key = api_key

    async def dispatch(self, request: Request, call_next):
        if request.url.path == "/health":
            return await call_next(request)
        if self._api_key:
            provided = request.headers.get("X-API-Key", "")
            if provided != self._api_key:
                return JSONResponse({"detail": "Unauthorized"}, status_code=401)
        return await call_next(request)
