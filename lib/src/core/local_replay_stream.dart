part of 'library.dart';

enum LocalReplaySpeed { x1, x2, x4, x8 }

enum LocalReplayStartMode { continuous, singleRecord }

enum LocalReplaySeekError {
  utcMismatch,
  unknown,
  recoveryFailed;

  static LocalReplaySeekError fromCode(int code) {
    switch (code) {
      case 1:
        return utcMismatch;
      case 2:
        return recoveryFailed;
      default:
        return unknown;
    }
  }
}

class LocalReplaySeekFailure {
  const LocalReplaySeekFailure({
    required this.error,
    required this.targetTimestampSecond,
    required this.actualTimestampSecond,
  });

  final LocalReplaySeekError error;
  final int targetTimestampSecond;
  final int actualTimestampSecond;
}

class LocalReplayStream {
  static const String _tag = "LocalReplayStream";
  final RapidNativeLocalReplayStream _nativeStream;
  bool _started = false;
  ValueChanged<LocalReplaySeekFailure>? _seekErrorListener;

  LocalReplayStream._(this._nativeStream) {
    _nativeStream.setSeekErrorListener((errorCode, target, actual) {
      _seekErrorListener?.call(LocalReplaySeekFailure(
        error: LocalReplaySeekError.fromCode(errorCode),
        targetTimestampSecond: target,
        actualTimestampSecond: actual,
      ));
    });
    Logging.i(_tag, "[create] caller=${rapidStackTrace()}");
  }

  set onSeekError(ValueChanged<LocalReplaySeekFailure>? listener) {
    _seekErrorListener = listener;
  }

  void start() {
    if (_nativeStream.isStarted()) {
      _started = true;
      Logging.i(_tag, "[start] already started");
      return;
    }
    _started = false;
    final stopwatch = Stopwatch()..start();
    Logging.i(_tag, "[start] caller=${rapidStackTrace()}");
    _nativeStream.start();
    _started = _nativeStream.isStarted();
    stopwatch.stop();
    Logging.i(
      _tag,
      "[start] execution time: ${stopwatch.elapsedMilliseconds}ms",
    );
  }

  void prepare(int startTimestampInSecond, int endTimestampInSecond) {
    Logging.i(
      _tag,
      "[prepare] start=${startTimestampInSecond}s end=${endTimestampInSecond}s",
    );
    _nativeStream.prepare(startTimestampInSecond, endTimestampInSecond);
  }

  void seek(
    int timestampInSecond, {
    LocalReplayStartMode startMode = LocalReplayStartMode.continuous,
  }) =>
      _nativeStream.seek(
        timestampInSecond,
        startMode: startMode.index,
      );
  void updateLastRenderedUtc(int timestampMs) =>
      _nativeStream.updateLastRenderedUtc(timestampMs);
  void stop() {
    if (!_nativeStream.isStarted()) {
      _started = false;
      Logging.i(_tag, "[stop] not started");
      return;
    }
    final stopwatch = Stopwatch()..start();
    Logging.i(_tag, "[stop] caller=${rapidStackTrace()}");
    _nativeStream.stop();
    _started = false;
    stopwatch.stop();
    Logging.i(
      _tag,
      "[stop] execution time: ${stopwatch.elapsedMilliseconds}ms",
    );
  }

  void pause() => _nativeStream.pause();
  void resume() => _nativeStream.resume();
  bool isPaused() => _nativeStream.isPaused();
  void destroy() {
    final stopwatch = Stopwatch()..start();
    Logging.i(_tag, "[destroy] caller=${rapidStackTrace()}");
    if (_nativeStream.isStarted()) {
      Logging.i(
        _tag,
        "[destroy] local replay stream is started, should stop it first",
      );
      if (kDebugMode) {
        throw FlutterError(
          'LocalReplayStream.destroy() called - you MUST call stop() first!',
        );
      }
    }
    _started = false;
    _nativeStream.destroy();
    stopwatch.stop();
    Logging.i(
      _tag,
      "[destroy] execution time: ${stopwatch.elapsedMilliseconds}ms",
    );
  }

  void setSpeed(LocalReplaySpeed speed) => _nativeStream.setSpeed(speed.index);

  /// Legacy call retained for older native SDKs. Current SDKs ignore the flag:
  /// local replay audio always follows the video UTC transition boundary.
  /// Returns false when the native SDK does not expose the legacy API.
  @Deprecated('Local replay audio follows video UTC without configuration.')
  bool setAudioUtcFallback(bool enabled) =>
      _nativeStream.setAudioUtcFallback(enabled);

  Pointer<Void>? provider({int cameraIndex = 0}) =>
      _nativeStream.indexedProvider(cameraIndex);

  static LocalReplayStream create(Pipe pipe, {bool enableAudio = true}) {
    final nativeLiveStream = RapidNativeLocalReplayStream(pipe._nativePipe);
    nativeLiveStream.create(enableAudio: enableAudio);
    return LocalReplayStream._(nativeLiveStream);
  }
}
