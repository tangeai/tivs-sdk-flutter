part of 'library.dart';

enum RenderState { started, buffering, completed, paused }

enum PlayerBufferingMode { off, auto, fixed }

enum PlayerClockMode { audio, video }

enum VideoDecoderPreference { auto, software, hardware }

typedef RenderStateListener = void Function(RenderState);
typedef RenderPixelSizeListener = void Function(int, int);
typedef RenderTimestampListener = void Function(int);
typedef RenderMuxQueueSizeListener = void Function(int);
typedef RecordDurationListener = void Function(int);

@Deprecated(
  'Deprecated: audio output always uses the media path. Voice call routing is no longer supported.',
)
enum AudioOutputMode { media, voice }

class Player {
  static const String _tag = "Player";
  static const _textureNone = -1;
  static const _defaultTimestampInterval = 100;
  static const _defaultMuxQueueSizeInterval = 500;
  static const _minTimestampInterval = 10;
  static const _defaultFixedBufferingMs = 200;
  static const _minAutoBufferingMaxMs = 100;
  static bool _androidGlesVideoRenderEnabled = false;
  static PlayerBufferingMode _defaultBufferingMode = PlayerBufferingMode.auto;
  static int _defaultBufferingMs = _defaultFixedBufferingMs;
  static PlayerClockMode _defaultClockMode = PlayerClockMode.audio;
  static VideoDecoderPreference _defaultVideoDecoderPreference =
      VideoDecoderPreference.software;

  final RapidNativePlayer _nativeMediaPlayer;
  late final int _instanceId = identityHashCode(this);
  final Stopwatch _startStopwatch = Stopwatch();
  final StreamController<int> _textureIdController =
      StreamController<int>.broadcast();
  Stream<int> get textureIdStream => _textureIdController.stream;
  int _textureId = _textureNone;
  int _textureGeneration = 0;
  Future<int>? _textureBindingOperation;
  bool _textureBindingOperationForcesRecreation = false;
  bool _destroyed = false;
  String _recordingCachePath = "";
  bool _renderStarted = false;
  bool _enableVideoRender = true;
  bool _videoEnabled = true;
  RenderStateListener? _renderStateListener;
  RenderPixelSizeListener? _renderSizeListener;
  RenderMuxQueueSizeListener? _muxQueueSizeListener;
  RecordDurationListener? _recordDurationListener;
  int _lastRecordDurationForwardLogSecond = -1;

  bool _started = false;
  RenderState? _lastRenderState;

  RenderTimestampListener? _ptsListener;
  RenderTimestampListener? _utsListener;

  int _ptsUpdateInterval = _defaultTimestampInterval;
  int _utsUpdateInterval = _defaultTimestampInterval;
  int _muxQueueSizeUpdateInterval = _defaultMuxQueueSizeInterval;

  Timer? _muxQueueSizeTimer;
  final Stopwatch _timestampStopwatch = Stopwatch()..start();
  int _lastPtsForwardWallMs = -1;
  int _lastUtsForwardWallMs = -1;
  int _lastForwardedPts = 0;
  int _lastForwardedUts = 0;

  double _lastWidgetWidth = 0;
  double _lastWidgetHeight = 0;
  bool _textureInitialized = false;
  bool _prepared = false;
  bool _videoEnabledAtPrepare = true;
  VideoDecoderPreference _videoDecoderPreference =
      _defaultVideoDecoderPreference;

