import 'dart:convert';

class PrimaryByPage {
  List<Primary>? list;
  int? total;

  PrimaryByPage({this.list, this.total});

  factory PrimaryByPage.fromJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      var itemsList = json['items'] as List?;
      List<Primary>? list = itemsList?.map((dynamic i) => Primary.fromJson(i as Map<String, dynamic>)).toList();

      return PrimaryByPage(
        list: list,
        total: json['total'] as int?,
      );
    } catch (e) {
      return PrimaryByPage(list: null, total: null);
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'items': list?.map((i) => i.toJson()).toList(),
      'total': total,
    };
  }
}

class Primary {
  String? deviceId;
  String? deviceName;
  String? connectionMode;
  String? productName;
  String? productKey;
  bool? isOwner;
  String? deviceAbilities;
  String? deviceAttributes;
  String? extraDeviceAttributes;
  String? aiAbilities;
  String? extendAbilities;

  Primary({
    this.deviceId,
    this.deviceName,
    this.connectionMode,
    this.productName,
    this.productKey,
    this.isOwner,
    this.deviceAbilities,
    this.deviceAttributes,
    this.extraDeviceAttributes,
    this.aiAbilities,
    this.extendAbilities,
  });

  factory Primary.fromJson(Map<String, dynamic> json) {
    return Primary(
      deviceId: json['device_id'] as String?,
      deviceName: json['device_name'] as String?,
      connectionMode: json['connect_way'] as String?,
      productName: json['product_name'] as String?,
      productKey: json['product_key'] as String?,
      isOwner: json['is_owner'] as bool?,
      deviceAbilities: json['abilities'] as String?,
      deviceAttributes: json['attrs'] as String?,
      extraDeviceAttributes: json['ext_attrs'] as String?,
      aiAbilities: json['ai_abilities'] as String?,
      extendAbilities: json['extends'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'device_id': deviceId,
      'device_name': deviceName,
      'connect_way': connectionMode,
      'product_name': productName,
      'product_key': productKey,
      'is_owner': isOwner,
      'abilities': deviceAbilities,
      'attrs': deviceAttributes,
      'ext_attrs': extraDeviceAttributes,
      'ai_abilities': aiAbilities,
      'extends': extendAbilities,
    };
  }
}

class Thumbnail {
  String? url;
  int? updateAt;

  Thumbnail({this.url, this.updateAt});

  factory Thumbnail.fromJson(Map<String, dynamic> json) {
    return Thumbnail(
      url: json['image_path'] as String?,
      updateAt: json['event_time'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'image_path': url,
      'event_time': updateAt,
    };
  }
}

class Timezone {
  String? timezone;
  String? deviceTime;

  Timezone({this.timezone, this.deviceTime});

  factory Timezone.fromJson(Map<String, dynamic> json) {
    return Timezone(
      timezone: json['tz'] as String?,
      deviceTime: json['time'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tz': timezone,
      'time': deviceTime,
    };
  }
}

class OnlineStatus {
  bool? isOnline = false;
  int? onlineAt;
  int? offlineAt;

  OnlineStatus({this.isOnline, this.onlineAt, this.offlineAt});

  factory OnlineStatus.fromJson(Map<String, dynamic> json) {
    return OnlineStatus(
      isOnline: json['is_online'] as bool?,
      onlineAt: json['up_at'] as int?,
      offlineAt: json['down_at'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'is_online': isOnline,
      'up_at': onlineAt,
      'down_at': offlineAt,
    };
  }
}

class BatteryStatus {
  int? level;
  bool? isLow;
  bool? isCharging;

  BatteryStatus({this.level, this.isLow, this.isCharging});

  factory BatteryStatus.fromJson(Map<String, dynamic> json) {
    return BatteryStatus(
      level: json['qoe'] as int?,
      isLow: json['is_qoe_low'] as bool?,
      isCharging: json['is_charging'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'qoe': level,
      'is_qoe_low': isLow,
      'is_charging': isCharging,
    };
  }
}
