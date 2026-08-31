import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../storage/app_db.dart';

final recentPlaysProvider = FutureProvider<List<Track>>((ref) async {
  final db = ref.watch(dbProvider);
  return db.recentPlays();
});

final topPlaysProvider = FutureProvider<List<Track>>((ref) async {
  final db = ref.watch(dbProvider);
  return db.topPlays();
});
