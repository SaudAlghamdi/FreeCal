import 'package:freecal/features/events/domain/entities/event_entity.dart';
import 'package:freecal/features/events/domain/entities/event_target_settings_entity.dart';
import 'package:freecal/features/events/domain/entities/mirror_link_entity.dart';

/// Abstract repository interface for event operations.
abstract class EventRepository {
  // --- Events ---
  Future<List<EventEntity>> getAllEvents();
  Future<List<EventEntity>> getEventsByCalendar(String calendarId);
  Future<List<EventEntity>> getEventsInRange(
    DateTime start,
    DateTime end,
  );
  Future<EventEntity?> getEventById(String id);
  Future<String> insertEvent(EventEntity event);
  Future<void> updateEvent(EventEntity event);
  Future<void> deleteEvent(String id);
  Stream<List<EventEntity>> watchEvents();

  // --- Mirror Links ---
  Future<List<MirrorLinkEntity>> getMirrorLinksForEvent(String eventId);
  Future<List<MirrorLinkEntity>> getMirrorLinksForCalendar(
    String targetCalendarId,
  );
  Future<String> insertMirrorLink(MirrorLinkEntity link);
  Future<void> updateMirrorLink(MirrorLinkEntity link);
  Future<void> deleteMirrorLink(String id);
  Future<void> deleteMirrorLinksForEvent(String eventId);

  // --- Event Target Settings ---
  Future<List<EventTargetSettingsEntity>> getTargetSettingsForEvent(
    String eventId,
  );
  Future<EventTargetSettingsEntity?> getTargetSettingsForEventAndCalendar(
    String eventId,
    String targetCalendarId,
  );
  Future<String> insertTargetSettings(EventTargetSettingsEntity settings);
  Future<void> updateTargetSettings(EventTargetSettingsEntity settings);
  Future<void> deleteTargetSettings(String id);
}
