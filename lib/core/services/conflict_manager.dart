import 'package:freecal/features/conflicts/domain/entities/conflict_entity.dart';
import 'package:freecal/features/events/domain/entities/event_entity.dart';
import 'package:freecal/features/events/domain/entities/mirror_link_entity.dart';
import 'package:freecal/features/events/domain/repositories/event_repository.dart';
import 'package:uuid/uuid.dart';

/// Detects and helps resolve scheduling conflicts between events.
class ConflictManager {
  const ConflictManager({required EventRepository eventRepository})
      : _eventRepo = eventRepository;

  final EventRepository _eventRepo;
  static const Uuid _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // Detection
  // ---------------------------------------------------------------------------

  /// Returns all conflicts within the given [events] list.
  List<ConflictEntity> detectConflicts(List<EventEntity> events) {
    final conflicts = <ConflictEntity>[];

    for (int i = 0; i < events.length; i++) {
      for (int j = i + 1; j < events.length; j++) {
        final a = events[i];
        final b = events[j];

        if (!_overlaps(a, b)) continue;

        final type = a.sourceCalendarId == b.sourceCalendarId
            ? ConflictType.sameCalendar
            : ConflictType.crossCalendar;

        conflicts.add(
          ConflictEntity(
            id: _uuid.v4(),
            eventA: a,
            eventB: b,
            type: type,
          ),
        );
      }
    }

    return conflicts;
  }

  /// Checks whether [events] contain any duplicated mirror targets for the
  /// same source event.
  Future<List<ConflictEntity>> detectDuplicateMirrors(
    List<EventEntity> events,
  ) async {
    final conflicts = <ConflictEntity>[];
    final seen = <String>{};

    for (final event in events) {
      final links = await _eventRepo.getMirrorLinksForEvent(event.id);
      for (final link in links) {
        final key = '${event.id}-${link.targetCalendarId}';
        if (seen.contains(key)) {
          // Find the conflicting event (the mirror event in the target)
          final mirrors = await _eventRepo.getEventsByCalendar(
            link.targetCalendarId,
          );
          final mirrorEvents = mirrors.where((e) => e.isMirror).toList();

          if (mirrorEvents.isNotEmpty) {
            conflicts.add(
              ConflictEntity(
                id: _uuid.v4(),
                eventA: event,
                eventB: mirrorEvents.first,
                type: ConflictType.duplicateMirror,
              ),
            );
          }
        } else {
          seen.add(key);
        }
      }
    }

    return conflicts;
  }

  // ---------------------------------------------------------------------------
  // Resolution
  // ---------------------------------------------------------------------------

  /// Applies a [resolution] to a [conflict].
  ///
  /// Returns true if the resolution was successfully applied.
  Future<bool> resolve(
    ConflictEntity conflict,
    ConflictResolution resolution,
  ) async {
    switch (resolution) {
      case ConflictResolution.keepBoth:
        // No action needed
        return true;

      case ConflictResolution.convertToBusy:
        await _convertEventToBusy(conflict.eventB);
        return true;

      case ConflictResolution.reschedule:
        // UI will handle rescheduling; here we just flag it
        return true;

      case ConflictResolution.disableMirroring:
        await _disableMirroringForEvent(conflict.eventA);
        return true;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  bool _overlaps(EventEntity a, EventEntity b) {
    return a.startTime.isBefore(b.endTime) &&
        b.startTime.isBefore(a.endTime);
  }

  Future<void> _convertEventToBusy(EventEntity event) async {
    // Update all mirror links for this event to Busy mode
    final links = await _eventRepo.getMirrorLinksForEvent(event.id);
    for (final link in links) {
      await _eventRepo.updateMirrorLink(
        link.copyWith(mirrorMode: MirrorMode.busy),
      );
    }
  }

  Future<void> _disableMirroringForEvent(EventEntity event) async {
    await _eventRepo.deleteMirrorLinksForEvent(event.id);
  }
}