  Player._(this._nativeMediaPlayer) {
    if (kDebugMode) {
      player_diagnostics.registerVideoFrameDumpControl(
        this,
        _nativeMediaPlayer.enableVideoFrameDump,
      );
    }
    Logging.i(_tag, "[$_logPrefix][create] caller=${rapidStackTrace()}");
    _nativeMediaPlayer.onRenderState = (state) {
      final renderState = RenderState.values[state];
      if (_lastRenderState != renderState) {
        _lastRenderState = renderState;
        final elapsedMs = _startStopwatch.isRunning
            ? _startStopwatch.elapsedMilliseconds
            : -1;
        Logging.i(
          _tag,
          "[$_logPrefix][render.state] raw=$state state=$renderState started=$_started "
          "elapsed=${elapsedMs}ms prepared=$_prepared textureInitialized=$_textureInitialized "
          "textureId=$_textureId size=${_lastWidgetWidth}x$_lastWidgetHeight startupMetrics=$startupMetricsSnapshot",
        );
      }
      if (renderState == RenderState.started && !_renderStarted) {
        _renderStarted = true;
        if (!_textureInitialized && _videoEnabled && _videoEnabledAtPrepare) {
          debugPrint("==================================================");
          debugPrint("⚠️  TEXTURE NOT BIND, VIDEO WILL NOT BE RENDERED !");
          if (_lastWidgetWidth <= 0 || _lastWidgetHeight <= 0) {
            debugPrint(
              "  texture size is invalid, width=$_lastWidgetWidth, height=$_lastWidgetHeight",
            );
          }
          if (!_prepared) {
            debugPrint("  [prepare] not called !");
          }

          debugPrint("==================================================");

          Logging.e(_tag, "⚠️  TEXTURE NOT BIND, VIDEO WILL NOT BE RENDERED !");
          Logging.e(
            _tag,
            "     1. texture size: $_lastWidgetWidth x $_lastWidgetHeight",
          );
          Logging.e(_tag, "     2. prepare = $_prepared");
        }
        _notifyTextureRenderIfNeeded();
      }
      _renderStateListener?.call(renderState);
    };

    _nativeMediaPlayer.onPixelSizeChanged =
        (width, height) => _renderSizeListener?.call(width, height);
    _nativeMediaPlayer.onRecordDurationChanged = (durationMs) {
      final hasUserListener = _recordDurationListener != null;
      final durationSecond = durationMs ~/ Duration.millisecondsPerSecond;
      if (durationMs == 0 ||
          durationSecond != _lastRecordDurationForwardLogSecond) {
        _lastRecordDurationForwardLogSecond = durationSecond;
        Logging.i(
          _tag,
          "[$_logPrefix][recordDurationCallback] forward, durationMs=$durationMs, hasUserListener=$hasUserListener",
        );
      }
      _recordDurationListener?.call(durationMs);
    };
  }

  String get _logPrefix => "player#$_instanceId";

  String? get metricsSnapshot => _nativeMediaPlayer.metricsSnapshot;
  String? get startupMetricsSnapshot =>
      _nativeMediaPlayer.startupMetricsSnapshot;
  int get textureId => _textureId;
  int get textureGeneration => _textureGeneration;
  static bool get androidGlesVideoRenderEnabled =>
      _androidGlesVideoRenderEnabled;

  static Future<void> enableAndroidGlesVideoRender(bool enable) async {
    _androidGlesVideoRenderEnabled = Platform.isAndroid && enable;
    await _PlatformChannel.setAndroidGlesVideoRender(
      _androidGlesVideoRenderEnabled,
    );
  }

  static bool get _isOhos => Platform.operatingSystem == 'ohos';

  bool get _usesSizedAndroidTexture =>
      Platform.isAndroid &&
      (androidGlesVideoRenderEnabled ||
          _videoDecoderPreference != VideoDecoderPreference.software);

  bool get _usesSizedTexture => _isOhos || _usesSizedAndroidTexture;

  static void setDefaultBufferingMode(
    PlayerBufferingMode mode, {
    int bufferingMs = _defaultFixedBufferingMs,
  }) {
    if (!_isValidBufferingConfig(mode, bufferingMs)) return;
    _defaultBufferingMode = mode;
    _defaultBufferingMs = bufferingMs;
  }

  static void setDefaultClockMode(PlayerClockMode mode) {
    _defaultClockMode = mode;
  }

  static void setDefaultVideoDecoderPreference(
    VideoDecoderPreference preference,
  ) {
    _defaultVideoDecoderPreference = preference;
  }

  @Deprecated(
    'Deprecated: audio output always uses the media path. Voice call routing is no longer supported.',
  )
  AudioOutputMode get audioOutputMode => AudioOutputMode.media;

  void _notifyTextureRenderIfNeeded() {
    if (_renderStarted &&
        _textureId != _textureNone &&
        !_textureIdController.isClosed) {
      Logging.i(
        _tag,
        "[_notifyTextureRenderIfNeeded] success, _textureId=$_textureId",
      );
      _textureIdController.add(_textureId);
    } else {
      Logging.i(
        _tag,
        "[_notifyTextureRenderIfNeeded] failed, _renderStarted=$_renderStarted, _textureId=$_textureId, _textureIdController.isClosed=${_textureIdController.isClosed}",
      );
    }
  }

