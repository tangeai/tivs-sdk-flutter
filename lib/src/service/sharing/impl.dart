import '../http/http_builder.dart';
import 'struct.dart';
export 'struct.dart';
export '../../struct/resp.dart';
export '../../struct/ret.dart';

class SharingImpl {
  static Future<Resp<SharingOverview>> overview(String deviceId) async {
    final resp = await Http.create().path("/v2/share/$deviceId").get();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    return Resp.success(SharingOverview.fromJson(jsonResponse));
  }

  static Future<Ret> to({required String deviceId, int? userId, String? userName}) async {
    if (userId == null && userName == null) return Ret.error(-1, "userId and userName cannot be both null");

    if ((userId ?? 0) > 0) {
      final resp = await Http.create().path("/v2/share/user-id").param("device_id", deviceId).param("user_id", userId ?? 0).post();
      return resp.success ? Ret.success() : Ret.error(resp.code ?? -1, resp.message ?? "Unknown Error");
    } else {
      final resp = await Http.create().path("/v2/share/$deviceId").param("username", userName ?? "").post();
      return resp.success ? Ret.success() : Ret.error(resp.code ?? -1, resp.message ?? "Unknown Error");
    }
  }

  static Future<Resp<String?>> generateInvitation(String deviceId, int expiredSeconds) async {
    final resp = await Http.create().path("/v2/share/code/$deviceId/$expiredSeconds").get();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    final codeResp = InviteCodeResp.fromJson(jsonResponse);
    return codeResp.code == null ? Resp.error(-1, "Unknown Server Error") : Resp.success(codeResp.code!);
  }

  static Future<Resp<InviteCodeDetail?>> peekInvitation(String code) async {
    final resp = await Http.create().path("/v2/share/code").param("code", code).post();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    return Resp.success(InviteCodeDetail.fromJson(jsonResponse));
  }

  static Future<Ret> acceptInvitation(String code) async {
    final resp = await Http.create().path("/v2/share/using-code").param("code", code).post();
    return resp.toRet();
  }

  static Future<Ret> removeRecipient(String deviceId, int shareId, int shareType) async {
    final resp = await Http.create().path("/v2/share/cancel/$deviceId").param("share_id", shareId).param("share_type", shareType).post();
    return resp.toRet();
  }

  static Future<Ret> leaveSharing(String deviceId) async {
    final resp = await Http.create().path("/v2/share/quit/$deviceId").delete();
    return resp.toRet();
  }

  static Future<Ret> acceptRequest(String shareId) async {
    final resp = await Http.create().path("/v2/share/acceptance/$shareId").post();
    return resp.toRet();
  }

  static Future<Ret> rejectRequest(String shareId) async {
    final resp = await Http.create().path("/v2/share/rejection/$shareId").post();
    return resp.toRet();
  }

  static Future<Ret> requestSharing(String deviceId) async {
    final resp = await Http.create().path("/v2/share/application/$deviceId").post();
    return resp.toRet();
  }
}
