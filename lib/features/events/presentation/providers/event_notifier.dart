import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/database_provider.dart';
import '../../data/models/event_model.dart';
import '../../domain/repositories/event_repository.dart';

/// State notifier that manages the list of events.
class EventNotifier extends AsyncNotifier<List<EventModel>> {
  late EventRepository _repository;

  @override
  Future<List<EventModel>> build() async {
    _repository = await ref.watch(eventRepositoryProvider.future);
    return _repository.getAll();
  }

  Future<EventModel> addEvent({
    required String title,
    required String startTime,
    required String endTime,
    required String sourceCalendarId,
    bool isMirror = false,
    String? notes,
    String? location,
  }) async {
    final event = EventModel(
      id: const Uuid().v4(),
      title: title,
      startTime: startTime,
      endTime: endTime,
      sourceCalendarId: sourceCalendarId,
      isMirror: isMirror,
      notes: notes,
      location: location,
    );
    await _repository.insert(event);
    ref.invalidateSelf();
    return event;
  }

  Future<void> updateEvent(EventModel event) async {
    await _repository.update(event);
    ref.invalidateSelf();
  }

  Future<void> deleteEvent(String id) async {
    await _repository.delete(id);
    ref.invalidateSelf();
  }

  Future<List<EventModel>> getEventsByCalendar(String calendarId) async {
    return _repository.getByCalendarId(calendarId);
  }
}

/// Provider for the event list state.
final eventNotifierProvider =
    AsyncNotifierProvider<EventNotifier, List<EventModel>>(
  EventNotifier.new,
);
