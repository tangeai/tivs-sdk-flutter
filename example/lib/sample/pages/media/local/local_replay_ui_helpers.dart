part of '../../rapid_kit_sample_pages.dart';

class LocalReplayUiHelpers {
  static const int secondsPerDay = 24 * 60 * 60;

  static bool isAovDeviceAbilities(String? deviceAbilities) {
    if (deviceAbilities == null || deviceAbilities.isEmpty) return false;
    try {
      final decoded = convert.jsonDecode(deviceAbilities);
      return decoded is Map && decoded['BatteryCam'] == 'AOV';
    } catch (_) {
      return false;
    }
  }

  static bool shouldShowConnectionError({
    required bool hasSelectedRecord,
    required bool establishFailed,
    required PipeState pipeState,
  }) {
    if (!hasSelectedRecord) return false;
    return establishFailed ||
        (pipeState != PipeState.attempting &&
            pipeState != PipeState.established);
  }

  static double timelinePlayheadY({
    required int secondOfDay,
    required double pixelsPerSecond,
    required double viewportHeight,
  }) {
    final second = secondOfDay.clamp(0, secondsPerDay - 1);
    final centerY = viewportHeight / 2;
    final distanceFromStart = second * pixelsPerSecond;
    final distanceFromEnd = (secondsPerDay - second) * pixelsPerSecond;
    return math.max(
      math.min(centerY, distanceFromStart),
      viewportHeight - distanceFromEnd,
    );
  }

  static int dayStartSecond(DateTime date) {
    return DateTime(date.year, date.month, date.day).millisecondsSinceEpoch ~/
        1000;
  }

  static bool isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static RecordIndex? firstPlayableRecord(
      List<RecordIndex> records, DateTime date) {
    final dayStart = dayStartSecond(date);
    final dayEnd =
        dayStartSecond(DateTime(date.year, date.month, date.day + 1));
    RecordIndex? first;
    for (final record in records) {
      if (record.startTimestampSecond <= 0 ||
          record.endTimestampSecond <= record.startTimestampSecond ||
          record.startTimestampSecond < dayStart ||
          record.startTimestampSecond >= dayEnd) {
        continue;
      }
      if (first != null &&
          first.startTimestampSecond <= record.startTimestampSecond) {
        continue;
      }
      first = record;
    }
    return first;
  }

  /// Returns the requested timestamp when it is covered by a recording.
  /// AOV timeline seeks bypass record ranges and use the selected timestamp.
  static int? resolvePlayableTimestamp(
      List<RecordIndex> records, DateTime date, int requestedTimestampSecond,
      {bool allowUnboundedAovDay = false}) {
    final dayStart = dayStartSecond(date);
    final dayEnd =
        dayStartSecond(DateTime(date.year, date.month, date.day + 1));
    final requested = requestedTimestampSecond.clamp(dayStart, dayEnd - 1);
    if (allowUnboundedAovDay) return requested;
    for (final record in records) {
      if (record.startTimestampSecond < dayStart ||
          record.startTimestampSecond >= dayEnd) {
        continue;
      }
      final start = record.startTimestampSecond;
      final end = math.min(record.endTimestampSecond, dayEnd);
      if (end <= start) continue;
      if (start <= requested && requested < end) return requested;
    }
    return null;
  }

  static RecordIndex? eventRecordAtTimestamp(
    List<RecordIndex> records,
    int timestampSecond,
  ) {
    if (timestampSecond <= 0) return null;

    RecordIndex? match;
    for (final record in records) {
      if (record.eventType <= 0 ||
          record.endTimestampSecond <= record.startTimestampSecond ||
          timestampSecond < record.startTimestampSecond ||
          timestampSecond >= record.endTimestampSecond) {
        continue;
      }
      if (match == null ||
          record.startTimestampSecond > match.startTimestampSecond) {
        match = record;
      }
    }
    return match;
  }

  static RecordIndex? eventRecordForTimeline(
    List<RecordIndex> records,
    int timestampSecond,
  ) {
    final active = eventRecordAtTimestamp(records, timestampSecond);
    if (active != null) return active;

    RecordIndex? next;
    RecordIndex? previous;
    for (final record in records) {
      if (record.eventType <= 0 ||
          record.endTimestampSecond <= record.startTimestampSecond) {
        continue;
      }
      if (record.startTimestampSecond >= timestampSecond) {
        if (next == null ||
            record.startTimestampSecond < next.startTimestampSecond) {
          next = record;
        }
      } else if (previous == null ||
          record.startTimestampSecond > previous.startTimestampSecond) {
        previous = record;
      }
    }
    return next ?? previous;
  }

