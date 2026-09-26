import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/models.dart';
import '../audio/audio_handler.dart';
import '../audio/stream_resolver.dart';
import '../forYou/history_providers.dart';
import '../storage/app_db.dart';
import '../sync/tab_sync.dart';

final audioHandlerProvider = Provider<AudioPlayerHandler>((ref) {
  final handler = AudioPlayerHandler();
  ref.onDispose(handler.dispose);
  return handler;
});

class PlayerState {
  const PlayerState({
    this.queue = const [],
    this.index = -1,
    this.playing = false,
    this.loading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.repeat = PlaybackRepeat.off,
    this.shuffle = false,
    this.error,
  });

  final List<Track> queue;
  final int index;
  final bool playing;
  final bool loading;
  final Duration position;
  final Duration duration;
  final PlaybackRepeat repeat;
  final bool shuffle;
  final String? error;

  bool get hasTrack => index >= 0 && index < queue.length;

  Track? get current => hasTrack ? queue[index] : null;

  PlayerState copyWith({
    List<Track>? queue,
    int? index,
    bool? playing,
    bool? loading,
    Duration? position,
    Duration? duration,
    PlaybackRepeat? repeat,
    bool? shuffle,
    String? error,
  }) {
    return PlayerState(
      queue: queue ?? this.queue,
      index: index ?? this.index,
      playing: playing ?? this.playing,
      loading: loading ?? this.loading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      repeat: repeat ?? this.repeat,
      shuffle: shuffle ?? this.shuffle,
      error: error,
    );
  }
}

final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerState>(PlayerController.new);

typedef PlaybackPosition = ({Duration position, Duration duration});

final playerPositionProvider = StreamProvider<PlaybackPosition>((ref) {
  final durationSeconds = ref.watch(
    playerControllerProvider.select((s) => s.hasTrack ? s.current!.durationSeconds : 0),
  );
  final handler = ref.watch(audioHandlerProvider);
  final out = StreamController<PlaybackPosition>();
  var duration = Duration(seconds: durationSeconds);
  StreamSubscription<Duration?>? durSub;

  out.onListen = () {
    ref.onDispose(() {
      durSub?.cancel();
    });
    durSub = handler.player.durationStream.listen((d) {
      if (d != null && d > Duration.zero) duration = d;
    });
  };

  final sub = _throttleEvents(
    handler.player.positionStream.map((position) {
      return (position: position, duration: duration);
    }),
    const Duration(milliseconds: 250),
  ).listen(out.add, onError: out.addError, onDone: out.close);

  ref.onDispose(() {
    sub.cancel();
    out.close();
  });
  return out.stream;
});

Stream<T> _throttleEvents<T>(Stream<T> source, Duration interval) {
  var nextAllowed = 0;
  return source.transform(StreamTransformer.fromHandlers(
    handleData: (T value, EventSink<T> sink) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now >= nextAllowed) {
        nextAllowed = now + interval.inMilliseconds;
        sink.add(value);
      }
    },
  ));
}

/// Memutar antrian sehingga lagu pada [startIndex] menjadi elemen pertama, lalu
/// mengembalikan sisanya. Handler dibangun sebagai prefix dari hasil ini, jadi
/// indeks handler dan indeks state selalu menunjuk lagu yang sama.
List<T> rotateQueue<T>(List<T> order, int startIndex) {
  if (order.isEmpty) return const [];
  final i = startIndex.clamp(0, order.length - 1);
  return <T>[...order.sublist(i), ...order.sublist(0, i)];
}

class PlayerController extends Notifier<PlayerState> {
  AudioPlayerHandler? _handler;
  final Map<String, String> _srcCache = {};
  List<Track> _baseOrder = const [];
  StreamSubscription<PlaybackState>? _sub;
  TabSync? _sync;
  StreamSubscription<TabSyncControl>? _ctrlSub;
  StreamSubscription<TabSyncState>? _stateSub;
  DateTime? _lastBroadcastAt;
  int _localPlaySeq = 0;
  int _lastRecordedIndex = -1;
  bool _applying = false;
  final Set<String> _failedVideos = {};

  // Pesan error dibuat dalam bahasa aktif saat error terjadi, lalu disimpan
  // sebagai teks siap tampil supaya SnackBar tidak perlu tahu asal-usulnya.
  L10n get l10n => ref.read(l10nProvider);

