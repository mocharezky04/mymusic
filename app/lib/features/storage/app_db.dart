import 'dart:io' show File;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/models.dart';

part 'app_db.g.dart';

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

QueryExecutor _openExecutor() {
  if (kIsWeb) {
    return driftDatabase(
      name: 'mymusic',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  }
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    return NativeDatabase.createInBackground(File('${dir.path}/mymusic.sqlite'));
  });
}

class SearchHistoryRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get term => text().unique()();
  DateTimeColumn get createdAt => dateTime()();
}

class QueueRows extends Table {
  IntColumn get position => integer()();
  TextColumn get id => text()();
  TextColumn get source => text()();
  TextColumn get title => text()();
  TextColumn get artist => text().withDefault(const Constant(''))();
  IntColumn get duration => integer().withDefault(const Constant(0))();
  TextColumn get thumb => text().withDefault(const Constant(''))();
  TextColumn get uploader => text().withDefault(const Constant(''))();
  TextColumn get url => text().withDefault(const Constant(''))();
}

class MetaRows extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
}

class DownloadsRows extends Table {
  TextColumn get id => text()();
  TextColumn get source => text()();
  TextColumn get title => text()();
  TextColumn get artist => text().withDefault(const Constant(''))();
  IntColumn get duration => integer().withDefault(const Constant(0))();
  TextColumn get thumb => text().withDefault(const Constant(''))();
  TextColumn get uploader => text().withDefault(const Constant(''))();
  TextColumn get url => text().withDefault(const Constant(''))();
  TextColumn get filePath => text()();
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

class PlaybackHistoryRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get trackId => text()();
  TextColumn get source => text()();
  TextColumn get title => text()();
  TextColumn get artist => text().withDefault(const Constant(''))();
  IntColumn get duration => integer().withDefault(const Constant(0))();
  TextColumn get thumb => text().withDefault(const Constant(''))();
  TextColumn get uploader => text().withDefault(const Constant(''))();
  TextColumn get url => text().withDefault(const Constant(''))();
  DateTimeColumn get playedAt => dateTime()();
  IntColumn get plays => integer().withDefault(const Constant(1))();
}

class SavedMixRows extends Table {
  TextColumn get mixId => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get source => text().withDefault(const Constant('youtube'))();
  DateTimeColumn get createdAt => dateTime()();
}

class DownloadRecord {
  const DownloadRecord({
    required this.track,
    required this.filePath,
    required this.sizeBytes,
  });

  final Track track;
  final String filePath;
  final int sizeBytes;
}

