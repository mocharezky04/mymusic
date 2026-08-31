import 'dart:async';

import 'tab_sync.dart';

TabSync createTabSync() => NoopTabSync();

class NoopTabSync implements TabSync {
  final _controls = StreamController<TabSyncControl>.broadcast();
  final _states = StreamController<TabSyncState>.broadcast();

  @override
  String get tabId => 'native';

  @override
  Stream<TabSyncControl> get controls => _controls.stream;

  @override
  Stream<TabSyncState> get states => _states.stream;

  @override
  void sendControl(TabSyncControl control) {}

  @override
  void sendState({required bool playing, required int index, required int queueLength, required int seq}) {}

  @override
  void close() {
    _controls.close();
    _states.close();
  }
}