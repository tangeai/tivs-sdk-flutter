part of '../../rapid_kit_sample_pages.dart';

class LocalReplayUiHelpers {
  static String formatDateLabel(DateTime selectedDate, DateTime todayDate) {
    var formattedDate = selectedDate.toChineseDate();
    if (todayDate.day == selectedDate.day) {
      formattedDate = "$formattedDate | 今天";
    }
    return formattedDate;
  }

  static String eventLabel(int event) {
    switch (event) {
      case 0:
        return " ";
      case 1:
        return "发现移动 ";
      case 2:
        return "发现人形 ";
      case 3:
        return "发现声音 ";
      case 4:
        return "PIR ";
      default:
        return "未知 ";
    }
  }

  static String? formatTimestampLabel(int timestampInMs) {
    if (timestampInMs <= 0) {
      return null;
    }
    return timestampInMs.millisecondToHHmmss();
  }
}
