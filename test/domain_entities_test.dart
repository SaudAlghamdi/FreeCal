import 'package:flutter_test/flutter_test.dart';
import 'package:freecal/features/events/domain/entities/event_entity.dart';
import 'package:freecal/features/events/domain/entities/event_target_settings_entity.dart';
import 'package:freecal/features/events/domain/entities/mirror_link_entity.dart';
import 'package:freecal/features/rules/domain/entities/sync_rule_entity.dart';
import 'package:freecal/features/conflicts/domain/entities/conflict_entity.dart';

void main() {
  // ---------------------------------------------------------------------------
  // EventEntity
  // ---------------------------------------------------------------------------
  group('EventEntity', () {
    final start = DateTime(2024, 6, 15, 9, 0);
    final end = DateTime(2024, 6, 15, 10, 0);

    test('creates with required fields', () {
      final event = EventEntity(
        id: 'evt-1',
        title: 'Doctor Appointment',
        startTime: start,
        endTime: end,
        sourceCalendarId: 'cal-personal',
      );
      expect(event.id, 'evt-1');
      expect(event.title, 'Doctor Appointment');
      expect(event.isMirror, isFalse);
      expect(event.isAllDay, isFalse);
    });

    test('duration is correct', () {
      final event = EventEntity(
        id: 'evt-1',
        title: 'Test',
        startTime: start,
        endTime: end,
        sourceCalendarId: 'cal-personal',
      );
      expect(event.duration, const Duration(hours: 1));
    });

    test('copyWith updates fields', () {
      final event = EventEntity(
        id: 'evt-1',
        title: 'Original',
        startTime: start,
        endTime: end,
        sourceCalendarId: 'cal-personal',
      );
      final updated = event.copyWith(title: 'Updated');
      expect(updated.title, 'Updated');
      expect(updated.id, 'evt-1');
    });

    test('equality is based on id', () {
      final a = EventEntity(
        id: 'evt-1',
        title: 'A',
        startTime: start,
        endTime: end,
        sourceCalendarId: 'cal-1',
      );
      final b = EventEntity(
        id: 'evt-1',
        title: 'B',
        startTime: start,
        endTime: end,
        sourceCalendarId: 'cal-2',
      );
      expect(a, equals(b));
    });
  });

  // ---------------------------------------------------------------------------
  // MirrorMode
  // ---------------------------------------------------------------------------
  group('MirrorMode', () {
    test('isPrivate returns true for busy and outOfOffice', () {
      expect(MirrorMode.busy.isPrivate, isTrue);
      expect(MirrorMode.outOfOffice.isPrivate, isTrue);
      expect(MirrorMode.full.isPrivate, isFalse);
      expect(MirrorMode.none.isPrivate, isFalse);
    });

    test('labels are non-empty', () {
      for (final mode in MirrorMode.values) {
        expect(mode.label, isNotEmpty);
        expect(mode.shortLabel, isNotEmpty);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // SyncRuleEntity
  // ---------------------------------------------------------------------------
  group('SyncRuleEntity', () {
    test('isHourInWindow returns correct results', () {
      final rule = SyncRuleEntity(
        id: 'rule-1',
        sourceCalendarId: 'cal-personal',
        targetCalendarId: 'cal-work',
        mode: MirrorMode.busy,
        timeWindowStart: 6,
        timeWindowEnd: 18,
      );

      expect(rule.isHourInWindow(6), isTrue);
      expect(rule.isHourInWindow(9), isTrue);
      expect(rule.isHourInWindow(17), isTrue);
      expect(rule.isHourInWindow(18), isFalse);
      expect(rule.isHourInWindow(20), isFalse);
      expect(rule.isHourInWindow(5), isFalse);
    });

    test('isInTimeWindow uses startTime hour', () {
      final rule = SyncRuleEntity(
        id: 'rule-1',
        sourceCalendarId: 'cal-personal',
        targetCalendarId: 'cal-work',
        mode: MirrorMode.busy,
        timeWindowStart: 6,
        timeWindowEnd: 18,
      );

      final morning = DateTime(2024, 6, 15, 9, 0);
      final evening = DateTime(2024, 6, 15, 20, 0);

      expect(rule.isInTimeWindow(morning), isTrue);
      expect(rule.isInTimeWindow(evening), isFalse);
    });

    test('hasTimeWindow returns false when window not set', () {
      final rule = SyncRuleEntity(
        id: 'rule-1',
        sourceCalendarId: 'cal-personal',
        targetCalendarId: 'cal-work',
        mode: MirrorMode.busy,
      );
      expect(rule.hasTimeWindow, isFalse);
      // When no window, isInTimeWindow always returns true
      expect(rule.isInTimeWindow(DateTime(2024, 6, 15, 23, 59)), isTrue);
    });

    test('copyWith updates isActive', () {
      final rule = SyncRuleEntity(
        id: 'rule-1',
        sourceCalendarId: 'cal-personal',
        targetCalendarId: 'cal-work',
        mode: MirrorMode.busy,
      );
      final disabled = rule.copyWith(isActive: false);
      expect(disabled.isActive, isFalse);
      expect(disabled.id, 'rule-1');
    });
  });

  // ---------------------------------------------------------------------------
  // ConflictType
  // ---------------------------------------------------------------------------
  group('ConflictType', () {
    test('all types have labels', () {
      for (final type in ConflictType.values) {
        expect(type.label, isNotEmpty);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // ConflictResolution
  // ---------------------------------------------------------------------------
  group('ConflictResolution', () {
    test('all resolutions have labels', () {
      for (final res in ConflictResolution.values) {
        expect(res.label, isNotEmpty);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // EventTargetSettingsEntity
  // ---------------------------------------------------------------------------
  group('EventTargetSettingsEntity', () {
    test('creates with defaults', () {
      final settings = EventTargetSettingsEntity(
        id: 's-1',
        eventId: 'evt-1',
        targetCalendarId: 'cal-work',
        mode: MirrorMode.busy,
      );
      expect(settings.overrideRule, isFalse);
      expect(settings.hideDetails, isFalse);
      expect(settings.applyWorkHoursRule, isFalse);
    });

    test('copyWith updates fields', () {
      final settings = EventTargetSettingsEntity(
        id: 's-1',
        eventId: 'evt-1',
        targetCalendarId: 'cal-work',
        mode: MirrorMode.busy,
      );
      final updated = settings.copyWith(
        mode: MirrorMode.full,
        overrideRule: true,
      );
      expect(updated.mode, MirrorMode.full);
      expect(updated.overrideRule, isTrue);
      expect(updated.id, 's-1');
    });
  });

  // ---------------------------------------------------------------------------
  // MirrorLinkEntity
  // ---------------------------------------------------------------------------
  group('MirrorLinkEntity', () {
    test('creates correctly', () {
      final link = MirrorLinkEntity(
        id: 'link-1',
        sourceEventId: 'evt-1',
        targetCalendarId: 'cal-work',
        mirrorMode: MirrorMode.busy,
      );
      expect(link.mirrorMode, MirrorMode.busy);
      expect(link.mirrorMode.isPrivate, isTrue);
    });

    test('copyWith updates mirrorMode', () {
      final link = MirrorLinkEntity(
        id: 'link-1',
        sourceEventId: 'evt-1',
        targetCalendarId: 'cal-work',
        mirrorMode: MirrorMode.busy,
      );
      final updated = link.copyWith(mirrorMode: MirrorMode.outOfOffice);
      expect(updated.mirrorMode, MirrorMode.outOfOffice);
    });
  });
}
