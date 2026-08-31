// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';

import 'tab_sync.dart';

TabSync createTabSync() => WebTabSync();

/// Sinkronisasi antar-tab pakai BroadcastChannel. Model "yang terakhir mulai
/// = yang menang": perintah transport disiarkan, follower ikut; bila ada dua
/// tab sama-sama memutar, yang mulai paling baru menang.
class WebTabSync implements TabSync {
  WebTabSync() {
    _channel.onMessage.listen(_onMessage);
  }

  final html.BroadcastChannel _channel = html.BroadcastChannel('mymusic-sync');
  final _controls = StreamController<TabSyncControl>.broadcast();
  final _states = StreamController<TabSyncState>.broadcast();
  final _random = Random();

  @override
  String get tabId => _tabId;
  late final String _tabId =
      'web-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(1 << 30)}';

  void _onMessage(html.MessageEvent event) {
    final data = event.data;
    if (data is! String) return;
    final map = jsonDecode(data);
    if (map is! Map || map['from'] == _tabId) return;
    switch (map['k']) {
      case 'cmd':
        _controls.add(TabSyncControl(
          map['a'] as String,
          map['ms'] is num ? Duration(milliseconds: (map['ms'] as num).toInt()) : null,
        ));
      case 'state':
        _states.add(TabSyncState(
          tabId: map['from'] as String,
          playing: map['p'] == true,
          index: (map['idx'] as num?)?.toInt() ?? -1,
          queueLength: (map['q'] as num?)?.toInt() ?? 0,
          seq: (map['seq'] as num?)?.toInt() ?? 0,
        ));
    }
  }

  @override
  Stream<TabSyncControl> get controls => _controls.stream;

  @override
  Stream<TabSyncState> get states => _states.stream;

  @override
  void sendControl(TabSyncControl control) {
    _channel.postMessage(jsonEncode({
      'k': 'cmd',
      'from': _tabId,
      'a': control.action,
      'ms': control.position?.inMilliseconds,
    }));
  }

  @override
  void sendState({
    required bool playing,
    required int index,
    required int queueLength,
    required int seq,
  }) {
    _channel.postMessage(jsonEncode({
      'k': 'state',
      'from': _tabId,
      'p': playing,
      'idx': index,
      'q': queueLength,
      'seq': seq,
    }));
  }

  @override
  void close() {
    _channel.close();
    _controls.close();
    _states.close();
  }
}