@DriftDatabase(
  tables: [SearchHistoryRows, QueueRows, MetaRows, DownloadsRows, PlaybackHistoryRows, SavedMixRows],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openExecutor());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(downloadsRows);
          }
          if (from < 3) {
            await m.createTable(playbackHistoryRows);
          }
          if (from < 4) {
            await m.createTable(savedMixRows);
          }
        },
      );

  Future<List<String>> get history async {
    final rows = await (select(searchHistoryRows)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map((r) => r.term).toList();
  }

  Future<void> addHistory(String term) async {
    await into(searchHistoryRows).insert(
      SearchHistoryRowsCompanion.insert(term: term, createdAt: DateTime.now()),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> removeHistory(String term) async {
    await (delete(searchHistoryRows)..where((t) => t.term.equals(term))).go();
  }

  Future<void> clearHistory() => delete(searchHistoryRows).go();

  Future<void> writeQueue(List<Track> tracks, int index) async {
    await transaction(() async {
      await delete(queueRows).go();
      for (var i = 0; i < tracks.length; i++) {
        final t = tracks[i];
        await into(queueRows).insert(QueueRowsCompanion.insert(
          position: i,
          id: t.id,
          source: t.source.apiValue,
          title: t.title,
          artist: Value(t.artist),
          duration: Value(t.durationSeconds),
          thumb: Value(t.thumb),
          uploader: Value(t.uploader),
          url: Value(t.url),
        ));
      }
      await upsertMeta('queue_index', '$index');
    });
  }

  Future<(List<Track>, int)> readQueue() async {
    final rows = await (select(queueRows)..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
    final tracks = rows
        .map((r) => Track(
              id: r.id,
              source: TrackSource.fromApi(r.source),
              title: r.title,
              artist: r.artist,
              durationSeconds: r.duration,
              thumb: r.thumb,
              uploader: r.uploader,
              url: r.url,
            ))
        .toList();
    final index = int.tryParse(await getMeta('queue_index') ?? '-1') ?? -1;
    final clamped = tracks.isEmpty ? -1 : index.clamp(0, tracks.length - 1);
    return (tracks, clamped);
  }

  Future<void> clearQueue() async {
    await transaction(() async {
      await delete(queueRows).go();
      await (delete(metaRows)..where((t) => t.key.equals('queue_index'))).go();
    });
  }

  Future<void> upsertMeta(String key, String value) async {
    await transaction(() async {
      await (delete(metaRows)..where((t) => t.key.equals(key))).go();
      await into(metaRows)
          .insert(MetaRowsCompanion.insert(key: key, value: value));
    });
  }

  Future<String?> getMeta(String key) async {
    final rows = await (select(metaRows)..where((t) => t.key.equals(key))).get();
    return rows.isEmpty ? null : rows.last.value;
  }

  Future<DownloadRecord?> downloadFor(String id, String source) async {
    final rows = await (select(downloadsRows)
          ..where((t) => t.id.equals(id) & t.source.equals(source)))
        .get();
    if (rows.isEmpty) return null;
    final row = rows.last;
    return _downloadFromRow(row);
  }

  Future<List<DownloadRecord>> downloads() async {
    final rows = await (select(downloadsRows)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_downloadFromRow).toList();
  }

  Future<void> addDownload(DownloadRecord record) async {
    final t = record.track;
    await into(downloadsRows).insert(
      DownloadsRowsCompanion.insert(
        id: t.id,
        source: t.source.apiValue,
        title: t.title,
        artist: Value(t.artist),
        duration: Value(t.durationSeconds),
        thumb: Value(t.thumb),
        uploader: Value(t.uploader),
        url: Value(t.url),
        filePath: record.filePath,
        sizeBytes: Value(record.sizeBytes),
        createdAt: DateTime.now(),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> removeDownload(String id, String source) async {
    await (delete(downloadsRows)..where((t) => t.id.equals(id) & t.source.equals(source))).go();
  }

  static const _historyKey = 'record-play-';

  Future<void> recordPlay(Track track) async {
    await transaction(() async {
      final existing = await (select(playbackHistoryRows)
            ..where((t) => t.trackId.equals(track.id) & t.source.equals(track.source.apiValue)))
          .get();
      final now = DateTime.now();
      if (existing.isEmpty) {
        await into(playbackHistoryRows).insert(
          PlaybackHistoryRowsCompanion.insert(
            trackId: track.id,
            source: track.source.apiValue,
            title: track.title,
            artist: Value(track.artist),
            duration: Value(track.durationSeconds),
            thumb: Value(track.thumb),
            uploader: Value(track.uploader),
            url: Value(track.url),
            playedAt: now,
            plays: const Value(1),
          ),
        );
      } else {
        final row = existing.last;
        await (update(playbackHistoryRows)
              ..where((t) => t.id.equals(row.id)))
            .write(
          PlaybackHistoryRowsCompanion(
            title: Value(track.title),
            artist: Value(track.artist),
            duration: Value(track.durationSeconds),
            thumb: Value(track.thumb),
            uploader: Value(track.uploader),
            url: Value(track.url),
            playedAt: Value(now),
            plays: Value(row.plays + 1),
          ),
        );
      }
      await upsertMeta('$_historyKey${track.id}-${track.source.apiValue}', '1');
    });
  }

  Future<List<Track>> recentPlays({int limit = 24}) async {
    final rows = await (select(playbackHistoryRows)
          ..orderBy([(t) => OrderingTerm.desc(t.playedAt)])
          ..limit(limit))
        .get();
    return rows.map(_historyTrack).toList();
  }

  Future<List<Track>> topPlays({int limit = 12}) async {
    final rows = await (select(playbackHistoryRows)
          ..orderBy([
            (t) => OrderingTerm.desc(t.plays),
            (t) => OrderingTerm.desc(t.playedAt),
          ])
          ..limit(limit))
        .get();
    return rows.map(_historyTrack).toList();
  }

  Future<List<SavedMixRow>> savedMixes() async {
    return (select(savedMixRows)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<void> saveMix(String mixId, String title) async {
    await into(savedMixRows).insert(
      SavedMixRowsCompanion.insert(
        mixId: mixId,
        title: Value(title),
        createdAt: DateTime.now(),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> removeMix(String mixId) async {
    await (delete(savedMixRows)..where((t) => t.mixId.equals(mixId))).go();
  }

  Future<bool> isMixSaved(String mixId) async {
    final rows = await (select(savedMixRows)
          ..where((t) => t.mixId.equals(mixId)))
        .get();
    return rows.isNotEmpty;
  }
}

Track _historyTrack(PlaybackHistoryRow row) {
  return Track(
    id: row.trackId,
    source: TrackSource.fromApi(row.source),
    title: row.title,
    artist: row.artist,
    durationSeconds: row.duration,
    thumb: row.thumb,
    uploader: row.uploader,
    url: row.url,
  );
}

DownloadRecord _downloadFromRow(DownloadsRow row) {
  return DownloadRecord(
    track: Track(
      id: row.id,
      source: TrackSource.fromApi(row.source),
      title: row.title,
      artist: row.artist,
      durationSeconds: row.duration,
      thumb: row.thumb,
      uploader: row.uploader,
      url: row.url,
    ),
    filePath: row.filePath,
    sizeBytes: row.sizeBytes,
  );
}