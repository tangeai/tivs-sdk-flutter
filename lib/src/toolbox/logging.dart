import '../native/library.dart';

class Logging {
  static const String _prefix = 'FLUTTER/';

  Logging._();

  static void v(String tag, String message) => _log(2, _prefix + tag, message);
  static void d(String tag, String message) => _log(3, _prefix + tag, message);
  static void i(String tag, String message) => _log(4, _prefix + tag, message);
  static void w(String tag, String message) => _log(5, _prefix + tag, message);
  static void e(String tag, String message) => _log(5, _prefix + tag, message);
  static void fatal(String tag, String message) => _log(5, _prefix + tag, message);
  static void _log(int level, String tag, String message) => RapidNativeLogging().log(level, tag, message);
}
