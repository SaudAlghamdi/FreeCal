import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freecal/features/rules/data/repositories/sync_rule_repository_impl.dart';
import 'package:freecal/features/rules/domain/entities/sync_rule_entity.dart';
import 'package:freecal/features/rules/domain/repositories/sync_rule_repository.dart';

// ---------------------------------------------------------------------------
// Provider: SyncRuleRepository
// ---------------------------------------------------------------------------

final syncRuleRepositoryProvider = Provider<SyncRuleRepository>((ref) {
  final repo = SyncRuleRepositoryImpl();
  ref.onDispose(repo.dispose);
  return repo;
});

// ---------------------------------------------------------------------------
// Provider: All Rules stream
// ---------------------------------------------------------------------------

final syncRulesStreamProvider = StreamProvider<List<SyncRuleEntity>>((ref) {
  final repo = ref.watch(syncRuleRepositoryProvider);
  return repo.watchRules();
});

// ---------------------------------------------------------------------------
// Provider: Rules for a specific source calendar
// ---------------------------------------------------------------------------

final rulesForCalendarProvider =
    FutureProvider.family<List<SyncRuleEntity>, String>(
        (ref, sourceCalendarId) async {
  final repo = ref.watch(syncRuleRepositoryProvider);
  return repo.getRulesForSourceCalendar(sourceCalendarId);
});
