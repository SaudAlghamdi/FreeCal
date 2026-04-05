import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/mirror_mode.dart';
import '../../../../core/widgets/calendar_color_dot.dart';
import '../../../../core/widgets/mirror_badge.dart';
import '../../../calendars/data/models/calendar_model.dart';
import '../../../calendars/presentation/providers/calendar_notifier.dart';
import '../../../mirror_links/data/models/mirror_link_model.dart';
import '../../../mirror_links/presentation/providers/mirror_link_notifier.dart';
import '../../data/models/event_model.dart';
import '../providers/event_notifier.dart';

/// Displays full details of an event including mirror targets.
class EventDetailsScreen extends ConsumerWidget {
  final EventModel event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarsAsync = ref.watch(calendarNotifierProvider);
    final mirrorLinksAsync = ref.watch(mirrorLinkNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: calendarsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (calendars) {
          final calMap = {for (final c in calendars) c.id: c};
          final sourceCal = calMap[event.sourceCalendarId];

          final mirrorLinks = mirrorLinksAsync.valueOrNull
                  ?.where((l) => l.sourceEventId == event.id)
                  .toList() ??
              [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title
              Text(
                event.title,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              // Time
              _DetailRow(
                icon: Icons.access_time,
                label: _formatDateRange(),
              ),

              // Location
              if (event.location != null && event.location!.isNotEmpty)
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: event.location!,
                ),

              // Notes
              if (event.notes != null && event.notes!.isNotEmpty)
                _DetailRow(
                  icon: Icons.notes,
                  label: event.notes!,
                ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Source Calendar
              Text('Source Calendar', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _CalendarChip(calendar: sourceCal),

              if (event.isMirror) ...[
                const SizedBox(height: 8),
                const MirrorBadge(mode: MirrorMode.full),
              ],

              if (mirrorLinks.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text('Mirror Targets', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ...mirrorLinks.map((link) => _MirrorLinkTile(
                      link: link,
                      calendar: calMap[link.targetCalendarId],
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  String _formatDateRange() {
    final start = DateTime.tryParse(event.startTime);
    final end = DateTime.tryParse(event.endTime);
    if (start == null || end == null) return '${event.startTime} – ${event.endTime}';

    final dateStr = '${_monthName(start.month)} ${start.day}, ${start.year}';
    return '$dateStr  ${_fmtTime(start)} – ${_fmtTime(end)}';
  }

  String _fmtTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(eventNotifierProvider.notifier).deleteEvent(event.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _CalendarChip extends StatelessWidget {
  final CalendarModel? calendar;

  const _CalendarChip({required this.calendar});

  @override
  Widget build(BuildContext context) {
    if (calendar == null) {
      return const Text('Unknown calendar', style: TextStyle(color: Colors.grey));
    }
    return Row(
      children: [
        CalendarColorDot(colorValue: calendar!.color),
        const SizedBox(width: 8),
        Text(calendar!.name, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _MirrorLinkTile extends StatelessWidget {
  final MirrorLinkModel link;
  final CalendarModel? calendar;

  const _MirrorLinkTile({required this.link, required this.calendar});

  @override
  Widget build(BuildContext context) {
    final mode = MirrorMode.fromDbString(link.mirrorMode);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CalendarColorDot(colorValue: calendar?.color ?? 0xFF9E9E9E),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              calendar?.name ?? 'Unknown',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          MirrorBadge(mode: mode),
        ],
      ),
    );
  }
}
