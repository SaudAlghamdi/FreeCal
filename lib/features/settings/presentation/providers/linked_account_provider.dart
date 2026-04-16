import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freecal/features/settings/data/repositories/linked_account_repository_impl.dart';
import 'package:freecal/features/settings/domain/entities/linked_account_entity.dart';
import 'package:freecal/features/settings/domain/repositories/linked_account_repository.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final linkedAccountRepositoryProvider =
    Provider<LinkedAccountRepository>((ref) {
  final repo = LinkedAccountRepositoryImpl();
  ref.onDispose(repo.dispose);
  return repo;
});

// ---------------------------------------------------------------------------
// Stream provider: watch all linked accounts
// ---------------------------------------------------------------------------

final linkedAccountsStreamProvider =
    StreamProvider<List<LinkedAccountEntity>>((ref) {
  final repo = ref.watch(linkedAccountRepositoryProvider);
  return repo.watchAll();
});

// ---------------------------------------------------------------------------
// Notifier: link / unlink accounts
// ---------------------------------------------------------------------------

const _uuid = Uuid();

class LinkedAccountNotifier extends AsyncNotifier<List<LinkedAccountEntity>> {
  @override
  Future<List<LinkedAccountEntity>> build() async {
    final repo = ref.watch(linkedAccountRepositoryProvider);
    return repo.getAll();
  }

  Future<void> linkAccount(AccountProvider provider, String email) async {
    final repo = ref.read(linkedAccountRepositoryProvider);
    final existing = await repo.getByProvider(provider);
    final account = LinkedAccountEntity(
      id: existing?.id ?? _uuid.v4(),
      provider: provider,
      email: email,
      isConnected: true,
      lastSyncAt: null,
    );
    await repo.upsert(account);
    state = AsyncData(await repo.getAll());
  }

  Future<void> unlinkAccount(AccountProvider provider) async {
    final repo = ref.read(linkedAccountRepositoryProvider);
    final existing = await repo.getByProvider(provider);
    if (existing == null) return;
    await repo.delete(existing.id);
    state = AsyncData(await repo.getAll());
  }

  Future<void> updateLastSync(AccountProvider provider) async {
    final repo = ref.read(linkedAccountRepositoryProvider);
    final existing = await repo.getByProvider(provider);
    if (existing == null) return;
    await repo.upsert(existing.copyWith(lastSyncAt: DateTime.now()));
    state = AsyncData(await repo.getAll());
  }
}

final linkedAccountNotifierProvider =
    AsyncNotifierProvider<LinkedAccountNotifier, List<LinkedAccountEntity>>(
  LinkedAccountNotifier.new,
);
