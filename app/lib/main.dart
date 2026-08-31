import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/l10n.dart';
import 'core/theme.dart';
import 'features/audio/audio_handler.dart';
import 'features/forYou/account_providers.dart';
import 'features/player/player_provider.dart';
import 'features/shell/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AudioPlayerHandler? serviceHandler;
  if (!kIsWeb && Platform.isAndroid) {
    try {
      await Permission.notification.request();
    } catch (_) {}
    serviceHandler = await AudioService.init(
      builder: AudioPlayerHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.mymusic.player',
        androidNotificationChannelName: 'MyMusic',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  }
  runApp(
    ProviderScope(
      overrides: [
        if (serviceHandler != null) audioHandlerProvider.overrideWithValue(serviceHandler),
      ],
      child: const MyMusicApp(),
    ),
  );
}

class MyMusicApp extends ConsumerStatefulWidget {
  const MyMusicApp({super.key});

  @override
  ConsumerState<MyMusicApp> createState() => _MyMusicAppState();
}

class _MyMusicAppState extends ConsumerState<MyMusicApp> with WidgetsBindingObserver {
  static const _channel = MethodChannel('mymusic/deeplink');

  String? _pendingEmail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _channel.setMethodCallHandler(_handleChannel);
    _channel.invokeMethod<String?>('getInitialLink').then(_processDeepLink);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(accountsProvider.notifier).refresh();
    }
  }

  Future<dynamic> _handleChannel(MethodCall call) async {
    if (call.method == 'onDeepLink' && call.arguments is String) {
      _processDeepLink(call.arguments as String);
    }
  }

  void _processDeepLink(String? uri) {
    if (uri == null || uri.isEmpty) return;
    final lower = uri.toLowerCase();
    if (lower.startsWith('mymusic://youtube-connected')) {
      final email = _queryParam(uri, 'email');
      if (email != null && email.isNotEmpty) {
        setState(() => _pendingEmail = email);
      }
      ref.read(accountsProvider.notifier).refresh();
    } else if (lower.startsWith('mymusic://youtube-connection-failed')) {
      ref.read(accountsProvider.notifier).refresh();
    }
  }

  String? _queryParam(String uri, String key) {
    final qIndex = uri.indexOf('?');
    if (qIndex < 0) return null;
    final params = uri.substring(qIndex + 1).split('&');
    for (final p in params) {
      final eq = p.indexOf('=');
      if (eq < 0) continue;
      if (Uri.decodeComponent(p.substring(0, eq)) == key) {
        return Uri.decodeComponent(p.substring(eq + 1));
      }
    }
    return null;
  }

  void _dismissPending() {
    if (_pendingEmail != null) {
      setState(() => _pendingEmail = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: isDark ? AppColors.ink : AppColors.paper,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      );
    });

    final app = MaterialApp(
      key: ValueKey(themeMode),
      title: 'MyMusic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: Builder(
        builder: (innerContext) {
          if (_pendingEmail != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final messenger = ScaffoldMessenger.of(innerContext);
              final l10n = ProviderScope.containerOf(innerContext).read(l10nProvider);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(l10n.accountLinked(_pendingEmail!)),
                  duration: const Duration(seconds: 3),
                ),
              );
              _dismissPending();
            });
          }
          return const HomeShell();
        },
      ),
    );

    return app;
  }
}
