import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/enums/mirror_mode.dart';
import '../../../../core/widgets/calendar_color_dot.dart';
import '../../../calendars/data/models/calendar_model.dart';
import '../../../calendars/presentation/providers/calendar_notifier.dart';
import '../../../event_target_settings/presentation/providers/event_target_setting_notifier.dart';
import '../../../mirror_links/data/models/mirror_link_model.dart';
import '../../../mirror_links/presentation/providers/mirror_link_notifier.dart';
import '../../../sync_engine/domain/sync_engine.dart';
import '../../../sync_engine/domain/sync_engine_provider.dart';
import '../../../sync_rules/presentation/providers/sync_rule_notifier.dart';
import '../providers/event_notifier.dart';
import '../widgets/mirror_control_section.dart';

/// Screen for creating a new event with mirror control options.
class AddEventScreen extends ConsumerStatefulWidget {
  const AddEventScreen({super.key});

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  String? _sourceCalendarId;

  Map<String, MirrorMode> _mirrorSelections = {};
  bool _hideDetails = false;
  bool _applyWorkHoursRule = false;
  bool _saveAsDefault = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calendarsAsync = ref.watch(calendarNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Event'),
        actions: [
          FilledButton(
            onPressed: _isSaving ? null : _saveEvent,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: calendarsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (calendars) {
          // Set default source calendar on first build.
          if (_sourceCalendarId == null && calendars.isNotEmpty) {
            _sourceCalendarId = calendars.first.id;
            _initMirrorSelections(calendars);
          }

          final targetCalendars = calendars
              .where((c) => c.id != _sourceCalendarId)
              .toList();

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --- Basic Info ---
                Text('Event Details', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                // Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(_formatDate(_selectedDate)),
                  subtitle: const Text('Date'),
                  onTap: _pickDate,
                ),

                // Start / End time
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time),
                        title: Text(_startTime.format(context)),
                        subtitle: const Text('Start'),
                        onTap: () => _pickTime(isStart: true),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time_filled),
                        title: Text(_endTime.format(context)),
                        subtitle: const Text('End'),
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Source Calendar picker
                Text('Source Calendar', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _CalendarDropdown(
                  calendars: calendars,
                  selectedId: _sourceCalendarId,
                  onChanged: (id) {
                    setState(() {
                      _sourceCalendarId = id;
                      _initMirrorSelections(calendars);
                    });
                  },
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),

                // --- Mirror Control Section ---
                MirrorControlSection(
                  targetCalendars: targetCalendars,
                  selections: _mirrorSelections,
                  onChanged: (updated) {
                    setState(() => _mirrorSelections = updated);
                  },
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // --- Options ---
                Text('Options', style: theme.textTheme.titleMedium),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hide details in mirrors'),
                  subtitle: const Text('Title, notes, location hidden'),
                  value: _hideDetails,
                  onChanged: (v) => setState(() => _hideDetails = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Apply work-hours rule'),
                  subtitle: const Text('Only mirror during time window'),
                  value: _applyWorkHoursRule,
                  onChanged: (v) => setState(() => _applyWorkHoursRule = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Save as default rule'),
                  subtitle: const Text('Apply these mirror settings to future events'),
                  value: _saveAsDefault,
                  onChanged: (v) => setState(() => _saveAsDefault = v),
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  void _initMirrorSelections(List<CalendarModel> calendars) {
    _mirrorSelections = {
      for (final c in calendars)
        if (c.id != _sourceCalendarId) c.id: MirrorMode.none,
    };
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sourceCalendarId == null) return;

    setState(() => _isSaving = true);

    try {
      final startDt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final endDt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      // 1. Create the source event.
      final event = await ref.read(eventNotifierProvider.notifier).addEvent(
            title: _titleController.text.trim(),
            startTime: startDt.toIso8601String(),
            endTime: endDt.toIso8601String(),
            sourceCalendarId: _sourceCalendarId!,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            location: _locationController.text.trim().isEmpty
                ? null
                : _locationController.text.trim(),
          );

      // 2. Create mirror links for non-none selections.
      final linksToCreate = <MirrorLinkModel>[];
      for (final entry in _mirrorSelections.entries) {
        if (entry.value == MirrorMode.none) continue;

        final effectiveMode = _hideDetails && entry.value == MirrorMode.full
            ? MirrorMode.busy
            : entry.value;

        linksToCreate.add(MirrorLinkModel(
          id: const Uuid().v4(),
          sourceEventId: event.id,
          targetCalendarId: entry.key,
          mirrorMode: effectiveMode.toDbString(),
        ));
      }

      if (linksToCreate.isNotEmpty) {
        await ref.read(mirrorLinkNotifierProvider.notifier).addLinks(linksToCreate);
      }

      // 3. Save per-event overrides.
      for (final entry in _mirrorSelections.entries) {
        if (entry.value == MirrorMode.none) continue;
        await ref.read(eventTargetSettingNotifierProvider.notifier).addSetting(
              eventId: event.id,
              targetCalendarId: entry.key,
              mode: entry.value.toDbString(),
              overrideRule: true,
            );
      }

      // 4. If "save as default", persist as sync rules.
      if (_saveAsDefault) {
        for (final entry in _mirrorSelections.entries) {
          if (entry.value == MirrorMode.none) continue;
          await ref.read(syncRuleNotifierProvider.notifier).addRule(
                sourceCalendarId: _sourceCalendarId!,
                targetCalendarId: entry.key,
                mode: entry.value.toDbString(),
              );
        }
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _CalendarDropdown extends StatelessWidget {
  final List<CalendarModel> calendars;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _CalendarDropdown({
    required this.calendars,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedId,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.calendar_month),
      ),
      items: calendars.map((cal) {
        return DropdownMenuItem<String>(
          value: cal.id,
          child: Row(
            children: [
              CalendarColorDot(colorValue: cal.color),
              const SizedBox(width: 8),
              Text(cal.name),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
