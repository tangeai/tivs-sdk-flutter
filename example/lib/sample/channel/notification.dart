part of 'rapid_kit_sample_channel.dart';

MethodChannel _methodChannel = const MethodChannel(
    'com.tange.ai/rapid_kit_example/method.channel/notification');
EventChannel _eventChannel = const EventChannel(
    'com.tange.ai/rapid_kit_example/event.channel/notification');
StreamSubscription? _eventSubscription;
typedef NotificationEventListener = void Function(String data);

class NotificationChannel {
  static Stream<dynamic>? _events;

  static Stream<dynamic> get events =>
      _events ??= _eventChannel.receiveBroadcastStream().asBroadcastStream();

  static void startListening(NotificationEventListener listener) {
    _eventSubscription = events.listen((event) {
      if (event is Map && event['type'] != 'notification') return;
      getPendingNotification().then((value) {
        if (value.isNotEmpty) {
          listener(value);
        }
      });
    });
  }

  static void stopListening() {
    _eventSubscription?.cancel();
  }

  static Future<String> getPendingNotification() async {
    final String? result =
        await _methodChannel.invokeMethod<String>('getPendingNotification');
    if (result != null) {
      return result;
    } else {
      throw Exception('Expected String but got null');
    }
  }

  static Future<String> getPushServiceToken() async {
    final String? result =
        await _methodChannel.invokeMethod<String>('getPushServiceToken');
    if (result != null) {
      return result;
    } else {
      throw Exception('Expected String but got null');
    }
  }

  static Future<Map<String, dynamic>?> getPushRegistration() async {
    final result = await _methodChannel
        .invokeMapMethod<String, dynamic>('getPushRegistration');
    return result;
  }

  static Future<bool> isNotificationEnabled() async {
    // Notice: we only provide sample on OpenHarmonyOS.
    if (!PlatformUtil.ohos()) {
      return true;
    }

    final bool? result =
        await _methodChannel.invokeMethod<bool>('isNotificationEnabled');
    if (result != null) {
      return result;
    } else {
      throw Exception('Expected bool but got null');
    }
  }

  static Future<void> requestNotificationEnabled() async {
    await _methodChannel.invokeMethod<void>('requestNotificationEnabled');
  }
}