  static String formatRecordDateTime(int timestampSecond) {
    final value = DateTime.fromMillisecondsSinceEpoch(timestampSecond * 1000);
    String twoDigits(int part) => part.toString().padLeft(2, '0');
    return '${value.year.toString().padLeft(4, '0')}-'
        '${twoDigits(value.month)}-${twoDigits(value.day)} '
        '${twoDigits(value.hour)}:${twoDigits(value.minute)}:'
        '${twoDigits(value.second)}';
  }

  static String formatDateLabel(DateTime selectedDate, DateTime todayDate) {
    var formattedDate = selectedDate.toChineseDate();
    if (isSameDate(todayDate, selectedDate)) {
      formattedDate = "$formattedDate | 今天";
    }
    return formattedDate;
  }

  static String eventLabel(int event) {
    switch (event) {
      case 0:
        return " ";
      case 1:
        return "发现移动 ";
      case 2:
        return "发现人形 ";
      case 3:
        return "发现声音 ";
      case 4:
        return "PIR ";
      default:
        return "未知 ";
    }
  }

  static String? formatTimestampLabel(int timestampInMs) {
    if (timestampInMs <= 0) {
      return null;
    }
    return timestampInMs.millisecondToHHmmss();
  }
}

class LocalReplayBufferingState {
  static const Duration defaultVisibilityDelay = Duration(seconds: 10);
  static const int _minimumVisibilityDelayMs = 8000;
  static const int _maximumVisibilityDelayMs = 15000;
  static const int _minimumCadenceSampleMs = 1000;
  static const int _maximumCadenceSampleMs = 15000;
  static const int _maximumCadenceSamples = 5;
  static const double _visibilityDelayMultiplier = 2.5;

  LocalReplayBufferingState(
    int cameraCount, {
    required this.aovCardReplay,
  })  : _buffering = List.filled(cameraCount, false),
        _visible = List.filled(cameraCount, false),
        _lastFrameArrivalMs = List<int?>.filled(cameraCount, null),
        _cadenceSamples = List.generate(cameraCount, (_) => <int>[]),
        _laneTimers = List<Timer?>.filled(cameraCount, null);

  final bool aovCardReplay;
  final List<bool> _buffering;
  final List<bool> _visible;
  final List<int?> _lastFrameArrivalMs;
  final List<List<int>> _cadenceSamples;
  final List<Timer?> _laneTimers;
  Timer? _sharedTimer;
  int _epoch = 0;

  bool get anyBuffering => _buffering.contains(true);
  bool get anyVisible => _visible.contains(true);

  bool isBuffering(int index) => _isValidIndex(index) && _buffering[index];

  bool isVisible(int index) => _isValidIndex(index) && _visible[index];

