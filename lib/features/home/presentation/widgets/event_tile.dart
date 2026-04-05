import 'package:flutter/material.dart';

import '../../../calendars/data/models/calendar_model.dart';
import '../../../events/data/models/event_model.dart';
import '../../../../core/enums/mirror_mode.dart';
import '../../../../core/widgets/calendar_color_dot.dart';
import '../../../../core/widgets/mirror_badge.dart';

/// A single event tile displayed in the home screen timeline.
class EventTile extends StatelessWidget {
  final EventModel event;
  final CalendarModel? calendar;
  final MirrorMode? mirrorMode;
  final VoidCallback? onTap;

  const EventTile({
    super.key,
    required this.event,
    this.calendar,
    this.mirrorMode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final calColor = calendar?.color ?? 0xFF9E9E9E;
    final theme = Theme.of(context);

    final startDt = DateTime.tryParse(event.startTime);
    final endDt = DateTime.tryParse(event.endTime);
    final timeStr = startDt != null && endDt != null
        ? '${_formatTime(startDt)} – ${_formatTime(endDt)}'
        : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Color(calColor).withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Color(calColor), width: 4),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CalendarColorDot(colorValue: calColor, size: 10),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.isMirror ? _maskedTitle : event.title,
                            style: theme.textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (event.location != null && event.location!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.location!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (event.isMirror)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.sync_alt, size: 16, color: Colors.grey),
                ),
              if (mirrorMode != null && mirrorMode != MirrorMode.none) ...[
                const SizedBox(width: 6),
                MirrorBadge(mode: mirrorMode!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _maskedTitle {
    // For mirrored events in busy/OOO mode, hide the real title.
    if (mirrorMode == MirrorMode.busy) return 'Busy';
    if (mirrorMode == MirrorMode.outOfOffice) return 'Out of Office';
    return event.title;
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