  void _hideTextureUntilNextRenderedFrame() {
    _renderStarted = false;
    if (!_textureIdController.isClosed) {
      _textureIdController.add(_textureNone);
    }
  }

  set enableVideoRender(bool enable) {
    _enableVideoRender = enable;
  }

  set ptsUpdateInterval(int interval) {
    if (interval < _minTimestampInterval) {
      Logging.e(
        _tag,
        "PTS update interval must be greater than $_minTimestampInterval ms",
      );
      return;
    }

    _ptsUpdateInterval = interval;
  }

  set muxQueueSizeUpdateInterval(int interval) {
    if (interval < _minTimestampInterval) {
      Logging.e(
        _tag,
        "MUX queue size update interval must be greater than $_minTimestampInterval ms",
      );
      return;
    }
    _muxQueueSizeUpdateInterval = interval;
    if (_muxQueueSizeListener != null) _launchMuxQueueSizeTimer();
  }

  set utsUpdateInterval(int interval) {
    if (interval < _minTimestampInterval) {
      Logging.e(
        _tag,
        "UTS update interval must be greater than $_minTimestampInterval ms",
      );
      return;
    }

    _utsUpdateInterval = interval;
  }

  set onRenderState(RenderStateListener listener) =>
      _renderStateListener = listener;

  set onPixelSizeChanged(RenderPixelSizeListener listener) =>
      _renderSizeListener = listener;

  set onMuxerQueueSizeChanged(RenderMuxQueueSizeListener listener) =>
      _muxQueueSizeListener = listener;

  set onRecordDuration(RecordDurationListener listener) {
    _recordDurationListener = listener;
    _lastRecordDurationForwardLogSecond = -1;
    Logging.i(
      _tag,
      "[$_logPrefix][setRecordDurationListener] registered, recording=${recording()}, durationMs=${recordDurationMs()}",
    );
  }

  void setRecordDurationListener(RecordDurationListener listener) {
    onRecordDuration = listener;
  }

  set onPresentationTimestamp(RenderTimestampListener listener) {
    _ptsListener = listener;
    _nativeMediaPlayer.onPresentationTimestamp = _onPresentationTimestamp;
  }

  void _onPresentationTimestamp(int timestamp) {
    final nowMs = _timestampStopwatch.elapsedMilliseconds;
    if (!_shouldForwardTimestamp(
      timestamp,
      _lastForwardedPts,
      _lastPtsForwardWallMs,
      _ptsUpdateInterval,
      nowMs,
    )) {
      return;
    }
    _lastForwardedPts = timestamp;
    _lastPtsForwardWallMs = nowMs;
    _ptsListener?.call(timestamp);
  }

  set onUniversalTimestamp(RenderTimestampListener listener) {
    _utsListener = listener;
    _nativeMediaPlayer.onUniversalTimestamp = _onUniversalTimestamp;
  }

  /// Call after a synchronous seek to discard queued pre-seek UTC callbacks.
  void resetUniversalTimestampNotifications() {
    if (_destroyed) return;
    _lastForwardedUts = 0;
    _lastUtsForwardWallMs = -1;
    _nativeMediaPlayer.resetUniversalTimestampNotifications();
  }

  void _onUniversalTimestamp(int timestamp) {
    final nowMs = _timestampStopwatch.elapsedMilliseconds;
    if (!_shouldForwardTimestamp(
      timestamp,
      _lastForwardedUts,
      _lastUtsForwardWallMs,
      _utsUpdateInterval,
      nowMs,
    )) {
      return;
    }
    _lastForwardedUts = timestamp;
    _lastUtsForwardWallMs = nowMs;
    _utsListener?.call(timestamp);
  }

  bool _shouldForwardTimestamp(
    int timestamp,
    int previousTimestamp,
    int previousWallMs,
    int intervalMs,
    int nowMs,
  ) {
    if (timestamp == 0) return false;
    if (previousWallMs < 0 || nowMs - previousWallMs >= intervalMs) return true;
    if (previousTimestamp == 0 || timestamp < previousTimestamp) return true;
    if (timestamp == previousTimestamp) return false;
    return timestamp - previousTimestamp > intervalMs * 2;
  }

  void _launchMuxQueueSizeTimer() {
    _muxQueueSizeTimer?.cancel();
    _muxQueueSizeTimer = Timer.periodic(
      Duration(milliseconds: _muxQueueSizeUpdateInterval),
      (timer) {
        final size = _nativeMediaPlayer.muxerQueueSize();
        if (size >= 0) _muxQueueSizeListener?.call(size);
      },
    );
  }

