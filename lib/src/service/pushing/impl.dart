import '../http/http_builder.dart';
export '../../struct/resp.dart';
export '../../struct/ret.dart';

class PushNotificationServiceImpl {
  static Future<Ret> associate(
    String id,
    String channel, {
    List<String>? sounds,
    bool isTest = false,
  }) async {
    final request = Http.create()
        .path("/v2/push/id")
        .param("id", id)
        .param("channel", channel)
        .param("is_test", isTest);

    if (sounds != null && sounds.isNotEmpty) {
      request.param("sound", sounds);
    }

    return (await request.post()).toRet();
  }
}
