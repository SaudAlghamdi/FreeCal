import 'package:freecal/features/rules/domain/entities/sync_rule_entity.dart';

/// Abstract repository interface for sync rule operations.
abstract class SyncRuleRepository {
  Future<List<SyncRuleEntity>> getAllRules();
  Future<List<SyncRuleEntity>> getRulesForSourceCalendar(
    String sourceCalendarId,
  );
  Future<SyncRuleEntity?> getRuleById(String id);
  Future<String> insertRule(SyncRuleEntity rule);
  Future<void> updateRule(SyncRuleEntity rule);
  Future<void> deleteRule(String id);
  Stream<List<SyncRuleEntity>> watchRules();
}
