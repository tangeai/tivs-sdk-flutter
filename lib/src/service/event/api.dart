import 'impl.dart';
export 'struct.dart';

class EventService {
  static Future<Resp<RemotePushConfigure>> currentNotificationSettings(String deviceId) async {
    return EventServiceImpl.currentNotificationSettings(deviceId);
  }

  static Future<Ret> updateNotificationSettings(
      String deviceId, LocalPushConfigure configure) async {
    return EventServiceImpl.updateNotificationSettings(deviceId, configure);
  }

  static Future<Resp<Categories>> catagories(String deviceId) async {
    return EventServiceImpl.catagoriesOfList([deviceId]);
  }

  static Future<Resp<Categories>> catagoriesOfList(List<String> deviceIdList) async {
    return EventServiceImpl.catagoriesOfList(deviceIdList);
  }

  static Future<Resp<Events?>> allEvents(String deviceId, String date) async {
    return EventServiceImpl.allEvents(deviceId, date);
  }

  static Future<Resp<List<Event>?>> eventsByPage(String deviceId, String date, int offset,
      {int limit = 30, List<String>? catagoriesLabel}) async {
    return EventServiceImpl.listEventsByPage([deviceId], date, offset, limit, catagoriesLabel);
  }

  static Future<Resp<List<Event>?>> listEventsByPageOfDays(
      String deviceId, String startDate, String endDate, int offset,
      {int limit = 30, List<String>? catagoriesLabel}) async {
    return EventServiceImpl.listEventsByPageOfDays(
        deviceId, startDate, endDate, offset, limit, catagoriesLabel);
  }

  static Future<Resp<List<Event>?>> eventsByPageOfList(
      List<String> deviceIdList, String date, int offset,
      {int limit = 30, List<String>? catagoriesLabel}) async {
    return EventServiceImpl.listEventsByPage(deviceIdList, date, offset, limit, catagoriesLabel);
  }

  static Future<Resp<Event?>> event(String eventId) async {
    return EventServiceImpl.event(eventId);
  }

  static Future<Ret> delete(String eventId, {bool global = false}) async {
    return EventServiceImpl.deleteList([eventId], global: global);
  }

  static Future<Ret> deleteList(List<String> eventIdList, {bool global = false}) async {
    return EventServiceImpl.deleteList(eventIdList, global: global);
  }

  static Future<Ret> deleteRangeOfList(
      List<String> deviceIdList, int startTimestampInSecond, int endTimestampInSecond,
      {bool global = false}) async {
    return EventServiceImpl.deleteRangeOfList(
        deviceIdList, startTimestampInSecond, endTimestampInSecond,
        global: global);
  }

  static Future<Ret> deleteRange(
      String deviceId, int startTimestampInSecond, int endTimestampInSecond,
      {bool global = false}) async {
    return EventServiceImpl.deleteRangeOfList(
        [deviceId], startTimestampInSecond, endTimestampInSecond,
        global: global);
  }
}
