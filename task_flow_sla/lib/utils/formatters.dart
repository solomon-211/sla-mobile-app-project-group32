import 'package:intl/intl.dart';

/// "6 Oct 2026"
String formatDate(DateTime date) => DateFormat('d MMM yyyy').format(date);

/// "6 Oct 2026, 09:00"
String formatDateTime(DateTime date) {
  return DateFormat('d MMM yyyy, HH:mm').format(date);
}

/// "09:00"
String formatTime(DateTime date) => DateFormat('HH:mm').format(date);

/// "Oct 6"
String formatShortDate(DateTime date) => DateFormat('MMM d').format(date);
