part of 'library.dart';

typedef UnauthorizedCallback = void Function();

class Authenticate {
  static Resp<VerifiedToken> _configure(String token) {
    final nativeResp = rapidNativeAuthenticate(token);
    if (nativeResp.success) {
      VerifiedToken verifiedToken = VerifiedToken(nativeResp.userId, nativeResp.issueAt, nativeResp.expiresIn);
      return Resp.success(verifiedToken);
    } else {
      return Resp.error(nativeResp.code, nativeResp.message);
    }
  }

  static Future<Resp<VerifiedToken>> configure(String token) => compute(_configure, token);

  static final List<UnauthorizedCallback> _unauthorizedListeners = [];
  static bool _isUnauthorizedCallbackSet = false;

  static void addUnauthorizedListener(UnauthorizedCallback callback) {
    if (!_unauthorizedListeners.contains(callback)) {
      _unauthorizedListeners.add(callback);
    }

    if (!_isUnauthorizedCallbackSet) {
      RapidNativeUnauthorizedChannel.instance.setCallback(_onUnauthorized);
      _isUnauthorizedCallbackSet = true;
    }
  }

  static void removeUnauthorizedListener(UnauthorizedCallback callback) {
    _unauthorizedListeners.remove(callback);
  }

  static void clearUnauthorizedListeners() {
    _unauthorizedListeners.clear();
  }

  static void cleanup() {
    clearUnauthorizedListeners();
    _isUnauthorizedCallbackSet = false;
    RapidNativeUnauthorizedChannel.instance.cleanup();
  }

  static void _onUnauthorized() {
    for (final callback in _unauthorizedListeners) {
      callback();
    }
  }
}

class VerifiedToken {
  final int userId;
  final int issueAt;
  final int expiresIn;

  VerifiedToken(this.userId, this.issueAt, this.expiresIn);

  @override
  String toString() => 'AccessToken{userId: $userId, issueAt: $issueAt, expiresIn: $expiresIn}';
}

class CaptchaRobotCheck {
  static Future<String> acquire() async => _PlatformChannel.accountRobotCheck();
}
