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

Future<String> _fromLocal(String videoId) async {
  final clients = [
    ('visionos', visionosClient),
    ('ios', YoutubeApiClient.ios),
  ];
  final yt = _sharedYt();
  String? result = await _tryClients(yt, videoId, clients);
  if (result != null) return result;
  debugPrint('stream: all clients failed, retrying visionos once');
  await Future<void>.delayed(const Duration(seconds: 3));
  result = await _tryClients(yt, videoId, [
    ('visionos', visionosClient),
  ]);
  if (result != null) return result;
  throw Exception('all local clients failed');
}

Future<String?> _tryClients(
  YoutubeExplode yt,
  String videoId,
  List<(String, YoutubeApiClient)> clients,
) async {
  for (final (label, client) in clients) {
    StreamManifest manifest;
    try {
      manifest = await yt.videos.streams
          .getManifest(videoId, ytClients: [client])
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      debugPrint('stream: client $label manifest failed: $e');
      continue;
    }
    final audio = manifest.audioOnly.withHighestBitrate();
    try {
      final probe = await Dio().getUri(
        audio.url,
        options: Options(
          headers: {'Range': 'bytes=0-0'},
          validateStatus: (s) => s != null,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      final status = probe.statusCode;
      if (status == 200 || status == 206) {
        debugPrint('stream: local ok ($label)');
        return audio.url.toString();
      }
      debugPrint('stream: client $label url rejected: $status');
    } catch (e) {
      debugPrint('stream: client $label url probe failed: $e');
    }
  }
  return null;
}

Future<String> resolveStreamUrl(String videoId, {String quality = '128k'}) async {
  if (!kIsWeb) {
    try {
      return await _fromLocal(videoId);
    } catch (_) {
      debugPrint('stream: local failed, falling back to backend');
    }
  }
  return _fromBackend(videoId, quality: quality);
}
