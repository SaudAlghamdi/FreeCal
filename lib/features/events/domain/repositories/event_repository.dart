import '../../data/models/event_model.dart';

/// Abstract interface for event CRUD operations.
abstract class EventRepository {
  Future<List<EventModel>> getAll();
  Future<EventModel?> getById(String id);
  Future<List<EventModel>> getByCalendarId(String calendarId);
  Future<void> insert(EventModel event);
  Future<void> update(EventModel event);
  Future<void> delete(String id);
}