  Duration visibilityDelayForLane(int index) {
    if (!aovCardReplay || !_isValidIndex(index)) {
      return defaultVisibilityDelay;
    }
    final samples = _cadenceSamples[index];
    if (samples.isEmpty) return defaultVisibilityDelay;
    final sorted = [...samples]..sort();
    final middle = sorted.length ~/ 2;
    final median = sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) ~/ 2;
    final delayMs = (median * _visibilityDelayMultiplier)
        .round()
        .clamp(_minimumVisibilityDelayMs, _maximumVisibilityDelayMs)
        .toInt();
    return Duration(milliseconds: delayMs);
  }

  void noteFrame(
    int index,
    int arrivalMs, {
    VoidCallback? onStalled,
  }) {
    if (!_isValidIndex(index)) return;
    if (aovCardReplay) {
      final previousArrivalMs = _lastFrameArrivalMs[index];
      if (previousArrivalMs != null) {
        final intervalMs = arrivalMs - previousArrivalMs;
        if (intervalMs >= _minimumCadenceSampleMs &&
            intervalMs <= _maximumCadenceSampleMs) {
          final samples = _cadenceSamples[index];
          samples.add(intervalMs);
          if (samples.length > _maximumCadenceSamples) samples.removeAt(0);
        }
      }
      _lastFrameArrivalMs[index] = arrivalMs;
      _laneTimers[index]?.cancel();
      _laneTimers[index] = null;
    }
    _buffering[index] = false;
    _visible[index] = false;
    if (!aovCardReplay && !anyBuffering) {
      _sharedTimer?.cancel();
      _sharedTimer = null;
    }
    if (aovCardReplay && onStalled != null) {
      _laneTimers[index]?.cancel();
      _laneTimers[index] = null;
      _scheduleLaneTimer(index, onStalled);
    }
  }

  void noteBuffering(
    int index,
    VoidCallback onVisible, {
    bool scheduleVisibility = true,
  }) {
    if (!_isValidIndex(index)) return;
    _buffering[index] = true;
    if (_visible[index] || !scheduleVisibility) return;
    if (!aovCardReplay) {
      _scheduleSharedTimer(onVisible);
      return;
    }
    _scheduleLaneTimer(index, onVisible);
  }

  void _scheduleLaneTimer(int index, VoidCallback onVisible) {
    if (_laneTimers[index]?.isActive == true) return;
    final epoch = _epoch;
    _laneTimers[index] = Timer(visibilityDelayForLane(index), () {
      _laneTimers[index] = null;
      if (epoch != _epoch) return;
      _buffering[index] = true;
      _visible[index] = true;
      onVisible();
    });
  }

  void cancelVisibilityTimers() {
    _epoch += 1;
    _sharedTimer?.cancel();
    _sharedTimer = null;
    for (var index = 0; index < _laneTimers.length; index++) {
      _laneTimers[index]?.cancel();
      _laneTimers[index] = null;
      _visible[index] = false;
    }
  }

  void reset({bool resetCadence = false}) {
    cancelVisibilityTimers();
    _buffering.fillRange(0, _buffering.length, false);
    if (!resetCadence) return;
    _lastFrameArrivalMs.fillRange(0, _lastFrameArrivalMs.length, null);
    for (final samples in _cadenceSamples) {
      samples.clear();
    }
  }

  void dispose() => reset(resetCadence: true);

  void _scheduleSharedTimer(VoidCallback onVisible) {
    if (_sharedTimer?.isActive == true) return;
    final epoch = _epoch;
    _sharedTimer = Timer(defaultVisibilityDelay, () {
      _sharedTimer = null;
      if (epoch != _epoch) return;
      var changed = false;
      for (var index = 0; index < _buffering.length; index++) {
        if (!_buffering[index] || _visible[index]) continue;
        _visible[index] = true;
        changed = true;
      }
      if (changed) onVisible();
    });
  }

  bool _isValidIndex(int index) => index >= 0 && index < _buffering.length;
}

enum LocalReplayLanePresentationState { pending, ready, unavailable }

/// Tracks which cameras have presented a frame for the current transition.
/// Render-state callbacks carry no UTC, so a targeted seek must wait for UTC.
class LocalReplayPresentationState {
  static const int timestampToleranceMs = 5000;
  static const int maxForwardJumpMs = 5000;
  static const int aovTimelineToleranceMs = 150000;

  LocalReplayPresentationState(int cameraCount)
      : _lanes = List.filled(
          cameraCount,
          LocalReplayLanePresentationState.pending,
        );

  final List<LocalReplayLanePresentationState> _lanes;
  int generation = 0;
  int floorUtcMs = 0;
  int acceptableEndUtcMs = 0;
  bool active = false;
  bool seeking = false;
  bool paused = false;
  bool _acceptingFrames = true;
  int _maxPlaybackRate = 1;
  bool _aovTimelineSeek = false;

  bool get anyReady => _lanes.contains(LocalReplayLanePresentationState.ready);
  bool get allReady => _lanes.every(
        (lane) => lane == LocalReplayLanePresentationState.ready,
      );
  bool get anyUnavailable =>
      _lanes.contains(LocalReplayLanePresentationState.unavailable);
  bool get allSettled => _lanes.every(
        (lane) => lane != LocalReplayLanePresentationState.pending,
      );
  bool get timedOut => anyUnavailable;
  int get readyCount => _lanes
      .where((lane) => lane == LocalReplayLanePresentationState.ready)
      .length;
  bool isReady(int index) =>
      _isValidIndex(index) &&
      _lanes[index] == LocalReplayLanePresentationState.ready;
  bool isUnavailable(int index) =>
      _isValidIndex(index) &&
      _lanes[index] == LocalReplayLanePresentationState.unavailable;
  String get readySummary => _lanes
      .map((lane) => lane == LocalReplayLanePresentationState.ready ? '1' : '0')
      .join();
  String get laneSummary => _lanes.map((lane) {
        switch (lane) {
          case LocalReplayLanePresentationState.pending:
            return 'P';
          case LocalReplayLanePresentationState.ready:
            return 'R';
          case LocalReplayLanePresentationState.unavailable:
            return 'U';
        }
      }).join();

