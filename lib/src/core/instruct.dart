part of 'library.dart';

class RemoteIpConfig {
  final String intf;
  final int enableDhcp;
  final String ip;
  final String netmask;
  final String gateway;
  final String dns1;
  final String dns2;
  final String mac;
  RemoteIpConfig(this.intf, this.enableDhcp, this.ip, this.netmask,
      this.gateway, this.dns1, this.dns2, this.mac);
}

class ActiveNetworkState {
  final int type;
  final int signal;
  ActiveNetworkState(this.type, this.signal);
}

class BatteryState {
  final int mode;
  final int power;
  final int low;
  BatteryState(this.mode, this.power, this.low);
}

class AiState {
  final int mask;
  final int flags;
  AiState(this.mask, this.flags);
}

class StorageState {
  final int total;
  final int free;
  StorageState(this.total, this.free);
}

class VolumeState {
  final int volume;
  final int rangeKnown;
  VolumeState(this.volume, this.rangeKnown);
}

class MotionTrackingState {
  final int mode;
  final int support;
  MotionTrackingState(this.mode, this.support);
}

class MicrophoneSensitivity {
  final int supportRange;
  final int sensitivity;
  MicrophoneSensitivity(this.supportRange, this.sensitivity);
}

class RecordingProfile {
  final int recordType;
  final int recordQuality;
  RecordingProfile(this.recordType, this.recordQuality);
}

class NightVision {
  final int mode;
  final int support;
  NightVision(this.mode, this.support);
}

class MotionDetectState {
  final int enabled;
  final int sensitivity;
  MotionDetectState(this.enabled, this.sensitivity);
}

class MotionDetectRect {
  final int left;
  final int top;
  final int width;
  final int height;

  MotionDetectRect(this.left, this.top, this.width, this.height);

  factory MotionDetectRect.fromJson(Map<String, dynamic> value) =>
      MotionDetectRect(
        value["left"] as int? ?? 0,
        value["top"] as int? ?? 0,
        value["width"] as int? ?? 0,
        value["height"] as int? ?? 0,
      );

  Map<String, dynamic> toJson() =>
      {"left": left, "top": top, "width": width, "height": height};
}

class MotionDetectPoint {
  final int x;
  final int y;

  MotionDetectPoint(this.x, this.y);

  factory MotionDetectPoint.fromJson(Map<String, dynamic> value) =>
      MotionDetectPoint(value["x"] as int? ?? 0, value["y"] as int? ?? 0);

  Map<String, dynamic> toJson() => {"x": x, "y": y};
}

class MotionDetectPolygon {
  final List<MotionDetectPoint> points;

  MotionDetectPolygon(this.points);

  factory MotionDetectPolygon.fromJson(Map<String, dynamic> value) =>
      MotionDetectPolygon(
        (value["points"] as List? ?? const [])
            .map((item) => MotionDetectPoint.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
      );

  Map<String, dynamic> toJson() =>
      {"points": points.map((item) => item.toJson()).toList()};
}

class MotionDetectArea {
  final int channel;
  final bool enabled;
  final int sensitivity;
  final int areaType;
  final bool hasZone;
  final bool excludeZone;
  final bool supportsExcludeZone;
  final List<MotionDetectRect> rects;
  final List<MotionDetectPolygon> polygons;

  MotionDetectArea({
    this.channel = 0,
    required this.enabled,
    required this.sensitivity,
    required this.areaType,
    required this.hasZone,
    required this.excludeZone,
    this.supportsExcludeZone = false,
    this.rects = const [],
    this.polygons = const [],
  });

