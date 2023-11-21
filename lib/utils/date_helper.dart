class DateHelper{
  static DateTime getLocalDateTimeFromTimestamp(int timestamp) {
    return DateTime.fromMicrosecondsSinceEpoch(timestamp * 1000).toLocal();
  }

  static DateTime getUtcDateTimeFromTimestamp(int timestamp) {
    return DateTime.fromMicrosecondsSinceEpoch(timestamp * 1000).toUtc();
  }
}