  int get pixelWidth => _nativeMediaPlayer.pixelWidth();
  int get pixelHeight => _nativeMediaPlayer.pixelHeight();
  PixelFrame? get currentPixelFrame => _nativeMediaPlayer.currentPixelFrame();

  Future<void> prepare(Pointer<Void> providerPtr) async {
    _videoEnabledAtPrepare = _videoEnabled;
    _nativeMediaPlayer.prepare(providerPtr);
    _prepared = true;
    Logging.i(
      _tag,
      "[$_logPrefix][prepare] _enableVideoRender=$_enableVideoRender, _videoEnabled=$_videoEnabled, _videoEnabledAtPrepare=$_videoEnabledAtPrepare",
    );
    if (!_videoEnabledAtPrepare || !_enableVideoRender) {
      await _initializeTextureWithSize(10, 10);
    }
  }

  Future<void> _initializeTextureWithSize(int width, int height) async {
    if (_textureInitialized) return;
    await _ensureTextureWithSize(width, height);
  }

  /// Ensures that the native texture binding exists.
  ///
  /// Call with [forceRecreate] after stopping playback when an OHOS surface may
  /// have been invalidated. The returned id is registered and bound, but the
  /// first subsequent timestamp is the signal that a frame reached the vout.
  Future<int> ensureTexture({bool forceRecreate = false}) {
    if (!_prepared) {
      throw StateError(
          'Player.prepare() must be called before ensureTexture().');
    }
    if (_destroyed) {
      throw StateError('Player.ensureTexture() called after destroy().');
    }
    if (forceRecreate && _started) {
      throw StateError(
        'Stop the player before force-recreating its texture.',
      );
    }

    final width = _lastWidgetWidth > 0 ? _lastWidgetWidth.toInt() : 10;
    final height = _lastWidgetHeight > 0 ? _lastWidgetHeight.toInt() : 10;
    return _ensureTextureWithSize(
      width,
      height,
      forceRecreate: forceRecreate,
    );
  }

  Future<int> _ensureTextureWithSize(
    int width,
    int height, {
    bool forceRecreate = false,
  }) {
    final activeOperation = _textureBindingOperation;
    if (activeOperation != null) {
      if (!forceRecreate || _textureBindingOperationForcesRecreation) {
        return activeOperation;
      }
      return activeOperation.then(
        (_) => _ensureTextureWithSize(
          width,
          height,
          forceRecreate: true,
        ),
      );
    }

    final operation = _performTextureBinding(
      width,
      height,
      forceRecreate: forceRecreate,
    );
    _textureBindingOperation = operation;
    _textureBindingOperationForcesRecreation = forceRecreate;
    operation.then<void>(
      (_) => _clearTextureBindingOperation(operation),
      onError: (Object _, StackTrace __) {
        _clearTextureBindingOperation(operation);
      },
    );
    return operation;
  }

  void _clearTextureBindingOperation(Future<int> operation) {
    if (!identical(_textureBindingOperation, operation)) return;
    _textureBindingOperation = null;
    _textureBindingOperationForcesRecreation = false;
  }

  Future<int> _performTextureBinding(
    int width,
    int height, {
    required bool forceRecreate,
  }) async {
    if (forceRecreate) {
      _hideTextureUntilNextRenderedFrame();
    }

    int playerPtr = _nativeMediaPlayer.ptr;
    final textureWidth = _usesSizedTexture ? width : 0;
    final textureHeight = _usesSizedTexture ? height : 0;
    final previousTextureId = _textureId;
    final nextTextureId = _isOhos
        ? await _PlatformChannel.ensurePlayerTexture(
            playerPtr,
            previousTextureId,
            textureWidth,
            textureHeight,
            forceRecreate: forceRecreate,
          )
        : previousTextureId != _textureNone
            ? previousTextureId
            : await _PlatformChannel.attachPlayerTexture(
                playerPtr,
                textureWidth,
                textureHeight,
                playerOutputToken: Platform.isAndroid ? _nativeMediaPlayer.outputToken : null,
              );

    if (_destroyed) {
      if (nextTextureId != _textureNone && nextTextureId != previousTextureId) {
        await _PlatformChannel.detachPlayerTexture(nextTextureId);
      }
      throw StateError('Player was destroyed while binding its texture.');
    }

    if (nextTextureId == _textureNone) {
      throw StateError('Failed to bind player texture.');
    }

    _textureInitialized = true;
    if (nextTextureId != previousTextureId) {
      _textureId = nextTextureId;
      _textureGeneration++;
      Logging.i(
        _tag,
        "[$_logPrefix][texture.binding] previous=$previousTextureId current=$nextTextureId generation=$_textureGeneration forceRecreate=$forceRecreate",
      );
    }

    if (!_enableVideoRender) {
      final vout = RapidNativeSDL.createVoutSilence();
      _nativeMediaPlayer.setVout(vout);
    }

    _notifyTextureRenderIfNeeded();
    return _textureId;
  }

