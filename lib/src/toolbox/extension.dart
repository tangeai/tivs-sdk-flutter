import 'dart:convert';

String _padLeft(int value, int width) {
  return value.toString().padLeft(width, '0');
}

String _formatYyyyMmDd(DateTime dt) {
  final yyyy = _padLeft(dt.year, 4);
  final mm = _padLeft(dt.month, 2);
  final dd = _padLeft(dt.day, 2);
  return '$yyyy-$mm-$dd';
}

String _formatHhMmSs(DateTime dt) {
  final hh = _padLeft(dt.hour, 2);
  final mm = _padLeft(dt.minute, 2);
  final ss = _padLeft(dt.second, 2);
  return '$hh:$mm:$ss';
}

String _formatHhMmSsSss(DateTime dt) {
  final base = _formatHhMmSs(dt);
  final sss = _padLeft(dt.millisecond, 3);
  return '$base.$sss';
}

String _formatYyyyMmDdHhMmSs(DateTime dt) {
  final date = _formatYyyyMmDd(dt);
  final time = _formatHhMmSs(dt);
  return '$date $time';
}

String _formatYyyyMmDdHhMmSsSss(DateTime dt) {
  final base = _formatYyyyMmDdHhMmSs(dt);
  final sss = _padLeft(dt.millisecond, 3);
  return '$base.$sss';
}

extension JsonEncodeExtension on Map<String, dynamic> {
  String json() => jsonEncode(this);
}

extension TimestampExtension on int {
  String secondToFormattedDate() => _formatYyyyMmDdHhMmSs(DateTime.fromMillisecondsSinceEpoch(this * 1000));

  String millisecondToYYYYMMddHHmmSS() {
    if (this == 0) return '';
    return _formatYyyyMmDdHhMmSs(DateTime.fromMillisecondsSinceEpoch(this));
  }

  String toHHmmss() => _formatHhMmSs(DateTime.fromMillisecondsSinceEpoch(this * 1000));
  String millisecondToHHmmss() => _formatHhMmSs(DateTime.fromMillisecondsSinceEpoch(this));
  String asLoggingFormat() => _formatYyyyMmDdHhMmSsSss(DateTime.fromMillisecondsSinceEpoch(this));
  String asSimpleLoggingFormat() => _formatHhMmSsSss(DateTime.fromMillisecondsSinceEpoch(this));
}

extension ChineseDateFormat on DateTime {
  String toChineseDate() => '$month月$day日';
  String toStandardDate() => _formatYyyyMmDd(this);
}
