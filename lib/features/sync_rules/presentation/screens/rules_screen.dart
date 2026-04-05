import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/mirror_mode.dart';
import '../../../../core/widgets/calendar_color_dot.dart';
import '../../../calendars/data/models/calendar_model.dart';
import '../../../calendars/presentation/providers/calendar_notifier.dart';
import '../../data/models/sync_rule_model.dart';
import '../providers/sync_rule_notifier.dart';

/// Displays and manages default sync rules between calendars.
class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(syncRuleNotifierProvider);
    final calendarsAsync = ref.watch(calendarNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sync Rules')),
      body: calendarsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (calendars) {
          final calMap = {for (final c in calendars) c.id: c};

          return rulesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (rules) {
              if (rules.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rule, size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text('No sync rules yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )),
                      const SizedBox(height: 8),
                      Text('Tap + to create a default rule',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: rules.length,
                itemBuilder: (context, index) {
                  final rule = rules[index];
                  return _RuleTile(
                    rule: rule,
                    sourceCal: calMap[rule.sourceCalendarId],
                    targetCal: calMap[rule.targetCalendarId],
                    onEdit: () => _showEditDialog(
                        context, ref, calendars, rule),
                    onDelete: () => _confirmDelete(context, ref, rule),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addRule',
        onPressed: () {
          final calendars = ref.read(calendarNotifierProvider).valueOrNull ?? [];
          if (calendars.length < 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Need at least 2 calendars to create a rule')),
            );
            return;
          }
          _showAddDialog(context, ref, calendars);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(
    BuildContext context,
    WidgetRef ref,
    List<CalendarModel> calendars,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _RuleDialog(calendars: calendars),
    ).then((result) {
      if (result != null) {
        ref.read(syncRuleNotifierProvider.notifier).addRule(
              sourceCalendarId: result['sourceCalendarId'] as String,
              targetCalendarId: result['targetCalendarId'] as String,
              mode: result['mode'] as String,
              timeWindowStart: result['timeWindowStart'] as String?,
              timeWindowEnd: result['timeWindowEnd'] as String?,
            );
      }
    });
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    List<CalendarModel> calendars,
    SyncRuleModel rule,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _RuleDialog(calendars: calendars, existingRule: rule),
    ).then((result) {
      if (result != null) {
        ref.read(syncRuleNotifierProvider.notifier).updateRule(
              rule.copyWith(
                sourceCalendarId: result['sourceCalendarId'] as String,
                targetCalendarId: result['targetCalendarId'] as String,
                mode: result['mode'] as String,
                timeWindowStart: result['timeWindowStart'] as String?,
                timeWindowEnd: result['timeWindowEnd'] as String?,
              ),
            );
      }
    });
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SyncRuleModel rule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Rule'),
        content: const Text('Remove this sync rule?'),
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
    if (confirmed == true) {
      ref.read(syncRuleNotifierProvider.notifier).deleteRule(rule.id);
    }
  }
}

// ---------------------------------------------------------------------------
// Rule Tile
// ---------------------------------------------------------------------------

class _RuleTile extends StatelessWidget {
  final SyncRuleModel rule;
  final CalendarModel? sourceCal;
  final CalendarModel? targetCal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RuleTile({
    required this.rule,
    required this.sourceCal,
    required this.targetCal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final mode = MirrorMode.fromDbString(rule.mode);
    final theme = Theme.of(context);

    final hasWindow = rule.timeWindowStart != null && rule.timeWindowEnd != null;
    final windowLabel = hasWindow
        ? '${rule.timeWindowStart} – ${rule.timeWindowEnd}'
        : 'All day';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source → Target
              Row(
                children: [
                  CalendarColorDot(
                      colorValue: sourceCal?.color ?? 0xFF9E9E9E),
                  const SizedBox(width: 6),
                  Text(sourceCal?.name ?? 'Unknown',
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  CalendarColorDot(
                      colorValue: targetCal?.color ?? 0xFF9E9E9E),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(targetCal?.name ?? 'Unknown',
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Mode + time window
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(mode.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        )),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.schedule, size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(windowLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add / Edit Rule Dialog
// ---------------------------------------------------------------------------

class _RuleDialog extends StatefulWidget {
  final List<CalendarModel> calendars;
  final SyncRuleModel? existingRule;

  const _RuleDialog({required this.calendars, this.existingRule});

  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  late String _sourceId;
  late String _targetId;
  late MirrorMode _mode;
  bool _useTimeWindow = false;
  TimeOfDay _windowStart = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _windowEnd = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    final rule = widget.existingRule;
    if (rule != null) {
      _sourceId = rule.sourceCalendarId;
      _targetId = rule.targetCalendarId;
      _mode = MirrorMode.fromDbString(rule.mode);
      _useTimeWindow =
          rule.timeWindowStart != null && rule.timeWindowEnd != null;
      if (_useTimeWindow) {
        _windowStart = _parseTime(rule.timeWindowStart!) ??
            const TimeOfDay(hour: 6, minute: 0);
        _windowEnd = _parseTime(rule.timeWindowEnd!) ??
            const TimeOfDay(hour: 18, minute: 0);
      }
    } else {
      _sourceId = widget.calendars.first.id;
      _targetId = widget.calendars.length > 1
          ? widget.calendars[1].id
          : widget.calendars.first.id;
      _mode = MirrorMode.busy;
    }
  }

  TimeOfDay? _parseTime(String s) {
    final parts = s.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) return TimeOfDay(hour: h, minute: m);
    }
    return null;
  }

  String _timeToString(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingRule != null;
    final cals = widget.calendars;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Rule' : 'Add Rule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source calendar
            const Text('From'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _sourceId,
              isExpanded: true,
              items: cals.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Row(children: [
                      CalendarColorDot(colorValue: c.color, size: 10),
                      const SizedBox(width: 6),
                      Expanded(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                    ]),
                  )).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _sourceId = v);
              },
            ),
            const SizedBox(height: 12),

            // Target calendar
            const Text('To'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _targetId,
              isExpanded: true,
              items: cals.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Row(children: [
                      CalendarColorDot(colorValue: c.color, size: 10),
                      const SizedBox(width: 6),
                      Expanded(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                    ]),
                  )).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _targetId = v);
              },
            ),
            const SizedBox(height: 12),

            // Mode
            const Text('Mirror Mode'),
            const SizedBox(height: 4),
            SegmentedButton<MirrorMode>(
              segments: [MirrorMode.full, MirrorMode.busy, MirrorMode.outOfOffice]
                  .map((m) => ButtonSegment(
                        value: m,
                        label: Text(m.label, style: const TextStyle(fontSize: 11)),
                      ))
                  .toList(),
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 4)),
              ),
            ),
            const SizedBox(height: 12),

            // Time window
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Time Window'),
              subtitle: const Text('Only sync during specific hours'),
              value: _useTimeWindow,
              onChanged: (v) => setState(() => _useTimeWindow = v),
            ),
            if (_useTimeWindow) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(_windowStart.format(context)),
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _windowStart,
                        );
                        if (t != null) setState(() => _windowStart = t);
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('–'),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(_windowEnd.format(context)),
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _windowEnd,
                        );
                        if (t != null) setState(() => _windowEnd = t);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_sourceId == _targetId) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Source and target must be different')),
              );
              return;
            }
            Navigator.pop(context, {
              'sourceCalendarId': _sourceId,
              'targetCalendarId': _targetId,
              'mode': _mode.toDbString(),
              'timeWindowStart':
                  _useTimeWindow ? _timeToString(_windowStart) : null,
              'timeWindowEnd':
                  _useTimeWindow ? _timeToString(_windowEnd) : null,
            });
          },
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
