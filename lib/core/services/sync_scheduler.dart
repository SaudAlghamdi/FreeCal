import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freecal/features/settings/domain/entities/linked_account_entity.dart';
import 'package:freecal/features/settings/domain/repositories/linked_account_repository.dart';
import 'package:freecal/features/settings/presentation/providers/linked_account_provider.dart';

/// How often the scheduler re-syncs all connected accounts.
const _kSyncInterval = Duration(seconds: 30);

/// The result of the most recent sync cycle.
class SyncStatus {
  const SyncStatus({
    required this.lastSyncAt,
    required this.syncedProviders,
    this.error,
  });

  final DateTime lastSyncAt;
  final List<AccountProvider> syncedProviders;
  final String? error;

  bool get hasError => error != null;
}

/// Runs a periodic sync job every [_kSyncInterval].
///
/// On each tick it:
/// 1. Loads all connected [LinkedAccountEntity] records.
/// 2. Simulates fetching remote calendar data for each provider.
/// 3. Updates the [lastSyncAt] timestamp.
class SyncScheduler {
  SyncScheduler({
    required LinkedAccountRepository accountRepository,
    required Ref ref,
    Duration interval = _kSyncInterval,
  })  : _accountRepo = accountRepository,
        _ref = ref,
        _interval = interval;

  final LinkedAccountRepository _accountRepo;
  final Ref _ref;
  final Duration _interval;

  Timer? _timer;
  final _statusController = StreamController<SyncStatus>.broadcast();

  Stream<SyncStatus> get statusStream => _statusController.stream;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void start() {
    _timer?.cancel();
    // Run once immediately, then repeat.
    _runSync();
    _timer = Timer.periodic(_interval, (_) => _runSync());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    _statusController.close();
  }

  // ---------------------------------------------------------------------------
  // Sync logic
  // ---------------------------------------------------------------------------

  Future<void> _runSync() async {
    try {
      final accounts = await _accountRepo.getAll();
      final connected =
          accounts.where((a) => a.isConnected).toList();

      if (connected.isEmpty) return;

      final synced = <AccountProvider>[];

      for (final account in connected) {
        await _syncProvider(account);
        synced.add(account.provider);
      }

      // Refresh provider state so UI picks up new lastSyncAt timestamps
      await _ref
          .read(linkedAccountNotifierProvider.notifier)
          .build(); // re-triggers current state rebuild

      if (!_statusController.isClosed) {
        _statusController.add(
          SyncStatus(
            lastSyncAt: DateTime.now(),
            syncedProviders: synced,
          ),
        );
      }
    } catch (e) {
      if (!_statusController.isClosed) {
        _statusController.add(
          SyncStatus(
            lastSyncAt: DateTime.now(),
            syncedProviders: const [],
            error: e.toString(),
          ),
        );
      }
    }
  }

  /// Simulates fetching and processing events from a remote calendar provider.
  ///
  /// In a production app this would call the provider's REST/OAuth API and
  /// insert/update local events accordingly.
  Future<void> _syncProvider(LinkedAccountEntity account) async {
    // Simulate network latency
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Update the lastSyncAt timestamp in the database
    final notifier = _ref.read(linkedAccountNotifierProvider.notifier);
    await notifier.updateLastSync(account.provider);
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final syncSchedulerProvider = Provider<SyncScheduler>((ref) {
  final accountRepo = ref.watch(linkedAccountRepositoryProvider);
  final scheduler = SyncScheduler(accountRepository: accountRepo, ref: ref);
  scheduler.start();
  ref.onDispose(scheduler.dispose);
  return scheduler;
});

/// Exposes the latest [SyncStatus] emitted by the scheduler.
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final scheduler = ref.watch(syncSchedulerProvider);
  return scheduler.statusStream;
});
