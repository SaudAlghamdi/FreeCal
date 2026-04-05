import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/database_provider.dart';
import '../../data/models/event_target_setting_model.dart';
import '../../domain/repositories/event_target_setting_repository.dart';

/// State notifier that manages per-event target settings (overrides).
class EventTargetSettingNotifier
    extends AsyncNotifier<List<EventTargetSettingModel>> {
  late EventTargetSettingRepository _repository;

  @override
  Future<List<EventTargetSettingModel>> build() async {
    _repository =
        await ref.watch(eventTargetSettingRepositoryProvider.future);
    return _repository.getAll();
  }

  Future<void> addSetting({
    required String eventId,
    required String targetCalendarId,
    required String mode,
    bool overrideRule = true,
  }) async {
    final setting = EventTargetSettingModel(
      id: const Uuid().v4(),
      eventId: eventId,
      targetCalendarId: targetCalendarId,
      mode: mode,
      overrideRule: overrideRule,
    );
    await _repository.insert(setting);
    ref.invalidateSelf();
  }

  Future<void> updateSetting(EventTargetSettingModel setting) async {
    await _repository.update(setting);
    ref.invalidateSelf();
  }

  Future<void> deleteSetting(String id) async {
    await _repository.delete(id);
    ref.invalidateSelf();
  }

  Future<List<EventTargetSettingModel>> getSettingsForEvent(
    String eventId,
  ) async {
    return _repository.getByEventId(eventId);
  }
}

/// Provider for the event target settings list state.
final eventTargetSettingNotifierProvider = AsyncNotifierProvider<
    EventTargetSettingNotifier, List<EventTargetSettingModel>>(
  EventTargetSettingNotifier.new,
);
