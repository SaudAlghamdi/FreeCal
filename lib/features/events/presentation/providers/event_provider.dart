import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freecal/features/events/data/repositories/event_repository_impl.dart';
import 'package:freecal/features/events/domain/entities/event_entity.dart';
import 'package:freecal/features/events/domain/entities/event_target_settings_entity.dart';
import 'package:freecal/features/events/domain/entities/mirror_link_entity.dart';
import 'package:freecal/features/events/domain/repositories/event_repository.dart';

// ---------------------------------------------------------------------------
// Provider: EventRepository
// ---------------------------------------------------------------------------

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final repo = EventRepositoryImpl();
  ref.onDispose(repo.dispose);
  return repo;
});

// ---------------------------------------------------------------------------
// Provider: All Events stream
// ---------------------------------------------------------------------------

final eventsStreamProvider = StreamProvider<List<EventEntity>>((ref) {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.watchEvents();
});

// ---------------------------------------------------------------------------
// Provider: Events in date range
// ---------------------------------------------------------------------------

final eventsInRangeProvider = FutureProvider.family<
    List<EventEntity>,
    ({DateTime start, DateTime end})>((ref, params) async {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getEventsInRange(params.start, params.end);
});

// ---------------------------------------------------------------------------
// StateNotifier: Add/Edit Event
// ---------------------------------------------------------------------------

class EventFormState {
  const EventFormState({
    this.title = '',
    this.notes,
    this.location,
    required this.startTime,
    required this.endTime,
    this.sourceCalendarId = '',
    this.targetSettings = const [],
    this.isSaving = false,
    this.error,
  });

  final String title;
  final String? notes;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final String sourceCalendarId;
  final List<EventTargetSettingsEntity> targetSettings;
  final bool isSaving;
  final String? error;

  bool get isValid =>
      title.trim().isNotEmpty && sourceCalendarId.isNotEmpty;

  EventFormState copyWith({
    String? title,
    String? notes,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    String? sourceCalendarId,
    List<EventTargetSettingsEntity>? targetSettings,
    bool? isSaving,
    String? error,
  }) {
    return EventFormState(
      title: title ?? this.title,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sourceCalendarId: sourceCalendarId ?? this.sourceCalendarId,
      targetSettings: targetSettings ?? this.targetSettings,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class EventFormNotifier extends StateNotifier<EventFormState> {
  EventFormNotifier(this._repo)
      : super(EventFormState(
          startTime: _defaultStart(),
          endTime: _defaultEnd(),
        ));

  final EventRepository _repo;

  static DateTime _defaultStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  static DateTime _defaultEnd() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 2);
  }

  void setTitle(String value) => state = state.copyWith(title: value);
  void setNotes(String? value) => state = state.copyWith(notes: value);
  void setLocation(String? value) =>
      state = state.copyWith(location: value);
  void setStartTime(DateTime value) =>
      state = state.copyWith(startTime: value);
  void setEndTime(DateTime value) =>
      state = state.copyWith(endTime: value);
  void setSourceCalendar(String id) =>
      state = state.copyWith(sourceCalendarId: id);

  void updateTargetSettings(EventTargetSettingsEntity settings) {
    final updated = List<EventTargetSettingsEntity>.from(state.targetSettings);
    final idx = updated.indexWhere(
      (s) => s.targetCalendarId == settings.targetCalendarId,
    );
    if (idx >= 0) {
      updated[idx] = settings;
    } else {
      updated.add(settings);
    }
    state = state.copyWith(targetSettings: updated);
  }

  void setModeForCalendar(String calendarId, MirrorMode mode) {
    final existing = state.targetSettings.firstWhere(
      (s) => s.targetCalendarId == calendarId,
      orElse: () => EventTargetSettingsEntity(
        id: calendarId,
        eventId: '',
        targetCalendarId: calendarId,
        mode: mode,
      ),
    );
    updateTargetSettings(existing.copyWith(mode: mode));
  }

  void reset() {
    state = EventFormState(
      startTime: _defaultStart(),
      endTime: _defaultEnd(),
    );
  }
}

final eventFormProvider =
    StateNotifierProvider<EventFormNotifier, EventFormState>((ref) {
  final repo = ref.watch(eventRepositoryProvider);
  return EventFormNotifier(repo);
});

// ---------------------------------------------------------------------------
// Provider: Mirror links for a specific event
// ---------------------------------------------------------------------------

final mirrorLinksForEventProvider =
    FutureProvider.family<List<MirrorLinkEntity>, String>((ref, eventId) {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getMirrorLinksForEvent(eventId);
});

// ---------------------------------------------------------------------------
// Provider: Target settings for a specific event
// ---------------------------------------------------------------------------

final targetSettingsForEventProvider =
    FutureProvider.family<List<EventTargetSettingsEntity>, String>(
        (ref, eventId) {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getTargetSettingsForEvent(eventId);
});
