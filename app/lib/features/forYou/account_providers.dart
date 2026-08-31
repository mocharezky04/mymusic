import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../search/search_providers.dart' show apiProvider;

class AccountsController extends AsyncNotifier<List<YoutubeAccount>> {
  @override
  Future<List<YoutubeAccount>> build() async {
    try {
      return await ref.read(apiProvider).youtubeAccounts();
    } catch (_) {
      return const [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await ref.read(apiProvider).youtubeAccounts());
    } on DioApiException {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> remove(YoutubeAccount account) async {
    try {
      await ref.read(apiProvider).youtubeDisconnect(account.email);
      state = AsyncValue.data(
        (state.value ?? const []).where((a) => a.email != account.email).toList(),
      );
    } on DioApiException {
      rethrow;
    } catch (e) {
      throw DioApiException();
    }
  }
}

final accountsProvider =
    AsyncNotifierProvider<AccountsController, List<YoutubeAccount>>(AccountsController.new);

final activeAccountProvider = StateProvider<YoutubeAccount?>((ref) => null);
