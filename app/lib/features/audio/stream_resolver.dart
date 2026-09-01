import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../core/config.dart';

Future<String> resolveStreamUrl(String videoId, {String quality = '128k'}) async {
  if (!kIsWeb) {
    try {
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
      final res = await dio.get('/stream', queryParameters: {'video_id': videoId, 'quality': quality});
      final url = (res.data as Map<String, dynamic>)['url'] as String?;
      if (url != null && url.isNotEmpty) {
        debugPrint('stream: backend');
        return url;
      }
    } on DioException catch (e) {
      debugPrint('stream: backend failed (${e.response?.statusCode ?? e.type}), falling back to local');
    } catch (e) {
      debugPrint('stream: backend error ($e), falling back to local');
    }

    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final audio = manifest.audioOnly.withHighestBitrate();
      debugPrint('stream: local fallback');
      return audio.url.toString();
    } finally {
      yt.close();
    }
  }

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
  final res = await dio.get('/stream', queryParameters: {'video_id': videoId, 'quality': quality});
  final url = (res.data as Map<String, dynamic>)['url'] as String?;
  if (url == null || url.isEmpty) throw Exception('No stream URL');
  debugPrint('stream: backend');
  return url;
}
