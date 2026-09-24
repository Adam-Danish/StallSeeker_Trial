import 'package:flutter/material.dart';
import '../../../core/models/stall_schedule.dart';

class OpeningTimeFilter {
  const OpeningTimeFilter(this.start, this.label, {this.end});
  final DateTime start;
  final DateTime? end;
  final String label;
}

Future<OpeningTimeFilter?> showOpeningTimePicker(BuildContext context) async {
  final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Padding(
                padding: EdgeInsets.all(20),
                child: Text('When would you like to visit?',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                    'Based on vendor schedules in Malaysia time (MYT). Actual opening may change.')),
            ListTile(
                leading: const Icon(Icons.nightlight_outlined),
                title: const Text('After 10 PM tonight'),
                subtitle: const Text('Any opening between 10 PM and 6 AM'),
                onTap: () => Navigator.pop(context, 'tonight')),
            ListTile(
                leading: const Icon(Icons.wb_sunny_outlined),
                title: const Text('Tomorrow morning'),
                subtitle: const Text('Any opening between 6 AM and 12 PM'),
                onTap: () => Navigator.pop(context, 'morning')),
            ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Choose date and time'),
                onTap: () => Navigator.pop(context, 'custom')),
            const SizedBox(height: 12),
          ])));
  if (choice == null || !context.mounted) return null;
  final now = DateTime.now();
  final local = malaysiaTime(now);
  final today = DateTime(local.year, local.month, local.day);
  final tomorrow = today.add(const Duration(days: 1));
  if (choice == 'tonight') {
    final ten = malaysiaInstant(today.year, today.month, today.day, 22, 0);
    return OpeningTimeFilter(
        ten.isBefore(now) ? now : ten, 'After 10 PM tonight',
        end:
            malaysiaInstant(tomorrow.year, tomorrow.month, tomorrow.day, 6, 0));
  }
  if (choice == 'morning') {
    return OpeningTimeFilter(
        malaysiaInstant(tomorrow.year, tomorrow.month, tomorrow.day, 6, 0),
        'Tomorrow morning',
        end: malaysiaInstant(
            tomorrow.year, tomorrow.month, tomorrow.day, 12, 0));
  }
  final date = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)));
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: local.hour, minute: local.minute),
      helpText: 'Visit time (MYT)');
  if (time == null || !context.mounted) return null;
  final instant =
      malaysiaInstant(date.year, date.month, date.day, time.hour, time.minute);
  if (instant.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a future date and time.')));
    return null;
  }
  return OpeningTimeFilter(instant,
      '${date.day}/${date.month}/${date.year} · ${formatStallTime(time.hour * 60 + time.minute)} MYT');
}
