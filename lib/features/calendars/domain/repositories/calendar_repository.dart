import '../../data/models/calendar_model.dart';

/// Abstract interface for calendar CRUD operations.
abstract class CalendarRepository {
  Future<List<CalendarModel>> getAll();
  Future<CalendarModel?> getById(String id);
  Future<void> insert(CalendarModel calendar);
  Future<void> update(CalendarModel calendar);
  Future<void> delete(String id);
}
