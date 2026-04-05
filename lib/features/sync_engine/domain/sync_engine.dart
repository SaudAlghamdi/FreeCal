import '../../../core/enums/mirror_mode.dart';
import '../../events/data/models/event_model.dart';
import '../../event_target_settings/data/models/event_target_setting_model.dart';
import '../../mirror_links/data/models/mirror_link_model.dart';
import '../../sync_rules/data/models/sync_rule_model.dart';

/// Result of evaluating sync rules for a single event against a target calendar.
class SyncDecision {
  final String targetCalendarId;
  final MirrorMode mode;
  final bool isOverride;

  const SyncDecision({
    required this.targetCalendarId,
    required this.mode,
    this.isOverride = false,
  });
}

/// The sync engine evaluates which calendars should receive a mirrored copy
/// of an event, and in what mode, based on default rules, time windows,
/// and per-event overrides.
class SyncEngine {
  const SyncEngine();

  /// Determines the [SyncDecision] for each target calendar given:
  /// - [event]: the source event
  /// - [rules]: all sync rules from the source calendar
  /// - [overrides]: per-event target settings that override default rules
  ///
  /// Returns a list of decisions (one per target calendar that has a rule).
  /// Decisions with [MirrorMode.none] are included so the caller can
  /// distinguish "explicitly hidden" from "no rule exists".
  List<SyncDecision> evaluate({
    required EventModel event,
    required List<SyncRuleModel> rules,
    required List<EventTargetSettingModel> overrides,
  }) {
    final decisions = <SyncDecision>[];

    for (final rule in rules) {
      // Skip rules not originating from this event's calendar.
      if (rule.sourceCalendarId != event.sourceCalendarId) continue;

      // Check for a per-event override first.
      final override = _findOverride(overrides, event.id, rule.targetCalendarId);
      if (override != null && override.overrideRule) {
        decisions.add(SyncDecision(
          targetCalendarId: rule.targetCalendarId,
          mode: MirrorMode.fromDbString(override.mode),
          isOverride: true,
        ));
        continue;
      }

      // Apply time window filtering.
      if (!_isWithinTimeWindow(event, rule)) {
        decisions.add(SyncDecision(
          targetCalendarId: rule.targetCalendarId,
          mode: MirrorMode.none,
        ));
        continue;
      }

      // Apply the default rule mode.
      decisions.add(SyncDecision(
        targetCalendarId: rule.targetCalendarId,
        mode: MirrorMode.fromDbString(rule.mode),
      ));
    }

    return decisions;
  }

  /// Generates the [MirrorLinkModel] entries that should exist for [event]
  /// based on sync decisions. Only creates links for non-none modes.
  List<MirrorLinkModel> generateMirrorLinks({
    required EventModel event,
    required List<SyncDecision> decisions,
    required String Function() idGenerator,
  }) {
    return decisions
        .where((d) => d.mode != MirrorMode.none)
        .map((d) => MirrorLinkModel(
              id: idGenerator(),
              sourceEventId: event.id,
              targetCalendarId: d.targetCalendarId,
              mirrorMode: d.mode.toDbString(),
            ))
        .toList();
  }

  EventTargetSettingModel? _findOverride(
    List<EventTargetSettingModel> overrides,
    String eventId,
    String targetCalendarId,
  ) {
    for (final o in overrides) {
      if (o.eventId == eventId && o.targetCalendarId == targetCalendarId) {
        return o;
      }
    }
    return null;
  }

  /// Checks whether [event] falls within the time window defined by [rule].
  ///
  /// If no time window is set on the rule, the event always qualifies.
  /// The time window is compared against the event's start time using
  /// hour-of-day comparison (e.g., 06:00–18:00).
  bool _isWithinTimeWindow(EventModel event, SyncRuleModel rule) {
    if (rule.timeWindowStart == null || rule.timeWindowEnd == null) {
      return true;
    }

    final eventStart = DateTime.tryParse(event.startTime);
    final eventEnd = DateTime.tryParse(event.endTime);
    if (eventStart == null || eventEnd == null) return true;

    final windowStart = _parseTimeOfDay(rule.timeWindowStart!);
    final windowEnd = _parseTimeOfDay(rule.timeWindowEnd!);
    if (windowStart == null || windowEnd == null) return true;

    // Compare using minutes since midnight for the event's start time.
    final eventStartMinutes = eventStart.hour * 60 + eventStart.minute;
    final eventEndMinutes = eventEnd.hour * 60 + eventEnd.minute;

    // Event must start AND end within the time window.
    return eventStartMinutes >= windowStart && eventEndMinutes <= windowEnd;
  }

  /// Parses a time string like "06:00" or an ISO 8601 datetime and returns
  /// minutes since midnight, or null if unparseable.
  int? _parseTimeOfDay(String timeStr) {
    // Try HH:mm format first.
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return hour * 60 + minute;
      }
    }

    // Fall back to ISO 8601 parsing.
    final dt = DateTime.tryParse(timeStr);
    if (dt != null) {
      return dt.hour * 60 + dt.minute;
    }

    return null;
  }
}