  // Invarian: [AudioPlayerHandler] selalu berisi prefix dari [PlayerState.queue]
  // pada posisi yang sama, dan [_queueGen] membatalkan prefetch yang sudah usang.
  int _queueGen = 0;
  bool _prefetching = false;

  @override
  PlayerState build() {
    final handler = ref.watch(audioHandlerProvider);
    _handler = handler;
    _sub = handler.playbackState.listen(_applyPlayback);
    final sync = createTabSync();
    _sync = sync;
    _ctrlSub = sync.controls.listen(_applyRemoteControl);
    _stateSub = sync.states.listen(_applyRemoteState);
    _restoreQueue();
    ref.onDispose(() {
      _sub?.cancel();
      _ctrlSub?.cancel();
      _stateSub?.cancel();
      sync.close();
      _srcCache.clear();
    });
    return const PlayerState();
  }

  void _restoreQueue() {
    final db = ref.read(dbProvider);
    db.readQueue().then((res) async {
      if (res.$1.isEmpty || state.queue.isNotEmpty) return;
      final repeatRaw = await db.getMeta('repeat');
      final shuffleRaw = await db.getMeta('shuffle');
      final repeat = PlaybackRepeat.values.firstWhere(
        (r) => r.name == repeatRaw,
        orElse: () => PlaybackRepeat.off,
      );
      final shuffleOn = shuffleRaw == 'true';
      state = PlayerState(
        queue: res.$1,
        index: res.$2,
        repeat: repeat,
        shuffle: shuffleOn,
      );
    }).catchError((_) {});
  }

  void _persistQueue() {
    ref.read(dbProvider).writeQueue(state.queue, state.index).catchError((_) {});
    _persistPlayMode();
  }

  void _persistPlayMode() {
    final db = ref.read(dbProvider);
    db.upsertMeta('repeat', state.repeat.name).catchError((_) {});
    db.upsertMeta('shuffle', state.shuffle.toString()).catchError((_) {});
  }

  void _applyPlayback(PlaybackState ps) {
    final idx = ps.queueIndex;
    final index = (idx != null && idx >= 0 && idx < state.queue.length)
        ? idx
        : state.index;
    final loading = ps.processingState == AudioProcessingState.loading ||
        ps.processingState == AudioProcessingState.buffering;
    if (ps.processingState == AudioProcessingState.error) {
      state = state.copyWith(
        loading: false,
        playing: false,
        error: l10n.playError,
      );
      return;
    }
    final wasPlaying = state.playing;
    state = state.copyWith(
      index: index,
      playing: ps.playing,
      loading: loading,
      position: ps.updatePosition,
    );
    if (ps.playing && (index != _lastRecordedIndex || !wasPlaying)) {
      _lastRecordedIndex = index;
      _localPlaySeq = DateTime.now().millisecondsSinceEpoch;
      final playingTrack = state.current;
      if (playingTrack != null) {
        final db = ref.read(dbProvider);
        db.recordPlay(playingTrack).then((_) {
          ref.invalidate(recentPlaysProvider);
          ref.invalidate(topPlaysProvider);
        }).catchError((_) {});
      }
    }
    _maybeSyncState();
  }

  void _maybeSyncState() {
    final sync = _sync;
    if (sync == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastBroadcastAt != null && now - _lastBroadcastAt!.millisecondsSinceEpoch < 1500) {
      return;
    }
    _lastBroadcastAt = DateTime.fromMillisecondsSinceEpoch(now);
    sync.sendState(
      playing: state.playing,
      index: state.index,
      queueLength: state.queue.length,
      seq: _localPlaySeq,
    );
  }

  void _applyRemoteControl(TabSyncControl control) {
    if (_handler == null) return;
    switch (control.action) {
      case TabSyncControl.play:
        if (!state.playing && state.hasTrack) _handler!.play();
      case TabSyncControl.pause:
        if (state.playing) _handler!.pause();
      case TabSyncControl.next:
        if (state.hasTrack) _handler!.skipToNext();
      case TabSyncControl.previous:
        if (state.hasTrack) _handler!.skipToPrevious();
      case TabSyncControl.seek:
        if (state.hasTrack && control.position != null) {
          _handler!.seek(control.position!);
        }
    }
  }

  void _applyRemoteState(TabSyncState s) {
    if (_handler == null || !state.playing) return;
    if (s.playing && s.seq > _localPlaySeq && s.tabId != _sync?.tabId) {
      _handler!.pause();
    }
  }

