/// Controls how a source event appears in a target calendar.
enum MirrorMode {
  full,
  busy,
  outOfOffice,
  none;

  String get label {
    switch (this) {
      case MirrorMode.full:
        return 'Full Event';
      case MirrorMode.busy:
        return 'Busy';
      case MirrorMode.outOfOffice:
        return 'Out of Office';
      case MirrorMode.none:
        return 'Do Not Show';
    }
  }

  String get shortLabel {
    switch (this) {
      case MirrorMode.full:
        return 'Full';
      case MirrorMode.busy:
        return 'Busy';
      case MirrorMode.outOfOffice:
        return 'OOO';
      case MirrorMode.none:
        return 'None';
    }
  }

  bool get isPrivate => this == MirrorMode.busy || this == MirrorMode.outOfOffice;
}

/// Links a source event to a target calendar with a specific mirror mode.
class MirrorLinkEntity {
  const MirrorLinkEntity({
    required this.id,
    required this.sourceEventId,
    required this.targetCalendarId,
    required this.mirrorMode,
  });

  final String id;
  final String sourceEventId;
  final String targetCalendarId;
  final MirrorMode mirrorMode;

  MirrorLinkEntity copyWith({
    String? id,
    String? sourceEventId,
    String? targetCalendarId,
    MirrorMode? mirrorMode,
  }) {
    return MirrorLinkEntity(
      id: id ?? this.id,
      sourceEventId: sourceEventId ?? this.sourceEventId,
      targetCalendarId: targetCalendarId ?? this.targetCalendarId,
      mirrorMode: mirrorMode ?? this.mirrorMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MirrorLinkEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'MirrorLinkEntity(sourceEventId: $sourceEventId, '
      'targetCalendarId: $targetCalendarId, mode: $mirrorMode)';
}
