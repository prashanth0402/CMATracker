import 'package:intl/intl.dart';

/// Centralised date / time helpers. All persistence uses UTC ISO-8601 strings
/// via [toIso]; all display uses the device local timezone.
class AppDate {
  const AppDate._();

  static final DateFormat _ymd = DateFormat('yyyy-MM-dd');
  static final DateFormat _display = DateFormat('EEE, d MMM yyyy');
  static final DateFormat _monthLabel = DateFormat('MMMM yyyy');
  static final DateFormat _time = DateFormat('HH:mm');
  static final DateFormat _dayNum = DateFormat('d');

  /// Midnight (local) of the given date.
  static DateTime dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Last microsecond of the given day (local).
  static DateTime dayEnd(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999, 999);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isWeekend(DateTime d) =>
      d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

  /// Start of the week containing [d]. [startOfWeek] is a [DateTime.weekday]
  /// value (1 = Monday .. 7 = Sunday).
  static DateTime weekStart(DateTime d, {int startOfWeek = DateTime.monday}) {
    final date = dayStart(d);
    final diff = (date.weekday - startOfWeek) % 7;
    return date.subtract(Duration(days: diff < 0 ? diff + 7 : diff));
  }

  static DateTime weekEnd(DateTime d, {int startOfWeek = DateTime.monday}) =>
      dayEnd(weekStart(d, startOfWeek: startOfWeek).add(const Duration(days: 6)));

  static DateTime monthStart(DateTime d) => DateTime(d.year, d.month);

  static DateTime monthEnd(DateTime d) =>
      dayEnd(DateTime(d.year, d.month + 1, 0));

  /// Number of days in the month of [d] (leap-year safe via DateTime rollover).
  static int daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;

  /// ISO week-of-year number (1..53).
  static int weekOfYear(DateTime d) {
    final date = dayStart(d);
    final firstThursday = DateTime(date.year, 1, 4);
    final firstMonday = weekStart(firstThursday);
    return ((date.difference(firstMonday).inDays) / 7).floor() + 1;
  }

  static String isoDay(DateTime d) => _ymd.format(dayStart(d));
  static String displayDate(DateTime d) => _display.format(d);
  static String monthLabel(DateTime d) => _monthLabel.format(d);
  static String time(DateTime d) => _time.format(d);
  static String dayNumber(DateTime d) => _dayNum.format(d);

  static String toIso(DateTime d) => d.toUtc().toIso8601String();
  static DateTime fromIso(String s) => DateTime.parse(s).toLocal();

  /// Inclusive list of day-start DateTimes between [from] and [to].
  static List<DateTime> daysBetween(DateTime from, DateTime to) {
    final start = dayStart(from);
    final end = dayStart(to);
    final out = <DateTime>[];
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      out.add(d);
    }
    return out;
  }

  /// Formats a minute count as e.g. "1h 45m" or "45m".
  static String formatMinutes(int minutes) {
    if (minutes <= 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// Formats a [Duration] as HH:MM:SS.
  static String formatHms(Duration d) {
    final total = d.inSeconds < 0 ? 0 : d.inSeconds;
    final h = (total ~/ 3600).toString().padLeft(2, '0');
    final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
