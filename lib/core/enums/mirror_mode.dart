/// Defines how an event appears in a target calendar.
enum MirrorMode {
  full,
  busy,
  outOfOffice,
  none;

  /// Converts to the string stored in the database.
  String toDbString() {
    switch (this) {
      case MirrorMode.full:
        return 'full';
      case MirrorMode.busy:
        return 'busy';
      case MirrorMode.outOfOffice:
        return 'out_of_office';
      case MirrorMode.none:
        return 'none';
    }
  }

  /// Parses a database string into a [MirrorMode].
  static MirrorMode fromDbString(String value) {
    switch (value) {
      case 'full':
        return MirrorMode.full;
      case 'busy':
        return MirrorMode.busy;
      case 'out_of_office':
        return MirrorMode.outOfOffice;
      case 'none':
        return MirrorMode.none;
      default:
        return MirrorMode.none;
    }
  }

  /// Human-readable label for UI display.
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
}
