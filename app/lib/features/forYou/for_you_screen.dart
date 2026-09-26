import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api.dart';
import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../player/player_provider.dart';
import '../playlist/add_to_playlist_sheet.dart';
import '../search/search_providers.dart' show apiProvider;
import '../search/track_tile.dart';
import '../storage/app_db.dart';
import 'account_providers.dart';
import 'history_providers.dart';
import 'recommendation_provider.dart';

class ForYouScreen extends ConsumerWidget {
  const ForYouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    // Watch accountsProvider here so the parent rebuilds when the
    // account list finishes loading (avoids stale child in IndexedStack).
    ref.watch(accountsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            children: [
              _Label(l10n.forYou),
              const Spacer(),
              AccountAvatar(l10n: l10n),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(recommendationProvider);
              ref.invalidate(recentPlaysProvider);
              ref.invalidate(topPlaysProvider);
              ref.invalidate(accountsProvider);
              await Future<void>.delayed(const Duration(milliseconds: 300));
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _Label(l10n.recommendedForYou),
                const _RecommendedSection(),
                const SizedBox(height: 20),
                _Label(l10n.recentlyPlayed),
                const ForYouRows(),
                const SizedBox(height: 20),
                _Label(l10n.accountsLabel),
                AccountSection(l10n: l10n),
                const SizedBox(height: 20),
                _Label(l10n.savedMixes),
                const _SavedMixesSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SavedMixesSection extends ConsumerWidget {
  const _SavedMixesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    final scheme = Theme.of(context).colorScheme;
    final l10n = ref.watch(l10nProvider);

    return FutureBuilder<List<SavedMixRow>>(
      future: db.savedMixes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }
        final mixes = snapshot.data ?? [];
        if (mixes.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              l10n.noSavedMixes,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          );
        }
        return SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: mixes.length,
            separatorBuilder: (_, ix) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final m = mixes[i];
              return GestureDetector(
                onTap: () {
                  // TODO: fetch mix tracks and play
                },
                onLongPress: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.deleteMixTitle),
                      content: Text(l10n.deleteMixConfirm(m.title)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await db.removeMix(m.mixId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.mixRemoved(m.title))),
                      );
                    }
                  }
                },
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.queue_music_rounded,
                        size: 28,
                        color: scheme.primary,
                      ),
                      const Spacer(),
                      Text(
                        m.title.isNotEmpty ? m.title : m.mixId,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.dynamicFromYoutube,
                        style: TextStyle(
                          fontSize: 9,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ForYouRows extends ConsumerWidget {
  const ForYouRows({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentPlaysProvider).value ?? const <Track>[];
    final top = ref.watch(topPlaysProvider).value ?? const <Track>[];
    final controller = ref.read(playerControllerProvider.notifier);
    final l10n = ref.watch(l10nProvider);

    if (recent.isEmpty && top.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Text(
          l10n.noHistory,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (top.isNotEmpty) ...[
          _CardTitle(l10n.topPlayed),
          _BigCard(
            title: l10n.topPlayed,
            subtitle: l10n.topSubtitle(top.length),
            thumb: top.first.thumb,
            onPlay: () => controller.playFrom(top, 0),
          ),
        ],
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 14),
          _CardTitle(l10n.recentlyPlayedTitle),
          _BigCard(
            title: l10n.recentlyPlayedTitle,
            subtitle: l10n.recentSubtitle(recent.length),
            thumb: recent.first.thumb,
            onPlay: () => controller.playFrom(recent, 0),
          ),
        ],
      ],
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  const _BigCard({
    required this.title,
    required this.subtitle,
    required this.thumb,
    required this.onPlay,
  });

  final String title;
  final String subtitle;
  final String thumb;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 7,
              child: thumb.isEmpty
                  ? Container(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.music_note,
                        size: 44,
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  : Image.network(
                      thumb,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: scheme.surfaceContainerHighest),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    onPressed: onPlay,
                    icon: Icon(
                      Icons.play_arrow_rounded,
                      color: scheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AccountMenu { select, add, disconnect }

class AccountAvatar extends ConsumerWidget {
  const AccountAvatar({super.key, required this.l10n});

  final L10n l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final accounts =
        ref.watch(accountsProvider).value ?? const <YoutubeAccount>[];
    final active = ref.watch(activeAccountProvider);
    final activeOrFirst =
        active ?? (accounts.isNotEmpty ? accounts.first : null);
    return PopupMenuButton<_AccountMenu>(
      tooltip: l10n.noAccounts,
      onSelected: (menu) {
        switch (menu) {
          case _AccountMenu.select:
            break;
          case _AccountMenu.add:
            _connect(context, ref);
          case _AccountMenu.disconnect:
            if (activeOrFirst != null) _disconnect(context, ref, activeOrFirst);
        }
      },
      itemBuilder: (_) => [
        for (final acc in accounts)
          PopupMenuItem(
            value: _AccountMenu.select,
            onTap: () => ref.read(activeAccountProvider.notifier).state = acc,
            child: Row(
              children: [
                if (acc.email == activeOrFirst?.email)
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(acc.displayName, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        if (accounts.isNotEmpty) const PopupMenuDivider(),
        PopupMenuItem(value: _AccountMenu.add, child: Text(l10n.addAccount)),
        if (activeOrFirst != null)
          PopupMenuItem(
            value: _AccountMenu.disconnect,
            child: Text(l10n.removeActiveAccount),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: _avatar(context, activeOrFirst),
      ),
    );
  }

  Widget _avatar(BuildContext context, YoutubeAccount? acc) {
    final scheme = Theme.of(context).colorScheme;
    final String? url = (acc != null && acc.avatarUrl.isNotEmpty)
        ? acc.avatarUrl
        : null;
    final fallback = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        size: 20,
        color: scheme.onSurfaceVariant,
      ),
    );
    return Stack(
      children: [
        if (url != null)
          ClipOval(
            child: Image.network(
              url,
              width: 34,
              height: 34,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
          )
        else
          fallback,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: scheme.surface, width: 1.5),
            ),
            child: Icon(Icons.add, size: 11, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Future<void> _connect(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = ref.read(l10nProvider);
    try {
      final url = await ref.read(apiProvider).youtubeAuthStart();
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.cantOpenBrowser)));
      }
    } on DioApiException {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.accountsNotConfigured)),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.connectionError)));
    }
  }

  Future<void> _disconnect(
    BuildContext context,
    WidgetRef ref,
    YoutubeAccount account,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = ref.read(l10nProvider);
    try {
      await ref.read(accountsProvider.notifier).remove(account);
      messenger.showSnackBar(
        SnackBar(content: Text('${account.displayName} ${l10n.disconnected}')),
      );
    } on DioApiException {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.accountsNotConfigured)),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.connectionError)));
    }
  }
}

