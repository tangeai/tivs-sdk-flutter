import 'impl.dart';
export 'struct.dart';

class SharingService {
  static Future<Resp<SharingOverview>> overview(String deviceId) async {
    return SharingImpl.overview(deviceId);
  }

  static Future<Ret> to(String deviceId, {int? userId, String? account}) async {
    return SharingImpl.to(deviceId: deviceId, userId: userId, userName: account);
  }

  static Future<Resp<String?>> generateInvitation(String deviceId, {int expiredSeconds = 60 * 10}) async {
    return SharingImpl.generateInvitation(deviceId, expiredSeconds);
  }

  static Future<Resp<InviteCodeDetail?>> peekInvitation(String code) async {
    return SharingImpl.peekInvitation(code);
  }

  static Future<Ret> acceptInvitation(String code) async {
    return SharingImpl.acceptInvitation(code);
  }

  static Future<Ret> removeRecipient(String deviceId, int shareId, int shareType) async {
    return SharingImpl.removeRecipient(deviceId, shareId, shareType);
  }

  static Future<Ret> leaveSharing(String deviceId) async {
    return SharingImpl.leaveSharing(deviceId);
  }

  static Future<Ret> acceptRequest(String shareId) async {
    return SharingImpl.acceptRequest(shareId);
  }

  static Future<Ret> rejectRequest(String shareId) async {
    return SharingImpl.rejectRequest(shareId);
  }

  static Future<Ret> requestSharing(String deviceId) async {
    return SharingImpl.requestSharing(deviceId);
  }
}
