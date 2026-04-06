import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freecal/app.dart';
import 'package:freecal/core/services/sync_scheduler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      observers: const [],
      child: _AppStartup(child: const FreecalApp()),
    ),
  );
}

/// Ensures the [syncSchedulerProvider] is initialized at app start.
class _AppStartup extends ConsumerWidget {
  const _AppStartup({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reading (not watching) eagerly instantiates the scheduler.
    ref.read(syncSchedulerProvider);
    return child;
  }
}
