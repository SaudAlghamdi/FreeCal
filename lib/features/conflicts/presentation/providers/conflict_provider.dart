import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freecal/core/services/conflict_manager.dart';
import 'package:freecal/core/services/sync_engine.dart';
import 'package:freecal/features/conflicts/domain/entities/conflict_entity.dart';
import 'package:freecal/features/events/domain/entities/event_entity.dart';
import 'package:freecal/features/events/presentation/providers/event_provider.dart';
import 'package:freecal/features/rules/presentation/providers/rules_provider.dart';

// ---------------------------------------------------------------------------
// Provider: SyncEngine
// ---------------------------------------------------------------------------

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    eventRepository: ref.watch(eventRepositoryProvider),
    ruleRepository: ref.watch(syncRuleRepositoryProvider),
  );
});

// ---------------------------------------------------------------------------
// Provider: ConflictManager
// ---------------------------------------------------------------------------

final conflictManagerProvider = Provider<ConflictManager>((ref) {
  return ConflictManager(
    eventRepository: ref.watch(eventRepositoryProvider),
  );
});

// ---------------------------------------------------------------------------
// StateNotifier: Conflict detection state
// ---------------------------------------------------------------------------

class ConflictState {
  const ConflictState({
    this.conflicts = const [],
    this.isLoading = false,
    this.error,
  });

  final List<ConflictEntity> conflicts;
  final bool isLoading;
  final String? error;

  ConflictState copyWith({
    List<ConflictEntity>? conflicts,
    bool? isLoading,
    String? error,
  }) {
    return ConflictState(
      conflicts: conflicts ?? this.conflicts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ConflictNotifier extends StateNotifier<ConflictState> {
  ConflictNotifier(this._manager) : super(const ConflictState());

  final ConflictManager _manager;

  Future<void> detectConflicts(
    List<EventEntity> events,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final detected = _manager.detectConflicts(events);
      state = state.copyWith(conflicts: detected, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> resolve(
    ConflictEntity conflict,
    ConflictResolution resolution,
  ) async {
    await _manager.resolve(conflict, resolution);
    final updated = state.conflicts
        .where((c) => c.id != conflict.id)
        .toList();
    state = state.copyWith(conflicts: updated);
  }

  void clear() {
    state = const ConflictState();
  }
}

final conflictProvider =
    StateNotifierProvider<ConflictNotifier, ConflictState>((ref) {
  return ConflictNotifier(ref.watch(conflictManagerProvider));
});
