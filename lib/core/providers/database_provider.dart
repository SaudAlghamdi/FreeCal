import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../../features/calendars/data/repositories/calendar_repository_impl.dart';
import '../../features/calendars/domain/repositories/calendar_repository.dart';
import '../../features/events/data/repositories/event_repository_impl.dart';
import '../../features/events/domain/repositories/event_repository.dart';
import '../../features/mirror_links/data/repositories/mirror_link_repository_impl.dart';
import '../../features/mirror_links/domain/repositories/mirror_link_repository.dart';
import '../../features/sync_rules/data/repositories/sync_rule_repository_impl.dart';
import '../../features/sync_rules/domain/repositories/sync_rule_repository.dart';
import '../../features/event_target_settings/data/repositories/event_target_setting_repository_impl.dart';
import '../../features/event_target_settings/domain/repositories/event_target_setting_repository.dart';

/// Provides the initialized SQLite database instance.
final databaseProvider = FutureProvider<Database>((ref) async {
  return DatabaseHelper.instance.database;
});

/// Provides the [CalendarRepository] implementation.
final calendarRepositoryProvider =
    FutureProvider<CalendarRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return CalendarRepositoryImpl(db);
});

/// Provides the [EventRepository] implementation.
final eventRepositoryProvider = FutureProvider<EventRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return EventRepositoryImpl(db);
});

/// Provides the [MirrorLinkRepository] implementation.
final mirrorLinkRepositoryProvider =
    FutureProvider<MirrorLinkRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return MirrorLinkRepositoryImpl(db);
});

/// Provides the [SyncRuleRepository] implementation.
final syncRuleRepositoryProvider =
    FutureProvider<SyncRuleRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return SyncRuleRepositoryImpl(db);
});

/// Provides the [EventTargetSettingRepository] implementation.
final eventTargetSettingRepositoryProvider =
    FutureProvider<EventTargetSettingRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return EventTargetSettingRepositoryImpl(db);
});