  Widget texture() {
    if (!_videoEnabled) {
      return const ColoredBox(color: Colors.transparent);
    }

    return _RapidTexture(
      textureIdStream: textureIdStream,
      initialTextureId: _renderStarted ? _textureId : _textureNone,
      onSizeChanged: (width, height) {
        if (width <= 0 || height <= 0) {
          Logging.i(
            _tag,
            "[texture] size is invalid, width=$width, height=$height",
          );
          return;
        }

        if (!_prepared) {
          Logging.i(
            _tag,
            "[texture] error: not call [prepare] before calling [texture]",
          );
          throw Exception(
            "\n\n====================== Exception occurred in rapid_kit: ======================\n  Must call [Player.prepare] before calling [Player.texture] !\n============================================",
          );
        }

        if (width == _lastWidgetWidth && height == _lastWidgetHeight) {
          return;
        }

        _lastWidgetWidth = width;
        _lastWidgetHeight = height;

        if (!_textureInitialized) {
          Logging.i(
            _tag,
            "[texture] do initialize, width=$width, height=$height",
          );
          _initializeTextureWithSize(width.toInt(), height.toInt());
        } else if (_textureId != _textureNone && _usesSizedAndroidTexture) {
          _PlatformChannel.updatePlayerTextureSize(
            _textureId,
            width.toInt(),
            height.toInt(),
          );
        }
      },
    );
  }

  void buffering(bool enable) => setBufferingMode(
        enable ? PlayerBufferingMode.auto : PlayerBufferingMode.off,
      );

  void setBufferingMode(
    PlayerBufferingMode mode, {
    int bufferingMs = _defaultFixedBufferingMs,
  }) {
    if (!_isValidBufferingConfig(mode, bufferingMs)) return;
    _nativeMediaPlayer.setBufferingMode(mode.index, bufferingMs);
  }

  void setAutoBufferingMaxMs(int value) {
    if (!_isValidAutoBufferingMax(value)) return;
    _nativeMediaPlayer.setAutoBufferingMax(value);
  }

  void setClockMode(PlayerClockMode mode) =>
      _nativeMediaPlayer.setClockMode(mode.index);

  /// Lets local replay audio continue during a video gap, keeping the video clock.
  /// Configure before prepare. Other stream types and secondary players ignore it.
  bool setLocalReplayAudioContinuity(bool enabled) {
    if (_prepared) return false;
    return _nativeMediaPlayer.setLocalReplayAudioContinuity(enabled);
  }

  void setVideoDecoderPreference(VideoDecoderPreference preference) {
    if (_prepared) {
      Logging.w(
        _tag,
        "[setVideoDecoderPreference] called after prepare, ignored. preference must be configured before prepare",
      );
      return;
    }
    _videoDecoderPreference = preference;
    _nativeMediaPlayer.setVideoDecoderPreference(preference.index);
  }

  void enableAudio(bool enable) => _nativeMediaPlayer.enableAudio(enable);

  void enableVideo(bool enable) {
    if (_prepared) {
      if (_videoEnabled != enable) {
        Logging.w(
          _tag,
          "[enableVideo] called after prepare, ignored. audio-only initialization requires calling before prepare",
        );
      }
      return;
    }
    _videoEnabled = enable;
    _nativeMediaPlayer.enableVideo(enable);
  }

  @Deprecated(
    'Deprecated: audio output always uses the media path. Voice call routing is no longer supported.',
  )
  Future<bool> setAudioOutputMode(AudioOutputMode mode) async {
    Logging.w(
      _tag,
      "[setAudioOutputMode] deprecated no-op, audio always uses media path, requested=$mode",
    );
    return true;
  }

