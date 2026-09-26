from typing import Literal

from pydantic import BaseModel

Source = Literal["youtube", "ytmusic", "soundcloud", "spotify"]


class Track(BaseModel):
    id: str
    source: Source
    title: str
    artist: str = ""
    duration: int = 0
    thumb: str = ""
    uploader: str = ""
    url: str = ""
    # "video" (bisa diputar), "mix" (radio YouTube Music), "album", "channel".
    kind: str = "video"


class SuggestResponse(BaseModel):
    suggestions: list[str] = []


class SearchResponse(BaseModel):
    query: str
    results: list[Track]


class StreamInfo(BaseModel):
    video_id: str
    url: str
    ext: str = ""
    abr: float | None = None
    title: str = ""


class LyricsResponse(BaseModel):
    found: bool
    synced: bool = False
    plain: str | None = None
    lrc: str | None = None


class YoutubeAccount(BaseModel):
    email: str
    channel_id: str
    channel_title: str
    avatar_url: str = ""


class YoutubeAccountsResponse(BaseModel):
    accounts: list[YoutubeAccount]


class YoutubePlaylist(BaseModel):
    id: str
    title: str
    count: int = 0
    thumb: str = ""
    owner: str = ""


class YoutubePlaylistsResponse(BaseModel):
    account: str
    playlists: list[YoutubePlaylist]


class YoutubeTracksResponse(BaseModel):
    account: str
    playlist_id: str
    tracks: list[Track]
    next_page_token: str | None = None


class DisconnectRequest(BaseModel):
    account: str


class SeedTrack(BaseModel):
    artist: str = ""
    title: str = ""


class RecommendationRequest(BaseModel):
    seeds: list[str] = []
    seed_tracks: list[SeedTrack] = []
    exclude_ids: list[str] = []
    limit: int = 13


class RecommendationResponse(BaseModel):
    recommendations: list[Track]