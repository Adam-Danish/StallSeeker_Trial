import 'package:cloud_firestore/cloud_firestore.dart';

/// Calendar fields in Malaysia, independent of the phone's time zone.
DateTime malaysiaTime(DateTime instant) =>
    instant.toUtc().add(const Duration(hours: 8));

DateTime malaysiaInstant(int year, int month, int day, int hour, int minute) =>
    DateTime.utc(year, month, day, hour, minute)
        .subtract(const Duration(hours: 8));

/// True when any scheduled serving time remains in this window after closures.
bool hasScheduledOpening(DateTime start, DateTime end,
    Map<int, List<StallHoursInterval>> hours, List<TemporaryClosure> closures) {
  if (!end.isAfter(start) || hours.isEmpty) return false;
  final first = malaysiaTime(start);
  final last = malaysiaTime(end);
  var day = DateTime.utc(first.year, first.month, first.day)
      .subtract(const Duration(days: 1));
  final lastDay = DateTime.utc(last.year, last.month, last.day);
  while (!day.isAfter(lastDay)) {
    final midnight = malaysiaInstant(day.year, day.month, day.day, 0, 0);
    for (final interval in hours[day.weekday] ?? <StallHoursInterval>[]) {
      var open = midnight.add(Duration(minutes: interval.openMinute));
      var close = midnight.add(Duration(
          minutes: interval.closeMinute +
              (interval.closeMinute < interval.openMinute ? 1440 : 0)));
      if (open.isBefore(start)) open = start;
      if (close.isAfter(end)) close = end;
      if (!close.isAfter(open)) continue;
      var available = <TemporaryClosure>[TemporaryClosure(open, close)];
      for (final closure in closures) {
        final remaining = <TemporaryClosure>[];
        for (final segment in available) {
          if (!closure.end.isAfter(segment.start) ||
              !closure.start.isBefore(segment.end)) {
            remaining.add(segment);
          } else {
            if (closure.start.isAfter(segment.start)) {
              remaining.add(TemporaryClosure(segment.start, closure.start));
            }
            if (closure.end.isBefore(segment.end)) {
              remaining.add(TemporaryClosure(closure.end, segment.end));
            }
          }
        }
        available = remaining;
      }
      if (available.isNotEmpty) return true;
    }
    day = day.add(const Duration(days: 1));
  }
  return false;
}

bool isWithinStallSchedule(DateTime instant,
    Map<int, List<StallHoursInterval>> hours, List<TemporaryClosure> closures) {
  if (hours.isEmpty || closures.any((closure) => closure.contains(instant))) {
    return false;
  }
  final local = malaysiaTime(instant);
  final minute = local.hour * 60 + local.minute;
  for (final interval in hours[local.weekday] ?? <StallHoursInterval>[]) {
    if (interval.closeMinute > interval.openMinute) {
      if (minute >= interval.openMinute && minute < interval.closeMinute) {
        return true;
      }
    } else if (minute >= interval.openMinute) {
      return true;
    }
  }
  final previousDay = local.weekday == 1 ? 7 : local.weekday - 1;
  return (hours[previousDay] ?? <StallHoursInterval>[]).any((interval) =>
      interval.closeMinute < interval.openMinute &&
      minute < interval.closeMinute);
}

/// Weekly hours use Monday=1 through Sunday=7 and minutes after midnight.
class StallHoursInterval {
  const StallHoursInterval(this.openMinute, this.closeMinute);
  final int openMinute;
  final int closeMinute;

  Map<String, int> toMap() => {'open': openMinute, 'close': closeMinute};

  static StallHoursInterval? fromMap(Object? value) {
    if (value is! Map) return null;
    final open = value['open'];
    final close = value['close'];
    if (open is! int ||
        close is! int ||
        open < 0 ||
        open >= 1440 ||
        close < 0 ||
        close >= 1440 ||
        open == close) {
      return null;
    }
    return StallHoursInterval(open, close);
  }
}

class TemporaryClosure {
  const TemporaryClosure(this.start, this.end);
  final DateTime start;
  final DateTime end;

  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(end);
  Map<String, Timestamp> toMap() => {
        'startAt': Timestamp.fromDate(start.toUtc()),
        'endAt': Timestamp.fromDate(end.toUtc()),
      };

  static TemporaryClosure? fromMap(Object? value) {
    if (value is! Map) return null;
    final start = value['startAt'];
    final end = value['endAt'];
    if (start is! Timestamp || end is! Timestamp) return null;
    final result = TemporaryClosure(start.toDate(), end.toDate());
    return result.end.isAfter(result.start) ? result : null;
  }
}

Map<int, List<StallHoursInterval>> parseWeeklyHours(Object? value) {
  if (value is! Map) return {};
  final result = <int, List<StallHoursInterval>>{};
  for (var day = 1; day <= 7; day++) {
    final raw = value['$day'];
    if (raw is List) {
      result[day] = raw
          .map(StallHoursInterval.fromMap)
          .whereType<StallHoursInterval>()
          .toList();
    }
  }
  return result;
}

Map<String, List<Map<String, int>>> serializeWeeklyHours(
        Map<int, List<StallHoursInterval>> hours) =>
    {
      for (var day = 1; day <= 7; day++)
        '$day': (hours[day] ?? []).map((interval) => interval.toMap()).toList(),
    };

String formatStallTime(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  final period = hour < 12 ? 'AM' : 'PM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
}
