import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freecal/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:freecal/features/calendar/domain/entities/calendar_entity.dart';
import 'package:freecal/features/calendar/domain/repositories/calendar_repository.dart';

// ---------------------------------------------------------------------------
// Provider: CalendarRepository
// ---------------------------------------------------------------------------

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  final repo = CalendarRepositoryImpl();
  ref.onDispose(repo.dispose);
  return repo;
});

// ---------------------------------------------------------------------------
// Provider: All Calendars (async)
// ---------------------------------------------------------------------------

final calendarsProvider =
    FutureProvider<List<CalendarEntity>>((ref) async {
  final repo = ref.watch(calendarRepositoryProvider);
  return repo.getAllCalendars();
});

// ---------------------------------------------------------------------------
// Provider: Calendars stream
// ---------------------------------------------------------------------------

final calendarsStreamProvider =
    StreamProvider<List<CalendarEntity>>((ref) {
  final repo = ref.watch(calendarRepositoryProvider);
  return repo.watchCalendars();
});
