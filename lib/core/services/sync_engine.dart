import 'package:freecal/features/events/domain/entities/event_entity.dart';
import 'package:freecal/features/events/domain/entities/event_target_settings_entity.dart';
import 'package:freecal/features/events/domain/entities/mirror_link_entity.dart';
import 'package:freecal/features/events/domain/repositories/event_repository.dart';
import 'package:freecal/features/rules/domain/entities/sync_rule_entity.dart';
import 'package:freecal/features/rules/domain/repositories/sync_rule_repository.dart';
import 'package:uuid/uuid.dart';

/// The Sync Rules Engine processes events and generates mirror links
/// according to per-event override settings and default sync rules.
class SyncEngine {
  const SyncEngine({
    required EventRepository eventRepository,
    required SyncRuleRepository ruleRepository,
  })  : _eventRepo = eventRepository,
        _ruleRepo = ruleRepository;

  final EventRepository _eventRepo;
  final SyncRuleRepository _ruleRepo;
  static const Uuid _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Processes an [event] after it is saved:
  /// 1. Applies per-event [targetSettings] if present.
  /// 2. Falls back to matching [SyncRuleEntity] defaults.
  ///
  /// Creates or updates [MirrorLinkEntity] records accordingly.
  Future<void> processEvent(
    EventEntity event, {
    List<EventTargetSettingsEntity>? targetSettings,
  }) async {
    // Remove any stale mirror links first
    await _eventRepo.deleteMirrorLinksForEvent(event.id);

    final rules = await _ruleRepo.getRulesForSourceCalendar(
      event.sourceCalendarId,
    );

    final settings = targetSettings ??
        await _eventRepo.getTargetSettingsForEvent(event.id);

    for (final rule in rules) {
      if (!rule.isActive) continue;

      // Check per-event override first
      final override = _findSettingsForCalendar(
        settings,
        rule.targetCalendarId,
      );

      if (override != null) {
        if (override.overrideRule) {
          // Per-event override takes precedence
          await _applyMirror(
            event: event,
            targetCalendarId: rule.targetCalendarId,
            mode: override.mode,
          );
          continue;
        }
      }

      // Apply default rule, respecting the time window
      if (!_eventFallsInRuleWindow(event, rule)) continue;

      final effectiveMode = override?.mode ?? rule.mode;
      if (effectiveMode == MirrorMode.none) continue;

      await _applyMirror(
        event: event,
        targetCalendarId: rule.targetCalendarId,
        mode: effectiveMode,
      );
    }
  }

  /// Determines the effective [MirrorMode] for an [event] in a given
  /// [targetCalendarId], considering rules and per-event settings.
  Future<MirrorMode> resolveMode(
    EventEntity event,
    String targetCalendarId, {
    List<EventTargetSettingsEntity>? targetSettings,
  }) async {
    final settings = targetSettings ??
        await _eventRepo.getTargetSettingsForEvent(event.id);

    final override = _findSettingsForCalendar(settings, targetCalendarId);
    if (override != null && override.overrideRule) {
      return override.mode;
    }

    final rules = await _ruleRepo.getRulesForSourceCalendar(
      event.sourceCalendarId,
    );

    for (final rule in rules) {
      if (rule.targetCalendarId != targetCalendarId) continue;
      if (!rule.isActive) continue;
      if (!_eventFallsInRuleWindow(event, rule)) return MirrorMode.none;
      return override?.mode ?? rule.mode;
    }

    return MirrorMode.none;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns true if the event's start time falls within the rule's time window.
  bool _eventFallsInRuleWindow(EventEntity event, SyncRuleEntity rule) {
    if (!rule.hasTimeWindow) return true;
    return rule.isInTimeWindow(event.startTime);
  }

  EventTargetSettingsEntity? _findSettingsForCalendar(
    List<EventTargetSettingsEntity> settings,
    String calendarId,
  ) {
    try {
      return settings.firstWhere(
        (s) => s.targetCalendarId == calendarId,
      );
    } on StateError {
      return null;
    }
  }

  Future<void> _applyMirror({
    required EventEntity event,
    required String targetCalendarId,
    required MirrorMode mode,
  }) async {
    final link = MirrorLinkEntity(
      id: _uuid.v4(),
      sourceEventId: event.id,
      targetCalendarId: targetCalendarId,
      mirrorMode: mode,
    );
    await _eventRepo.insertMirrorLink(link);
  }
}
