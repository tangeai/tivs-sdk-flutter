import 'impl.dart';

export 'struct.dart';

class MessageService {
  static Future<Resp<SendByAppResp>> send(
    String deviceId, {
    String? id,
    required String topic,
    required String data,
  }) async {
    return MessageServiceImpl.send(deviceId, id: id, topic: topic, data: data);
  }
}
