import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../core/config.dart';

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

Future<String> _fromLocal(String videoId) async {
  final yt = YoutubeExplode();
  try {
    StreamManifest manifest;
    try {
      manifest = await yt.videos.streams.getManifest(
        videoId,
        ytClients: [YoutubeApiClient.androidVr],
      );
    } catch (_) {
      debugPrint('stream: androidVr client failed, trying default');
      manifest = await yt.videos.streams.getManifest(videoId);
    }
    final audio = manifest.audioOnly.withHighestBitrate();
    debugPrint('stream: local fallback');
    return audio.url.toString();
  } catch (e) {
    debugPrint('stream: local fallback failed: $e');
    rethrow;
  } finally {
    yt.close();
  }
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
