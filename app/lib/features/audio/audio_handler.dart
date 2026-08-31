import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/models.dart';

MediaItem mediaItemForTrack(Track track, String url) => MediaItem(
      id: '${track.source.apiValue}:${track.id}',
      title: track.title,
      artist: track.artist.isNotEmpty ? track.artist : track.uploader,
      duration: track.durationSeconds > 0 ? Duration(seconds: track.durationSeconds) : null,
      artUri: track.thumb.isNotEmpty ? Uri.tryParse(track.thumb) : null,
      extras: {'url': url, 'source': track.source.apiValue},
    );

/// Wrapper tunggal around [AudioPlayer] yang menyiarkan state lewat
/// audio_service. Dipakai di semua platform; di Android di-register lewat
/// [AudioService.init] supaya playback tetap jalan saat layar mati.
class AudioPlayerHandler extends BaseAudioHandler {
  AudioPlayerHandler() {
    _player = AudioPlayer();
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _player.sequenceStateStream
        .map((sequence) => sequence.currentSource?.tag as MediaItem?)
        .listen(mediaItem.add);
  }

  late final AudioPlayer _player;
  PlaybackRepeat _repeatMode = PlaybackRepeat.off;

  bool get isQueueLoaded => _player.audioSources.isNotEmpty;

  AudioPlayer get player => _player;

  PlaybackState _transformEvent(PlaybackEvent event) {
    final playing = _player.playing && event.processingState != ProcessingState.completed;
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[event.processingState]!,
      playing: playing,
      updatePosition: event.updatePosition,
      bufferedPosition: event.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  AudioSource _source(Track track, String url) {
    return AudioSource.uri(
      Uri.parse(url),
      tag: mediaItemForTrack(track, url),
    );
  }

  Future<void> loadQueue(
    List<(Track, String)> items, {
    required int startIndex,
    bool autoPlay = true,
  }) async {
    await _player.setAudioSources(
      [for (final (track, url) in items) _source(track, url)],
      initialIndex: startIndex.clamp(0, items.length - 1),
    );
    await _player.setLoopMode(_toLoopMode(_repeatMode));
    queue.add([for (final (track, url) in items) mediaItemForTrack(track, url)]);
    if (autoPlay) unawaited(_player.play());
  }

  Future<void> addLast(Track track, String url) async {
    await _player.addAudioSource(_source(track, url));
    queue.add(queue.value + [mediaItemForTrack(track, url)]);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final url = mediaItem.extras?['url'] as String?;
    if (url == null || url.isEmpty) return;
    await _player.addAudioSource(AudioSource.uri(Uri.parse(url), tag: mediaItem));
    queue.add(queue.value + [mediaItem]);
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    final index = _indexOfSource(mediaItem.id);
    await removeAt(index);
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _player.audioSources.length) return;
    await _player.removeAudioSourceAt(index);
  }

  Future<void> move(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _player.audioSources.length) return;
    if (newIndex < 0 || newIndex >= _player.audioSources.length) return;
    await _player.moveAudioSource(oldIndex, newIndex);
  }

  int _indexOfSource(String id) {
    for (var i = 0; i < _player.audioSources.length; i++) {
      final tag = (_player.audioSources[i] as UriAudioSource).tag;
      if (tag is MediaItem && tag.id == id) return i;
    }
    return -1;
  }

  Future<void> setRepeat(PlaybackRepeat mode) async {
    _repeatMode = mode;
    await _player.setLoopMode(_toLoopMode(mode));
  }

  LoopMode _toLoopMode(PlaybackRepeat mode) => switch (mode) {
        PlaybackRepeat.off => LoopMode.off,
        PlaybackRepeat.all => LoopMode.all,
        PlaybackRepeat.one => LoopMode.one,
      };

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    final index = _player.currentIndex;
    if (index != null && index < _player.audioSources.length - 1) {
      await _player.seekToNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
    } else {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) => _player.seek(Duration.zero, index: index);

  @override
  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.dispose();
}