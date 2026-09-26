import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../storage/app_db.dart';

final apiProvider = Provider<MyMusicApi>((ref) {
  return MyMusicApi(ApiConfig.baseUrl);
});

class SearchController extends AsyncNotifier<List<Track>> {
  @override
  Future<List<Track>> build() async => const [];

  Future<void> run(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final results = await ref.read(apiProvider).search(q);
      state = AsyncValue.data(results);
      if (results.isNotEmpty) {
        ref.read(historyProvider.notifier).add(q);
      }
    } catch (err, st) {
      debugPrint('search: "$q" failed: $err');
      debugPrintStack(stackTrace: st, maxFrames: 2);
      state = AsyncValue.error(err, st);
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
}

final searchControllerProvider =
    AsyncNotifierProvider<SearchController, List<Track>>(SearchController.new);

final historyProvider =
    AsyncNotifierProvider<HistoryController, List<String>>(HistoryController.new);

class HistoryController extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() => ref.watch(dbProvider).history;

  Future<void> add(String term) async {
    final db = ref.read(dbProvider);
    await db.addHistory(term);
    state = AsyncValue.data(await db.history);
  }

  Future<void> removeAt(int index) async {
    final db = ref.read(dbProvider);
    final terms = await db.history;
    await db.removeHistory(terms[index]);
    state = AsyncValue.data(await db.history);
  }

  Future<void> clear() async {
    final db = ref.read(dbProvider);
    await db.clearHistory();
    state = const AsyncValue.data([]);
  }
}