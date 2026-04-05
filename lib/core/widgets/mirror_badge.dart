import 'package:flutter/material.dart';

import '../../core/enums/mirror_mode.dart';

/// A small badge indicating the mirror mode of an event.
class MirrorBadge extends StatelessWidget {
  final MirrorMode mode;

  const MirrorBadge({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    if (mode == MirrorMode.none) return const SizedBox.shrink();

    final (IconData icon, Color color, String tooltip) = switch (mode) {
      MirrorMode.full => (Icons.copy_all, Colors.blue, 'Full Mirror'),
      MirrorMode.busy => (Icons.block, Colors.orange, 'Busy'),
      MirrorMode.outOfOffice => (Icons.do_not_disturb, Colors.red, 'Out of Office'),
      MirrorMode.none => (Icons.visibility_off, Colors.grey, 'Hidden'),
    };

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 3),
            Text(
              mode.label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
