import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../forYou/for_you_screen.dart';
import '../forYou/recommendation_provider.dart';
import '../playlist/playlist_screen.dart';
import '../player/mini_player.dart';
import '../search/search_screen.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';

enum AppTab {
  forYou(Icons.home_outlined),
  search(Icons.search_outlined),
  playlist(Icons.library_music_outlined);

  const AppTab(this.icon);

  final IconData icon;

  String label(L10n l10n) => switch (this) {
    AppTab.forYou => l10n.forYou,
    AppTab.search => l10n.search,
    AppTab.playlist => l10n.playlist,
  };
  String title(L10n l10n) => label(l10n);
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'themeMode';

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.dark;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'light') state = ThemeMode.light;
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, next == ThemeMode.dark ? 'dark' : 'light');
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  void _onTabSelected(int i) {
    setState(() => _index = i);
    if (i == 0) {
      ref.invalidate(recommendationProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final tab = AppTab.values[_index];
    final wide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(tab.title(l10n)),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate_rounded),
            tooltip: l10n.changeLanguage,
            onPressed: () => ref.read(languageProvider.notifier).toggle(),
          ),
          IconButton(
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: l10n.changeTheme,
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: wide ? _wideLayout(tab, l10n) : _narrowLayout(tab, l10n),
      ),
    );
  }

  Widget _narrowLayout(AppTab tab, L10n l10n) {
    return Column(
      children: [
        Expanded(child: _body(tab)),
        const MiniPlayer(),
        _PillNav(selected: _index, l10n: l10n, onSelected: _onTabSelected),
      ],
    );
  }

  Widget _wideLayout(AppTab tab, L10n l10n) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _index,
          onDestinationSelected: _onTabSelected,
          leading: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Icon(
              Icons.graphic_eq_rounded,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          destinations: [
            for (final t in AppTab.values)
              NavigationRailDestination(
                icon: Icon(t.icon),
                label: Text(t.label(l10n)),
              ),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              Expanded(child: _body(tab)),
              const MiniPlayer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _body(AppTab tab) {
    return IndexedStack(
      index: _index,
      children: const [ForYouScreen(), SearchScreen(), PlaylistScreen()],
    );
  }
}

class _PillNav extends StatelessWidget {
  const _PillNav({
    required this.selected,
    required this.l10n,
    required this.onSelected,
  });

  final int selected;
  final L10n l10n;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (var i = 0; i < AppTab.values.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: AppTab.values[i].icon,
                    label: AppTab.values[i].label(l10n),
                    selected: selected == i,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            height: 3,
            width: selected ? 20 : 0,
            decoration: BoxDecoration(
              color: scheme.onSurface,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          ),
          const SizedBox(height: 8),
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
