import 'impl.dart';
export 'struct.dart';

class SpecService {
  static Future<Resp<Primary>> primary(String deviceId) async {
    return SpecServiceImpl.primary(deviceId);
  }

  static Future<Resp<PrimaryByPage>> primaryByPage(int offset, {int limit = 10, String? nameFilter = ""}) {
    return SpecServiceImpl.primaryByPage(offset: offset, limit: limit, nameFilter: nameFilter);
  }

  static Future<Resp<Timezone>> timezone(String deviceId) async {
    return SpecServiceImpl.requireSingleTimezone(deviceId);
  }

  static Future<Resp<Map<String, Timezone>>> timezoneOfList(List<String> deviceList) async {
    return SpecServiceImpl.requireTimezone(deviceList);
  }

  static Future<Resp<Map<String, BatteryStatus>>> batteryStatusOfList(List<String> deviceList) async {
    return SpecServiceImpl.battery(deviceList);
  }

  static Future<Resp<BatteryStatus>> batteryStatus(String deviceId) async {
    return SpecServiceImpl.requireSingleBatteryStatus(deviceId);
  }

  static Future<Resp<Map<String, OnlineStatus>>> onlineStatusOfList(List<String> deviceList) async {
    return SpecServiceImpl.requireOnlineStatus(deviceList);
  }

  static Future<Resp<OnlineStatus>> onlineStatus(String deviceId) async {
    return SpecServiceImpl.requireSingleOnlineStatus(deviceId);
  }

  static Future<Resp<Map<String, Thumbnail>>> thumbnailsOfList(List<String> deviceList) async {
    return SpecServiceImpl.requireThumbnails(deviceList);
  }

  static Future<Resp<Thumbnail>> thumbnail(String deviceId) async {
    return SpecServiceImpl.requireSingleThumbnail(deviceId);
  }

  static Future<Ret> rename(String deviceId, String newName) async {
    return SpecServiceImpl.rename(deviceId, newName);
  }

  static Future<Ret> updateTimezone(String deviceId, String time, String zone) async {
    return SpecServiceImpl.updateTimezone(deviceId, time, zone);
  }
}
