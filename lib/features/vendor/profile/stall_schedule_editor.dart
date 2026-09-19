import 'package:flutter/material.dart';
import '../../../core/models/stall_schedule.dart';

class StallScheduleEditor extends StatelessWidget {
  const StallScheduleEditor({super.key, required this.hours,
    required this.closures, required this.onChanged});

  final Map<int, List<StallHoursInterval>> hours;
  final List<TemporaryClosure> closures;
  final void Function(Map<int, List<StallHoursInterval>>, List<TemporaryClosure>) onChanged;

  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday'];

  Map<int, List<StallHoursInterval>> _copyHours() => {
    for (var day = 1; day <= 7; day++) day: [...?hours[day]],
  };

  Future<void> _pickTime(BuildContext context, int day, int index,
      {required bool opening}) async {
    final interval = hours[day]![index];
    final current = opening ? interval.openMinute : interval.closeMinute;
    final picked = await showTimePicker(context: context,
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

  Future<DateTime?> _pickDateTime(BuildContext context, DateTime initial) async {
    final date = await showDatePicker(context: context,
      initialDate: initial, firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)));
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(context: context,
      initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return null;
    // The stall operates in Malaysia time, independently of device timezone.
    return DateTime.utc(date.year, date.month, date.day,
      time.hour - 8, time.minute);
  }

  Future<void> _addClosure(BuildContext context) async {
    if (closures.length >= 20) return;
    final nowMy = DateTime.now().toUtc().add(const Duration(hours: 8));
    final start = await _pickDateTime(context, nowMy);
    if (start == null || !context.mounted) return;
    final end = await _pickDateTime(context,
      start.toUtc().add(const Duration(hours: 18)));
    if (end == null || !context.mounted) return;
    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Closure end must be after its start.')));
      return;
    }
    onChanged(hours, [...closures, TemporaryClosure(start, end)]
      ..sort((a, b) => a.start.compareTo(b.start)));
  }

  String _formatClosure(DateTime value) {
    final my = value.toUtc().add(const Duration(hours: 8));
    return '${my.day}/${my.month}/${my.year} ${formatStallTime(my.hour * 60 + my.minute)}';
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Weekly opening hours', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 5),
      const Text('These are planned hours. Use the Open switch when you start serving.'),
      const SizedBox(height: 8),
      for (var day = 1; day <= 7; day++) ...[
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_days[day - 1]),
          subtitle: Text((hours[day] ?? []).isEmpty ? 'Closed' : 'Scheduled'),
          value: (hours[day] ?? []).isNotEmpty,
          onChanged: (enabled) {
            final next = _copyHours();
            next[day] = enabled ? [const StallHoursInterval(9 * 60, 17 * 60)] : [];
            onChanged(next, closures);
          },
        ),
        for (var index = 0; index < (hours[day] ?? []).length; index++)
          Padding(padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => _pickTime(context, day, index, opening: true),
                child: Text(formatStallTime(hours[day]![index].openMinute)))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 5), child: Text('to')),
              Expanded(child: OutlinedButton(
                onPressed: () => _pickTime(context, day, index, opening: false),
                child: Text(formatStallTime(hours[day]![index].closeMinute)))),
              IconButton(tooltip: 'Remove time', icon: const Icon(Icons.close),
                onPressed: () {
                  final next = _copyHours();
                  next[day]!.removeAt(index);
                  onChanged(next, closures);
                }),
            ])),
        if ((hours[day] ?? []).isNotEmpty && hours[day]!.length < 3)
          TextButton.icon(onPressed: () {
            final next = _copyHours();
            next[day]!.add(const StallHoursInterval(18 * 60, 22 * 60));
            onChanged(next, closures);
          }, icon: const Icon(Icons.add), label: const Text('Add time')),
        const Divider(),
      ],
      const SizedBox(height: 12),
      Text('Temporary closures', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 5),
      const Text('Choose dates and times for breaks or days off. Your stall will close during a break. Use the Open switch to reopen afterward.'),
      for (var index = 0; index < closures.length; index++)
        ListTile(contentPadding: EdgeInsets.zero,
          title: Text('${_formatClosure(closures[index].start)} –'),
          subtitle: Text(_formatClosure(closures[index].end)),
          trailing: IconButton(tooltip: 'Remove closure',
            icon: const Icon(Icons.delete_outline), onPressed: () {
              final next = [...closures]..removeAt(index);
              onChanged(hours, next);
            })),
      TextButton.icon(onPressed: closures.length >= 20 ? null : () => _addClosure(context),
        icon: const Icon(Icons.event_busy_outlined), label: const Text('Add closure')),
    ],
  );
}
