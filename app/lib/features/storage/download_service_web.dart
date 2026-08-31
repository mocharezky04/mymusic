import '../../core/models.dart';
import 'app_db.dart';

class DownloadService {
  DownloadService(this._db);

  final AppDatabase _db;

  Future<DownloadRecord?> existing(Track track) =>
      _db.downloadFor(track.id, track.source.apiValue);

  Future<DownloadRecord> download(
    Track track,
    String url, {
    void Function(int received, int total)? onProgress,
  }) {
    throw UnsupportedError('Offline downloads are not supported on web.');
  }

  Future<void> remove(Track track) async {
    await _db.removeDownload(track.id, track.source.apiValue);
  }
}

DownloadService createDownloadService(AppDatabase db) => DownloadService(db);