  factory MotionDetectArea.fromJson(Map<String, dynamic> value) =>
      MotionDetectArea(
        channel: value["channel"] as int? ?? 0,
        enabled: value["enabled"] as bool? ?? false,
        sensitivity: value["sensitivity"] as int? ?? 0,
        areaType: value["area_type"] as int? ?? 0,
        hasZone: value["has_zone"] as bool? ?? false,
        excludeZone: value["exclude_zone"] as bool? ?? false,
        supportsExcludeZone: value["supports_exclude_zone"] as bool? ?? false,
        rects: (value["rects"] as List? ?? const [])
            .map((item) => MotionDetectRect.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
        polygons: (value["polygons"] as List? ?? const [])
            .map((item) => MotionDetectPolygon.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        "channel": channel,
        "enabled": enabled,
        "sensitivity": sensitivity,
        "area_type": areaType,
        "has_zone": hasZone,
        "exclude_zone": excludeZone,
        "supports_exclude_zone": supportsExcludeZone,
        "rects": rects.map((item) => item.toJson()).toList(),
        "polygons": polygons.map((item) => item.toJson()).toList(),
      };
}

class OsdItem {
  final int id;
  final int flags;
  final int type;
  final int position;
  final int x;
  final int y;
  final int alignment;
  final String? data;
  final String? text;

  OsdItem({
    required this.id,
    required this.flags,
    required this.type,
    this.position = 0,
    this.x = 0,
    this.y = 0,
    this.alignment = 0,
    this.data,
    this.text,
  });

  factory OsdItem.fromJson(Map<String, dynamic> value) => OsdItem(
        id: value["id"] as int? ?? 0,
        flags: value["flags"] as int? ?? 0,
        type: value["type"] as int? ?? 0,
        position: value["position"] as int? ?? 0,
        x: value["x"] as int? ?? 0,
        y: value["y"] as int? ?? 0,
        alignment: value["alignment"] as int? ?? 0,
        data: value["data"] as String?,
        text: value["text"] as String?,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "flags": flags,
        "type": type,
        "position": position,
        "x": x,
        "y": y,
        "alignment": alignment,
        if (data != null) "data": data,
        if (text != null) "text": text,
      };
}

class OsdConfig {
  final int channel;
  final int supportedTypes;
  final int encoding;
  final int maxTextLength;
  final int maxItems;
  final List<OsdItem> items;

  OsdConfig({
    this.channel = 0,
    this.supportedTypes = 0,
    this.encoding = 0,
    this.maxTextLength = 32,
    this.maxItems = 0,
    this.items = const [],
  });

  factory OsdConfig.fromJson(Map<String, dynamic> value) => OsdConfig(
        channel: value["channel"] as int? ?? 0,
        supportedTypes: value["supported_types"] as int? ?? 0,
        encoding: value["encoding"] as int? ?? 0,
        maxTextLength: value["max_text_length"] as int? ?? 32,
        maxItems: value["max_items"] as int? ?? 0,
        items: (value["items"] as List? ?? const [])
            .map((item) =>
                OsdItem.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        "channel": channel,
        "items": items.map((item) => item.toJson()).toList()
      };
}

class CruiseAbility {
  final int channel;
  final int maxTracks;
  final int type;

  CruiseAbility(this.channel, this.maxTracks, this.type);
}

class CruiseTrack {
  final int trackNo;
  final List<int> presetPoints;
  final String name;
  final int action;

  CruiseTrack(this.trackNo, this.presetPoints,
      {this.name = "", this.action = 0});

  factory CruiseTrack.fromJson(Map<String, dynamic> value) => CruiseTrack(
        value["track_no"] as int? ?? 0,
        (value["preset_points"] as List? ?? const []).cast<int>(),
        name: value["name"] as String? ?? "",
        action: value["action"] as int? ?? 0,
      );
}

class CruiseTracks {
  final int channel;
  final int type;
  final int stayTime;
  final int activeTrack;
  final List<CruiseTrack> tracks;

  CruiseTracks(
      this.channel, this.type, this.stayTime, this.activeTrack, this.tracks);
}

class TimedCruiseItem {
  final int timerTrackNo;
  final int repeatWeek;
  final int startHour;
  final int startMinute;
  final int startSecond;
  final int endHour;
  final int endMinute;
  final int endSecond;
  final int trackNo;
  final int trackInterval;

  TimedCruiseItem({
    required this.timerTrackNo,
    required this.repeatWeek,
    required this.startHour,
    required this.startMinute,
    required this.startSecond,
    required this.endHour,
    required this.endMinute,
    required this.endSecond,
    required this.trackNo,
    required this.trackInterval,
  });

  factory TimedCruiseItem.fromJson(Map<String, dynamic> value) =>
      TimedCruiseItem(
        timerTrackNo: value["timer_track_no"] as int? ?? 0,
        repeatWeek: value["repeat_week"] as int? ?? 0,
        startHour: value["start_hour"] as int? ?? 0,
        startMinute: value["start_minute"] as int? ?? 0,
        startSecond: value["start_second"] as int? ?? 0,
        endHour: value["end_hour"] as int? ?? 0,
        endMinute: value["end_minute"] as int? ?? 0,
        endSecond: value["end_second"] as int? ?? 0,
        trackNo: value["track_no"] as int? ?? 0,
        trackInterval: value["track_interval"] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "timer_track_no": timerTrackNo,
        "repeat_week": repeatWeek,
        "start_hour": startHour,
        "start_minute": startMinute,
        "start_second": startSecond,
        "end_hour": endHour,
        "end_minute": endMinute,
        "end_second": endSecond,
        "track_no": trackNo,
        "track_interval": trackInterval,
      };
}

class TimedCruise {
  final int channel;
  final int action;
  final List<TimedCruiseItem> items;

  TimedCruise(this.action, this.items, {this.channel = 0});

  factory TimedCruise.fromJson(Map<String, dynamic> value) => TimedCruise(
        value["action"] as int? ?? 0,
        (value["items"] as List? ?? const [])
            .map((item) => TimedCruiseItem.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
        channel: value["channel"] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "channel": channel,
        "action": action,
        "items": items.map((item) => item.toJson()).toList(),
      };
}

class WatchPoint {
  final int channel;
  final int presetPointNo;
  final int idleTime;

  WatchPoint(this.presetPointNo, this.idleTime, {this.channel = 0});

  factory WatchPoint.fromJson(Map<String, dynamic> value) => WatchPoint(
        value["preset_point_no"] as int? ?? 0,
        value["idle_time"] as int? ?? 0,
        channel: value["channel"] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "channel": channel,
        "preset_point_no": presetPointNo,
        "idle_time": idleTime
      };
}

class Light {
  final int mode;
  final int support;
  Light(this.mode, this.support);
}

class RecordIndexPacket {
  final List<RecordIndex> list;
  final int total;
  RecordIndexPacket(this.total, this.list);
}

class RecordIndex {
  final int startTimestampSecond;
  final int endTimestampSecond;
  final int durationSecond;
  final int eventType;
  final int eventTimestampSecond;
  RecordIndex(this.startTimestampSecond, this.endTimestampSecond,
      this.durationSecond, this.eventType, this.eventTimestampSecond);
}

class RecordDate {
  final int year;
  final int month;
  final int day;
  RecordDate(this.year, this.month, this.day);
}

class RecordDatesPacket {
  final List<RecordDate>? list;
  final int total;
  RecordDatesPacket(this.total, this.list);
}

class Picture {
  final int mode;
  Picture(this.mode);
}

class CurrentWifi {
  final String ssid;
  final int signal;
  CurrentWifi(this.ssid, this.signal);
}

class FeedingSpec {
  final int maxServingCount;
  final int maxTimerCount;
  FeedingSpec(this.maxServingCount, this.maxTimerCount);
}

class FeedingSchedule {
  final List<FeedingTimer>? list;
  final int total;
  FeedingSchedule(this.total, this.list);
}

class NearbyWifi {
  final String ssid;
  final int signal;
  final int mode;
  final int enctype;
  final int status;
  NearbyWifi(this.ssid, this.signal, this.mode, this.enctype, this.status);
}

class NearbyWifiPacket {
  final List<NearbyWifi>? list;
  final int total;
  NearbyWifiPacket(this.total, this.list);
}

class TimePlan {
  final int startHour;
  final int startMinute;
  final int startSecond;
  final int endHour;
  final int endMinute;
  final int endSecond;
  final List<int> repeatDays;
  final int enabled;
  TimePlan(this.startHour, this.startMinute, this.startSecond, this.endHour,
      this.endMinute, this.endSecond, this.repeatDays, this.enabled);
}

class TimePlans {
  final List<TimePlan>? list;
  final int total;
  TimePlans(this.total, this.list);
}

class PowerStrategy {
  final int strategy;
  final int recLen;
  final int planCount;
  final List<TimePlan>? planList;
  PowerStrategy(this.strategy, this.recLen, this.planCount, this.planList);
}

class FeedingTimer {
  final int hour;
  final int minute;
  final int second;
  final List<int> repeatDays;
  final int servingCount;
  final int enabled;
  FeedingTimer(this.hour, this.minute, this.second, this.repeatDays,
      this.servingCount, this.enabled);
}

class Quality {
  final String label;
  final int value;
  Quality(this.label, this.value);
}

class Ability {
  final Map<String, dynamic>? features;
  final Map<String, dynamic>? settings;
  Ability(this.features, this.settings);
}

class RingtonePacket {
  final int id;
  final int type;
  final int format;
  final int codec;
  final String content;

  RingtonePacket(this.id, this.type, this.format, this.codec, this.content);
}

class RingtoneSpec {
  final int sampleRate;
  final int bitDepth;
  final int channels;
  final int id;
  final int limit;
  final List<int> format;
  final List<int> codec;

  RingtoneSpec(this.sampleRate, this.bitDepth, this.channels, this.id,
      this.limit, this.format, this.codec);
}

enum Direction { up, down, left, right, leftUp, leftDown, rightUp, rightDown }

class PtzPosition {
  final double x;
  final double y;
  final double z;
  final int presetIndex;
  PtzPosition(this.x, this.y, this.z, {this.presetIndex = 0});
}

enum PresetType { byIndex, byPosition, byIndexNoName, byPositionNoName }

class Coordinate {
  final double x;
  final double y;
  final double z;
  Coordinate(this.x, this.y, this.z);
}

class PresetAbility {
  final int max;
  final PresetType type;

  PresetAbility(this.max, this.type);
}

class PresetPoint {
  final PresetType type;
  final int index;
  final String? name;
  final Coordinate? coordinate;
  final int _flags;

  PresetPoint(this.type, this.index, {this.name, this.coordinate}) : _flags = 0;

  PresetPoint._internal(this.type, this.index,
      {int flags = 0, this.name, this.coordinate})
      : _flags = flags;
}

class PresetPointResp {
  final PresetType type;
  final List<PresetPoint>? array;

  PresetPointResp(this.type, this.array);
}

const String _keyFeature = "feature";
const String _keySetting = "setting";

class InstructStandard {
  static const int _successCode = 0;
  static const int _errorCode = -1;
  static const int _operationFailedCode = 20;
  static const int _platformErrorCode = 30;
  static const int _presetTypeByIndex = 1;
  static const int _presetTypeByPosition = 2;
  static const int _presetTypeByIndexNoName = 3;
  static const int _presetTypeByPositionNoName = 4;
  static const int _presetFlagCannotDelete = 0x08;

  InstructStandard._();

  static Future<Ret> _sendNoneParams(Pipe pipe, String name) async =>
      _parseCommonRetByCode(await _request(pipe, name, ""));

  static Ret _parseCommonRetByCode(Resp<Map<String, dynamic>> resp) {
    if (!resp.success) return Ret.error(resp.code ?? -1, resp.message ?? "");
    return Ret.success();
  }

  static Ret _parseCommonRet(Resp<Map<String, dynamic>> resp) {
    if (!resp.success) return Ret.error(resp.code ?? -1, resp.message ?? "");
    final result = resp.data?["result"] as int? ?? _errorCode;
    return result == _successCode
        ? Ret.success()
        : Ret.error(_operationFailedCode, "operation failed");
  }

  static Resp<T> _parseData<T>(Resp<Map<String, dynamic>> resp,
      T Function(Map<String, dynamic>) parser) {
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "");
    try {
      return Resp.success(parser(resp.data ?? <String, dynamic>{}));
    } catch (_) {
      return Resp.error(_operationFailedCode, "failed to parse response");
    }
  }

  static Future<Ret> keepAwake(Pipe pipe) async =>
      _sendNoneParams(pipe, "keep_awake");

  static Future<Ret> leaveAwake(Pipe pipe) async =>
      _sendNoneParams(pipe, "leave_awake");

  static Future<Resp<int>> startCallRaw(Pipe pipe,
      {required int flavor, int timeoutSecond = 30, String name = ''}) async {
    final resp = await _requestRaw(
        pipe,
        'start_call',
        <String, dynamic>{
          'flavor': flavor,
          'timeout_second': timeoutSecond,
          'name': name,
        }.json());
    final result = resp.data?['result'] as int? ?? -10000;
    if (resp.success || resp.data?.containsKey('result') == true) {
      return Resp.success(result);
    }
    return Resp.error(resp.code ?? -1, resp.message ?? '');
  }

  static Future<Ret> cancelCall(Pipe pipe) async =>
      _parseCommonRetByCode(await _request(pipe, 'cancel_call', ''));

  static Future<Ret> answerCall(Pipe pipe) async =>
      _parseCommonRetByCode(await _request(pipe, 'answer_call', ''));

  static Future<Ret> rejectCall(Pipe pipe) async =>
      _parseCommonRetByCode(await _request(pipe, 'reject_call', ''));

  static Future<Ret> hangupCall(Pipe pipe) async =>
      _parseCommonRetByCode(await _request(pipe, 'hangup_call', ''));

  static Future<Ret> ptzReset(Pipe pipe, {int channel = 0}) async {
    Map<String, dynamic> params = channel != 0
        ? <String, dynamic>{"channel": channel}
        : <String, dynamic>{};
    final resp = await _request(pipe, "ptz_reset", params.json());
    return _parseCommonRetByCode(resp);
  }

  static Future<Ret> ptzStopMoving(Pipe pipe, {int channel = 0}) async {
    Map<String, dynamic> params = channel != 0
        ? <String, dynamic>{"channel": channel}
        : <String, dynamic>{};
    final resp = await _request(pipe, "ptz_stop_moving", params.json());
    return _parseCommonRetByCode(resp);
  }

  static Future<Ret> ptzMoveByStep(Pipe pipe, Direction direction,
      {int channel = 0}) async {
    Map<String, dynamic> params = <String, dynamic>{
      "direction": direction.index,
    };
    if (channel != 0) params["channel"] = channel;
    final resp = await _request(pipe, "ptz_move_by_step", params.json());
    return _parseCommonRetByCode(resp);
  }

  static Future<Ret> ptzMoveByContinuous(Pipe pipe, Direction direction,
      {int channel = 0}) async {
    Map<String, dynamic> params = <String, dynamic>{
      "direction": direction.index,
    };
    if (channel != 0) params["channel"] = channel;
    final resp = await _request(pipe, "ptz_move_by_continuous", params.json());
    return _parseCommonRetByCode(resp);
  }

  static Future<Ret> sendPtzLongCmd(Pipe pipe,
      {required int control,
      int speed = 0,
      int point = 0,
      int limit = 0,
      int aux = 0,
      int channel = 0}) async {
    final values = <int>[control, speed, point, limit, aux, channel];
    if (values.any((value) => value < 0 || value > 255)) {
      return Ret.error(
          _platformErrorCode, "PTZ command values must be between 0 and 255");
    }
    final params = <String, dynamic>{
      "control": control,
      "speed": speed,
      "point": point,
      "limit": limit,
      "aux": aux,
      "channel": channel,
    };
    return _parseCommonRetByCode(
        await _request(pipe, "send_ptz_long_cmd", params.json()));
  }

  static Future<Ret> zoomInContinuous(Pipe pipe, {int channel = 0}) async {
    Map<String, dynamic> params = channel != 0
        ? <String, dynamic>{"channel": channel}
        : <String, dynamic>{};
    final resp = await _request(pipe, "zoom_in_continuous", params.json());
    return _parseCommonRetByCode(resp);
  }

  static Future<Ret> zoomOutContinuous(Pipe pipe, {int channel = 0}) async {
    Map<String, dynamic> params = channel != 0
        ? <String, dynamic>{"channel": channel}
        : <String, dynamic>{};
    final resp = await _request(pipe, "zoom_out_continuous", params.json());
    return _parseCommonRetByCode(resp);
  }

  static Future<Ret> zoomStop(Pipe pipe, {int channel = 0}) =>
      ptzStopMoving(pipe, channel: channel);

  static Future<Resp<double>> zoomRatio(Pipe pipe, {int channel = 0}) async {
    final resp = await currentPtzPosition(pipe, channel: channel);
    return resp.success
        ? Resp.success(resp.data?.z ?? 0.0)
        : Resp.error(resp.code ?? -1, resp.message ?? "");
  }

  static Future<Ret> setZoomRatio(Pipe pipe, double ratio,
          {int channel = 0}) async =>
      setPtzPosition(pipe, PtzPosition(-1.0, -1.0, ratio), channel: channel);

  static Future<Resp<List<Quality>>> quality(Pipe pipe) async {
    final resp = await _request(pipe, "quality", '');
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "");

    final List<Quality> list = List<Quality>.empty(growable: true);
    final itemsList = resp.data!["items"] as List?;
    if (itemsList != null) {
      for (var item in itemsList) {
        final label = item["label"] as String? ?? "";
        final value = item["value"] as int? ?? 0;
        list.add(Quality(label, value));
      }
    }

    return Resp.success(list);
  }

  static Future<Ret> reboot(Pipe pipe) async => _sendNoneParams(pipe, "reboot");

  static Future<Ret> setAlarmRingtone(Pipe pipe, RingtonePacket packet) async {
    Map<String, dynamic> params = <String, dynamic>{
      "id": packet.id,
      "type": packet.type,
      "format": packet.format,
      "codec": packet.codec,
      "base64_content": packet.content,
    };
    final resp = await _request(pipe, "set_alarm_tone", params.json());
    return _parseCommonRetByCode(resp);
  }

  static Future<Resp<RingtoneSpec>> ringtoneSpec(Pipe pipe) async {
    final resp = await _request(pipe, "get_alarm_tone_spec", "");
    if (resp.success) {
      final sampleRate = resp.data!["audio_sample_rate"] as int? ?? 0;
      final bitDepth = resp.data!["audio_bit_depth"] as int? ?? 0;
      final channels = resp.data!["audio_channels"] as int? ?? 0;
      final currentRingtoneId = resp.data!["current_tone_id"] as int? ?? 0;
      final sizeLimit = resp.data!["audio_size_limit_kb"] as int? ?? 0;
      final format =
          (resp.data!["ExpectedFileFormats"] as List?)?.cast<int>() ?? <int>[];
      final codec =
          (resp.data!["SupportedAudioCodecs"] as List?)?.cast<int>() ?? <int>[];
      return Resp.success(RingtoneSpec(sampleRate, bitDepth, channels,
          currentRingtoneId, sizeLimit, format, codec));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  @Deprecated("Use 'ability()' instead")
  static Future<Resp<Map<String, dynamic>>> abilities(Pipe pipe) =>
      _request(pipe, "abilities", "");

  static Future<Resp<Ability>> ability(Pipe pipe) async {
    final response = await _request(pipe, "abilities", "");
    if (response.success && response.data is Map<String, dynamic>) {
      try {
        final map = response.data!;
        final f = map[_keyFeature] != null
            ? Map<String, dynamic>.from(map[_keyFeature] as Map)
            : null;
        final s = map[_keySetting] != null
            ? Map<String, dynamic>.from(map[_keySetting] as Map)
            : null;
        return Resp.success(Ability(f, s));
      } catch (e) {
        Logging.e("InstructStandard", "Error parsing ability: ${e.toString()}");
        return Resp.error(-1, e.toString());
      }
    }
    return Resp.error(response.code ?? -1, response.message ?? "");
  }

  @visibleForTesting
  static Map<String, dynamic> buildListRecordIndexParams(String date) {
    final dateTime = DateTime.parse('${date}T00:00:00Z');
    if (dateTime.toIso8601String().substring(0, 10) != date) {
      throw FormatException('Invalid date format', date);
    }
    return <String, dynamic>{
      "year": dateTime.year,
      "month": dateTime.month,
      "day": dateTime.day,
    };
  }

  static Future<Resp<RecordIndexPacket>> listRecords(
      Pipe pipe, String date) async {
    buildListRecordIndexParams(date);
    final query = RecordListQuery.shared(pipe);
    late final Resp<RecordIndexPacket> response;
    late final Resp<void> cleanup;
    try {
      response = await query.load(date);
    } finally {
      cleanup = await query.dispose();
    }
    return cleanup.success
        ? response
        : Resp.error(cleanup.code ?? 4, cleanup.message ?? 'Record query cleanup failed');
  }

  static Resp<RecordIndexPacket> _recordListResponse(Resp<Map<String, dynamic>> resp) {
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "");
    final total = resp.data!["total"] as int? ?? -1;
    final List<RecordIndex> list = List<RecordIndex>.empty(growable: true);
    final itemsList = resp.data!["items"] as List?;
    if (itemsList != null) {
      for (var item in itemsList) {
        final startTimestampSecond = item["start"] as int? ?? 0;
        final endTimestampSecond = item["end"] as int? ?? 0;
        final durationSecond = item["duration"] as int? ?? 0;
        final eventType = item["event"] as int? ?? 0;
        final eventTimestampSecond = item["event_ts"] as int? ?? 0;
        list.add(RecordIndex(startTimestampSecond, endTimestampSecond,
            durationSecond, eventType, eventTimestampSecond));
      }
    }

    return Resp.success(RecordIndexPacket(total, list));
  }

  static Future<Ret> setAlarmState(Pipe pipe, int state) async {
    Map<String, dynamic> params = <String, dynamic>{
      "enable": state,
    };

    final resp = await _request(pipe, "set_alarm_state", params.json());
    // force resp.data?["result"] to 0, because the response of set_alarm_state is not standard.
    resp.data?["result"] = 0;

    return _parseCommonRet(resp);
  }

  static Future<Resp<int>> pirSensitivity(Pipe pipe) async {
    final resp = await _request(pipe, "get_pir_sens", "");
    return resp.success
        ? Resp.success(resp.data!["sensitivity"] as int? ?? 0)
        : Resp.error(resp.code ?? -1, resp.message ?? "");
  }

  static Future<Ret> setPirSensitivity(Pipe pipe, int sensitivity) async {
    Map<String, dynamic> params = <String, dynamic>{
      "sensitivity": sensitivity,
    };
    final resp = await _request(pipe, "set_pir_sens", params.json());
    return _parseCommonRetByCode(resp);
  }

  static Future<Resp<int>> ledState(Pipe pipe) async {
    final resp = await _request(pipe, "get_led_state", "");
    return resp.success
        ? Resp.success(resp.data!["status"] as int? ?? 0)
        : Resp.error(resp.code ?? -1, resp.message ?? "");
  }

  static Future<Ret> setLedState(Pipe pipe, int state) async {
    Map<String, dynamic> params = <String, dynamic>{
      "status": state,
    };
    final resp = await _request(pipe, "set_led_state", params.json());
    return _parseCommonRetByCode(resp);
  }

  static Future<Resp<int>> primaryChannel(Pipe pipe) async {
    final resp = await _request(pipe, "get_primary_channel", "");
    return resp.success
        ? Resp.success(resp.data!["channel"] as int? ?? 0)
        : Resp.error(resp.code ?? -1, resp.message ?? "");
  }

  static Future<Ret> setPrimaryChannel(Pipe pipe, int channel) async {
    Map<String, dynamic> params = <String, dynamic>{
      "channel": channel,
    };
    final resp = await _request(pipe, "set_primary_channel", params.json());
    return _parseCommonRetByCode(resp);
  }

  static Future<Resp<int>> powerHz(Pipe pipe) async {
    final resp = await _request(pipe, "get_power_hz", "");
    return resp.success
        ? Resp.success(resp.data!["mode"] as int? ?? 0)
        : Resp.error(resp.code ?? -1, resp.message ?? "");
  }

  static Future<Ret> setPowerHz(Pipe pipe, int mode) async {
    Map<String, dynamic> params = <String, dynamic>{
      "mode": mode,
    };
    final resp = await _request(pipe, "set_power_hz", params.json());
    return _parseCommonRet(resp);
  }

  static Future<Resp<int>> eventState(Pipe pipe, int event) async {
    Map<String, dynamic> params = <String, dynamic>{
      "event": event,
    };

    final resp = await _request(pipe, "get_event_state", params.json());
    return resp.success
        ? Resp.success(resp.data!["enabled"] as int? ?? 0)
        : Resp.error(resp.code ?? -1, resp.message ?? "");
  }

  static Future<Ret> setEventState(Pipe pipe, int event, int enabled) async {
    Map<String, dynamic> params = <String, dynamic>{
      "event": event,
      "enabled": enabled,
    };
    final resp = await _request(pipe, "set_event_state", params.json());
    return _parseCommonRetByCode(resp);
  }

  static Future<Resp<int>> alarmState(Pipe pipe) async {
    final resp = await _request(pipe, "get_alarm_state", "");
    return resp.success
        ? Resp.success(resp.data!["status"] as int? ?? 0)
        : Resp.error(resp.code ?? -1, resp.message ?? "");
  }

  static Future<Ret> playAlarmSound(Pipe pipe, {int timeout = 60}) async =>
      _parseCommonRetByCode(await _request(pipe, "play_alarm_sound",
          <String, dynamic>{"timeout": timeout}.json()));

  static Future<Ret> feedPet(Pipe pipe, int servingCount) async {
    Map<String, dynamic> params = <String, dynamic>{
      "serving": servingCount,
    };

    final resp = await _request(pipe, "feed_pet", params.json());
    return _parseCommonRetByCode(resp);
  }

  static Future<Resp<FeedingSpec>> feedingSpec(Pipe pipe) async {
    final resp = await _request(pipe, "get_feed_config", "");
    if (resp.success) {
      final maxTimer = resp.data!["max_timers"] as int? ?? 0;
      final maxServing = resp.data!["max_servings"] as int? ?? 0;
      return Resp.success(FeedingSpec(maxServing, maxTimer));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Resp<TimePlans?>> shutdownPlans(Pipe pipe) async {
    final resp = await _request(pipe, "get_time_plan", "");
    if (resp.success) {
      final int planCount = resp.data!["plan_count"] as int? ?? 0;
      final List<TimePlan> list = List<TimePlan>.empty(growable: true);
      final itemsList = resp.data!["plan_list"] as List?;
      if (itemsList != null) {
        for (var item in itemsList) {
          final startHour = item["from_hour"] as int? ?? 0;
          final startMinute = item["from_minute"] as int? ?? 0;
          final startSecond = item["from_second"] as int? ?? 0;
          final endHour = item["to_hour"] as int? ?? 0;
          final endMinute = item["to_minute"] as int? ?? 0;
          final endSecond = item["to_second"] as int? ?? 0;
          final repeatDays =
              _getEnabledWeekDaysFromBitmask(item["day_mask"] as int? ?? 0);
          final enabled = item["enabled"] as int? ?? 0;
          list.add(TimePlan(startHour, startMinute, startSecond, endHour,
              endMinute, endSecond, repeatDays, enabled));
        }
      }
      return Resp.success(TimePlans(planCount, list));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Ret> setShutdownPlans(Pipe pipe, TimePlans plans) async {
    List<Map<String, dynamic>> list =
        List<Map<String, dynamic>>.empty(growable: true);
    for (TimePlan timer in plans.list ?? []) {
      list.add(<String, dynamic>{
        "from_hour": timer.startHour,
        "from_minute": timer.startMinute,
        "from_second": timer.startSecond,
        "to_hour": timer.endHour,
        "to_minute": timer.endMinute,
        "to_second": timer.endSecond,
        "day_mask": _bitmaskFromWeekDays(timer.repeatDays),
        "enabled": timer.enabled,
      });
    }

    Map<String, dynamic> params = <String, dynamic>{
      "plan_list": list,
      "plan_count": plans.total,
    };

    final resp = await _request(pipe, "set_time_plan", params.json());
    return _parseCommonRetByCode(resp);
  }

  static Future<Resp<FeedingSchedule?>> feedingSchedule(Pipe pipe) async {
    final resp = await _request(pipe, "get_feed_schedule", "");
    if (resp.success) {
      // resp.data looks like: {"code":0,"data":{"timer_count":2,"timer_list":[{"hour":1,"minute":1,"repeat":6,"second":1,"serving":10,"state":1},{"hour":2,"minute":2,"repeat":6,"second":2,"serving":2,"state":1}]}}
      final int timerCount = resp.data!["timer_count"] as int? ?? 0;
      final List<FeedingTimer> list = List<FeedingTimer>.empty(growable: true);
      final itemsList = resp.data!["timer_list"] as List?;
      if (itemsList != null) {
        for (var item in itemsList) {
          final hour = item["hour"] as int? ?? 0;
          final minute = item["minute"] as int? ?? 0;
          final second = item["second"] as int? ?? 0;
          final repeat = item["repeat"] as int? ?? 0;
          final serving = item["serving"] as int? ?? 0;
          final state = item["state"] as int? ?? 0;
          list.add(FeedingTimer(hour, minute, second,
              _getEnabledWeekDaysFromBitmask(repeat), serving, state));
        }
      }
      return Resp.success(FeedingSchedule(timerCount, list));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Resp<NearbyWifiPacket>> listNearbyWifi(Pipe pipe) async {
    final resp = await _request(pipe, "list_nearby_wifi", "");
    if (resp.success) {
      final number = resp.data!["number"] as int? ?? 0;
      final list = resp.data!["list"] as List?;
      final nearbyWifiList = List<NearbyWifi>.empty(growable: true);
      if (number > 0 && list != null && list.isNotEmpty) {
        for (int i = 0; i < number; i++) {
          final ssid = list[i]["ssid"] as String? ?? "";
          final signal = list[i]["signal"] as int? ?? 0;
          final mode = list[i]["mode"] as int? ?? 0;
          final enctype = list[i]["enctype"] as int? ?? 0;
          final status = list[i]["status"] as int? ?? 0;
          nearbyWifiList.add(NearbyWifi(ssid, signal, mode, enctype, status));
        }
        return Resp.success(NearbyWifiPacket(number, nearbyWifiList));
      } else {
        return Resp.success(NearbyWifiPacket(0, <NearbyWifi>[]));
      }
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Resp<RecordDatesPacket>> recordDates(Pipe pipe) async {
    final resp = await _request(pipe, "list_record_date", "");
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "");

    final count = resp.data!["count"] as int? ?? 0;
    final recordDatesList = List<RecordDate>.empty(growable: true);

    if (count <= 0) {
      return Resp.success(RecordDatesPacket(count, recordDatesList));
    }

    final list = resp.data!["list"] as List?;
    if (list == null || list.isEmpty) {
      return Resp.success(RecordDatesPacket(count, recordDatesList));
    }

    final actualCount = count < list.length ? count : list.length;
    for (int i = 0; i < actualCount; i++) {
      final item = list[i] as Map<String, dynamic>?;
      if (item == null) continue;

      final year = item["year"] as int? ?? 0;
      final month = item["month"] as int? ?? 0;
      final day = item["day"] as int? ?? 0;
      recordDatesList.add(RecordDate(year, month, day));
    }

    return Resp.success(RecordDatesPacket(count, recordDatesList));
  }

  static Future<Ret> setFeedingSchedule(
      Pipe pipe, FeedingSchedule schedule) async {
    List<Map<String, dynamic>> list =
        List<Map<String, dynamic>>.empty(growable: true);
    for (FeedingTimer timer in schedule.list ?? []) {
      list.add(<String, dynamic>{
        "hour": timer.hour,
        "minute": timer.minute,
        "second": timer.second,
        "repeat": _bitmaskFromWeekDays(timer.repeatDays),
        "serving": timer.servingCount,
        "enable": timer.enabled,
      });
    }

    Map<String, dynamic> params = <String, dynamic>{
      "timer_list": list,
      "timer_count": schedule.total,
    };

    final resp = await _request(pipe, "set_feed_schedule", params.json());
    return _parseCommonRetByCode(resp);
  }

  static List<int> _getEnabledWeekDaysFromBitmask(int bitmask) {
    List<int> enabledDays = [];

    for (int i = 0; i < 7; i++) {
      if ((bitmask & (1 << i)) != 0) {
        enabledDays.add(i);
      }
    }

    return enabledDays;
  }

  static int _bitmaskFromWeekDays(List<int> days) {
    int bitmask = 0;

    for (int day in days) {
      if (day >= 0 && day <= 6) {
        bitmask |= (1 << day);
      }
    }

    return bitmask;
  }

  static Future<Resp<Picture>> picture(Pipe pipe, {int channel = 0}) async {
    Map<String, dynamic> params = channel != 0
        ? <String, dynamic>{"channel": channel}
        : <String, dynamic>{};
    final resp = await _request(pipe, "get_picture_mode", params.json());
    if (resp.success) {
      return Resp.success(Picture(resp.data!["mode"] as int? ?? 0));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Resp<PtzPosition>> currentPtzPosition(Pipe pipe,
      {int channel = 0}) async {
    Map<String, dynamic> params = channel != 0
        ? <String, dynamic>{"channel": channel}
        : <String, dynamic>{};
    final resp = await _request(pipe, "get_ptz_position", params.json());
    if (resp.success) {
      return Resp.success(PtzPosition(resp.data!["x"] as double? ?? 0,
          resp.data!["y"] as double? ?? 0, resp.data!["z"] as double? ?? 0,
          presetIndex: resp.data!["psp_num"] as int? ?? 0));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Ret> setPtzPosition(Pipe pipe, PtzPosition position,
      {int channel = 0}) async {
    Map<String, dynamic> params = <String, dynamic>{
      "x": position.x,
      "y": position.y,
      "z": position.z,
    };
    if (channel != 0) params["channel"] = channel;

    final resp = await _request(pipe, "set_ptz_position", params.json());
    return _parseCommonRetByCode(resp);
  }

  static Future<Ret> turnToPreset(Pipe pipe, int presetIndex,
      {int channel = 0}) async {
    if (presetIndex <= 0) {
      return Ret.error(
          _platformErrorCode, "presetIndex must be greater than zero");
    }
    final params = <String, dynamic>{
      "preset_index": presetIndex,
      "channel": channel
    };
    return _parseCommonRetByCode(
        await _request(pipe, "turn_to_preset", params.json()));
  }

  static Future<Resp<PresetAbility>> presetSpec(Pipe pipe) async {
    final params = <String, dynamic>{"channel": 0};
    final resp = await _requestRaw(pipe, "get_preset_ability", params.json());
    if (!resp.success) {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }

    final data = resp.data ?? <String, dynamic>{};
    final type = _parsePresetType(data["type"] as int? ?? 0);
    if (type == null) {
      return Resp.error(_errorCode, "invalid preset type");
    }

    return Resp.success(PresetAbility(data["max_psp"] as int? ?? 0, type));
  }

  static Future<Resp<PresetPointResp>> allPresetPoints(Pipe pipe) async {
    final params = <String, dynamic>{"channel": 0};
    final resp = await _requestRaw(pipe, "list_preset_points", params.json());
    if (!resp.success) {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }

    final data = resp.data ?? <String, dynamic>{};
    final type = _parsePresetType(data["type"] as int? ?? 0);
    if (type == null) {
      return Resp.error(_errorCode, "invalid preset type");
    }

    final List<PresetPoint> list = List<PresetPoint>.empty(growable: true);
    final items = data["items"] as List?;
    if (items != null) {
      for (final item in items) {
        final point = _parsePresetPoint(type, item);
        list.add(point);
      }
    }

    return Resp.success(PresetPointResp(type, list));
  }

  static Future<Ret> updatePresetPoint(Pipe pipe, PresetPoint point) async {
    final resp = await _requestRaw(
        pipe, "set_preset_point", _presetPointParams(point).json());
    return _parseCommonRetByCode(resp);
  }

  static Future<Ret> deletePresetPoint(Pipe pipe, PresetPoint point) async {
    if ((point._flags & _presetFlagCannotDelete) != 0) {
      return Ret.error(_errorCode, "preset cannot delete");
    }

    final resp = await _requestRaw(
        pipe, "delete_preset_point", _presetPointParams(point).json());
    return _parseCommonRetByCode(resp);
  }

  static void setOnPresetPointReachedListener(
      LiveStream stream, ValueChanged<int>? listener) {
    if (listener == null) {
      stream.setExternalDataListener(null);
      return;
    }

    stream.setExternalDataListener(
        (int type, int data1, int data2, Uint8List? buffer) {
      if (type != 3) return;
      listener(data2);
    });
  }

  static Future<Resp<CurrentWifi>> currentWifi(Pipe pipe) async {
    final resp = await _request(pipe, "get_wifi_info", "");
    if (resp.success) {
      final ssid = resp.data!["ssid"] as String? ?? "";
      final signal = resp.data!["signal"] as int? ?? 0;
      return Resp.success(CurrentWifi(ssid, signal));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Resp<ActiveNetworkState>> currentNetworkState(Pipe pipe) async {
    final resp = await _request(pipe, "get_signal_level", "");
    if (resp.success) {
      final type = resp.data!["activeNetIntf"] as int? ?? 0;
      final signal = resp.data!["signalLevel"] as int? ?? 0;
      return Resp.success(ActiveNetworkState(type, signal));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Resp<BatteryState>> batteryState(Pipe pipe) async {
    final resp = await _request(pipe, "get_battery_state", "");
    if (resp.success) {
      return Resp.success(BatteryState(resp.data!["mode"] as int? ?? 0,
          resp.data!["power"] as int? ?? 0, resp.data!["low"] as int? ?? 0));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Resp<RemoteIpConfig>> remoteIpConfig(Pipe pipe) async {
    final resp = await _request(pipe, "get_ip_config", "");
    if (resp.success) {
      return Resp.success(RemoteIpConfig(
          resp.data!["intf"] as String? ?? "",
          resp.data!["bDhcpEnabled"] as int? ?? 0,
          resp.data!["ip"] as String? ?? "",
          resp.data!["netmask"] as String? ?? "",
          resp.data!["gateway"] as String? ?? "",
          resp.data!["dns1"] as String? ?? "",
          resp.data!["dns2"] as String? ?? "",
          resp.data!["mac"] as String? ?? ""));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Ret> setRemoteIpConfig(Pipe pipe, RemoteIpConfig config) async {
    Map<String, dynamic> params = <String, dynamic>{
      "intf": config.intf,
      "bDhcpEnabled": config.enableDhcp,
      "ip": config.ip,
      "netmask": config.netmask,
      "gateway": config.gateway,
      "dns1": config.dns1,
      "dns2": config.dns2,
      "mac": config.mac,
    };
    final resp = await _request(pipe, "set_ip_config", params.json());
    return _parseCommonRetByCode(resp);
  }

  static Future<Ret> setPicture(Pipe pipe, int mode, {int channel = 0}) async {
    Map<String, dynamic> params = <String, dynamic>{
      "mode": mode,
    };
    if (channel != 0) {
      params["channel"] = channel;
    }
    final resp = await _request(pipe, "set_picture_mode", params.json());
    return _parseCommonRet(resp);
  }

  static Future<Resp<Light>> light(Pipe pipe) async {
    final resp = await _request(pipe, "get_light_mode", "");
    if (resp.success) {
      final mode = resp.data!["mode"] as int? ?? 0;
      final support = resp.data!["support"] as int? ?? 0;
      return Resp.success(Light(mode, support));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Resp<MotionDetectState>> motionDetectState(Pipe pipe) async {
    final resp = await _request(pipe, "get_motion_detect_sensitivity", "");
    if (resp.success) {
      final enabled = resp.data!["enabled"] as int? ?? 0;
      final sensitivity = resp.data!["sensitivity"] as int? ?? 0;
      return Resp.success(MotionDetectState(enabled, sensitivity));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Ret> setMotionDetectState(
      Pipe pipe, int enabled, int sensitivity) async {
    Map<String, dynamic> params = <String, dynamic>{
      "enable": enabled,
      "sensitivity": sensitivity,
    };
    final resp =
        await _request(pipe, "set_motion_detect_sensitivity", params.json());
    return _parseCommonRet(resp);
  }

  static Future<Resp<int>> maxAwakeTime(Pipe pipe) async {
    final resp = await _request(pipe, "get_max_awake_time", "");
    return _parseData(resp, (data) => data["seconds"] as int? ?? 0);
  }

  static Future<Ret> setMaxAwakeTime(Pipe pipe, int seconds) async =>
      _parseCommonRetByCode(await _request(pipe, "set_max_awake_time",
          <String, dynamic>{"seconds": seconds}.json()));

  static Future<Resp<int>> screenDisplayTime(Pipe pipe) async {
    final resp = await _request(pipe, "get_screen_display_time", "");
    return _parseData(resp, (data) => data["seconds"] as int? ?? 0);
  }

  static Future<Ret> setScreenDisplayTime(Pipe pipe, int seconds) async =>
      _parseCommonRetByCode(await _request(pipe, "set_screen_display_time",
          <String, dynamic>{"seconds": seconds}.json()));

  static Future<Resp<OsdConfig>> osd(Pipe pipe, {int channel = 0}) async {
    final resp = await _request(
        pipe, "get_osd", <String, dynamic>{"channel": channel}.json());
    return _parseData(resp, OsdConfig.fromJson);
  }

  static Future<Ret> setOsd(Pipe pipe, OsdConfig config) async =>
      _parseCommonRetByCode(
          await _request(pipe, "set_osd", config.toJson().json()));

  static Future<Resp<MotionDetectArea>> motionDetectArea(Pipe pipe,
      {int channel = 0}) async {
    final resp = await _request(pipe, "get_motion_detect_area",
        <String, dynamic>{"channel": channel}.json());
    return _parseData(resp, MotionDetectArea.fromJson);
  }

  static Future<Ret> setMotionDetectArea(
          Pipe pipe, MotionDetectArea area) async =>
      _parseCommonRetByCode(
          await _request(pipe, "set_motion_detect_area", area.toJson().json()));

  static Future<Resp<bool>> motionDetectAreaVisible(Pipe pipe,
      {int channel = 0}) async {
    final resp = await _request(pipe, "get_motion_detect_area_visible",
        <String, dynamic>{"channel": channel}.json());
    return _parseData(resp, (data) => data["visible"] as bool? ?? false);
  }

  static Future<Ret> setMotionDetectAreaVisible(Pipe pipe, bool visible,
          {int channel = 0}) async =>
      _parseCommonRetByCode(await _request(
          pipe,
          "set_motion_detect_area_visible",
          <String, dynamic>{"visible": visible, "channel": channel}.json()));

  static Future<Resp<CruiseAbility>> cruiseAbility(Pipe pipe,
      {int channel = 0}) async {
    final resp = await _request(pipe, "get_cruise_ability",
        <String, dynamic>{"channel": channel}.json());
    return _parseData(
        resp,
        (data) => CruiseAbility(data["channel"] as int? ?? 0,
            data["max_tracks"] as int? ?? 0, data["type"] as int? ?? 0));
  }

  static Future<Resp<CruiseTracks>> cruiseTracks(Pipe pipe,
      {int channel = 0}) async {
    final resp = await _request(pipe, "list_cruise_tracks",
        <String, dynamic>{"channel": channel}.json());
    return _parseData(
        resp,
        (data) => CruiseTracks(
              data["channel"] as int? ?? 0,
              data["type"] as int? ?? 0,
              data["stay_time"] as int? ?? 0,
              data["active_track"] as int? ?? 0,
              (data["tracks"] as List? ?? const [])
                  .map((item) => CruiseTrack.fromJson(
                      Map<String, dynamic>.from(item as Map)))
                  .toList(),
            ));
  }

  static Map<String, dynamic> _cruiseTrackParams(
          CruiseTrack track, int type, int stayTime, int channel) =>
      {
        "channel": channel,
        "type": type,
        "stay_time": stayTime,
        "track_no": track.trackNo,
        "preset_points": track.presetPoints,
        "name": track.name,
      };

  static Future<Ret> setCruiseTrack(Pipe pipe, CruiseTrack track,
          {required int type, required int stayTime, int channel = 0}) async =>
      _parseCommonRetByCode(await _request(pipe, "set_cruise_track",
          _cruiseTrackParams(track, type, stayTime, channel).json()));

  static Future<Ret> deleteCruiseTrack(Pipe pipe, CruiseTrack track,
          {required int type, int channel = 0}) async =>
      _parseCommonRetByCode(await _request(pipe, "delete_cruise_track",
          _cruiseTrackParams(track, type, 0, channel).json()));

  static Future<Ret> startCruiseAutoScan(Pipe pipe, {int channel = 0}) async =>
      _parseCommonRetByCode(await _request(pipe, "start_cruise_auto_scan",
          <String, dynamic>{"channel": channel}.json()));

  static Future<Ret> selectCruiseTrack(Pipe pipe, int trackNo,
          {int channel = 0}) async =>
      _parseCommonRetByCode(await _request(pipe, "select_cruise_track",
          <String, dynamic>{"track_no": trackNo, "channel": channel}.json()));

  static Future<Resp<TimedCruise>> timedCruise(Pipe pipe,
      {int timerTrackNo = 0, int channel = 0}) async {
    final resp = await _request(
        pipe,
        "get_timed_cruise",
        <String, dynamic>{"timer_track_no": timerTrackNo, "channel": channel}
            .json());
    return _parseData(resp, TimedCruise.fromJson);
  }

  static Future<Ret> setTimedCruise(Pipe pipe, TimedCruise timedCruise) async =>
      _parseCommonRetByCode(await _request(
          pipe, "set_timed_cruise", timedCruise.toJson().json()));

  static Future<Ret> createTimedCruise(Pipe pipe, List<TimedCruiseItem> items,
          {int channel = 0}) async =>
      setTimedCruise(pipe, TimedCruise(1, items, channel: channel));

  static Future<Ret> updateTimedCruise(Pipe pipe, List<TimedCruiseItem> items,
          {int channel = 0}) async =>
      setTimedCruise(pipe, TimedCruise(2, items, channel: channel));

  static Future<Ret> deleteTimedCruise(Pipe pipe, List<TimedCruiseItem> items,
          {int channel = 0}) async =>
      setTimedCruise(pipe, TimedCruise(3, items, channel: channel));

  static Future<Resp<bool>> timedCruiseEnabled(Pipe pipe,
      {int channel = 0}) async {
    final resp = await _request(pipe, "get_timed_cruise_enabled",
        <String, dynamic>{"channel": channel}.json());
    return _parseData(resp, (data) => data["enabled"] as bool? ?? false);
  }

  static Future<Ret> setTimedCruiseEnabled(Pipe pipe, bool enabled,
          {int channel = 0}) async =>
      _parseCommonRetByCode(await _request(pipe, "set_timed_cruise_enabled",
          <String, dynamic>{"enabled": enabled, "channel": channel}.json()));

  static Future<Resp<WatchPoint>> watchPoint(Pipe pipe,
      {int channel = 0}) async {
    final resp = await _request(
        pipe, "get_watch_point", <String, dynamic>{"channel": channel}.json());
    return _parseData(resp, WatchPoint.fromJson);
  }

  static Future<Ret> setWatchPoint(Pipe pipe, WatchPoint watchPoint) async =>
      _parseCommonRetByCode(
          await _request(pipe, "set_watch_point", watchPoint.toJson().json()));

  static Future<Ret> setLight(Pipe pipe, int mode) async {
    Map<String, dynamic> params = <String, dynamic>{
      "mode": mode,
    };
    return (await _request(pipe, "set_light_mode", params.json())).toRet();
  }

  static Future<Ret> setNightVision(Pipe pipe, int mode) async {
    Map<String, dynamic> params = <String, dynamic>{
      "mode": mode,
    };
    final resp = await _request(pipe, "set_night_vision_mode", params.json());
    return _parseCommonRet(resp);
  }

  static Future<Resp<NightVision>> nightVision(Pipe pipe) async {
    final resp = await _request(pipe, "get_night_vision_mode", "");
    if (resp.success) {
      final mode = resp.data!["mode"] as int? ?? 0;
      final support = resp.data!["support"] as int? ?? 0;
      return Resp.success(NightVision(mode, support));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Resp<AiState>> currentAiState(Pipe pipe) async {
    final resp = await _request(pipe, "get_ai_state", "");
    if (resp.success) {
      return Resp.success(AiState(resp.data!["ait_mask"] as int? ?? 0,
          resp.data!["ai_flags"] as int? ?? 0));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Ret> setAiState(Pipe pipe, int mask, int flags) async {
    Map<String, dynamic> params = <String, dynamic>{
      "ait_mask": mask,
      "ai_flags": flags,
    };
    final resp = await _request(pipe, "set_ai_state", params.json());
    return _parseCommonRetByCode(resp);
  }

  static Future<Ret> storageFormat(Pipe pipe, {int timeout = 60}) async =>
      _parseCommonRetByCode(await _request(
          pipe, "card_format", <String, dynamic>{"timeout": timeout}.json()));

  static Future<Ret> setRecordingProfile(
      Pipe pipe, RecordingProfile profile) async {
    Map<String, dynamic> params = <String, dynamic>{
      "record_type": profile.recordType,
      "record_quality": profile.recordQuality,
    };
    final resp = await _request(pipe, "set_record_config", params.json());
    return _parseCommonRet(resp);
  }

  static Future<Resp<RecordingProfile>> recordingProfile(Pipe pipe) async {
    final resp = await _request(pipe, "get_record_config", "");
    if (resp.success) {
      final recordType = resp.data!["record_type"] as int? ?? 0;
      final recordQuality = resp.data!["record_quality"] as int? ?? 0;
      return Resp.success(RecordingProfile(recordType, recordQuality));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Ret> setDeviceSwitch(Pipe pipe, int status) async {
    Map<String, dynamic> params = <String, dynamic>{
      "status": status,
    };
    return (await _request(pipe, "set_device_switch", params.json())).toRet();
  }

  static Future<Resp<int>> deviceSwitch(Pipe pipe) async {
    final resp = await _request(pipe, "get_device_switch", "");
    if (resp.success) {
      return Resp.success(resp.data!["status"] as int? ?? 0);
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Ret> updateRemoteWifi(
      Pipe pipe, String ssid, String password) async {
    Map<String, dynamic> params = <String, dynamic>{
      "ssid": ssid,
      "password": password,
    };

    final resp = await _request(pipe, "set_wifi_info", params.json());
    if (!resp.success) return Ret.error(resp.code ?? -1, resp.message ?? "");
    return Ret.success();
  }

  static Future<Ret> setVolumeState(Pipe pipe, VolumeState volumeState) async {
    Map<String, dynamic> params = <String, dynamic>{
      "range": volumeState.rangeKnown,
      "volume": volumeState.volume,
    };

    final resp = await _request(pipe, "set_volume", params.json());
    return resp.toRet();
  }

  static Future<Resp<VolumeState>> volumeState(Pipe pipe) async {
    final resp = await _request(pipe, "get_volume", "");
    if (resp.success) {
      final supportRange = resp.data!["flags"] as int? ?? 0;
      final volume = resp.data!["volume"] as int? ?? 0;
      return Resp.success(VolumeState(volume, supportRange));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Resp<MotionTrackingState>> motionTrackingState(
      Pipe pipe) async {
    final resp = await _request(pipe, "get_motion_tracker", "");
    if (resp.success) {
      final mode = resp.data!["mode"] as int? ?? 0;
      final support = resp.data!["support"] as int? ?? 0;
      return Resp.success(MotionTrackingState(mode, support));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Ret> setMotionTrackingState(Pipe pipe, int mode) async {
    Map<String, dynamic> params = <String, dynamic>{
      "mode": mode,
    };
    return (await _request(pipe, "set_motion_tracker", params.json())).toRet();
  }

  static Future<Resp<int>> microphoneSwitch(Pipe pipe) async {
    final resp = await _request(pipe, "get_microphone_switch", "");
    if (resp.success) {
      final status = resp.data!["status"] as int? ?? 0;
      return Resp.success(status);
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Ret> setMicrophoneSwitch(Pipe pipe, int status) async {
    Map<String, dynamic> params = <String, dynamic>{
      "status": status,
    };
    return (await _request(pipe, "set_microphone_switch", params.json()))
        .toRet();
  }

  static Future<Resp<int>> microphoneSensitivity(Pipe pipe) async {
    final resp = await _request(pipe, "get_microphone_level", "");
    if (resp.success) {
      return Resp.success(resp.data!["sensitivity"] as int? ?? 0);
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Ret> setMicrophoneSensitivity(
      Pipe pipe, int sensitivity) async {
    Map<String, dynamic> params = <String, dynamic>{
      "sensitivity": sensitivity,
    };
    final resp = await _request(pipe, "set_microphone_level", params.json());
    return resp.toRet();
  }

  static Future<Resp<StorageState>> storageState(Pipe pipe) async {
    final resp = await _request(pipe, "card_state", "");
    if (resp.success) {
      final total = resp.data!["total"] as int? ?? 0;
      final free = resp.data!["free"] as int? ?? 0;
      return Resp.success(StorageState(total, free));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Resp<PowerStrategy>> powerStrategy(Pipe pipe) async {
    final resp = await _request(pipe, "get_power_strategy", "");
    if (resp.success) {
      final strategy = resp.data!["strategy"] as int? ?? 0;
      final recLen = resp.data!["rec_len"] as int? ?? 0;
      final planCount = resp.data!["plan_count"] as int? ?? 0;
      final List<TimePlan> list = List<TimePlan>.empty(growable: true);
      final itemsList = resp.data!["plan_list"] as List?;
      if (itemsList != null) {
        for (var item in itemsList) {
          final startHour = item["from_hour"] as int? ?? 0;
          final startMinute = item["from_minute"] as int? ?? 0;
          final startSecond = item["from_second"] as int? ?? 0;
          final endHour = item["to_hour"] as int? ?? 0;
          final endMinute = item["to_minute"] as int? ?? 0;
          final endSecond = item["to_second"] as int? ?? 0;
          final repeatDays =
              _getEnabledWeekDaysFromBitmask(item["day_mask"] as int? ?? 0);
          final enabled = item["enabled"] as int? ?? 0;
          list.add(TimePlan(startHour, startMinute, startSecond, endHour,
              endMinute, endSecond, repeatDays, enabled));
        }
      }
      return Resp.success(PowerStrategy(strategy, recLen, planCount, list));
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "");
    }
  }

  static Future<Ret> setPowerStrategy(
      Pipe pipe, PowerStrategy powerStrategy) async {
    List<Map<String, dynamic>> list =
        List<Map<String, dynamic>>.empty(growable: true);
    for (TimePlan plan in powerStrategy.planList ?? []) {
      list.add(<String, dynamic>{
        "from_hour": plan.startHour,
        "from_minute": plan.startMinute,
        "from_second": plan.startSecond,
        "to_hour": plan.endHour,
        "to_minute": plan.endMinute,
        "to_second": plan.endSecond,
        "day_mask": _bitmaskFromWeekDays(plan.repeatDays),
        "enabled": plan.enabled,
      });
    }

    Map<String, dynamic> params = <String, dynamic>{
      "strategy": powerStrategy.strategy,
      "rec_len": powerStrategy.recLen,
      "plan_count": powerStrategy.planCount,
      "plan_list": list,
    };

    final resp = await _request(pipe, "set_power_strategy", params.json());
    return _parseCommonRetByCode(resp);
  }

  static Future<Resp<Map<String, dynamic>>> _request(
      Pipe pipe, String name, String params) async {
    final resp = await _requestRaw(pipe, name, params);
    return resp.success
        ? Resp.success(resp.data ?? <String, dynamic>{})
        : Resp.error(resp.code ?? -1, resp.message ?? '');
  }

  static Future<Resp<Map<String, dynamic>>> _requestRaw(
      Pipe pipe, String name, String params) {
    final completer = Completer<Resp<Map<String, dynamic>>>();
    final nativeInstructStandard =
        RapidNativeInstructStandard(pipe._nativePipe);
    nativeInstructStandard.create();

    proxyListener(String response) {
      final jsonResponse = json.decode(response) as Map<String, dynamic>;
      final code = jsonResponse["code"] as int? ?? -1;
      final data =
          jsonResponse["data"] as Map<String, dynamic>? ?? <String, dynamic>{};
      completer.complete(
          code == 0 ? Resp.success(data) : Resp.error(code, "Instruction failed (code=$code)", data));
      nativeInstructStandard.destroy();
    }

    nativeInstructStandard.request(name, params, proxyListener);
    return completer.future;
  }

  static PresetType? _parsePresetType(int type) {
    switch (type) {
      case _presetTypeByIndex:
        return PresetType.byIndex;
      case _presetTypeByPosition:
        return PresetType.byPosition;
      case _presetTypeByIndexNoName:
        return PresetType.byIndexNoName;
      case _presetTypeByPositionNoName:
        return PresetType.byPositionNoName;
      default:
        return null;
    }
  }

  static int _presetTypeValue(PresetType type) {
    switch (type) {
      case PresetType.byIndex:
        return _presetTypeByIndex;
      case PresetType.byPosition:
        return _presetTypeByPosition;
      case PresetType.byIndexNoName:
        return _presetTypeByIndexNoName;
      case PresetType.byPositionNoName:
        return _presetTypeByPositionNoName;
    }
  }

  static bool _presetTypeHasName(PresetType type) =>
      type == PresetType.byIndex || type == PresetType.byPosition;

  static bool _presetTypeHasCoordinate(PresetType type) =>
      type == PresetType.byPosition || type == PresetType.byPositionNoName;

  static PresetPoint _parsePresetPoint(PresetType type, dynamic item) {
    final map = Map<String, dynamic>.from(item as Map);
    final coordinate = _presetTypeHasCoordinate(type)
        ? Coordinate(
            (map["x"] as num?)?.toDouble() ?? 0.0,
            (map["y"] as num?)?.toDouble() ?? 0.0,
            (map["z"] as num?)?.toDouble() ?? 0.0,
          )
        : null;

    return PresetPoint._internal(
      type,
      map["index"] as int? ?? 0,
      flags: map["flags"] as int? ?? 0,
      name: _presetTypeHasName(type) ? map["name"] as String? : null,
      coordinate: coordinate,
    );
  }

  static Map<String, dynamic> _presetPointParams(PresetPoint point) {
    final params = <String, dynamic>{
      "channel": 0,
      "type": _presetTypeValue(point.type),
      "index": point.index,
      "flags": point._flags,
    };

    if (_presetTypeHasName(point.type) && point.name != null) {
      params["name"] = point.name;
    }

    if (_presetTypeHasCoordinate(point.type) && point.coordinate != null) {
      params["coordinate"] = <String, dynamic>{
        "x": point.coordinate!.x,
        "y": point.coordinate!.y,
        "z": point.coordinate!.z,
      };
    }

    return params;
  }
}
