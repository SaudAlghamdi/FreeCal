import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/database_provider.dart';
import '../../data/models/calendar_model.dart';
import '../../domain/repositories/calendar_repository.dart';

/// State notifier that manages the list of calendars.
class CalendarNotifier extends AsyncNotifier<List<CalendarModel>> {
  late CalendarRepository _repository;

  @override
  Future<List<CalendarModel>> build() async {
    _repository = await ref.watch(calendarRepositoryProvider.future);
    return _repository.getAll();
  }

  Future<void> addCalendar({
    required String name,
    required String type,
    required int color,
  }) async {
    final calendar = CalendarModel(
      id: const Uuid().v4(),
      name: name,
      type: type,
      color: color,
    );
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.insert(calendar);
      return _repository.getAll();
    });
  }

  Future<void> updateCalendar(CalendarModel calendar) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.update(calendar);
      return _repository.getAll();
    });
  }

  Future<void> deleteCalendar(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.delete(id);
      return _repository.getAll();
    });
  }
}

/// Provider for the calendar list state.
final calendarNotifierProvider =
    AsyncNotifierProvider<CalendarNotifier, List<CalendarModel>>(
  CalendarNotifier.new,
);
