import 'impl.dart';
export 'struct.dart';

class FirmwareService {
  static Future<Resp<FirmwareVersion>> queryCurrentVersion(String deviceId) async {
    return FirmwareServiceImpl.queryCurrentVersion(deviceId);
  }

  static Future<Resp<DeviceUpgradeStatus>> queryUpgradeStatus(String deviceId) async {
    return FirmwareServiceImpl.queryUpgradeStatus(deviceId);
  }

  static Future<Resp<DeviceUpgradeStatus>> query_upgrade_status_for_version(String deviceId, String version) async {
    return FirmwareServiceImpl.query_upgrade_status_for_version(deviceId, version);
  }

  static Future<Ret> performUpgrade(String deviceId, String version, {bool immediate = true}) async {
    return FirmwareServiceImpl.performUpgrade(deviceId, version, immediate: immediate);
  }
}
