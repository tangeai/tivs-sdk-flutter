import '../http/http_builder.dart';
import 'struct.dart';

export 'struct.dart';
export '../../struct/resp.dart';

class MessageServiceImpl {
  static Future<Resp<SendByAppResp>> send(
    String deviceId, {
    String? id,
    required String topic,
    required String data,
  }) async {
    final request = SendByAppRequest(id: id, topic: topic, data: data);
    final resp = await Http.create()
        .path('/v2/msg/device/send-by-app/$deviceId')
        .map(request.toJson())
        .post();

    if (!resp.success) {
      return Resp.error(resp.code ?? -1, resp.message ?? 'Unknown Server Error');
    }

    return Resp.success(SendByAppResp());
  }
}
