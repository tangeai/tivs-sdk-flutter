part of 'rapid_kit_sample_util.dart';

class StatusBarUtil {
  StatusBarUtil._privateConstructor();

  static configureLightStatusBar() {
    if (Platform.isAndroid || PlatformUtil.ohos()) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ));
    }
  }
}
