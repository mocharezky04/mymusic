import 'tab_sync_stub.dart'
    if (dart.library.js_interop) 'tab_sync_web.dart' as impl;

typedef TabSyncController = void Function(TabSyncControl control);

class TabSyncControl {
  const TabSyncControl(this.action, this.position);

  final String action;
  final Duration? position;

  static const play = 'play';
  static const pause = 'pause';
  static const next = 'next';
  static const previous = 'previous';
  static const seek = 'seek';
}

class TabSyncState {
  const TabSyncState({
    required this.tabId,
    required this.playing,
    required this.index,
    required this.queueLength,
    required this.seq,
  });

  final String tabId;
  final bool playing;
  final int index;
  final int queueLength;
  final int seq;
}

abstract class TabSync {
  String get tabId;

  Stream<TabSyncControl> get controls;

  Stream<TabSyncState> get states;

  void sendControl(TabSyncControl control);

  void sendState({
    required bool playing,
    required int index,
    required int queueLength,
    required int seq,
  });

  void close();
}

TabSync createTabSync() => impl.createTabSync();