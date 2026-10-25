import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';

class TimeHelper {
  static String humanDateFromTimestamp(
      int timestampMillis, BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final target = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    final today = DateTime(now.year, now.month, now.day);
    final tDay = DateTime(target.year, target.month, target.day);
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMillis);

    final diffDays = today.difference(tDay).inDays;

    if (diffDays == 0) {
      return DateFormat.jm(locale).format(dt);
    } else if (diffDays == 1) {
      return '${AppLocalizations.of(context)!.yesterday} ${DateFormat.jm(locale).format(dt)}';
    }

    // Start of this week (assuming week starts on Monday)
    final weekday = today.weekday; // 1 = Monday ... 7 = Sunday
    final startOfWeek = today.subtract(Duration(days: weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    if (!tDay.isBefore(startOfWeek) && !tDay.isAfter(endOfWeek)) {
      // within current week, and not today/yesterday (already handled)
      final weekdayName = DateFormat.E(locale).format(target); // Mon, Tue...
      return weekdayName; // or e.g. 'Mon' or 'Monday'
    }

    // If older than this week, show formatted date
    return DateFormat.yMMMd(locale).format(target); // e.g. Jan 5, 2024
  }
}
