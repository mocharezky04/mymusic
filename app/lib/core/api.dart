import 'package:dio/dio.dart';

import 'config.dart';
import 'models.dart';

class DioApiException implements Exception {}

class ServerOfflineException implements Exception {}

class MyMusicApi {
  MyMusicApi(String baseUrl)
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
          ),
        ) {
    if (ApiConfig.apiKey.isNotEmpty) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['X-API-Key'] = ApiConfig.apiKey;
            handler.next(options);
          },
        ),
      );
    }
  }

  final Dio _dio;

  Future<List<Track>> search(
    String query, {
    List<String> sources = const ['youtube', 'ytmusic'],
  }) async {
    final res = await _dio.get(
      '/search',
      queryParameters: {'q': query, 'sources': sources.join(',')},
    );
    final data = res.data as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? const [];
    return results.map((e) => Track.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<StreamInfo> streamInfo(String id, {String quality = '128k'}) async {
    final res = await _dio.get('/stream', queryParameters: {'video_id': id, 'quality': quality});
    return StreamInfo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LyricsResult> lyrics(String track, String artist) async {
    final res = await _dio.get('/lyrics', queryParameters: {'track': track, 'artist': artist});
    return LyricsResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<YoutubeAccount>> youtubeAccounts() async {
    final res = await _guard(() => _dio.get('/youtube/me'));
    final data = res.data as Map<String, dynamic>;
    return (data['accounts'] as List<dynamic>? ?? const [])
        .map((e) => YoutubeAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<YoutubePlaylist>> youtubePlaylists(String account) async {
    final res = await _guard(() => _dio.get('/youtube/playlists', queryParameters: {'account': account}));
    final data = res.data as Map<String, dynamic>;
    return (data['playlists'] as List<dynamic>? ?? const [])
        .map((e) => YoutubePlaylist.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Track>> youtubeTracks(String account, String playlistId,
      {String? pageToken}) async {
    final params = <String, dynamic>{
      'account': account,
      'pageToken': ?pageToken,
    };
    final res = await _guard(
        () => _dio.get('/youtube/playlists/$playlistId/tracks', queryParameters: params));
    final data = res.data as Map<String, dynamic>;
    return (data['tracks'] as List<dynamic>? ?? const [])
        .map((e) => Track.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> youtubeDisconnect(String account) async {
    await _guard(() => _dio.post('/youtube/disconnect', data: {'account': account}));
  }

  Future<List<Track>> fetchMixTracks({
    required String mixId,
    required String account,
  }) async {
    final res = await _guard(() => _dio.get(
      '/youtube/mix',
      queryParameters: {'mix_id': mixId, 'account': account},
    ));
    final data = res.data as Map<String, dynamic>;
    return (data['tracks'] as List<dynamic>? ?? const [])
        .map((e) => Track.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Track>> recommendations({
    List<String> seeds = const [],
    List<({String artist, String title})> seedTracks = const [],
    List<String> excludeIds = const [],
    int limit = 13,
  }) async {
    final res = await _guard(() => _dio.post(
      '/recommendations',
      data: {
        'seeds': seeds,
        'seed_tracks': [
          for (final t in seedTracks) {'artist': t.artist, 'title': t.title},
        ],
        'exclude_ids': excludeIds,
        'limit': limit,
      },
    ));
    final data = res.data as Map<String, dynamic>;
    return (data['recommendations'] as List<dynamic>? ?? const [])
        .map((e) => Track.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> youtubeAuthStart() async {
    final res = await _dio.get(
      '/youtube/auth/start',
      options: Options(
        followRedirects: false,
        validateStatus: (s) => s == 302,
      ),
    );
    final location = res.headers.value('location');
    if (location == null) throw DioException(requestOptions: res.requestOptions);
    return location;
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      if (e.response?.statusCode == 503) throw DioApiException();
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw ServerOfflineException();
      }
      rethrow;
    }
  }
}