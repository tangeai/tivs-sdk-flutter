import 'package:flutter/foundation.dart';
import 'struct.dart';
import '../../native/library.dart';
import '../http/http_builder.dart';
export 'struct.dart';
export '../../struct/resp.dart';
export '../../struct/ret.dart';

class SpecServiceImpl {
  static Map<String, dynamic> _decodeMap(String? data) {
    if (data == null || data.isEmpty) return {};
    return json.decode(data) as Map<String, dynamic>;
  }

  static Future<Ret> rename(String deviceId, String newName) async {
    final resp = await Http.create().path("/v2/device/name").param("device_id", deviceId).param("name", newName).patch();
    return resp.toRet();
  }

  static Future<Ret> updateTimezone(String deviceId, String time, String zone) async {
    final resp = await Http.create().path("/v2/device/tz").param("device_id", deviceId).param("time", time).param("zone", zone).patch();
    return resp.toRet();
  }

  static Future<Resp<Map<String, BatteryStatus>>> battery(List<String> deviceList) async {
    String deviceListStr = deviceList.join(',');
    final resp = await Http.create().path('/v2/stats/battery').param('device_id', deviceListStr).post();

    if (resp.success) {
      Map<String, dynamic> jsonResponse = _decodeMap(resp.data);
      Map<String, BatteryStatus> map = {};
      jsonResponse.forEach((String key, dynamic value) {
        map[key] = BatteryStatus.fromJson(value as Map<String, dynamic>);
      });
      return Resp.success(map);
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Error");
    }
  }

  static Future<Resp<BatteryStatus>> requireSingleBatteryStatus(String deviceId) async {
    final mapResp = await battery([deviceId]);
    if (mapResp.success) {
      if (mapResp.data?.containsKey(deviceId) == true) {
        return Resp.success(mapResp.data![deviceId]!);
      } else {
        return Resp.error(mapResp.code ?? -1, mapResp.message ?? "No response for $deviceId");
      }
    } else {
      return Resp.error(mapResp.code ?? -1, mapResp.message ?? "Unknown Error");
    }
  }

  static Future<Resp<Map<String, OnlineStatus>>> requireOnlineStatus(List<String> deviceList) async {
    String deviceListStr = deviceList.join(',');
    final resp = await Http.create().path('/v2/device/online').param('device_id', deviceListStr).post();

    if (resp.success) {
      Map<String, dynamic> jsonResponse = _decodeMap(resp.data);
      Map<String, OnlineStatus> map = {};
      jsonResponse.forEach((String key, dynamic value) {
        map[key] = OnlineStatus.fromJson(value as Map<String, dynamic>);
      });
      return Resp.success(map);
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Error");
    }
  }

  static Future<Resp<OnlineStatus>> requireSingleOnlineStatus(String deviceId) async {
    final mapResp = await requireOnlineStatus([deviceId]);
    if (mapResp.success) {
      if (mapResp.data?.containsKey(deviceId) == true) {
        return Resp.success(mapResp.data![deviceId]!);
      } else {
        return Resp.error(mapResp.code ?? -1, mapResp.message ?? "No response for $deviceId");
      }
    } else {
      return Resp.error(mapResp.code ?? -1, mapResp.message ?? "Unknown Error");
    }
  }

  static Future<Resp<Map<String, Thumbnail>>> requireThumbnails(List<String> deviceList) async {
    String deviceListStr = deviceList.join(',');
    final resp = await Http.create().path('/v2/device/thumbnail').param('device_id', deviceListStr).post();

    if (resp.success) {
      Map<String, dynamic> jsonResponse = _decodeMap(resp.data);
      Map<String, Thumbnail> thumbnailMap = {};
      jsonResponse.forEach((String key, dynamic value) {
        thumbnailMap[key] = Thumbnail.fromJson(value as Map<String, dynamic>);
      });
      return Resp.success(thumbnailMap);
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Error");
    }
  }

  static Future<Resp<Thumbnail>> requireSingleThumbnail(String deviceId) async {
    final mapResp = await requireThumbnails([deviceId]);
    if (mapResp.success) {
      if (mapResp.data?.containsKey(deviceId) == true) {
        final thumbnail = mapResp.data![deviceId];
        return Resp.success(thumbnail!);
      } else {
        return Resp.error(mapResp.code ?? -1, mapResp.message ?? "No response for $deviceId");
      }
    } else {
      return Resp.error(mapResp.code ?? -1, mapResp.message ?? "Unknown Error");
    }
  }

  static Future<Resp<Map<String, Timezone>>> requireTimezone(List<String> deviceList) async {
    String deviceListStr = deviceList.join(',');
    final resp = await Http.create().path('/v2/device/tz').param('device_id', deviceListStr).post();

    if (resp.success) {
      Map<String, dynamic> jsonResponse = _decodeMap(resp.data);
      Map<String, Timezone> map = {};
      jsonResponse.forEach((String key, dynamic value) {
        map[key] = Timezone.fromJson(value as Map<String, dynamic>);
      });
      return Resp.success(map);
    } else {
      return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Error");
    }
  }

  static Future<Resp<Timezone>> requireSingleTimezone(String deviceId) async {
    final mapResp = await requireTimezone([deviceId]);
    if (mapResp.success) {
      if (mapResp.data?.containsKey(deviceId) == true) {
        return Resp.success(mapResp.data![deviceId]!);
      } else {
        return Resp.error(mapResp.code ?? -1, mapResp.message ?? "No response for $deviceId");
      }
    } else {
      return Resp.error(mapResp.code ?? -1, mapResp.message ?? "Unknown Error");
    }
  }

  static Future<Resp<Primary>> primary(String deviceId) async {
    final resp = await _primary(deviceId: deviceId);
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    if ((resp.data?.list?.length ?? 0) == 1) {
      return Resp.success(resp.data!.list![0]);
    } else {
      return Resp.error(-1, "No such device");
    }
  }

  static Future<Resp<PrimaryByPage>> primaryByPage({int offset = 0, int limit = 10, String? nameFilter = ""}) async {
    return _primary(offset: offset, limit: limit, nameFilter: nameFilter, deviceId: "");
  }

  static Future<Resp<PrimaryByPage>> _primary({int offset = 0, int limit = 10, String? nameFilter = "", String? deviceId = ""}) async {
    final resp = await Http.create()
        .path("/v2/device/list")
        .param("uuid", deviceId ?? "")
        .param("device_id", deviceId ?? "")
        .param("name", nameFilter ?? "")
        .param("offset", offset)
        .param("limit", limit)
        .post();
    if (!resp.success) return Resp.error(resp.code ?? -1, resp.message ?? "Unknown Server Error");
    final formatted = PrimaryByPage.fromJson(resp.data ?? "");

    if (formatted.list != null) {
      for (Primary basic in formatted.list!) {
        _prepareTokenAsync(basic.deviceId ?? "");
      }
    }
    return Resp.success(formatted);
  }

  static Future<void> _prepareTokenAsync(String deviceId) async => await compute(_prepareTokenInIsolate, deviceId);
  static void _prepareTokenInIsolate(String deviceId) => RapidNativePipe.prepareToken(deviceId);
}
