part of 'library.dart';

class WifiAbility {
  /// Enables Android Wi-Fi diagnostics only after the app has obtained consent.
  /// Location permission must also be granted. This never requests permission.
  /// Call with false when consent is withdrawn; other platforms are unchanged.
  // ignore: non_constant_identifier_names
  static Future<void> set_network_logging_enabled(bool enabled) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>(
      'setWifiNetworkLoggingEnabled',
      {'enabled': enabled},
    );
  }

  static Future<String> currentConnected() async => _PlatformChannel.currentWifi();

  static Future<bool> launchSetting() async => _PlatformChannel.launchWiFiSettings();
}
