import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class CloudReplayDeviceTimeZone {
  final String rawValue;
  final int _fixedOffsetSeconds;
  final tz.Location? _location;

  const CloudReplayDeviceTimeZone._(
      {required int fixedOffsetSeconds,
      required this.rawValue,
      tz.Location? location})
      : _fixedOffsetSeconds = fixedOffsetSeconds,
        _location = location;

  factory CloudReplayDeviceTimeZone.local() => CloudReplayDeviceTimeZone._(
      fixedOffsetSeconds: DateTime.now().timeZoneOffset.inSeconds,
      rawValue: DateTime.now().timeZoneName);

  static bool _timeZoneDatabaseInitialized = false;

  int get offsetSeconds => _location == null
      ? _fixedOffsetSeconds
      : dateTimeFromEpochMilliseconds(DateTime.now().millisecondsSinceEpoch)
          .timeZoneOffset
          .inSeconds;

  static CloudReplayDeviceTimeZone? parse(
    String? rawValue, {
    String? deviceTime,
    DateTime? currentUtc,
  }) {
    if (rawValue == null || rawValue.trim().isEmpty) return null;
    _initializeTimeZoneDatabase();
    final candidates = rawValue
        .split(',')
        .map((candidate) => candidate.trim())
        .where((candidate) => candidate.isNotEmpty)
        .toList();
    for (final candidate in candidates.reversed) {
      if (!candidate.contains('/')) continue;
      try {
        return CloudReplayDeviceTimeZone._(
          fixedOffsetSeconds: 0,
          rawValue: rawValue,
          location: tz.getLocation(candidate),
        );
      } on tz.LocationNotFoundException {
        continue;
      }
    }
    for (final candidate in candidates) {
      final match = RegExp(r'^(?:GMT|UTC)?([+-])(\d{1,2})(?::?(\d{2}))?$',
              caseSensitive: false)
          .firstMatch(candidate);
      if (match == null) continue;
      final hours = int.parse(match.group(2)!);
      final minutes = int.tryParse(match.group(3) ?? '0') ?? 0;
      if (hours > 23 || minutes > 59) continue;
      final sign = match.group(1) == '+' ? 1 : -1;
      return CloudReplayDeviceTimeZone._(
          fixedOffsetSeconds: sign * (hours * 3600 + minutes * 60),
          rawValue: rawValue);
    }
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})',
    ).firstMatch(deviceTime ?? '');
    if (match == null) return null;
    final parsedDeviceTime = DateTime.utc(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
    final offsetSeconds = (parsedDeviceTime
                    .difference(currentUtc ?? DateTime.now().toUtc())
                    .inSeconds /
                900)
            .round() *
        900;
    if (offsetSeconds.abs() > 24 * 3600) return null;
    return CloudReplayDeviceTimeZone._(
      fixedOffsetSeconds: offsetSeconds,
      rawValue: rawValue,
    );
  }

  static void _initializeTimeZoneDatabase() {
    if (_timeZoneDatabaseInitialized) return;
    tz_data.initializeTimeZones();
    _timeZoneDatabaseInitialized = true;
  }

  DateTime dateTimeFromEpochMilliseconds(int timestampInMs) {
    final location = _location;
    if (location != null) {
      return tz.TZDateTime.fromMillisecondsSinceEpoch(location, timestampInMs);
    }
    return DateTime.fromMillisecondsSinceEpoch(
      timestampInMs + _fixedOffsetSeconds * 1000,
      isUtc: true,
    );
  }

  String formatTimeMilliseconds(int timestampInMs) {
    final value = dateTimeFromEpochMilliseconds(timestampInMs);
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}';
  }

  String formatFileTimestamp(int timestampInMs) {
    final value = dateTimeFromEpochMilliseconds(timestampInMs);
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}-${value.hour.toString().padLeft(2, '0')}-${value.minute.toString().padLeft(2, '0')}-${value.second.toString().padLeft(2, '0')}';
  }
}

class CloudReplayTimeZone {
  final Duration offset;
  final CloudReplayDeviceTimeZone? _deviceZone;
  final String rawValue;
  final String source;

  const CloudReplayTimeZone({
    required this.offset,
    required this.rawValue,
    required this.source,
    CloudReplayDeviceTimeZone? deviceZone,
  }) : _deviceZone = deviceZone;

