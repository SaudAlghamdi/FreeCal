import 'package:uuid/uuid.dart';

import '../../events/data/models/event_model.dart';
import '../../mirror_links/data/models/mirror_link_model.dart';
import 'conflict_model.dart';

/// Detects scheduling conflicts between events.
class ConflictDetector {
  const ConflictDetector();

  /// Detects all conflicts among the given [events].
  ///
  /// Checks for:
  /// 1. Same-calendar overlaps
  /// 2. Cross-calendar overlaps
  /// 3. Duplicate mirror events (same source event mirrored to same calendar)
  List<ConflictModel> detectAll({
    required List<EventModel> events,
    required List<MirrorLinkModel> mirrorLinks,
  }) {
    final conflicts = <ConflictModel>[];

    conflicts.addAll(_detectTimeConflicts(events));
    conflicts.addAll(_detectDuplicateMirrors(events, mirrorLinks));

    return conflicts;
  }

  /// Detects time-based overlaps (same-calendar and cross-calendar).
  List<ConflictModel> _detectTimeConflicts(List<EventModel> events) {
    final conflicts = <ConflictModel>[];

    for (var i = 0; i < events.length; i++) {
      for (var j = i + 1; j < events.length; j++) {
        final a = events[i];
        final b = events[j];

        if (!_timesOverlap(a, b)) continue;

        final type = a.sourceCalendarId == b.sourceCalendarId
            ? ConflictType.sameCalendar
            : ConflictType.crossCalendar;

        conflicts.add(ConflictModel(
          id: const Uuid().v4(),
          eventA: a,
          eventB: b,
          type: type,
        ));
      }
    }

    return conflicts;
  }

  /// Detects duplicate mirror links — multiple mirrors of the same source
  /// event targeting the same calendar.
  List<ConflictModel> _detectDuplicateMirrors(
    List<EventModel> events,
    List<MirrorLinkModel> mirrorLinks,
  ) {
    final conflicts = <ConflictModel>[];
    final eventMap = <String, EventModel>{};
    for (final e in events) {
      eventMap[e.id] = e;
    }

    // Group mirror links by (sourceEventId, targetCalendarId).
    final linkGroups = <String, List<MirrorLinkModel>>{};
    for (final link in mirrorLinks) {
      final key = '${link.sourceEventId}::${link.targetCalendarId}';
      linkGroups.putIfAbsent(key, () => []).add(link);
    }

    for (final group in linkGroups.values) {
      if (group.length <= 1) continue;

      final sourceEvent = eventMap[group.first.sourceEventId];
      if (sourceEvent == null) continue;

      // Create a conflict for each duplicate pair.
      for (var i = 1; i < group.length; i++) {
        // Use the source event for both sides since the mirror links
        // reference the same source — the conflict is in the links, not
        // separate events.
        conflicts.add(ConflictModel(
          id: const Uuid().v4(),
          eventA: sourceEvent,
          eventB: sourceEvent,
          type: ConflictType.duplicateMirror,
        ));
      }
    }

    return conflicts;
  }

  /// Returns true if event [a] and event [b] have overlapping time ranges.
  bool _timesOverlap(EventModel a, EventModel b) {
    final aStart = DateTime.tryParse(a.startTime);
    final aEnd = DateTime.tryParse(a.endTime);
    final bStart = DateTime.tryParse(b.startTime);
    final bEnd = DateTime.tryParse(b.endTime);

    if (aStart == null || aEnd == null || bStart == null || bEnd == null) {
      return false;
    }

    // Two intervals overlap if one starts before the other ends.
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }
}
