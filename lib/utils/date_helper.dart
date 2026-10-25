import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class DateHelper {
  static DateTime getLocalDateTimeFromTimestamp(int timestamp) {
    var datetime =
        DateTime.fromMicrosecondsSinceEpoch(timestamp * 1000).toLocal();
    return DateTime(datetime.year, datetime.month, datetime.day, datetime.hour,
        datetime.minute);
  }

  static String getFormattedDatetimeFromTimestamp(
      int timestamp, BuildContext context) {
    var datetime =
        DateTime.fromMicrosecondsSinceEpoch(timestamp * 1000).toLocal();
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMd(locale).add_jm().format(datetime);
  }

  static DateTime getUtcDateTimeFromTimestamp(int timestamp) {
    return DateTime.fromMicrosecondsSinceEpoch(timestamp * 1000).toUtc();
  }
}
