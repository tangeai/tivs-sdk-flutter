import 'impl.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
export 'struct.dart';

class BindingService {
  static String profile(String wifi, String pwd, String bindToken) {
    return BindingServiceImpl.profile(wifi, pwd, bindToken);
  }

  static Widget qrcode(String profile, {double size = 200.0}) {
    return QrImageView(
      data: profile,
      version: QrVersions.auto,
      size: size,
    );
  }

  static Future<Resp<BindToken>> token({String deviceId = "", String? timezone}) async {
    return BindingServiceImpl.token(deviceId, timezone);
  }

  static Future<Resp<BindedResp>> status(String bindToken) async {
    return BindingServiceImpl.status(bindToken);
  }

  static Future<Ret> unbind(String deviceId) async {
    return BindingServiceImpl.unbind(deviceId);
  }

  static Future<Ret> bind(String deviceId, {String deviceName = "", String timezone = "GMT+08:00,Asia/Shanghai"}) async {
    return BindingServiceImpl.bind(deviceId, deviceName, timezone);
  }

  static Future<Ret> bindEx(String deviceId, BindingMode bindingMode, bool mustOnline, bool mustActived, String? deviceName, String? timezone) async {
    return BindingServiceImpl.bindEx(deviceId, bindingMode, mustOnline, mustActived, deviceName, timezone);
  }
}
