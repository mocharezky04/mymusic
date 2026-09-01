from app.ytdlp import YtDlpError, _pick_audio_format


def test_pick_audio_prefers_highest_abr_m4a():
    formats = [
        {"url": "u1", "acodec": "opus", "vcodec": "none", "abr": 128, "ext": "webm"},
        {"url": "u2", "acodec": "mp4a.40.2", "vcodec": "none", "abr": 256, "ext": "m4a"},
        {"url": "u3", "acodec": "mp4a.40.2", "vcodec": "none", "abr": 128, "ext": "m4a"},
    ]
    result = _pick_audio_format(formats)
    assert result["url"] == "u2"
    assert result["ext"] == "m4a"


def test_pick_audio_falls_back_to_muxed():
    formats = [
        {"url": "u1", "acodec": "none", "vcodec": "avc1", "abr": 0, "ext": "mp4", "height": 720},
        {"url": "u2", "acodec": "mp4a.40.2", "vcodec": "avc1", "abr": 128, "ext": "mp4", "height": 480},
    ]
    result = _pick_audio_format(formats)
    assert result["url"] == "u2"


def test_pick_audio_raises_when_no_playable():
    formats = [
        {"acodec": "none", "vcodec": "avc1"},
    ]
    try:
        _pick_audio_format(formats)
        assert False, "should have raised"
    except YtDlpError as e:
        assert "no playable" in str(e)