class AccountSection extends ConsumerWidget {
  const AccountSection({super.key, required this.l10n});

  final L10n l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts =
        ref.watch(accountsProvider).value ?? const <YoutubeAccount>[];
    final active = ref.watch(activeAccountProvider);
    final activeOrFirst =
        active ?? (accounts.isNotEmpty ? accounts.first : null);

    if (accounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: _LoginCard(
          l10n: l10n,
          onConnect: (context) => _connect(context, ref),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final acc in accounts)
          ListTile(
            dense: true,
            onTap: () => ref.read(activeAccountProvider.notifier).state = acc,
            leading: _avatar(scheme, acc),
            title: Text(
              acc.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              acc.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(
              acc.email == activeOrFirst?.email
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              color: acc.email == activeOrFirst?.email
                  ? scheme.primary
                  : scheme.outline,
            ),
          ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextButton.icon(
            onPressed: () => _connect(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.addAccount),
          ),
        ),
        if (activeOrFirst != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton.icon(
              onPressed: () => _disconnect(context, ref, activeOrFirst),
              icon: const Icon(Icons.link_off_rounded, size: 18),
              label: Text(l10n.removeActiveAccount),
            ),
          ),
          const Divider(height: 24),
          _PlaylistSection(account: activeOrFirst),
        ],
        if (accounts.length > 1) ...[
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              l10n.playlistFromSelected,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }

  Widget _avatar(ColorScheme scheme, YoutubeAccount acc) {
    final fallback = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        size: 20,
        color: scheme.onSurfaceVariant,
      ),
    );
    if (acc.avatarUrl.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        acc.avatarUrl,
        width: 38,
        height: 38,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }

  Future<void> _connect(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = ref.read(l10nProvider);
    try {
      final url = await ref.read(apiProvider).youtubeAuthStart();
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.cantOpenBrowser)));
      }
    } on DioApiException {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.accountsNotConfigured)),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.connectionError)));
    }
  }

  Future<void> _disconnect(
    BuildContext context,
    WidgetRef ref,
    YoutubeAccount account,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = ref.read(l10nProvider);
    try {
      await ref.read(accountsProvider.notifier).remove(account);
      messenger.showSnackBar(
        SnackBar(content: Text('${account.displayName} ${l10n.disconnected}')),
      );
    } on DioApiException {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.accountsNotConfigured)),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.connectionError)));
    }
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.l10n, required this.onConnect});

  final L10n l10n;
  final ValueChanged<BuildContext> onConnect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.account_circle_rounded,
              size: 40,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.connectYouTube,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.connectYouTubeSubtitle,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => onConnect(context),
              style: TextButton.styleFrom(foregroundColor: scheme.primary),
              child: Text(l10n.login),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistSection extends ConsumerWidget {
  const _PlaylistSection({required this.account});

  final YoutubeAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider(account.email));
    final scheme = Theme.of(context).colorScheme;
    final l10n = ref.watch(l10nProvider);
    return playlists.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$err', style: TextStyle(fontSize: 13, color: scheme.error)),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () => ref.invalidate(playlistsProvider(account.email)),
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(l10n.tryAgain),
            ),
          ],
        ),
      ),
      data: (list) => list.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                l10n.noPlaylistsForAccount,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardTitle(l10n.likedPlaylists),
                for (final pl in list)
                  _PlaylistListTile(playlist: pl, account: account),
              ],
            ),
    );
  }
}

