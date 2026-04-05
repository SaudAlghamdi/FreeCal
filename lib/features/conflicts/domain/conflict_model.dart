import '../../events/data/models/event_model.dart';

/// The type of scheduling conflict detected.
enum ConflictType {
  /// Two events overlap within the same calendar.
  sameCalendar,

  /// Two events overlap across different calendars.
  crossCalendar,

  /// A mirrored event duplicates an existing event in the target calendar.
  duplicateMirror,
}

/// Actions the user can take to resolve a conflict.
enum ConflictResolution {
  keepBoth,
  convertToBusy,
  reschedule,
  disableMirroring,
}

/// Represents a detected scheduling conflict between two events.
class ConflictModel {
  final String id;
  final EventModel eventA;
  final EventModel eventB;
  final ConflictType type;
  final ConflictResolution? resolution;

  const ConflictModel({
    required this.id,
    required this.eventA,
    required this.eventB,
    required this.type,
    this.resolution,
  });

  ConflictModel copyWith({
    String? id,
    EventModel? eventA,
    EventModel? eventB,
    ConflictType? type,
    ConflictResolution? resolution,
  }) {
    return ConflictModel(
      id: id ?? this.id,
      eventA: eventA ?? this.eventA,
      eventB: eventB ?? this.eventB,
      type: type ?? this.type,
      resolution: resolution ?? this.resolution,
    );
  }
}
