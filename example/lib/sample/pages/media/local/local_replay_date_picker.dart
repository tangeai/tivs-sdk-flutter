part of '../../rapid_kit_sample_pages.dart';

class LocalReplayDatePicker {
  static Future<DateTime?> pick(BuildContext context, DateTime selectedDate) {
    final today = DateUtils.dateOnly(DateTime.now());
    final normalizedSelectedDate = DateUtils.dateOnly(selectedDate);
    return showDatePicker(
      context: context,
      initialDate: normalizedSelectedDate.isAfter(today)
          ? today
          : normalizedSelectedDate,
      firstDate: DateTime(2000),
      lastDate: today,
    );
  }
}
