import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../search/search_providers.dart' show apiProvider;

final lyricsProvider =
    FutureProvider.family<LyricsResult, ({String track, String artist})>(
  (ref, args) => ref.read(apiProvider).lyrics(args.track, args.artist),
);

class LrcLine {
  const LrcLine(this.time, this.text);

  final Duration time;
  final String text;
}

class SyncedLyrics {
  const SyncedLyrics(this.lines);

  final List<LrcLine> lines;

  factory SyncedLyrics.parse(String lrc) {
    final lines = <LrcLine>[];
    final pattern = RegExp(r'\[(\d+):(\d+)(?:\.(\d+))?\]');
    for (final raw in lrc.split(RegExp(r'\r?\n'))) {
      final matches = pattern.allMatches(raw);
      if (matches.isEmpty) continue;
      final text = raw.replaceAll(pattern, '').trim();
      if (text.isEmpty) continue;
      for (final m in matches) {
        final min = int.parse(m.group(1)!);
        final sec = int.parse(m.group(2)!);
        final frac = int.tryParse(m.group(3) ?? '') ?? 0;
        lines.add(LrcLine(
          Duration(minutes: min, seconds: sec, milliseconds: frac * 10),
          text,
        ));
      }
    }
    lines.sort((a, b) => a.time.compareTo(b.time));
    return SyncedLyrics(lines);
  }
}