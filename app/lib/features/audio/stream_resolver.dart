import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../core/config.dart';
import 'app_ejs_solver.dart';
import 'yt/visionos_client.dart';

Dio _backendDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  if (ApiConfig.apiKey.isNotEmpty) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['X-API-Key'] = ApiConfig.apiKey;
          handler.next(options);
        },
      ),
    );
  }
  return dio;
}

Future<String> _fromBackend(String videoId, {String quality = '128k'}) async {
  final res = await _backendDio().get(
    '/stream',
    queryParameters: {'video_id': videoId, 'quality': quality},
  );
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
  final clients = [('visionos', visionosClient), ('ios', YoutubeApiClient.ios)];
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
        debugPrint(
          'stream: local ok ($label) manifest=${mMs}ms probe=${pMs}ms',
        );
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
/// membuat resolve ~1 detik lebih cepat, dan URL rusak tetap tertangkap sebagai
/// error playback di [_applyQueue], bukan sebagai hening diam-diam.
///
/// Bukti logcat 2026-09-26 (sesudah timeout dinaikkan ke 10 dtk + retry 2 dtk):
/// satu lagu butuh 26,7 detik = 10s visionos + 10s ios + 3s jeda + 3,7s retry.
/// Timeout panjang justru memperpanjang, bukan memperbaiki. Backend yang
/// cache-hit membalas dalam ~1,5 detik, jadi lokal dan backend dijalankan
/// bersamaan dan yang pertama selesai menang. Batas global 14 detik.
///
/// Perhatian: `Future.any` TIDAK boleh dipakai di sini. Semantiknya selesai
/// pada event pertama APA PUN, termasuk error, sehingga satu cabang yang gagal
/// duluan (mis. backend 502) langsung mematikan seluruh resolve padahal cabang
/// lain masih berjalan dan akan menang beberapa detik kemudian. Ganti dengan
/// menunggu tiap cabang selesai secara individual.
Future<String> resolveStreamUrl(
  String videoId, {
  String quality = '128k',
  bool probe = true,
  bool isStartTrack = false,
}) async {
  final t0 = DateTime.now().millisecondsSinceEpoch;
  const globalCap = Duration(seconds: 14);

  if (kIsWeb) {
    return _fromBackend(videoId, quality: quality);
  }

  // Bukti logcat: manifest lokal yang BERHASIL punya rentang 1827 ms sampai
  // 7985 ms, jadi batas 6 detik memotong yang sebenarnya bisa berbunyi.
  // Karena backend kini berjalan paralel, menambah batas lokal tidak menambah
  // latensi total: mana pun yang selesai duluan yang menang.
  final localTimeout = const Duration(seconds: 12);

  // Cabang lokal & backend: masing-masing mengembalikan String? tempat null
  // berarti "gagal". Error di-catch per cabang sehingga satu cabang gagal tidak
  // membatalkan yang lain. Pemenang diputuskan oleh Completer yang mengembalikan
  // URL pertama yang non-null; cabang yang kalah dibiarkan selesai sendiri.
  final completer = Completer<String>();
  var settled = false;

  Future<String?> runLocal() async {
    try {
      final url = await _fromLocal(
        videoId,
        probe: probe,
        manifestTimeout: localTimeout,
        retryOnce: false,
      );
      if (!settled) {
        settled = true;
        debugPrint(
          'stream: lokal menang ${DateTime.now().millisecondsSinceEpoch - t0}ms',
        );
        completer.complete(url);
      }
      return url;
    } catch (e) {
      debugPrint(
        'stream: lokal gagal ${DateTime.now().millisecondsSinceEpoch - t0}ms: '
        '${e.runtimeType}',
      );
      return null;
    }
  }

  Future<String?> runBackend() async {
    try {
      final url = await _fromBackend(videoId, quality: quality);
      if (!settled) {
        settled = true;
        debugPrint(
          'stream: backend menang ${DateTime.now().millisecondsSinceEpoch - t0}ms',
        );
        completer.complete(url);
      }
      return url;
    } catch (e) {
      debugPrint(
        'stream: backend gagal ${DateTime.now().millisecondsSinceEpoch - t0}ms: '
        '${e.runtimeType}',
      );
      return null;
    }
  }

  unawaited(runLocal());
  unawaited(runBackend());

  final winner = await completer.future.timeout(
    globalCap,
    onTimeout: () => '',
  );
  if (winner.isNotEmpty) return winner;

  debugPrint(
    'stream: resolve gagal dalam ${DateTime.now().millisecondsSinceEpoch - t0}ms '
    '(lokal + backend gagal dalam ${globalCap.inSeconds} dtk)',
  );
  throw Exception('stream unavailable');
}
