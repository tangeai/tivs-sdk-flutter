import 'impl.dart';

enum PushChannel { ali, apple, xiaomi, oppo, vivo, huawei, fcm, harmony }

const Map<PushChannel, String> _channelValues = {
  PushChannel.ali: "aliyun",
  PushChannel.apple: "apple",
  PushChannel.xiaomi: "xiaomi",
  PushChannel.oppo: "oppo",
  PushChannel.vivo: "vivo",
  PushChannel.huawei: "huawei",
  PushChannel.fcm: "google",
  PushChannel.harmony: "harmony",
};

extension PushChannelExtension on PushChannel {
  String get value => _channelValues[this] ?? 'unknown';
}

class PushNotificationService {
  static Future<Ret> associate(
    String id,
    PushChannel channel, {
    List<String>? sounds,
    bool isTest = false,
  }) async {
    return PushNotificationServiceImpl.associate(
      id,
      channel.value,
      sounds: sounds,
      isTest: isTest,
    );
  }
}
