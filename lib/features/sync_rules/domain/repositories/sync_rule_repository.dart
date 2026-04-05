import '../../data/models/sync_rule_model.dart';

/// Abstract interface for sync rule CRUD operations.
abstract class SyncRuleRepository {
  Future<List<SyncRuleModel>> getAll();
  Future<SyncRuleModel?> getById(String id);
  Future<List<SyncRuleModel>> getBySourceCalendarId(String calendarId);
  Future<void> insert(SyncRuleModel rule);
  Future<void> update(SyncRuleModel rule);
  Future<void> delete(String id);
}