  int begin({
    required int floorUtcMs,
    required bool seeking,
    int acceptableEndUtcMs = 0,
    int? affectedPlayerIndex,
    bool waitForSeek = false,
    bool aovTimelineSeek = false,
    bool isAovDevice = false,
    int playbackRate = 1,
  }) {
    generation += 1;
    this.floorUtcMs = floorUtcMs;
    this.acceptableEndUtcMs = acceptableEndUtcMs;
    this.seeking = seeking;
    active = true;
    _acceptingFrames = !waitForSeek;
    _aovTimelineSeek = seeking && (isAovDevice || aovTimelineSeek);
    _maxPlaybackRate = playbackRate;
    if (affectedPlayerIndex == null) {
      _lanes.fillRange(
        0,
        _lanes.length,
        LocalReplayLanePresentationState.pending,
      );
    } else if (_isValidIndex(affectedPlayerIndex)) {
      _lanes[affectedPlayerIndex] = LocalReplayLanePresentationState.pending;
    }
    return generation;
  }

  void notePlaybackRate(int rate) {
    // Returning from 4x to 1x must not move the UTC acceptance limit backward.
    if (rate > _maxPlaybackRate) _maxPlaybackRate = rate;
  }

  bool armSeek(int generation) {
    if (generation != this.generation || !active) return false;
    _acceptingFrames = true;
    return true;
  }

  bool acceptStarted(int index, {required int generation}) {
    if (!_isValidIndex(index) || floorUtcMs > 0 || !active) return false;
    return _accept(index, generation);
  }

  bool acceptTimestamp(
    int index,
    int timestamp, {
    required int generation,
    required int elapsedMilliseconds,
    int playbackRate = 1,
  }) {
    if (!_isValidIndex(index) || timestamp <= 0 || !_canAccept(generation)) {
      return false;
    }
    notePlaybackRate(playbackRate);
    if (floorUtcMs > 0) {
      final maxForward =
          maxForwardJumpMs + elapsedMilliseconds * _maxPlaybackRate;
      final toleranceMs =
          _aovTimelineSeek ? aovTimelineToleranceMs : timestampToleranceMs;
      // AOV's sparse frames may precede the target. Match the native seek
      // window, not the ordinary-record gate or the end of the whole day.
      // A ready lane may keep advancing while another lane is still pending.
      final maxAcceptedUtcMs = _aovTimelineSeek
          ? floorUtcMs +
              aovTimelineToleranceMs +
              (isReady(index) ? elapsedMilliseconds * _maxPlaybackRate : 0)
          : acceptableEndUtcMs > floorUtcMs
              ? acceptableEndUtcMs
              : floorUtcMs + maxForward;
      if (timestamp + toleranceMs < floorUtcMs ||
          timestamp > maxAcceptedUtcMs) {
        return false;
      }
    }
    return _accept(index, generation);
  }

  bool _canAccept(int generation) =>
      generation == this.generation && _acceptingFrames && !paused;

  bool _accept(int index, int generation) {
    if (!_canAccept(generation)) return false;
    _lanes[index] = LocalReplayLanePresentationState.ready;
    if (allReady) {
      active = false;
      seeking = false;
      floorUtcMs = 0;
      acceptableEndUtcMs = 0;
    } else if (allSettled) {
      active = false;
    }
    return true;
  }

  bool markBuffering(int index) {
    if (paused || !_isValidIndex(index)) return false;
    if (isReady(index)) return false;
    _lanes[index] = LocalReplayLanePresentationState.pending;
    return true;
  }

  bool expire(int generation) {
    if (generation != this.generation || !active || paused) return false;
    for (var index = 0; index < _lanes.length; index++) {
      if (_lanes[index] == LocalReplayLanePresentationState.pending) {
        _lanes[index] = LocalReplayLanePresentationState.unavailable;
      }
    }
    active = false;
    return true;
  }

  bool expireSeekFailure(int generation, int targetUtcMs) {
    if (generation != this.generation ||
        !active ||
        paused ||
        !seeking ||
        floorUtcMs != targetUtcMs) {
      return false;
    }
    for (var index = 0; index < _lanes.length; index++) {
      if (_lanes[index] == LocalReplayLanePresentationState.pending) {
        _lanes[index] = LocalReplayLanePresentationState.unavailable;
      }
    }
    _acceptingFrames = false;
    active = false;
    return true;
  }

  String? laneMessage(int index) {
    if (!_isValidIndex(index) || !anyReady || isReady(index) || paused) {
      return null;
    }
    final lane = '第${index + 1}路';
    if (isUnavailable(index)) {
      return seeking ? '$lane目标时间无录像\n请切换时间或录像' : '$lane恢复超时\n请切换录像或重新进入';
    }
    if (!active) return null;
    return seeking ? '$lane正在切换' : '$lane正在恢复';
  }

  bool _isValidIndex(int index) => index >= 0 && index < _lanes.length;
}