  void configureAudioProcessing(PlayerAudioProcessingConfig? audioProcessing) =>
      _nativeMediaPlayer.configureAudioProcessing(
        audioProcessing?.nsLevel ?? 0,
        audioProcessing?.agcLevel ?? 0,
      );

  void start() {
    if (_started) {
      Logging.i(_tag, "[$_logPrefix][start] already started, ignored");
      return;
    }
    final stopwatch = Stopwatch()..start();
    _startStopwatch
      ..reset()
      ..start();
    Logging.i(
      _tag,
      "[$_logPrefix][start.begin] started=$_started prepared=$_prepared textureInitialized=$_textureInitialized "
      "textureId=$_textureId size=${_lastWidgetWidth}x$_lastWidgetHeight caller=${rapidStackTrace()}",
    );
    _PlatformChannel.createAudioSession();
    _hideTextureUntilNextRenderedFrame();
    _lastPtsForwardWallMs = -1;
    _lastUtsForwardWallMs = -1;
    _lastForwardedPts = 0;
    _lastForwardedUts = 0;
    _nativeMediaPlayer.start();
    _started = true;
    stopwatch.stop();
    Logging.i(
      _tag,
      "[$_logPrefix][start.end] execution=${stopwatch.elapsedMilliseconds}ms startupMetrics=$startupMetricsSnapshot metrics=$metricsSnapshot",
    );
  }

  void stop() {
    if (!_started) {
      Logging.i(_tag, "[$_logPrefix][stop] not started, ignored");
      return;
    }
    final stopwatch = Stopwatch()..start();
    Logging.i(
      _tag,
      "[$_logPrefix][stop.begin] started=$_started renderStarted=$_renderStarted "
      "startupMetrics=$startupMetricsSnapshot metrics=$metricsSnapshot caller=${rapidStackTrace()}",
    );
    _muxQueueSizeTimer?.cancel();
    _nativeMediaPlayer.stop();
    _hideTextureUntilNextRenderedFrame();
    _PlatformChannel.destroyAudioSession();
    _started = false;
    _startStopwatch.stop();
    stopwatch.stop();
    Logging.i(
      _tag,
      "[$_logPrefix][stop.end] execution=${stopwatch.elapsedMilliseconds}ms",
    );
  }

  void pause() => _nativeMediaPlayer.pause();
  void resume() => _nativeMediaPlayer.resume();
  void mute(bool mute) => _nativeMediaPlayer.mute(mute);
  bool isMute() => _nativeMediaPlayer.isMute();

  void destroy() {
    final stopwatch = Stopwatch()..start();
    Logging.i(
      _tag,
      "[$_logPrefix][destroy.begin] started=$_started renderStarted=$_renderStarted "
      "prepared=$_prepared textureInitialized=$_textureInitialized startupMetrics=$startupMetricsSnapshot metrics=$metricsSnapshot caller=${rapidStackTrace()}",
    );
    if (_started) {
      Logging.i(
        _tag,
        "[$_logPrefix][destroy] player is started, should stop it first",
      );
      if (kDebugMode) {
        throw FlutterError(
          'Player.destroy() called - you MUST call stop() first!',
        );
      }
    }

    _destroyed = true;
    if (kDebugMode) {
      player_diagnostics.unregisterVideoFrameDumpControl(this);
    }
    _nativeMediaPlayer.destroy();
    if (_textureId != _textureNone) {
      _PlatformChannel.detachPlayerTexture(_textureId);
    }
    _textureIdController.close();
    stopwatch.stop();
    Logging.i(
      _tag,
      "[$_logPrefix][destroy.end] execution=${stopwatch.elapsedMilliseconds}ms",
    );
  }

  Future<String?> captureToFile() async {
    final cachedPath = await _PlatformChannel.requireWriteableCachePath();
    if (cachedPath.isEmpty) return null;
    final path = "$cachedPath.jpg";
    bool ret = _nativeMediaPlayer.capture(path);
    if (!ret) return null;
    return path;
  }

  Future<bool> capture() async {
    final filePath = await captureToFile();
    if (filePath == null) return false;
    return await _PlatformChannel.exportCapturedPicture(filePath);
  }

  bool recording() => _nativeMediaPlayer.recording();

  int recordDurationMs() => _nativeMediaPlayer.recordDurationMs();

