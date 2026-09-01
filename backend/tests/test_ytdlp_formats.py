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


def test_pick_audio_ignores_storyboards():
    formats = [
        {"url": "sb0", "ext": "mhtml", "acodec": "none", "vcodec": "none", "protocol": "mhtml"},
        {"url": "u1", "acodec": "mp4a.40.2", "vcodec": "avc1", "abr": 128, "ext": "mp4", "height": 360},
    ]
    result = _pick_audio_format(formats)
    assert result["url"] == "u1"


def test_pick_audio_respects_max_abr():
    formats = [
        {"url": "u1", "acodec": "mp4a.40.2", "vcodec": "none", "abr": 256, "ext": "m4a"},
        {"url": "u2", "acodec": "mp4a.40.2", "vcodec": "none", "abr": 96, "ext": "m4a"},
    ]
    result = _pick_audio_format(formats, max_abr=128)
    assert result["url"] == "u2"
    assert result["abr"] == 96
