part of 'rapid_kit_sample_channel.dart';

class HarmonyQrScannerChannel {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.tange.ai/rapid_kit_example/method.channel/harmony_qr_scanner',
  );

  static Future<String?> scan() {
    return _methodChannel.invokeMethod<String>('scanQrCode');
  }
}
