import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freecal/features/conflicts/domain/entities/conflict_entity.dart';
import 'package:freecal/features/conflicts/presentation/providers/conflict_provider.dart';
import 'package:freecal/features/events/presentation/providers/event_provider.dart';

/// Displays detected scheduling conflicts and resolution options.
class ConflictScreen extends ConsumerWidget {
  const ConflictScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final conflictState = ref.watch(conflictProvider);
    final eventsAsync = ref.watch(eventsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conflicts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Scan for conflicts',
            onPressed: () {
              final events = eventsAsync.valueOrNull ?? [];
              ref.read(conflictProvider.notifier).detectConflicts(events);
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (conflictState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (conflictState.error != null) {
            return Center(child: Text('Error: ${conflictState.error}'));
          }

          if (conflictState.conflicts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conflicts detected',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the refresh button to scan for conflicts',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: conflictState.conflicts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final conflict = conflictState.conflicts[index];
              return _ConflictCard(conflict: conflict);
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Conflict Card
// ---------------------------------------------------------------------------

class _ConflictCard extends ConsumerWidget {
  const _ConflictCard({required this.conflict});

  final ConflictEntity conflict;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conflict type badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    conflict.type.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Event A
            _EventSummaryRow(
              icon: Icons.event,
              title: conflict.eventA.title,
              start: conflict.eventA.startTime,
              end: conflict.eventA.endTime,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Icon(Icons.swap_vert, size: 16),
            ),
            // Event B
            _EventSummaryRow(
              icon: Icons.event_note,
              title: conflict.eventB.title,
              start: conflict.eventB.startTime,
              end: conflict.eventB.endTime,
            ),
            const SizedBox(height: 16),

            // Resolution actions
            Text(
              'Resolve',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ConflictResolution.values.map((resolution) {
                return ActionChip(
                  label: Text(
                    resolution.label,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  onPressed: () => ref
                      .read(conflictProvider.notifier)
                      .resolve(conflict, resolution),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventSummaryRow extends StatelessWidget {
  const _EventSummaryRow({
    required this.icon,
    required this.title,
    required this.start,
    required this.end,
  });

  final IconData icon;
  final String title;
  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${_fmt(start)} – ${_fmt(end)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
