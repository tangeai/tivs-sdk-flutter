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
      _lastPresentedTimestampInMs = utsInMs;
      return CloudReplayTimelineDecision(
          timestampInMs: utsInMs,
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
