class Recipient {
  int? shareId;
  String? shareTime;
  int? shareType;
  String? nickName;
  int? userId;

  Recipient({this.shareId, this.shareTime, this.shareType, this.nickName, this.userId});

  factory Recipient.fromJson(Map<String, dynamic> json) {
    return Recipient(
      shareId: json['share_id'] as int?,
      shareTime: json['share_time'] as String?,
      shareType: json['share_type'] as int?,
      nickName: json['nickname'] as String?,
      userId: json['user_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'share_id': shareId,
      'share_time': shareTime,
      'share_type': shareType,
      'nickname': nickName,
      'user_id': userId,
    };
  }

  @override
  String toString() {
    return 'Recipient{shareId: $shareId, shareTime: $shareTime, shareType: $shareType, nickName: $nickName, userId: $userId}';
  }

  static const int typePreShare = 0; // 预分享，表示用户账号创建后才能完成分享
  static const int typeShared = 1; // 分享，表示设备已正常被分享给此用户
  static const int typeRequestShare = 2; // 表示此用户发起了设备共享请求
}

class SharingOverview {
  List<Recipient>? list;
  int total = 0;

  SharingOverview({this.list, this.total = 0});

  factory SharingOverview.fromJson(Map<String, dynamic> json) {
    return SharingOverview(
      list: (json['items'] as List<dynamic>?)?.map((dynamic item) => Recipient.fromJson(item as Map<String, dynamic>)).toList(),
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'items': list?.map((item) => item.toJson()).toList(),
      'total': total,
    };
  }

  @override
  String toString() {
    return 'SharingOverview{list: $list, total: $total}';
  }
}

// InviteCodeResp 类
class InviteCodeResp {
  String? code;

  InviteCodeResp({this.code});

  factory InviteCodeResp.fromJson(Map<String, dynamic> json) {
    return InviteCodeResp(
      code: json['code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
    };
  }
}

class InviteCodeDetail {
  String? createdAt;
  String? expiresAt;
  List<String>? deviceName;
  String? ownerNickName;
  String? ownerUserId;

  InviteCodeDetail({this.createdAt, this.expiresAt, this.deviceName, this.ownerNickName, this.ownerUserId});

  factory InviteCodeDetail.fromJson(Map<String, dynamic> json) {
    return InviteCodeDetail(
      createdAt: json['created_at'] as String?,
      expiresAt: json['expired_at'] as String?,
      deviceName: (json['device'] as List<dynamic>?)?.map((dynamic item) => item as String).toList(),
      ownerNickName: json['nickname'] as String?,
      ownerUserId: json['user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'created_at': createdAt,
      'expired_at': expiresAt,
      'device': deviceName,
      'nickname': ownerNickName,
      'user_id': ownerUserId,
    };
  }
}
