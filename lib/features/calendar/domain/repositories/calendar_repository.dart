import 'package:freecal/features/calendar/domain/entities/calendar_entity.dart';

/// Abstract repository interface for calendar operations.
abstract class CalendarRepository {
  Future<List<CalendarEntity>> getAllCalendars();
  Future<CalendarEntity?> getCalendarById(String id);
  Future<String> insertCalendar(CalendarEntity calendar);
  Future<void> updateCalendar(CalendarEntity calendar);
  Future<void> deleteCalendar(String id);
  Stream<List<CalendarEntity>> watchCalendars();
}
