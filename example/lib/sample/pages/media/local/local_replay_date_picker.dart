part of '../../rapid_kit_sample_pages.dart';

class LocalReplayDatePicker {
  static Future<DateTime?> pick(BuildContext context, DateTime selectedDate) {
    return showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
  }
}
