part of 'rapid_kit_sample_channel.dart';

class ScreenAwakeChannel {
  static const MethodChannel kChannel = MethodChannel(
      'com.tange.ai/rapid_kit_example/method.channel/screen_awake');

  // ignore: non_constant_identifier_names
  static Future<void> set_enabled(String owner, bool enabled) async {
    if (kIsWeb ||
        ![TargetPlatform.iOS, TargetPlatform.android]
            .contains(defaultTargetPlatform)) {
      return;
    }
    try {
      final evidence = await kChannel.invokeMethod<String>(
          'setEnabled', {'owner': owner, 'enabled': enabled});
      if (evidence != null) Logging.i('ScreenAwake', evidence);
    } catch (error) {
      debugPrint('[ScreenAwake] update failed, owner=$owner, error=$error');
    }
  }
}
