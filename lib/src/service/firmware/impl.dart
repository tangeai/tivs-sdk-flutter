import '../http/http_builder.dart';
import 'struct.dart';
export 'struct.dart';
export '../../struct/resp.dart';
export '../../struct/ret.dart';

const String _pathQueryCurrentVersion = '/v2/device/upgrade';
const String _pathQueryUpgradeStatus = '/v2/device/upgrade';
const String _pathPerformUpgrade = '/v2/device/upgrade';
const String _paramDeviceId = 'device_id';

class FirmwareServiceImpl {
  static Future<Resp<FirmwareVersion>> queryCurrentVersion(String deviceId) async {
    final resp = await Http.create().path(_pathQueryCurrentVersion).param(_paramDeviceId, deviceId).post();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Error");

    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    return jsonResponse.containsKey(deviceId)
        ? Resp.success(FirmwareVersion.fromJson(jsonResponse[deviceId] as Map<String, dynamic>))
        : Resp.error(-1, "No response for device $deviceId");
  }

  static Future<Resp<DeviceUpgradeStatus>> queryUpgradeStatus(String deviceId) async {
    final resp = await Http.create().path("$_pathQueryUpgradeStatus/$deviceId").get();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Error");

    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    return jsonResponse.containsKey(deviceId)
        ? Resp.success(DeviceUpgradeStatus.fromJson(jsonResponse[deviceId] as Map<String, dynamic>))
        : Resp.error(-1, "No response for device $deviceId");
  }

  static Future<Resp<DeviceUpgradeStatus>> query_upgrade_status_for_version(String deviceId, String version) async {
    final resp = await Http.create()
        .path("$_pathQueryUpgradeStatus/${Uri.encodeComponent(deviceId)}/${Uri.encodeComponent(version)}")
        .get();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Error");

    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    return Resp.success(DeviceUpgradeStatus.fromJson(jsonResponse));
  }

  static Future<Ret> performUpgrade(String deviceId, String version, {bool immediate = true}) async {
    final resp = await Http.create().path("$_pathPerformUpgrade/$deviceId").param("version", version).param("immediate_upgrade", immediate).post();
    return resp.success ? Ret.success() : Ret.error(resp.code ?? -1, resp.message ?? "Unknown Error");
  }
}