  Future<String> _resolve(Track track, {bool noRetry = false}) async {
    final cached = _srcCache[track.id];
    if (cached != null) return cached;
    if (_failedVideos.contains(track.id)) {
      throw Exception('previously failed');
    }
    final download =
        await ref.read(dbProvider).downloadFor(track.id, track.source.apiValue);
    if (download != null) return 'file://${download.filePath}';
    try {
      final url = await resolveStreamUrl(track.id);
      _srcCache[track.id] = url;
      return url;
    } catch (e) {
      if (noRetry) {
        _failedVideos.add(track.id);
        rethrow;
      }
      debugPrint('stream: resolve failed for ${track.title}, retrying in 2s: $e');
      await Future<void>.delayed(const Duration(seconds: 2));
      try {
        final url = await resolveStreamUrl(track.id);
        _srcCache[track.id] = url;
        return url;
      } catch (e2) {
        _failedVideos.add(track.id);
        rethrow;
      }
    }
  }

  Future<bool> _applyQueue(List<Track> order, {required int startIndex, required bool autoPlay}) async {
    if (order.isEmpty) return false;
    if (_applying) return false;
    _applying = true;
    final gen = ++_queueGen;
    try {
      // Lagu awal diputar dari posisi 0 supaya handler (prefix) dan state
      // memakai indeks yang sama tanpa harus memutar ulang handler.
      final rotated = rotateQueue(order, startIndex);
      final startTrack = rotated.first;
      final String startUrl;
      try {
        startUrl = await _resolve(startTrack, noRetry: true);
      } catch (e) {
        debugPrint('stream: failed to resolve start track: $e');
        state = state.copyWith(error: l10n.trackLoadFailed(startTrack.title));
        unawaited(_ensurePrefetch());
        return false;
      }
      _handler!.stop();
      _lastRecordedIndex = -1;
      state = state.copyWith(queue: rotated, index: 0, loading: true, error: null);

      final items = <(Track, String)>[(startTrack, startUrl)];
      if (rotated.length > 1) {
        try {
          items.add((rotated[1], await _resolve(rotated[1])));
        } catch (e) {
          debugPrint('stream: next track unavailable: $e');
        }
      }
      await _handler!.loadQueue(items, startIndex: 0, autoPlay: autoPlay);
      if (gen != _queueGen) return false;
      final loaded = items[0].$1;
      state = state.copyWith(
        index: 0,
        loading: false,
        position: Duration.zero,
        duration: loaded.durationSeconds > 0
            ? Duration(seconds: loaded.durationSeconds)
            : Duration.zero,
        error: null,
      );
      _persistQueue();
      unawaited(_prefetch(gen));
      return true;
    } on Exception {
      _handler!.stop();
      state = state.copyWith(
        loading: false,
        playing: false,
        error: l10n.queueLoadFailed,
      );
      unawaited(_ensurePrefetch());
      return false;
    } finally {
      _applying = false;
    }
  }

  /// Handler selalu berisi prefix dari antrian pada posisi yang sama. Setiap
  /// putaran memuat satu lagu lagi tepat di ujung handler; lagu yang gagal
  /// dikeluarkan dari antrian supaya tidak pernah ada lagu hantu.
  Future<void> _prefetch(int gen) async {
    if (_prefetching) return;
    _prefetching = true;
    try {
      while (gen == _queueGen && _handler!.isQueueLoaded) {
        final loaded = _handler!.queueLength;
        if (loaded >= state.queue.length) return;
        final track = state.queue[loaded];
        String url;
        try {
          url = await _resolve(track);
        } catch (e) {
          if (gen != _queueGen) return;
          debugPrint('stream: prefetch drop ${track.title}: $e');
          _dropQueueAt(loaded);
          continue;
        }
        if (gen != _queueGen || !_handler!.isQueueLoaded) return;
        if (loaded >= state.queue.length || state.queue[loaded].id != track.id) {
          continue;
        }
        await _handler!.addLast(track, url);
      }
    } finally {
      _prefetching = false;
    }
  }

  void _dropQueueAt(int index) {
    final queue = List<Track>.of(state.queue);
    if (index < 0 || index >= queue.length) return;
    queue.removeAt(index);
    if (queue.isEmpty) {
      clearQueue();
      return;
    }
    var current = state.index;
    if (current > index) current -= 1;
    if (current >= queue.length) current = queue.length - 1;
    state = state.copyWith(queue: queue, index: current);
    _persistQueue();
  }