class _PlaylistListTile extends ConsumerWidget {
  const _PlaylistListTile({required this.playlist, required this.account});

  final YoutubePlaylist playlist;
  final YoutubeAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = ref.watch(l10nProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: playlist.thumb.isNotEmpty
            ? Image.network(
                playlist.thumb,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(scheme),
              )
            : _placeholder(scheme),
      ),
      title: Text(playlist.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(l10n.trackCount(playlist.count)),
      trailing: IconButton(
        onPressed: () => _play(context, ref, controller),
        icon: Icon(Icons.play_arrow_rounded, color: scheme.primary),
      ),
      onTap: () => _play(context, ref, controller),
    );
  }

  Future<void> _play(
    BuildContext context,
    WidgetRef ref,
    PlayerController controller,
  ) async {
    final l10n = ref.read(l10nProvider);
    try {
      final tracks = await ref.read(
        tracksProvider((account: account.email, playlistId: playlist.id))
            .future,
      );
      if (!context.mounted) return;
      if (tracks.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.playlistEmpty)));
        return;
      }
      controller.playFrom(tracks, 0);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.failedToLoadTracks)));
    }
  }

  Widget _placeholder(ColorScheme scheme) {
    return Container(
      width: 46,
      height: 46,
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.playlist_play_rounded, color: scheme.onSurfaceVariant),
    );
  }
}

final playlistsProvider = FutureProvider.family<List<YoutubePlaylist>, String>((
  ref,
  email,
) async {
  final api = ref.read(apiProvider);
  final accounts = ref.read(accountsProvider).value ?? const <YoutubeAccount>[];
  final match = accounts.where((a) => a.email == email);
  final refreshToken = match.isNotEmpty ? match.first.refreshToken : null;
  return api.youtubePlaylists(email, refreshToken: refreshToken);
});

final tracksProvider =
    FutureProvider.family<List<Track>, ({String playlistId, String account})>((
      ref,
      args,
    ) async {
      final api = ref.read(apiProvider);
      final accounts =
          ref.read(accountsProvider).value ?? const <YoutubeAccount>[];
      final match = accounts.where((a) => a.email == args.account);
      final refreshToken = match.isNotEmpty ? match.first.refreshToken : null;
      return api.youtubeTracks(
        args.account,
        args.playlistId,
        refreshToken: refreshToken,
      );
    });

class _RecommendedSection extends ConsumerWidget {
  const _RecommendedSection();

  static String _recommendationCause(Object err, L10n l10n) {
    if (err is ApiKeyRejectedException) return l10n.appBuildRejected;
    if (err is ServerOfflineException) return l10n.serverUnreachable;
    if (err is DioApiException) return l10n.serverBusy;
    return l10n.loadRecommendationsFailed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rec = ref.watch(recommendationProvider);
    final scheme = Theme.of(context).colorScheme;
    final l10n = ref.watch(l10nProvider);
    final controller = ref.read(playerControllerProvider.notifier);

    return rec.when(
      loading: () => const Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _recommendationCause(err, l10n),
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            if (err is! ApiKeyRejectedException)
              TextButton.icon(
                onPressed: () => ref.invalidate(recommendationProvider),
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(l10n.tryAgain, style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
      data: (data) {
        if (data.tracks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              data.excludeCount == 0
                  ? l10n.noHistory
                  : l10n.noNewRecommendations,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.recommendedForYou,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => controller.playFrom(data.tracks, 0),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.primary,
                    ),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 19),
                    label: Text(l10n.playAll),
                  ),
                ],
              ),
            ),
            for (final t in data.tracks)
              TrackTile(
                track: t,
                onTap: () => controller.playFrom([t], 0),
                trailing: _RecommendMenu(track: t),
              ),
          ],
        );
      },
    );
  }
}

class _RecommendMenu extends ConsumerWidget {
  const _RecommendMenu({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(playerControllerProvider.notifier);
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: scheme.onSurfaceVariant,
      ),
      tooltip: l10n.moreActions,
      onSelected: (action) async {
        switch (action) {
          case 'playNext':
            controller.playNext(track);
          case 'enqueue':
            controller.addToQueue(track);
          case 'playlist':
            await pickPlaylistForTrack(context, track);
        }
      },
      itemBuilder: (_) => [
        _menuItem(
          scheme,
          'playNext',
          Icons.playlist_add_rounded,
          l10n.playNext,
        ),
        _menuItem(
          scheme,
          'enqueue',
          Icons.queue_music_rounded,
          l10n.addToQueue,
        ),
        _menuItem(
          scheme,
          'playlist',
          Icons.playlist_add_rounded,
          l10n.addToPlaylist,
        ),
      ],
    );
  }

  static PopupMenuItem<String> _menuItem(
    ColorScheme scheme,
    String value,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      value: value,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 19, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
