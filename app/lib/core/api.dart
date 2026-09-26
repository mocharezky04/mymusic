import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'models.dart';

class DioApiException implements Exception {}

class ServerOfflineException implements Exception {}

/// API key ditolak server (401/403). Ini biasanya build lama dengan kunci yang
/// sudah dirotasi; pesan error harus menyebut ini supaya pengguna tahu harus
/// memperbarui aplikasi, bukan mengganti kata kunci.
class ApiKeyRejectedException implements Exception {}

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
    final res = await _guard(() => _dio.get(
          '/search',
          queryParameters: {'q': query, 'sources': sources.join(',')},
        ));
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
    if (ApiConfig.isServerless) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('youtube_accounts') ?? '[]';
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => YoutubeAccount.fromJson(e as Map<String, dynamic>)).toList();
    }
    final res = await _guard(() => _dio.get('/youtube/me'));
    final data = res.data as Map<String, dynamic>;
    return (data['accounts'] as List<dynamic>? ?? const [])
        .map((e) => YoutubeAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<YoutubePlaylist>> youtubePlaylists(String account, {String? refreshToken}) async {
    final params = <String, dynamic>{'account': account};
    final headers = <String, dynamic>{};
    if (ApiConfig.isServerless && refreshToken != null) {
      headers['X-Refresh-Token'] = refreshToken;
    }
    final res = await _guard(() => _dio.get(
      '/youtube/playlists',
      queryParameters: params,
      options: headers.isNotEmpty ? Options(headers: headers) : null,
    ));
    final data = res.data as Map<String, dynamic>;
    return (data['playlists'] as List<dynamic>? ?? const [])
        .map((e) => YoutubePlaylist.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Track>> youtubeTracks(String account, String playlistId,
      {String? pageToken, String? refreshToken}) async {
    final params = <String, dynamic>{
      'account': account,
      'pageToken': ?pageToken,
    };
    final headers = <String, dynamic>{};
    if (ApiConfig.isServerless && refreshToken != null) {
      headers['X-Refresh-Token'] = refreshToken;
    }
    final res = await _guard(() => _dio.get(
      '/youtube/playlists/$playlistId/tracks',
      queryParameters: params,
      options: headers.isNotEmpty ? Options(headers: headers) : null,
    ));
    final data = res.data as Map<String, dynamic>;
    return (data['tracks'] as List<dynamic>? ?? const [])
        .map((e) => Track.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> youtubeDisconnect(String account) async {
    if (ApiConfig.isServerless) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('youtube_accounts') ?? '[]';
      final list = (jsonDecode(raw) as List<dynamic>)
          .where((e) => (e as Map<String, dynamic>)['email'] != account)
          .toList();
      await prefs.setString('youtube_accounts', jsonEncode(list));
      return;
    }
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
      final status = e.response?.statusCode;
      if (e.response != null) {
        debugPrint('api: HTTP $status ${e.requestOptions.path}');
      }
      if (status == 401 || status == 403) throw ApiKeyRejectedException();
      if (status == 503) throw DioApiException();
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw ServerOfflineException();
      }
      rethrow;
    }
  }
}