  Future<void> _ensurePrefetch() {
    if (_prefetching || _handler == null || !_handler!.isQueueLoaded) {
      return Future<void>.value();
    }
    if (_handler!.queueLength >= state.queue.length) return Future<void>.value();
    return _prefetch(_queueGen);
  }

  Future<void> playFrom(List<Track> tracks, int index) async {
    if (tracks.isEmpty || index < 0 || index >= tracks.length) return;
    final track = tracks[index];
    if (!track.source.playable) {
      state = state.copyWith(
        queue: List.of(tracks),
        index: index,
        error: l10n.trackNotPlayable,
      );
      return;
    }
    final playable = [for (final t in tracks) if (t.source.playable) t];
    var start = 0;
    for (var i = 0; i < index; i++) {
      if (tracks[i].source.playable) start += 1;
    }
    _baseOrder = List.of(playable);
    final order = state.shuffle ? _shuffledOrder(playable, start) : playable;
    final startInOrder = state.shuffle ? 0 : start;
    await _applyQueue(order, startIndex: startInOrder, autoPlay: true);
    _sync?.sendControl(const TabSyncControl(TabSyncControl.play, null));
  }

  List<Track> _shuffledOrder(List<Track> base, int currentIndex) {
    final order = List<Track>.of(base)
      ..shuffle(Random());
    final current = base[currentIndex];
    if (order.isNotEmpty) {
      order.removeWhere((t) => t.id == current.id && t.source == current.source);
      order.insert(0, current);
    }
    return order;
  }

  Future<void> addToQueue(Track track) async {
    if (!track.source.playable) return;
    if (state.queue.isEmpty) {
      await playFrom([track], 0);
      return;
    }
    state = state.copyWith(queue: [...state.queue, track]);
    _persistQueue();
    // Lagu baru masuk antrian setelah yang sudah dimuat, lalu prefetch
    // melanjutkan sendiri. Handler tidak pernah增添了 di posisi yang salah.
    if (_handler!.isQueueLoaded && _handler!.queueLength == state.queue.length - 1) {
      try {
        final url = await _resolve(track);
        if (_handler!.isQueueLoaded && _handler!.queueLength < state.queue.length) {
          await _handler!.addLast(track, url);
        }
      } on Exception {
        debugPrint('stream: add to queue deferred: ${track.title}');
      }
    }
    _persistQueue();
  }

  Future<void> playNext(Track track) async {
    if (!track.source.playable) return;
    if (state.queue.isEmpty) {
      await playFrom([track], 0);
      return;
    }
    final insertAt = state.index < 0 ? 0 : min(state.index + 1, state.queue.length);
    state = state.copyWith(queue: [...state.queue]..insert(insertAt, track));
    _persistQueue();
    await _insertIntoHandler(insertAt, track);
  }

  Future<void> addAt(Track track, int index, {required bool shiftCurrent}) async {
    if (!track.source.playable) return;
    final queue = List<Track>.from(state.queue);
    final insertAt = index.clamp(0, queue.length);
    final oldCurrent = state.index;
    queue.insert(insertAt, track);
    var current = oldCurrent;
    if (shiftCurrent && oldCurrent >= insertAt) current = oldCurrent + 1;
    state = state.copyWith(queue: queue, index: current);
    _persistQueue();
    await _insertIntoHandler(insertAt, track);
  }

  /// Sisipan hanya bisa dilakukan di dalam region yang sudah dimuat atau tepat di
  /// ujungnya. Sisipan yang lebih jauh ditangani prefetch, jadi handler tidak
  /// pernah holding lagu di urutan yang tidak sama dengan antrian.
  Future<void> _insertIntoHandler(int insertAt, Track track) async {
    final handler = _handler;
    if (handler == null || !handler.isQueueLoaded) return;
    final loaded = handler.queueLength;
    if (insertAt > loaded) {
      unawaited(_ensurePrefetch());
      return;
    }
    try {
      final url = await _resolve(track);
      if (!handler.isQueueLoaded) return;
      if (handler.queueLength != loaded) {
        unawaited(_ensurePrefetch());
        return;
      }
      await handler.insert(insertAt, track, url);
    } on Exception {
      debugPrint('stream: insert at $insertAt deferred: ${track.title}');
      unawaited(_ensurePrefetch());
    }
  }

