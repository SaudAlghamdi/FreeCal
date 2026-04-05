/// Represents a link between a source event and a target calendar with a mirror mode.
///
/// Mirror modes: 'full', 'busy', 'out_of_office', 'none'.
class MirrorLinkModel {
  final String id;
  final String sourceEventId;
  final String targetCalendarId;
  final String mirrorMode;

  const MirrorLinkModel({
    required this.id,
    required this.sourceEventId,
    required this.targetCalendarId,
    required this.mirrorMode,
  });

  factory MirrorLinkModel.fromMap(Map<String, dynamic> map) {
    return MirrorLinkModel(
      id: map['id'] as String,
      sourceEventId: map['sourceEventId'] as String,
      targetCalendarId: map['targetCalendarId'] as String,
      mirrorMode: map['mirrorMode'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceEventId': sourceEventId,
      'targetCalendarId': targetCalendarId,
      'mirrorMode': mirrorMode,
    };
  }

  MirrorLinkModel copyWith({
    String? id,
    String? sourceEventId,
    String? targetCalendarId,
    String? mirrorMode,
  }) {
    return MirrorLinkModel(
      id: id ?? this.id,
      sourceEventId: sourceEventId ?? this.sourceEventId,
      targetCalendarId: targetCalendarId ?? this.targetCalendarId,
      mirrorMode: mirrorMode ?? this.mirrorMode,
    );
  }
}
