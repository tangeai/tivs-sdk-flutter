import '../http/http_builder.dart';
import 'struct.dart';
import '../../native/library.dart';
export 'struct.dart';
export '../../struct/resp.dart';
export '../../struct/ret.dart';

class BindingServiceImpl {
  /// Create a binding profile used to:
  /// 1. display a QR code for device binding
  /// 2. send via AP/BLE to device for binding
  static String profile(
    String wifi,
    String password,
    String bindToken,
  ) {
    return rapidNativeCreateBindingProfile(wifi, password, bindToken);
  }

  static Future<Resp<BindToken>> token(String? deviceId, String? timezone) async {
    final resp = await Http.create().path("/v2/device/pre-bind").param("device_id", deviceId ?? "").param("tz", timezone ?? _defaultTimeZone()).post();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    return Resp.success(BindToken.fromJson(jsonResponse));
  }

  /// Poll the binding status of a device.
  /// Notive that you should not poll for a while, as the device may need some time to connect to the network.
  static Future<Resp<BindedResp>> status(String bindToken) async {
    final resp = await Http.create().path("/v2/device/pre-bind/status/$bindToken").get();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    return Resp.success(BindedResp.fromJson(jsonResponse));
  }

  /// Unbind a device from the current user.
  /// Device would be automatically reset to network configuration mode.
  static Future<Ret> unbind(String deviceId) async {
    final resp = await Http.create().path("/v2/device/binding/$deviceId").delete();
    return resp.toRet();
  }

  /// Bind a device to the current user.
  /// "deviceName" and "timezone" are optional.
  static Future<Ret> bind(String deviceId, String? deviceName, String? timezone) async {
    final resp =
        await Http.create().path("/v2/device/bind/$deviceId").param("name", deviceName ?? '').param("tz", timezone ?? _defaultTimeZone()).post();
    return resp.toRet();
  }

  /// Bind a device to the current user with more options.
  static Future<Ret> bindEx(String deviceId, BindingMode bindingMode, bool mustOnline, bool mustActived, String? deviceName, String? timezone) async {
    final method = {
      BindingMode.modeDevice: "device",
      BindingMode.modeScan: "scan",
      BindingMode.mode4G: "4g",
      BindingMode.modeLan: "lan",
      BindingMode.modeOther: "other"
    }[bindingMode];

    final resp = await Http.create()
        .path("/v2/device/bind/$deviceId")
        .param("name", deviceName ?? '')
        .param("tz", timezone ?? _defaultTimeZone())
        .param("method", method)
        .param("must_be_online", mustOnline)
        .param("must_be_actived", mustActived)
        .post();

    return resp.toRet();
  }

  static String _defaultTimeZone() {
    return "GMT+08:00,Asia/Shanghai";
  }
}
