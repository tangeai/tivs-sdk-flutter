part of '../rapid_kit_sample_pages.dart';

enum CloudReplayTimelineDropReason {
  staleGeneration,
  beforeMinimum,
  afterMaximum,
  invalidPts,
  ptsRegression,
}

enum CloudReplayUtsAnomalyKind { regression, discontinuity }

class CloudReplayUtsAnomaly {
  final CloudReplayUtsAnomalyKind kind;
  final int previousTimestampInMs;
  final int timestampInMs;
  final int ptsDeltaInMs;
  final int utsDeltaInMs;
  final int count;

  const CloudReplayUtsAnomaly(
      {required this.kind,
      required this.previousTimestampInMs,
      required this.timestampInMs,
      required this.ptsDeltaInMs,
      required this.utsDeltaInMs,
      required this.count});
}

class CloudReplayTimelineDecision {
  final int? timestampInMs;
  final CloudReplayTimelineDropReason? dropReason;
  final bool firstAccepted;
  final int droppedCount;
  final CloudReplayUtsAnomaly? utsAnomaly;

  const CloudReplayTimelineDecision(
      {this.timestampInMs,
      this.dropReason,
      required this.firstAccepted,
      required this.droppedCount,
      this.utsAnomaly});
}

class CloudReplayTimelineState {
  static const int _maximumUtsDriftInMs = 500;
  static const int _uint32Mask = 0xffffffff;
  static const int _maximumForwardPtsDeltaInMs = 0x7fffffff;

  int generation = 0;
  int droppedCount = 0;
  int utsAnomalyCount = 0;
  int _endTimestampInMs = 0;
  int _minimumTimestampInMs = 0;
  int? _lastPresentedTimestampInMs;
  int? _lastPtsInMs;
  int? _lastUtsInMs;

  int begin(
      {required int startTimestampInMs,
      required int endTimestampInMs,
      required int minimumTimestampInMs}) {
    generation++;
    _endTimestampInMs = math.max(startTimestampInMs, endTimestampInMs);
    _minimumTimestampInMs = math.min(
        math.max(startTimestampInMs, minimumTimestampInMs), _endTimestampInMs);
    _lastPresentedTimestampInMs = _minimumTimestampInMs;
    _lastPtsInMs = null;
    _lastUtsInMs = null;
    droppedCount = 0;
    utsAnomalyCount = 0;
    return generation;
  }

  CloudReplayTimelineDecision evaluate(
      {required int ptsInMs,
      required int utsInMs,
      required int callbackGeneration}) {
    if (callbackGeneration != generation) {
      return _drop(CloudReplayTimelineDropReason.staleGeneration);
    }
    if (utsInMs < _minimumTimestampInMs) {
      return _drop(CloudReplayTimelineDropReason.beforeMinimum);
    }
    if (utsInMs > _endTimestampInMs) {
      return _drop(CloudReplayTimelineDropReason.afterMaximum);
    }
    if (ptsInMs <= 0) return _drop(CloudReplayTimelineDropReason.invalidPts);

    final lastPtsInMs = _lastPtsInMs;
    final lastUtsInMs = _lastUtsInMs;
    final lastPresentedTimestampInMs = _lastPresentedTimestampInMs;
    if (lastPtsInMs == null ||
        lastUtsInMs == null ||
        lastPresentedTimestampInMs == null) {
      _lastPtsInMs = ptsInMs;
      _lastUtsInMs = utsInMs;
      return CloudReplayTimelineDecision(
          timestampInMs: _minimumTimestampInMs,
          firstAccepted: true,
          droppedCount: droppedCount);
    }
    final ptsDeltaInMs = _ptsDeltaInMs(ptsInMs, lastPtsInMs);
    if (ptsDeltaInMs < 0) {
      return _drop(CloudReplayTimelineDropReason.ptsRegression);
    }

    final utsDeltaInMs = utsInMs - lastUtsInMs;
    CloudReplayUtsAnomaly? anomaly;
    if ((utsDeltaInMs - ptsDeltaInMs).abs() > _maximumUtsDriftInMs) {
      utsAnomalyCount++;
      anomaly = CloudReplayUtsAnomaly(
        kind: utsDeltaInMs < 0
            ? CloudReplayUtsAnomalyKind.regression
            : CloudReplayUtsAnomalyKind.discontinuity,
        previousTimestampInMs: lastUtsInMs,
        timestampInMs: utsInMs,
        ptsDeltaInMs: ptsDeltaInMs,
        utsDeltaInMs: utsDeltaInMs,
        count: utsAnomalyCount,
      );
    }
    final timestampInMs = (lastPresentedTimestampInMs +
            math.min(
                ptsDeltaInMs, _endTimestampInMs - lastPresentedTimestampInMs))
        .toInt();
    _lastPtsInMs = ptsInMs;
    _lastUtsInMs = utsInMs;
    _lastPresentedTimestampInMs = timestampInMs;
    return CloudReplayTimelineDecision(
        timestampInMs: timestampInMs,
        firstAccepted: false,
        droppedCount: droppedCount,
        utsAnomaly: anomaly);
  }

  CloudReplayTimelineDecision _drop(CloudReplayTimelineDropReason reason) {
    droppedCount++;
    return CloudReplayTimelineDecision(
        dropReason: reason, firstAccepted: false, droppedCount: droppedCount);
  }

  int _ptsDeltaInMs(int timestampInMs, int previousTimestampInMs) {
    final timestamp = timestampInMs & _uint32Mask;
    final previousTimestamp = previousTimestampInMs & _uint32Mask;
    final forwardDelta = (timestamp - previousTimestamp) & _uint32Mask;
    if (forwardDelta <= _maximumForwardPtsDeltaInMs) return forwardDelta;
    return -((previousTimestamp - timestamp) & _uint32Mask);
  }
}

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
