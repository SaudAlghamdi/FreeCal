import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';

/// Placeholder home screen that verifies database initialization.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FreeCal'),
      ),
      body: Center(
        child: dbAsync.when(
          data: (_) => const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
              SizedBox(height: 16),
              Text(
                'Database initialized successfully.',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'FreeCal Phase 1 complete.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text(
            'Database initialization failed:\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
