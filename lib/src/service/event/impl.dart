import '../http/http_builder.dart';
import 'struct.dart';
export 'struct.dart';
export '../../struct/resp.dart';
export '../../struct/ret.dart';

class EventServiceImpl {
  static Future<Resp<RemotePushConfigure>> currentNotificationSettings(String deviceId) async {
    final resp = await Http.create().path("/v2/cloud/switcher/$deviceId").get();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    return Resp.success(RemotePushConfigure.fromJson(jsonResponse));
  }

  static Future<Ret> updateNotificationSettings(
      String deviceId, LocalPushConfigure configure) async {
    final resp =
        await Http.create().path("/v2/cloud/switcher/$deviceId").map(configure.toJson()).post();
    return resp.toRet();
  }

  static Future<Resp<Categories>> catagoriesOfList(List<String> deviceIdList) async {
    String deviceListStr = deviceIdList.length > 1 ? deviceIdList.join(',') : deviceIdList.first;
    final resp =
        await Http.create().path("/v2/cloud/filter").param("device_id", deviceListStr).post();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final jsonResponse = json.decode(resp.data ?? "") as List<dynamic>;
    return Resp.success(Categories.fromJson(jsonResponse));
  }

  static Future<Resp<Events?>> allEvents(String deviceId, String date) async {
    final resp = await Http.create().path("/v2/cloud/events/$deviceId/$date").get();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    return Resp.success(Events.fromJson(jsonResponse));
  }

  static Future<Resp<Event?>> event(String eventId) async {
    final resp = await Http.create().path("/v2/cloud/event/$eventId").get();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    final event = Event.fromJson(jsonResponse);
    event.deviceId = _extractDeviceId(event.id ?? '');
    return Resp.success(event);
  }

  static Future<Resp<List<Event>?>> listEventsByPage(List<String> deviceIdList, String date,
      int offset, int limit, List<String>? catagoriesLabel) async {
    String deviceListStr = deviceIdList.length > 1 ? deviceIdList.join(',') : deviceIdList.first;
    final resp = await Http.create()
        .path("/v2/cloud/event")
        .param("device_id", deviceListStr)
        .param("date", date)
        .param("offset", offset)
        .param("tag", catagoriesLabel)
        .param("limit", limit)
        .post();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    final messages = Events.fromJson(jsonResponse).list ?? [];
    for (var i = 0; i < messages.length; i++) {
      final event = messages[i];
      event.deviceId = _extractDeviceId(event.id ?? '');
    }
    return Resp.success(messages);
  }

  static Future<Resp<List<Event>?>> listEventsByPageOfDays(String deviceId, String startDate,
      String endDate, int offset, int limit, List<String>? catagoriesLabel) async {
    String query = '';
    query += 'offset=$offset&';
    query += 'limit=$limit';

    if (catagoriesLabel != null && catagoriesLabel.isNotEmpty) {
      query += '&tags=${catagoriesLabel.join('&tags=')}';
    }

    final resp =
        await Http.create().path("/v2/cloud/events/$deviceId/$startDate/$endDate?$query").get();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    final messages = Events.fromJson(jsonResponse).list ?? [];
    for (var i = 0; i < messages.length; i++) {
      final event = messages[i];
      event.deviceId = _extractDeviceId(event.id ?? '');
    }
    return Resp.success(messages);
  }

  static String _extractDeviceId(String messageId) {
    if (messageId.isNotEmpty && messageId.contains(':')) {
      return messageId.split(':').first;
    }
    return '';
  }

  static Future<Ret> deleteList(List<String> eventIdList, {bool global = false}) async {
    final resp =
        await Http.create().path("/v2/cloud/event/delete-by-id").param("id", eventIdList).param("is_global", global ? 1 : 0).post();
    return resp.toRet();
  }

  static Future<Ret> deleteRangeOfList(
      List<String> deviceIdList, int startTimestampInSecond, int endTimestampInSecond, {bool global = false}) async {
    String deviceListStr = deviceIdList.length > 1 ? deviceIdList.join(',') : deviceIdList.first;
    final resp = await Http.create()
        .path("/v2/cloud/event/delete-by-range")
        .param("device_id", deviceListStr)
        .param("start_time", startTimestampInSecond)
        .param("end_time", endTimestampInSecond)
        .param("is_global", global ? 1 : 0)
        .post();
    return resp.toRet();
  }
}
