// ignore_for_file: deprecated_member_use

part of 'rapid_kit_sample_util.dart';

class PlatformUtil {
  PlatformUtil._privateConstructor();

  static bool ohos() {
    return Platform.operatingSystem == 'ohos';
  }

  static Widget autoUnfocus({required Widget child}) {
    return Builder(
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            if (FocusScope.of(context).hasFocus) {
              FocusScope.of(context).unfocus();
              return false;
            }
            return true;
          },
          child: child,
        );
      },
    );
  }

  static Widget filterPop({required Widget child}) {
    return Builder(
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: child,
        );
      },
    );
  }
}
