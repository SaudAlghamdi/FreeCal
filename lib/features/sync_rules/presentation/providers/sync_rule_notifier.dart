import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/database_provider.dart';
import '../../data/models/sync_rule_model.dart';
import '../../domain/repositories/sync_rule_repository.dart';

/// State notifier that manages sync rules.
class SyncRuleNotifier extends AsyncNotifier<List<SyncRuleModel>> {
  late SyncRuleRepository _repository;

  @override
  Future<List<SyncRuleModel>> build() async {
    _repository = await ref.watch(syncRuleRepositoryProvider.future);
    return _repository.getAll();
  }

  Future<void> addRule({
    required String sourceCalendarId,
    required String targetCalendarId,
    required String mode,
    String? timeWindowStart,
    String? timeWindowEnd,
  }) async {
    final rule = SyncRuleModel(
      id: const Uuid().v4(),
      sourceCalendarId: sourceCalendarId,
      targetCalendarId: targetCalendarId,
      mode: mode,
      timeWindowStart: timeWindowStart,
      timeWindowEnd: timeWindowEnd,
    );
    await _repository.insert(rule);
    ref.invalidateSelf();
  }

  Future<void> updateRule(SyncRuleModel rule) async {
    await _repository.update(rule);
    ref.invalidateSelf();
  }

  Future<void> deleteRule(String id) async {
    await _repository.delete(id);
    ref.invalidateSelf();
  }

  Future<List<SyncRuleModel>> getRulesForCalendar(String calendarId) async {
    return _repository.getBySourceCalendarId(calendarId);
  }
}

/// Provider for the sync rules list state.
final syncRuleNotifierProvider =
    AsyncNotifierProvider<SyncRuleNotifier, List<SyncRuleModel>>(
  SyncRuleNotifier.new,
);
