import 'package:flutter/material.dart';
import '../../../core/models/stall_schedule.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/ios_grouped.dart';

class OpeningTimeFilter {
  const OpeningTimeFilter(this.start, this.label, {this.end});
  final DateTime start;
  final DateTime? end;
  final String label;
}

Future<OpeningTimeFilter?> showOpeningTimePicker(BuildContext context) async {
  final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('When would you like to visit?',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text(
                  'Based on vendor schedules in Malaysia time (MYT). Actual opening may change.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 22),
                AppGroupedCard(children: [
                  ListTile(
                      leading: const AppIconTile(
                          icon: Icons.nightlight_outlined,
                          color: AppColors.primary),
                      title: const Text('After 10 PM tonight'),
                      subtitle: const Text('10 PM to 6 AM'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(context, 'tonight')),
                  ListTile(
                      leading: const AppIconTile(
                          icon: Icons.wb_sunny_outlined,
                          color: AppColors.primaryLight),
                      title: const Text('Tomorrow morning'),
                      subtitle: const Text('6 AM to 12 PM'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(context, 'morning')),
                  ListTile(
                      leading: const AppIconTile(
                          icon: Icons.calendar_month, color: AppColors.primary),
                      title: const Text('Choose date and time'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(context, 'custom')),
                ]),
              ]),
            ),
          ));
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
