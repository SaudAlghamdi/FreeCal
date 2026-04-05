import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_engine.dart';

/// Provides the [SyncEngine] instance.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  return const SyncEngine();
});
