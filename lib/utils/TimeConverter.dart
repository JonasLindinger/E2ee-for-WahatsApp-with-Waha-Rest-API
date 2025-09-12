import 'package:intl/intl.dart';

/// Converts a timestamp (milliseconds since epoch) to a formatted time string.
///
/// [use24HourFormat] - true = "13:45", false = "1:45 PM"
/// [timeZoneOffset] - optional manual override (Duration). If null, uses device timezone.
String formatMessageTime(
    int timestampMillis, {
      bool use24HourFormat = true,
      Duration? timeZoneOffset,
      bool timestampIsUtc = false, // <-- new parameter for clarity
    }) {
  DateTime dateTime = timestampIsUtc
      ? DateTime.fromMillisecondsSinceEpoch(timestampMillis, isUtc: true)
      : DateTime.fromMillisecondsSinceEpoch(timestampMillis);

  DateTime localTime = dateTime.toLocal();

  // Apply manual timezone override if provided
  if (timeZoneOffset != null) {
    localTime = dateTime.toUtc().add(timeZoneOffset);
  }

  final format = use24HourFormat ? DateFormat.Hm() : DateFormat.jm();
  return format.format(localTime);
}