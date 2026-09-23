import 'dart:async';
import 'dart:convert';

import 'package:flutter_js/flutter_js.dart';
import 'package:youtube_explode_dart/js_challenge.dart';

class AppEJSSolver extends BaseEJSSolver {
  JavascriptRuntime? _runtime;
  bool _modulesLoaded = false;

  Future<void> _ensureReady() async {
    if (_runtime != null && _modulesLoaded) return;
    final runtime = _createRuntime();
    final modules = await EJSBuilder.getJSModules();
    final init = runtime.evaluate(modules);
    if (init.isError) {
      runtime.dispose();
      throw Exception('EJS module init failed: ${init.stringResult}');
    }
    _runtime = runtime;
    _modulesLoaded = true;
  }

  JavascriptRuntime _createRuntime() {
    try {
      return QuickJsRuntime2(
        stackSize: 4 * 1024 * 1024,
        memoryLimit: 256 * 1024 * 1024,
        timeout: 20000,
      );
    } catch (_) {
      return getJavascriptRuntime();
    }
  }

  @override
  Future<String> executeJavaScript(String jsCode) async {
    await _ensureReady();
    try {
      return await _evaluate(jsCode).timeout(const Duration(seconds: 20));
    } catch (_) {
      _disposeRuntime();
      await _ensureReady();
      return _evaluate(jsCode).timeout(const Duration(seconds: 20));
    }
  }

  Future<String> _evaluate(String jsCode) async {
    final runtime = _runtime!;
    final result = await runtime.evaluateAsync(jsCode);
    if (result.isError) {
      throw Exception('EJS evaluate error: ${result.stringResult}');
    }
    return _unwrapJson(result.rawResult ?? result.stringResult);
  }

  String _unwrapJson(dynamic raw) {
    if (raw is Map || raw is List) {
      return jsonEncode(raw);
    }
    var s = (raw ?? '').toString().trim();
    while (s.startsWith('"') && s.endsWith('"') && s.length > 1) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is String) {
          s = decoded.trim();
          continue;
        }
      } catch (_) {}
      break;
    }
    return s;
  }

  void _disposeRuntime() {
    _runtime?.dispose();
    _runtime = null;
    _modulesLoaded = false;
  }

  @override
  void dispose() {
    _disposeRuntime();
    super.dispose();
  }
}

AppEJSSolver? _sharedSolver;

AppEJSSolver get appEjsSolver => _sharedSolver ??= AppEJSSolver();