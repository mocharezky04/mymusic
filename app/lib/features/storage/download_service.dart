import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'download_service_io.dart'
    if (dart.library.js_interop) 'download_service_web.dart' as impl;
import 'app_db.dart';

export 'download_service_io.dart'
    if (dart.library.js_interop) 'download_service_web.dart';

final downloadServiceProvider = Provider<impl.DownloadService>((ref) {
  return impl.createDownloadService(ref.watch(dbProvider));
});