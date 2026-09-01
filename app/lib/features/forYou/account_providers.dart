import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../search/search_providers.dart' show apiProvider;

const _kAccountsKey = 'youtube_accounts';
const _kActiveEmailKey = 'active_account_email';

class AccountsController extends AsyncNotifier<List<YoutubeAccount>> {
  @override
  Future<List<YoutubeAccount>> build() async {
    if (ApiConfig.isServerless) {
      return _loadLocal();
    }
    try {
      return await ref.read(apiProvider).youtubeAccounts();
    } catch (_) {
      return const [];
    }
  }

  Future<List<YoutubeAccount>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAccountsKey) ?? '[]';
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => YoutubeAccount.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      if (ApiConfig.isServerless) {
        state = AsyncValue.data(await _loadLocal());
      } else {
        state = AsyncValue.data(await ref.read(apiProvider).youtubeAccounts());
      }
    } on DioApiException {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> upsertFromCallback(YoutubeAccount account) async {
    if (!ApiConfig.isServerless) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAccountsKey) ?? '[]';
    final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    list.removeWhere((e) => e['email'] == account.email);
    list.add(account.toJson());
    await prefs.setString(_kAccountsKey, jsonEncode(list));
    await prefs.setString(_kActiveEmailKey, account.email);
    state = AsyncValue.data(
      list.map((e) => YoutubeAccount.fromJson(e)).toList(),
    );
  }

  Future<void> remove(YoutubeAccount account) async {
    try {
      if (ApiConfig.isServerless) {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_kAccountsKey) ?? '[]';
        final list = (jsonDecode(raw) as List<dynamic>)
            .where((e) => (e as Map<String, dynamic>)['email'] != account.email)
            .toList();
        await prefs.setString(_kAccountsKey, jsonEncode(list));
        final activeEmail = prefs.getString(_kActiveEmailKey);
        if (activeEmail == account.email) {
          await prefs.remove(_kActiveEmailKey);
        }
        state = AsyncValue.data(
          list.map((e) => YoutubeAccount.fromJson(e as Map<String, dynamic>)).toList(),
        );
      } else {
        await ref.read(apiProvider).youtubeDisconnect(account.email);
        state = AsyncValue.data(
          (state.value ?? const []).where((a) => a.email != account.email).toList(),
        );
      }
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

Future<void> loadActiveAccount(WidgetRef ref) async {
  if (!ApiConfig.isServerless) return;
  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString(_kActiveEmailKey);
  if (email == null) return;
  final accounts = ref.read(accountsProvider).value ?? const <YoutubeAccount>[];
  final match = accounts.where((a) => a.email == email);
  if (match.isNotEmpty) {
    ref.read(activeAccountProvider.notifier).state = match.first;
  }
}
