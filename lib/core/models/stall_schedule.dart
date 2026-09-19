import 'package:cloud_firestore/cloud_firestore.dart';

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
    if (open is! int || close is! int || open < 0 || open >= 1440 ||
        close < 0 || close >= 1440 || open == close) {
      return null;
    }
    return StallHoursInterval(open, close);
  }
}

class TemporaryClosure {
  const TemporaryClosure(this.start, this.end);
  final DateTime start;
  final DateTime end;

  bool contains(DateTime value) => !value.isBefore(start) && value.isBefore(end);
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
      result[day] = raw.map(StallHoursInterval.fromMap)
          .whereType<StallHoursInterval>().toList();
    }
  }
  return result;
}

Map<String, List<Map<String, int>>> serializeWeeklyHours(
    Map<int, List<StallHoursInterval>> hours) => {
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
