import '../../data/models/event_target_setting_model.dart';

/// Abstract interface for event target setting CRUD operations.
abstract class EventTargetSettingRepository {
  Future<List<EventTargetSettingModel>> getAll();
  Future<EventTargetSettingModel?> getById(String id);
  Future<List<EventTargetSettingModel>> getByEventId(String eventId);
  Future<void> insert(EventTargetSettingModel setting);
  Future<void> update(EventTargetSettingModel setting);
  Future<void> delete(String id);
}
