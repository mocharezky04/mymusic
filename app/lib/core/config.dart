import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const _baseOverride = String.fromEnvironment('API_BASE');

  static String get baseUrl {
    if (_baseOverride.isNotEmpty) return _baseOverride;
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://127.0.0.1:8000';
    return 'http://localhost:8000';
  }

  static bool get isServerless {
    if (_baseOverride.endsWith('.vercel.app')) return true;
    return const bool.fromEnvironment('USE_SERVERLESS');
  }

  static const apiKey = String.fromEnvironment('API_KEY');
}