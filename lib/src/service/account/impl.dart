import '../http/http_builder.dart';
import 'struct.dart';
import 'dart:io' show Platform;
import '../../core/library.dart';
export 'struct.dart';
export '../../struct/resp.dart';
export '../../struct/ret.dart';

class AccountServiceImpl {
  static const String sceneRegister = "REGISTER";
  static const String sceneForgetPassword = "FORGET";
  static const String areaCodeDefault = "86";
  static const String countryCodeDefault = "CN";

  static Future<Resp<VerificationCode>> requireCode(String? account, String scene, String? areaCode) async => _requireCode(account, scene, areaCode);

  static Future<Resp<VerificationCode>> _requireCode(String? account, String scene, String? areaCode, {String? robotCheckResult = ""}) async {
    final resp = await Http.create()
        .path("/v2/msg/send-code")
        .param("username", account ?? "")
        .param("area_code", areaCode ?? "")
        .param("scene", scene)
        .param("robot_check", robotCheckResult)
        .post();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    final parsed = VerificationCode.fromJson(jsonResponse);
    if (parsed.requireRobotCheck == true) {
      if (robotCheckResult != null && robotCheckResult.isNotEmpty) {
        return Resp.error(403, resp.message ?? "Robot check still failed.");
      } else {
        final result = await CaptchaRobotCheck.acquire();
        if (result.startsWith("ERROR")) {
          return Resp.error(403, "Robot check failed.");
        } else {
          return _requireCode(account, scene, areaCode, robotCheckResult: result);
        }
      }
    } else {
      return Resp.success(parsed);
    }
  }

  static Future<Ret> register(String account, String verificationCode, String password, String? areaCode, String countryCode) async {
    final resp = await Http.create()
        .path("/v2/user/signup")
        .param("username", account)
        .param("code", verificationCode)
        .param("pwd", password)
        .param("area_code", areaCode ?? "")
        .param("country_code", countryCode)
        .post();
    return resp.toRet();
  }

  static Future<Ret> delete() async {
    final resp = await Http.create().path("/v2/user").delete();
    return resp.toRet();
  }

  static Future<Resp<LoginRet>> login(String account, String password, String? areaCode) async {
    final resp =
        await Http.create().path("/v2/user/login").param("username", account).param("pwd", password).param("area_code", areaCode ?? "").post();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    return Resp.success(LoginRet.fromJson(jsonResponse));
  }

  static Future<Ret> logout() async {
    final resp = await Http.create().path("/v2/user/logout").get();
    return resp.toRet();
  }

  static Future<Ret> resetPassword(String account, String verificationCode, String password, String? areaCode) async {
    final resp = await Http.create()
        .path("/v2/user/pwd/reset")
        .param("username", account)
        .param("code", verificationCode)
        .param("pwd", password)
        .param("area_code", areaCode ?? "")
        .post();
    return resp.toRet();
  }

  static Future<Ret> changePassword(String oldPassword, String newPassword) async {
    final resp = await Http.create().path("/v2/user/pwd").param("old_pwd", oldPassword).param("new_pwd", newPassword).patch();
    return resp.toRet();
  }

  static Future<Resp<UserInfo>> detail() async {
    final resp = await Http.create().path("/v2/user").get();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    return Resp.success(UserInfo.fromJson(jsonResponse));
  }

  static Future<Ret> changeNickname(String name) async {
    final resp = await Http.create().path("/v2/user/nickname").param("nickname", name).patch();
    return resp.toRet();
  }

  static Future<Resp<LoginRet>> loginViaWechat(String code, String countryCode) async {
    final resp = await Http.create().path("/v2/user/login/wechat").param("code", code).param("country_code", countryCode).post();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    return Resp.success(LoginRet.fromJson(jsonResponse));
  }

  static Future<Resp<LoginRet>> loginViaGoogle(String idToken, String countryCode) async {
    final resp = await Http.create().path("/v2/user/login/google").param("id_token", idToken).param("country_code", countryCode).post();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    return Resp.success(LoginRet.fromJson(jsonResponse));
  }

  static Future<Resp<LoginRet>> loginViaFacebook(String idToken, String countryCode) async {
    final resp = await Http.create().path("/v2/user/login/facebook").param("id_token", idToken).param("country_code", countryCode).post();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    return Resp.success(LoginRet.fromJson(jsonResponse));
  }

  static Future<Resp<LoginRet>> loginViaLine(String idToken, String countryCode) async {
    final resp = await Http.create()
        .path("/v2/user/login/line")
        .param("access_token", "")
        .param("id_token", idToken)
        .param("country_code", countryCode)
        .post();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final jsonResponse = json.decode(resp.data ?? "") as Map<String, dynamic>;
    return Resp.success(LoginRet.fromJson(jsonResponse));
  }

  static Future<Ret> checkVerificationCode(String account, String scene, String verificationCode) async {
    final resp =
        await Http.create().path("/v2/msg/verify-code").param("username", account).param("scene", scene).param("code", verificationCode).post();
    return resp.toRet();
  }
}
