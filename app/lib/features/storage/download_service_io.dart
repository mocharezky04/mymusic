import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/models.dart';
import 'app_db.dart';

class DownloadService {
  DownloadService(this._db);

  final AppDatabase _db;
  final Dio _dio = Dio();

  Future<DownloadRecord?> existing(Track track) =>
      _db.downloadFor(track.id, track.source.apiValue);

  Future<DownloadRecord> download(
    Track track,
    String url, {
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/downloads');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final safeId = track.id.replaceAll(RegExp(r'[^\w\-]'), '_');
    final safeSrc = track.source.apiValue.replaceAll(RegExp(r'[^\w\-]'), '_');
    final target = '${folder.path}/${safeSrc}__$safeId.mp3';
    await _dio.download(
      url,
      target,
      onReceiveProgress: (received, total) {
        if (onProgress != null && total > 0) onProgress(received, total);
      },
      deleteOnError: true,
    );
    final record = DownloadRecord(
      track: track,
      filePath: target,
      sizeBytes: await File(target).length(),
    );
    await _db.addDownload(record);
    return record;
  }

  Future<void> remove(Track track) async {
    final record = await existing(track);
    await _db.removeDownload(track.id, track.source.apiValue);
    if (record != null) {
      try {
        await File(record.filePath).delete();
      } catch (_) {}
    }
  }
}

DownloadService createDownloadService(AppDatabase db) => DownloadService(db);