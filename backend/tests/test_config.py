from app.config import Settings


def test_strips_whitespace_from_callback_uri():
    s = Settings(
        youtube_callback_uri="  https://x/youtube/callback\n",
        google_client_id="  my-client-id  ",
        google_client_secret="my-secret\n",
    )
    assert s.youtube_callback_uri == "https://x/youtube/callback"
    assert s.google_client_id == "my-client-id"
    assert s.google_client_secret == "my-secret"
