import 'impl.dart';
export 'struct.dart';

class AccountService {
  static Future<Resp<VerificationCode>> verificationCodeForRegister(String account, {String areaCode = AccountServiceImpl.areaCodeDefault}) async =>
      AccountServiceImpl.requireCode(account, AccountServiceImpl.sceneRegister, areaCode);

  static Future<Resp<VerificationCode>> verificationCodeForForget(String account, {String areaCode = AccountServiceImpl.areaCodeDefault}) async =>
      AccountServiceImpl.requireCode(account, AccountServiceImpl.sceneForgetPassword, areaCode);

  static Future<Ret> register(String account, String verificationCode, String password,
          {String areaCode = AccountServiceImpl.areaCodeDefault, String countryCode = AccountServiceImpl.countryCodeDefault}) async =>
      AccountServiceImpl.register(account, verificationCode, password, areaCode, countryCode);

  static Future<Ret> delete() async => AccountServiceImpl.delete();

  static Future<Resp<LoginRet>> login(String account, String password, {String areaCode = AccountServiceImpl.areaCodeDefault}) async =>
      AccountServiceImpl.login(account, password, areaCode);

  static Future<Ret> logout() async => AccountServiceImpl.logout();

  static Future<Ret> resetPassword(String account, String verificationCode, String password,
          {String areaCode = AccountServiceImpl.areaCodeDefault}) async =>
      AccountServiceImpl.resetPassword(account, verificationCode, password, areaCode);

  static Future<Ret> changePassword(String oldPassword, String newPassword) async => AccountServiceImpl.changePassword(oldPassword, newPassword);

  static Future<Ret> changeNickname(String nickname) async => AccountServiceImpl.changeNickname(nickname);

  static Future<Resp<UserInfo>> detail() async => AccountServiceImpl.detail();

  static Future<Ret> checkVerificationCode(String account, String scene, String verificationCode) =>
      AccountServiceImpl.checkVerificationCode(account, scene, verificationCode);

  static Future<Resp<LoginRet>> loginViaWechat(String code, {String countryCode = AccountServiceImpl.countryCodeDefault}) async =>
      AccountServiceImpl.loginViaWechat(code, countryCode);

  static Future<Resp<LoginRet>> loginViaGoogle(String idToken, {String countryCode = AccountServiceImpl.countryCodeDefault}) async =>
      AccountServiceImpl.loginViaGoogle(idToken, countryCode);

  static Future<Resp<LoginRet>> loginViaFacebook(String token, {String countryCode = AccountServiceImpl.countryCodeDefault}) async =>
      AccountServiceImpl.loginViaFacebook(token, countryCode);

  static Future<Resp<LoginRet>> loginViaLine(String code, {String countryCode = AccountServiceImpl.countryCodeDefault}) async =>
      AccountServiceImpl.loginViaLine(code, countryCode);
}