  factory CloudReplayTimeZone.clientLocal() {
    return CloudReplayTimeZone(
      offset: DateTime.now().timeZoneOffset,
      rawValue: DateTime.now().timeZoneName,
      source: 'client',
    );
  }

  static CloudReplayTimeZone resolve({
    required String? rawValue,
    String? deviceTime,
    DateTime? nowUtc,
    Duration? fallbackOffset,
  }) {
    final raw = rawValue?.trim() ?? '';
    final deviceZone = CloudReplayDeviceTimeZone.parse(raw);
    if (deviceZone?._location != null) {
      return CloudReplayTimeZone(
        offset: Duration(seconds: deviceZone!.offsetSeconds),
        rawValue: raw,
        source: 'iana',
        deviceZone: deviceZone,
      );
    }
    for (final candidate in raw.split(',')) {
      final offset = _parseFixedOffset(candidate.trim());
      if (offset != null) {
        return CloudReplayTimeZone(
          offset: offset,
          rawValue: raw,
          source: 'fixed_offset',
        );
      }
    }

    final inferredOffset = _inferOffsetFromDeviceTime(
      deviceTime,
      (nowUtc ?? DateTime.now().toUtc()).toUtc(),
    );
    if (inferredOffset != null) {
      return CloudReplayTimeZone(
        offset: inferredOffset,
        rawValue: raw,
        source: 'device_time',
      );
    }

    return CloudReplayTimeZone(
      offset: fallbackOffset ?? DateTime.now().timeZoneOffset,
      rawValue: raw,
      source: 'client_fallback',
    );
  }

  DateTime fromEpochMilliseconds(int timestampInMs) {
    if (_deviceZone != null) {
      return _deviceZone!.dateTimeFromEpochMilliseconds(timestampInMs);
    }
    return DateTime.fromMillisecondsSinceEpoch(timestampInMs, isUtc: true)
        .add(offset);
  }

  DateTime now([DateTime? utcNow]) {
    return fromEpochMilliseconds(
        (utcNow ?? DateTime.now().toUtc()).millisecondsSinceEpoch);
  }

  String formatTimestamp(int timestampInMs) {
    final value = fromEpochMilliseconds(timestampInMs);
    return '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}:${_twoDigits(value.second)}';
  }

  String formatFileTimestamp(int timestampInMs) {
    final value = fromEpochMilliseconds(timestampInMs);
    return '${value.year.toString().padLeft(4, '0')}-'
        '${_twoDigits(value.month)}-${_twoDigits(value.day)}-'
        '${_twoDigits(value.hour)}-${_twoDigits(value.minute)}-'
        '${_twoDigits(value.second)}';
  }

  static Duration? _parseFixedOffset(String value) {
    final match = RegExp(
      r'^(?:GMT|UTC)?\s*([+-])(\d{1,2})(?::?(\d{2}))?$',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) return null;

    final hours = int.parse(match.group(2)!);
    final minutes = int.parse(match.group(3) ?? '0');
    if (hours > 23 || minutes > 59) return null;

    final totalMinutes = hours * 60 + minutes;
    return Duration(
      minutes: match.group(1) == '-' ? -totalMinutes : totalMinutes,
    );
  }

  static Duration? _inferOffsetFromDeviceTime(
    String? deviceTime,
    DateTime nowUtc,
  ) {
    if (deviceTime == null || deviceTime.trim().isEmpty) return null;
    final normalized = deviceTime.trim().replaceFirst(' ', 'T');
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) return null;

    final wallClockAsUtc = DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
    );
    final rawMinutes = wallClockAsUtc.difference(nowUtc).inMinutes;
    final roundedMinutes = (rawMinutes / 15).round() * 15;
    if (roundedMinutes < -23 * 60 - 59 || roundedMinutes > 23 * 60 + 59) {
      return null;
    }
    return Duration(minutes: roundedMinutes);
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class CloudReplayCompletionPolicy {
  static bool matchesActiveRecord({
    required bool recordSelected,
    required int startTimestampInMs,
    required int endTimestampInMs,
    required int lastPresentedTimestampInMs,
    int toleranceInMs = 2000,
  }) {
    if (!recordSelected ||
        startTimestampInMs <= 0 ||
        endTimestampInMs <= startTimestampInMs ||
        lastPresentedTimestampInMs < startTimestampInMs) {
      return false;
    }
    return (endTimestampInMs - lastPresentedTimestampInMs).abs() <=
        toleranceInMs;
  }
}
