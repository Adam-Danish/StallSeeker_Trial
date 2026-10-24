import 'package:flutter/material.dart';
import '../../../core/models/stall_schedule.dart';

class StallScheduleEditor extends StatelessWidget {
  const StallScheduleEditor(
      {super.key,
      required this.hours,
      required this.closures,
      required this.onChanged,
      this.showHours = true,
      this.showClosures = true,
      this.showSectionTitles = true});

  final Map<int, List<StallHoursInterval>> hours;
  final List<TemporaryClosure> closures;
  final bool showHours;
  final bool showClosures;
  final bool showSectionTitles;
  final void Function(
      Map<int, List<StallHoursInterval>>, List<TemporaryClosure>) onChanged;

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  Map<int, List<StallHoursInterval>> _copyHours() => {
        for (var day = 1; day <= 7; day++) day: [...?hours[day]],
      };

  Future<void> _pickTime(BuildContext context, int day, int index,
      {required bool opening}) async {
    final interval = hours[day]![index];
    final current = opening ? interval.openMinute : interval.closeMinute;
    final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60));
    if (picked == null || !context.mounted) return;
    final minutes = picked.hour * 60 + picked.minute;
    if (minutes == (opening ? interval.closeMinute : interval.openMinute)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Opening and closing times must be different.')));
      return;
    }
    final next = _copyHours();
    next[day]![index] = StallHoursInterval(
      opening ? minutes : interval.openMinute,
      opening ? interval.closeMinute : minutes,
    );
    onChanged(next, closures);
  }

  Future<DateTime?> _pickDateTime(
      BuildContext context, DateTime initial) async {
    final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 730)));
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return null;
    // The stall operates in Malaysia time, independently of device timezone.
    return DateTime.utc(
        date.year, date.month, date.day, time.hour - 8, time.minute);
  }

  Future<void> _addClosure(BuildContext context) async {
    if (closures.length >= 20) return;
    final nowMy = DateTime.now().toUtc().add(const Duration(hours: 8));
    final start = await _pickDateTime(context, nowMy);
    if (start == null || !context.mounted) return;
    final end = await _pickDateTime(
        context, start.toUtc().add(const Duration(hours: 18)));
    if (end == null || !context.mounted) return;
    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Closure end must be after its start.')));
      return;
    }
    onChanged(
        hours,
        [...closures, TemporaryClosure(start, end)]
          ..sort((a, b) => a.start.compareTo(b.start)));
  }

  String _formatClosure(DateTime value) {
    final my = value.toUtc().add(const Duration(hours: 8));
    return '${my.day}/${my.month}/${my.year} ${formatStallTime(my.hour * 60 + my.minute)}';
  }

  Widget _timeInterval(BuildContext context, int day, int index) {
    final interval = hours[day]![index];
    final opens = OutlinedButton(
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
        onPressed: () => _pickTime(context, day, index, opening: true),
        child: Text('Opens ${formatStallTime(interval.openMinute)}',
            textAlign: TextAlign.center));
    final closes = OutlinedButton(
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
        onPressed: () => _pickTime(context, day, index, opening: false),
        child: Text('Closes ${formatStallTime(interval.closeMinute)}',
            textAlign: TextAlign.center));
    final remove = IconButton(
        tooltip: 'Remove time',
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: const Icon(Icons.close),
        onPressed: () {
          final next = _copyHours();
          next[day]!.removeAt(index);
          onChanged(next, closures);
        });
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 400 ||
              MediaQuery.textScalerOf(context).scale(14) > 19) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  opens,
                  const SizedBox(height: 8),
                  closes,
                  Align(alignment: Alignment.centerRight, child: remove),
                ]);
          }
          return Row(children: [
            Expanded(child: opens),
            const SizedBox(width: 8),
            Expanded(child: closes),
            remove
          ]);
        }));
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHours) ...[
            if (showSectionTitles) ...[
              Text('Weekly opening hours',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 5),
            ],
            const Text(
                'Planned hours · Malaysia time. Manage your live Open / Closed status from the dashboard.'),
            const SizedBox(height: 12),
            for (var day = 1; day <= 7; day++) ...[
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_days[day - 1]),
                  subtitle:
                      Text((hours[day] ?? []).isEmpty ? 'Closed' : 'Scheduled'),
                  value: (hours[day] ?? []).isNotEmpty,
                  onChanged: (enabled) {
                    final next = _copyHours();
                    next[day] = enabled
                        ? [const StallHoursInterval(9 * 60, 17 * 60)]
                        : [];
                    onChanged(next, closures);
                  }),
              for (var index = 0; index < (hours[day] ?? []).length; index++)
                _timeInterval(context, day, index),
              if ((hours[day] ?? []).isNotEmpty && hours[day]!.length < 3)
                Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                        style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48)),
                        onPressed: () {
                          final next = _copyHours();
                          next[day]!
                              .add(const StallHoursInterval(18 * 60, 22 * 60));
                          onChanged(next, closures);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add time'))),
              if (day < 7) const Divider(height: 16),
            ],
          ],
          if (showHours && showClosures) const SizedBox(height: 20),
          if (showClosures) ...[
            if (showSectionTitles) ...[
              Text('Temporary closures',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 5),
            ],
            const Text(
                'Plan breaks or days off. Your stall closes during these dates. Reopen it from the dashboard afterward.'),
            const SizedBox(height: 12),
            if (closures.isEmpty)
              const Text('No temporary closures scheduled.'),
            for (var index = 0; index < closures.length; index++)
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${_formatClosure(closures[index].start)} –'),
                  subtitle: Text(_formatClosure(closures[index].end)),
                  trailing: IconButton(
                      tooltip: 'Remove closure',
                      constraints:
                          const BoxConstraints(minWidth: 48, minHeight: 48),
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        final next = [...closures]..removeAt(index);
                        onChanged(hours, next);
                      })),
            const SizedBox(height: 8),
            OutlinedButton.icon(
                style:
                    OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed:
                    closures.length >= 20 ? null : () => _addClosure(context),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add closure')),
          ],
        ],
      );
}
