class Events {
  int? total;
  List<Event>? list;

  Events({this.total, this.list});

  factory Events.fromJson(Map<String, dynamic> json) {
    return Events(
      total: json['total'] as int?,
      list: (json['items'] as List<dynamic>?)?.map((dynamic item) {
        return Event.fromJson(item as Map<String, dynamic>);
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'total': total,
      'items': list?.map((item) => item.toJson()).toList(),
    };
  }
}

class Categories {
  List<Category>? list;

  Categories({this.list});

  factory Categories.fromJson(List<dynamic> json) {
    return Categories(
      list: json.map((dynamic item) => Category.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'items': list?.map((item) => item.toJson()).toList(),
    };
  }
}

class Event {
  String? id;
  String? deviceId;
  String? storageId;
  int? startTime;
  int? endTime;
  String? image;
  String? thumbnail;
  bool? containsVideo;
  EventDetail? detail;

  Event({
    this.id,
    this.deviceId,
    this.storageId,
    this.startTime,
    this.endTime,
    this.image,
    this.thumbnail,
    this.containsVideo,
    this.detail,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String?,
      deviceId: json['deviceId'] as String?,
      storageId: json['ossid'] as String?,
      startTime: json['time'] as int?,
      endTime: json['end_time'] as int?,
      image: json['image'] as String?,
      thumbnail: json['thumbnail'] as String?,
      containsVideo: json['can_play'] as bool?,
      detail: json['tag'] != null ? EventDetail.fromJson(json['tag'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'deviceId': deviceId,
      'ossid': storageId,
      'time': startTime,
      'end_time': endTime,
      'image': image,
      'thumbnail': thumbnail,
      'can_play': containsVideo,
      'tag': detail?.toJson(),
    };
  }
}

class EventDetail {
  String? categoryIcon;
  String? msg;
  String? categoryName;
  String? categoryLabel;
  Map<String, dynamic>? extra;

  EventDetail({
    this.categoryIcon,
    this.msg,
    this.categoryName,
    this.categoryLabel,
    this.extra,
  });

  factory EventDetail.fromJson(Map<String, dynamic> json) {
    return EventDetail(
      categoryIcon: json['icon'] as String?,
      msg: json['msg'] as String?,
      categoryName: json['name'] as String?,
      categoryLabel: json['tag'] as String?,
      extra: json['extra'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'icon': categoryIcon,
      'msg': msg,
      'name': categoryName,
      'tag': categoryLabel,
      'extra': extra,
    };
  }
}

// Category.dart
class Category {
  String? categoryLabel;
  String? categoryName;
  String? categoryType;

  Category({this.categoryLabel, this.categoryName, this.categoryType});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryLabel: json['tag'] as String?,
      categoryName: json['name'] as String?,
      categoryType: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tag': categoryLabel,
      'name': categoryName,
      'type': categoryType,
    };
  }
}

// LocalPushConfigure.dart
class LocalPushConfigure {
  bool? enable;
  int? interval;
  PushUndisturbed? undisturbed;
  List<String>? tagWhichNeedToPush;

  factory LocalPushConfigure.fromRemote(RemotePushConfigure remote) {
    return LocalPushConfigure(
      enable: remote.enable,
      interval: remote.interval,
      undisturbed: remote.undisturbed,
      tagWhichNeedToPush: remote.switcher?.where((element) => element.enable == true).map((e) => e.categoryLabel ?? "").toList(),
    );
  }

  LocalPushConfigure({this.enable, this.interval, this.undisturbed, this.tagWhichNeedToPush});

  factory LocalPushConfigure.fromJson(Map<String, dynamic> json) {
    return LocalPushConfigure(
      enable: json['global_status'] as bool?,
      interval: json['interval'] as int?,
      undisturbed: json['undisturbed'] != null ? PushUndisturbed.fromJson(json['undisturbed'] as Map<String, dynamic>) : null,
      tagWhichNeedToPush: (json['tag'] as List<dynamic>?)?.map((dynamic item) => item as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'global_status': enable,
      'interval': interval,
      'undisturbed': undisturbed?.toJson(),
      'tag': tagWhichNeedToPush,
    };
  }
}

class RemotePushConfigure {
  bool? enable;
  int? interval;
  PushUndisturbed? undisturbed;
  List<PushSwitch>? switcher;

  RemotePushConfigure({this.enable, this.interval, this.undisturbed, this.switcher});

  factory RemotePushConfigure.fromJson(Map<String, dynamic> json) {
    return RemotePushConfigure(
      enable: json['global_status'] as bool?,
      interval: json['interval'] as int?,
      undisturbed: json['undisturbed'] != null ? PushUndisturbed.fromJson(json['undisturbed'] as Map<String, dynamic>) : null,
      switcher: (json['item'] as List<dynamic>?)?.map((dynamic item) => PushSwitch.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'global_status': enable,
      'interval': interval,
      'undisturbed': undisturbed?.toJson(),
      'item': switcher?.map((item) => item.toJson()).toList(),
    };
  }
}

class PushSwitch {
  String? categoryLabel;
  String? categoryName;
  bool? enable;

  PushSwitch({this.categoryLabel, this.categoryName, this.enable});

  factory PushSwitch.fromJson(Map<String, dynamic> json) {
    return PushSwitch(
      categoryLabel: json['tag'] as String?,
      categoryName: json['name'] as String?,
      enable: json['status'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tag': categoryLabel,
      'name': categoryName,
      'status': enable,
    };
  }
}

class PushUndisturbed {
  String? start;
  String? end;
  bool? enable;

  PushUndisturbed({this.start, this.end, this.enable});

  factory PushUndisturbed.fromJson(Map<String, dynamic> json) {
    return PushUndisturbed(
      start: json['start'] as String?,
      end: json['end'] as String?,
      enable: json['status'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'start': start,
      'end': end,
      'status': enable,
    };
  }
}
