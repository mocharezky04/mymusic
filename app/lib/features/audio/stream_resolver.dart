import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../core/config.dart';
import 'app_ejs_solver.dart';
import 'yt/visionos_client.dart';

Dio _backendDio() {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));
  if (ApiConfig.apiKey.isNotEmpty) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['X-API-Key'] = ApiConfig.apiKey;
        handler.next(options);
      },
    ));
  }
  return dio;
}

Future<String> _fromBackend(String videoId, {String quality = '128k'}) async {
  final res = await _backendDio().get('/stream', queryParameters: {'video_id': videoId, 'quality': quality});
  final url = (res.data as Map<String, dynamic>)['url'] as String?;
  if (url == null || url.isEmpty) throw Exception('No stream URL');
  debugPrint('stream: backend');
  return url;
}

YoutubeExplode? _sharedExplode;

YoutubeExplode _sharedYt() {
  return _sharedExplode ??= YoutubeExplode(jsSolver: appEjsSolver);
}

Future<String> _fromLocal(
  String videoId, {
  required bool probe,
  required Duration manifestTimeout,
  required bool retryOnce,
}) async {
  final clients = [
    ('visionos', visionosClient),
    ('ios', YoutubeApiClient.ios),
  ];
  final yt = _sharedYt();
  String? result = await _tryClients(
    yt,
    videoId,
    clients,
    probe: probe,
    manifestTimeout: manifestTimeout,
  );
  if (result != null) return result;
  if (!retryOnce) throw Exception('all local clients failed');
  debugPrint('stream: all clients failed, retrying visionos once');
  await Future<void>.delayed(const Duration(seconds: 3));
  result = await _tryClients(
    yt,
    videoId,
    [('visionos', visionosClient)],
    probe: probe,
    manifestTimeout: manifestTimeout,
  );
  if (result != null) return result;
  throw Exception('all local clients failed');
}

Future<String?> _tryClients(
  YoutubeExplode yt,
  String videoId,
  List<(String, YoutubeApiClient)> clients, {
  required bool probe,
  required Duration manifestTimeout,
}) async {
  for (final (label, client) in clients) {
    StreamManifest manifest;
    final mStart = DateTime.now().millisecondsSinceEpoch;
    try {
      manifest = await yt.videos.streams
          .getManifest(videoId, ytClients: [client])
          .timeout(manifestTimeout);
    } catch (e) {
      debugPrint('stream: client $label manifest failed: $e');
      continue;
    }
    final mMs = DateTime.now().millisecondsSinceEpoch - mStart;
    final audio = manifest.audioOnly.withHighestBitrate();
    if (!probe) {
      debugPrint('stream: manifest $mMs ms, probe dilewati ($label)');
      return audio.url.toString();
    }
    final pStart = DateTime.now().millisecondsSinceEpoch;
    try {
      final res = await Dio().getUri(
        audio.url,
        options: Options(
          headers: {'Range': 'bytes=0-0'},
          validateStatus: (s) => s != null,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      final pMs = DateTime.now().millisecondsSinceEpoch - pStart;
      final status = res.statusCode;
      if (status == 200 || status == 206) {
        debugPrint('stream: local ok ($label) manifest=${mMs}ms probe=${pMs}ms');
        return audio.url.toString();
      }
      debugPrint('stream: client $label url rejected: $status');
    } catch (e) {
      debugPrint('stream: client $label url probe failed: $e');
    }
  }
  return null;
}

/// [probe] memvalidasi URL dengan satu request Range 1 byte. Melewatkannya
/// membuat resolve ~1 detik lebih cepat, dan URL rusak tetap ketangkap sebagai
/// error playback di [_applyQueue], bukan sebagai hening diam-diam.
Future<String> resolveStreamUrl(
  String videoId, {
  String quality = '128k',
  bool probe = true,
  bool isStartTrack = false,
}) async {
  final t0 = DateTime.now().millisecondsSinceEpoch;
  if (!kIsWeb) {
    try {
      final url = await _fromLocal(
        videoId,
        probe: probe,
        // Lagu yang langsung berbunyi tidak bisa menunggu 12 detik per client:
        // pakai timeout pendek dan lewati putaran retry, supaya kondisi gagal
        // muncul sebagai pesan error, bukan loading yang menggantung.
        manifestTimeout: isStartTrack
            ? const Duration(seconds: 6)
            : const Duration(seconds: 20),
        retryOnce: !isStartTrack,
      );
      debugPrint(
        'stream: resolve total ${DateTime.now().millisecondsSinceEpoch - t0}ms '
        '(local, probe=$probe)',
      );
      return url;
    } catch (_) {
      debugPrint('stream: local failed, falling back to backend');
    }
  }
  final url = await _fromBackend(videoId, quality: quality);
  debugPrint(
    'stream: resolve total ${DateTime.now().millisecondsSinceEpoch - t0}ms '
    '(backend)',
  );
  return url;
}
