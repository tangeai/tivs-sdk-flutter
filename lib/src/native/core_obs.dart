part of 'library.dart';

enum ObsLevel { info, warn, error }

class ObsEvent {
  final String id;
  final String group;
  final String label;
  final ObsLevel level;
  final String deviceId;
  final int timestamp;
  final String ext;

  ObsEvent({
    required this.id,
    required this.group,
    required this.label,
    required this.level,
    required this.deviceId,
    required this.timestamp,
    required this.ext,
  });
}

class RenderPerfStage {
  final String name;
  final int duration;

  RenderPerfStage({
    required this.name,
    required this.duration,
  });

  factory RenderPerfStage.fromJson(Map<String, dynamic> json) {
    return RenderPerfStage(
      name: json['name'] ?? '',
      duration: json['duration'] ?? 0,
    );
  }
}

class RenderPerfStats {
  final String deviceId;
  final int startAt;
  final int completedAt;
  final int totalDuration;
  final List<RenderPerfStage> stages;

  RenderPerfStats({
    required this.deviceId,
    required this.startAt,
    required this.completedAt,
    required this.totalDuration,
    required this.stages,
  });

  factory RenderPerfStats.fromJson(Map<String, dynamic> json) {
    final stagesJson = json['stages'] as List<dynamic>? ?? [];
    final stages = stagesJson.map((stage) => RenderPerfStage.fromJson(stage)).toList();

    return RenderPerfStats(
      deviceId: json['device_id'] ?? '',
      startAt: json['start_at'] ?? 0,
      completedAt: json['completed_at'] ?? 0,
      totalDuration: json['total_duration'] ?? 0,
      stages: stages,
    );
  }
}

class RapidNativeObservability {
  static int _nextSeq = 1;
  static final List<ObsEvent> _cache = [];

  static void reset() {
    _nextSeq = 1;
    _cache.clear();
  }

  static bool poll(String deviceId) {
    final int seqBefore = _nextSeq;
    final int cacheBefore = _cache.length;

    final deviceIdC = deviceId.toNativeUtf8();
    final ptr = coreApiObsBinding.RAPID_Obs_PullEvents(deviceIdC, _nextSeq);
    calloc.free(deviceIdC);

    if (ptr == nullptr || ptr.address == 0) {
      return false;
    }

    final jsonStr = ptr.toDartString();
    coreApiObsBinding.RAPID_Obs_FreeString(ptr);

    try {
      final obj = jsonDecode(jsonStr);
      if (obj is! Map<String, dynamic>) {
        return false;
      }

      final events = obj['events'];
      final nextSeq = obj['next_seq'];
      final gapDetected = obj['gap_detected'];

      if (nextSeq is int && nextSeq > 0) {
        _nextSeq = nextSeq;
      }

      if (gapDetected is bool && gapDetected) {
        _cache.clear();
      }

      if (events is List) {
        for (final e in events) {
          if (e is! Map<String, dynamic>) continue;

          final int levelInt = (e['level'] is int) ? e['level'] as int : 0;
          final ObsLevel level = (levelInt >= 0 && levelInt < ObsLevel.values.length)
              ? ObsLevel.values[levelInt]
              : ObsLevel.info;

          final int tsMs = (e['ts_ms'] is int) ? e['ts_ms'] as int : 0;
          final String domain = (e['domain'] ?? '').toString();
          final String code = (e['code'] ?? '').toString();
          final String summary = (e['summary'] ?? '').toString();
          final String device = (e['device_id'] ?? '').toString();
          final ctx = e['context'];
          final String ctxStr = (ctx is Map<String, dynamic>) ? jsonEncode(ctx) : '';

          final event = ObsEvent(
            id: (e['seq'] ?? '').toString(),
            group: domain,
            label: summary.isNotEmpty ? summary : code,
            level: level,
            deviceId: device,
            timestamp: tsMs,
            ext: ctxStr.isNotEmpty ? ctxStr : code,
          );

          _cache.add(event);
        }

        if (_cache.length > 200) {
          _cache.removeRange(0, _cache.length - 200);
        }
      }
    } catch (_) {
      return false;
    }

    return _nextSeq != seqBefore || _cache.length != cacheBefore;
  }

  static List<ObsEvent> all(String deviceId) {
    if (deviceId.isEmpty) {
      return List<ObsEvent>.from(_cache);
    }
    return _cache.where((e) => e.deviceId == deviceId).toList(growable: false);
  }

  static ObsEvent? latest(String deviceId) {
    if (_cache.isEmpty) {
      return null;
    }

    if (deviceId.isEmpty) {
      return _cache.last;
    }

    for (int i = _cache.length - 1; i >= 0; --i) {
      final event = _cache[i];
      if (event.deviceId == deviceId) {
        return event;
      }
    }
    return null;
  }

  static RenderPerfStats? getRenderPerf(String deviceId) {
    // Deprecated: render startup metrics now comes from media metrics JSON.
    return null;
  }

  static void clear(String deviceId) {
    if (deviceId.isEmpty) {
      _cache.clear();
      return;
    }
    _cache.removeWhere((e) => e.deviceId == deviceId);
  }

}