  void toggle() {
    if (!state.hasTrack) return;
    if (state.playing) {
      _handler!.pause();
      _sync?.sendControl(const TabSyncControl(TabSyncControl.pause, null));
    } else {
      _handler!.play();
      _sync?.sendControl(const TabSyncControl(TabSyncControl.play, null));
    }
  }

  void next() {
    _sync?.sendControl(const TabSyncControl(TabSyncControl.next, null));
    _handler!.skipToNext();
  }

  void previous() {
    _sync?.sendControl(const TabSyncControl(TabSyncControl.previous, null));
    _handler!.skipToPrevious();
  }

  void seek(Duration position) {
    _sync?.sendControl(TabSyncControl(TabSyncControl.seek, position));
    _handler!.seek(position);
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.queue.length) return;
    if (newIndex < 0 || newIndex >= state.queue.length) return;
    final queue = List<Track>.of(state.queue);
    final moved = queue.removeAt(oldIndex);
    queue.insert(newIndex, moved);
    var currentIndex = state.index;
    if (oldIndex == currentIndex) {
      currentIndex = newIndex;
    } else if (oldIndex < currentIndex && newIndex >= currentIndex) {
      currentIndex -= 1;
    } else if (oldIndex > currentIndex && newIndex <= currentIndex) {
      currentIndex += 1;
    }
    state = state.copyWith(queue: queue, index: currentIndex);
    final handler = _handler;
    if (handler == null || !handler.isQueueLoaded) {
      _persistQueue();
      return;
    }
    final loaded = handler.queueLength;
    if (oldIndex < loaded && newIndex < loaded) {
      handler.move(oldIndex, newIndex);
    } else if (oldIndex < loaded) {
      // Tujuan di luar region yang sudah dimuat: keluarkan dari handler,
      // prefetch akan menambahkannya lagi di posisi yang benar.
      handler.removeAt(oldIndex);
    } else if (newIndex < loaded) {
      unawaited(_insertIntoHandler(newIndex, moved));
    }
    _persistQueue();
    unawaited(_ensurePrefetch());
  }

  void removeAt(int index) {
    if (index < 0 || index >= state.queue.length) return;
    final queue = List<Track>.from(state.queue)..removeAt(index);
    if (queue.isEmpty) {
      clearQueue();
      return;
    }
    var currentIndex = state.index;
    if (currentIndex > index) currentIndex -= 1;
    state = state.copyWith(queue: queue, index: currentIndex);
    final handler = _handler;
    if (handler != null && handler.isQueueLoaded && index < handler.queueLength) {
      handler.removeAt(index);
    }
    _persistQueue();
  }

  void clearQueue() {
    _queueGen++;
    _handler!.stop();
    state = PlayerState(repeat: state.repeat, shuffle: state.shuffle);
    _baseOrder = const [];
    _lastRecordedIndex = -1;
    ref.read(dbProvider).clearQueue().catchError((_) {});
    _persistPlayMode();
  }

  void setRepeat(PlaybackRepeat mode) {
    _handler!.setRepeat(mode);
    state = state.copyWith(repeat: mode);
    _persistPlayMode();
  }

  void cycleRepeat() {
    final next = {
      PlaybackRepeat.off: PlaybackRepeat.all,
      PlaybackRepeat.all: PlaybackRepeat.one,
      PlaybackRepeat.one: PlaybackRepeat.off,
    };
    setRepeat(next[state.repeat]!);
  }

  Future<void> toggleShuffle() async {
    if (state.queue.isEmpty) return;
    final base = _baseOrder.isNotEmpty ? List<Track>.from(_baseOrder) : List<Track>.from(state.queue);
    final current = state.current;
    if (!state.shuffle) {
      final order = _shuffledOrder(base, _baseIndex(current));
      await _applyQueue(order, startIndex: 0, autoPlay: state.playing);
      if (!state.shuffle) return;
      state = state.copyWith(shuffle: true);
      _persistPlayMode();
    } else {
      _baseOrder = base;
      await _applyQueue(base, startIndex: _baseIndex(current), autoPlay: state.playing);
      if (state.shuffle) return;
      state = state.copyWith(shuffle: false);
      _persistPlayMode();
    }
  }

  int _baseIndex(Track? current) {
    if (current == null) return 0;
    final i = _baseOrder.indexWhere((t) => t.id == current.id && t.source == current.source);
    return i < 0 ? 0 : i;
  }

  void clearError() {
    if (state.error != null) state = state.copyWith(error: null);
  }
}