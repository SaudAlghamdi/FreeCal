import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/calendar_color_dot.dart';
import '../../../calendars/data/models/calendar_model.dart';
import '../../../calendars/presentation/providers/calendar_notifier.dart';
import '../../../events/presentation/providers/event_notifier.dart';
import '../../../mirror_links/presentation/providers/mirror_link_notifier.dart';
import '../../domain/conflict_model.dart';
import '../providers/conflict_provider.dart';

/// Displays detected scheduling conflicts with resolution options.
class ConflictScreen extends ConsumerWidget {
  const ConflictScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflictsAsync = ref.watch(conflictsProvider);
    final calendarsAsync = ref.watch(calendarNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Conflicts')),
      body: calendarsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (calendars) {
          final calMap = {for (final c in calendars) c.id: c};

          return conflictsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (conflicts) {
              if (conflicts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 48,
                          color: Colors.green.withOpacity(0.6)),
                      const SizedBox(height: 12),
                      Text('No conflicts detected',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                itemCount: conflicts.length,
                itemBuilder: (context, index) {
                  final conflict = conflicts[index];
                  return _ConflictTile(
                    conflict: conflict,
                    calMap: calMap,
                    onResolve: (resolution) =>
                        _resolveConflict(context, ref, conflict, resolution),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _resolveConflict(
    BuildContext context,
    WidgetRef ref,
    ConflictModel conflict,
    ConflictResolution resolution,
  ) async {
    switch (resolution) {
      case ConflictResolution.keepBoth:
        // No action needed — user accepts both events.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keeping both events')),
        );
        break;

      case ConflictResolution.convertToBusy:
        // Convert eventB to a busy mirror — delete it and create a mirror link.
        await ref
            .read(eventNotifierProvider.notifier)
            .updateEvent(conflict.eventB.copyWith(
              title: 'Busy',
              isMirror: true,
              notes: null,
              location: null,
            ));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Converted to Busy')),
          );
        }
        break;

      case ConflictResolution.reschedule:
        // Show a time picker to reschedule eventB.
        if (!context.mounted) return;
        final newTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
          helpText: 'Pick new start time for "${conflict.eventB.title}"',
        );
        if (newTime != null) {
          final oldStart = DateTime.tryParse(conflict.eventB.startTime);
          final oldEnd = DateTime.tryParse(conflict.eventB.endTime);
          if (oldStart != null && oldEnd != null) {
            final duration = oldEnd.difference(oldStart);
            final newStart = DateTime(
              oldStart.year, oldStart.month, oldStart.day,
              newTime.hour, newTime.minute,
            );
            final newEnd = newStart.add(duration);
            await ref.read(eventNotifierProvider.notifier).updateEvent(
                  conflict.eventB.copyWith(
                    startTime: newStart.toIso8601String(),
                    endTime: newEnd.toIso8601String(),
                  ),
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event rescheduled')),
              );
            }
          }
        }
        break;

      case ConflictResolution.disableMirroring:
        // Remove mirror links for eventB.
        await ref
            .read(mirrorLinkNotifierProvider.notifier)
            .deleteLinksForEvent(conflict.eventB.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mirroring disabled for event')),
          );
        }
        break;
    }
  }
}

// ---------------------------------------------------------------------------
// Conflict Tile
// ---------------------------------------------------------------------------

class _ConflictTile extends StatelessWidget {
  final ConflictModel conflict;
  final Map<String, CalendarModel> calMap;
  final void Function(ConflictResolution) onResolve;

  const _ConflictTile({
    required this.conflict,
    required this.calMap,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calA = calMap[conflict.eventA.sourceCalendarId];
    final calB = calMap[conflict.eventB.sourceCalendarId];

    final (String label, IconData icon, Color color) = switch (conflict.type) {
      ConflictType.sameCalendar => (
          'Same Calendar Overlap',
          Icons.warning_amber,
          Colors.orange,
        ),
      ConflictType.crossCalendar => (
          'Cross-Calendar Overlap',
          Icons.compare_arrows,
          Colors.blue,
        ),
      ConflictType.duplicateMirror => (
          'Duplicate Mirror',
          Icons.copy_all,
          Colors.red,
        ),
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conflict type badge
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(label,
                    style: theme.textTheme.labelLarge?.copyWith(color: color)),
              ],
            ),
            const SizedBox(height: 10),

            // Event A
            _EventRow(
              event: conflict.eventA,
              calendar: calA,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 16),
                  Icon(Icons.compare_arrows, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('overlaps with',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

            // Event B
            _EventRow(
              event: conflict.eventB,
              calendar: calB,
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Resolution actions
            Text('Resolve:', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _ResolutionChip(
                  label: 'Keep Both',
                  icon: Icons.done_all,
                  onTap: () => onResolve(ConflictResolution.keepBoth),
                ),
                _ResolutionChip(
                  label: 'Convert to Busy',
                  icon: Icons.block,
                  onTap: () => onResolve(ConflictResolution.convertToBusy),
                ),
                _ResolutionChip(
                  label: 'Reschedule',
                  icon: Icons.schedule,
                  onTap: () => onResolve(ConflictResolution.reschedule),
                ),
                if (conflict.eventB.isMirror ||
                    conflict.type == ConflictType.duplicateMirror)
                  _ResolutionChip(
                    label: 'Disable Mirror',
                    icon: Icons.sync_disabled,
                    onTap: () =>
                        onResolve(ConflictResolution.disableMirroring),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final dynamic event; // EventModel
  final CalendarModel? calendar;

  const _EventRow({required this.event, required this.calendar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startDt = DateTime.tryParse(event.startTime as String);
    final endDt = DateTime.tryParse(event.endTime as String);
    final timeStr = startDt != null && endDt != null
        ? '${_fmtTime(startDt)} – ${_fmtTime(endDt)}'
        : '';

    return Row(
      children: [
        CalendarColorDot(colorValue: calendar?.color ?? 0xFF9E9E9E, size: 10),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.title as String,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis),
              Text(timeStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
            ],
          ),
        ),
        if (event.isMirror as bool)
          const Icon(Icons.sync_alt, size: 14, color: Colors.grey),
      ],
    );
  }

  String _fmtTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

class _ResolutionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ResolutionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}
