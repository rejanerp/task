import 'package:intl/intl.dart';

List<String> getCurrentWeekDays() {
  DateTime now = DateTime.now();
  int currentDayOfWeek = now.weekday;
  List<String> daysOfWeek = [];

  for (int i = 0; i < 24; i++) {
    DateTime date = now.add(Duration(days: i - currentDayOfWeek));
    String formattedDate = DateFormat('EEE').format(date).toUpperCase();
    daysOfWeek.add(formattedDate);
  }

  return daysOfWeek;
}

List<String> getCurrentWeekDates() {
  DateTime now = DateTime.now();
  int currentDayOfWeek = now.weekday;
  List<String> datesOfWeek = [];

  for (int i = 0; i < 24; i++) {
    DateTime date = now.add(Duration(days: i - currentDayOfWeek));
    String formattedDate = DateFormat('d').format(date);
    datesOfWeek.add(formattedDate);
  }

  return datesOfWeek;
}