  Future<bool> startRecord() async {
    final cachedPath = await _PlatformChannel.requireWriteableCachePath();
    if (cachedPath.isEmpty) return false;
    _recordingCachePath = "$cachedPath.mp4";
    if (_muxQueueSizeListener != null) _launchMuxQueueSizeTimer();
    final ret = _nativeMediaPlayer.startRecord(_recordingCachePath);
    Logging.i(_tag,
        "[startRecord] result=$ret, hasUserListener=${_recordDurationListener != null}, durationMs=${recordDurationMs()}");
    return ret;
  }

  Future<String?> stopRecordToFile() async {
    _muxQueueSizeTimer?.cancel();
    if (!_nativeMediaPlayer.stopRecord()) {
      return null;
    }

    if (_recordingCachePath.isEmpty) {
      return null;
    }

    return _recordingCachePath;
  }

  bool startDump() => _nativeMediaPlayer.startDump();

  bool stopDump() => _nativeMediaPlayer.stopDump();

  Future<bool> stopRecord() async {
    final filePath = await stopRecordToFile();
    if (filePath == null) return false;
    return await _PlatformChannel.exportCapturedVideo(filePath);
  }

  void bindingPrimaryPlayer(Player primaryPlayer) =>
      _nativeMediaPlayer.bindingPrimaryPlayer(primaryPlayer._nativeMediaPlayer);

  static Player create() {
    final nativeMediaPlayer = RapidNativePlayer();
    nativeMediaPlayer.create();
    final player = Player._(nativeMediaPlayer);
    player.setBufferingMode(
      _defaultBufferingMode,
      bufferingMs: _defaultBufferingMs,
    );
    player.setClockMode(_defaultClockMode);
    player.setVideoDecoderPreference(_defaultVideoDecoderPreference);
    return player;
  }

  static bool _isValidBufferingConfig(
    PlayerBufferingMode mode,
    int bufferingMs,
  ) {
    if (mode == PlayerBufferingMode.fixed && bufferingMs <= 0) {
      Logging.e(
        _tag,
        "Fixed buffering mode requires bufferingMs to be greater than 0",
      );
      return false;
    }
    return true;
  }

  static bool _isValidAutoBufferingMax(int value) {
    if (value < _minAutoBufferingMaxMs) {
      Logging.e(_tag,
          "Auto buffering max requires value to be at least $_minAutoBufferingMaxMs ms");
      return false;
    }
    return true;
  }
}

class PlayerAudioProcessingConfig {
  final int nsLevel;
  final int agcLevel;

  const PlayerAudioProcessingConfig({this.nsLevel = 0, this.agcLevel = 0});
}

class _RapidTexture extends StatefulWidget {
  final Stream<int> textureIdStream;
  final int initialTextureId;
  final void Function(double, double)? onSizeChanged;

  const _RapidTexture({
    required this.textureIdStream,
    required this.initialTextureId,
    this.onSizeChanged,
  });

  @override
  _RapidTextureState createState() => _RapidTextureState();
}

class _RapidTextureState extends State<_RapidTexture> {
  int _textureId = -1;
  StreamSubscription<int>? _subscription;
  double _lastWidth = 0;
  double _lastHeight = 0;

  @override
  void initState() {
    super.initState();

    _textureId = widget.initialTextureId;
    _subscribeToTextureIds();
  }

  void _subscribeToTextureIds() {
    _subscription = widget.textureIdStream.listen((newTextureId) {
      if (!mounted || newTextureId == _textureId) return;
      setState(() {
        _textureId = newTextureId;
      });
    });
  }

  @override
  void didUpdateWidget(covariant _RapidTexture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textureIdStream != widget.textureIdStream) {
      _subscription?.cancel();
      _subscribeToTextureIds();
    }
    if (widget.initialTextureId != oldWidget.initialTextureId &&
        widget.initialTextureId != _textureId) {
      _textureId = widget.initialTextureId;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        if ((width != _lastWidth || height != _lastHeight) &&
            width > 0 &&
            height > 0) {
          _lastWidth = width;
          _lastHeight = height;
          final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
          final physicalWidth = width * devicePixelRatio;
          final physicalHeight = height * devicePixelRatio;

          widget.onSizeChanged?.call(physicalWidth, physicalHeight);
        }

        return _textureId >= 0
            ? Texture(textureId: _textureId)
            : const ColoredBox(color: Colors.black);
      },
    );
  }
}
