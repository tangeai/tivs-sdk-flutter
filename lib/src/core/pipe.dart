part of 'library.dart';

enum PipeState {
  undefined,
  attempting,
  established,
  abolished,
  failed,
  shutdownByRemote,
  tokenNotAvailable,
  internetNotAvailable,
  authFailed,
}

typedef PipeStateListener = void Function(PipeState);

class Pipe {
  static const String _tag = "Pipe";
  final String _deviceId;
  final RapidNativePipe _nativePipe;
  late final int _instanceId = identityHashCode(this);
  final Stopwatch _establishStopwatch = Stopwatch();

  @Deprecated(
    "Use 'currentState()' instead, \"_state\" would be removed in the future",
  )
  PipeState _state = PipeState.undefined;

  PipeStateListener? _pipeStateListener;

  bool _establishedCalled = false;

  Pipe._(this._deviceId, this._nativePipe) {
    Logging.i(_tag, "[$_logPrefix][create] caller=${rapidStackTrace()}");
    _nativePipe.setStatusCallback(_updateState);
  }

  String get _logPrefix => "pipe#$_instanceId device=$_deviceId";

  void _updateState(int statusCode, String msg) {
    final newState = PipeState.values[statusCode];
    final oldState = _state;
    _state = newState;
    final elapsedMs = _establishStopwatch.isRunning
        ? _establishStopwatch.elapsedMilliseconds
        : -1;
    Logging.i(
      _tag,
      "[$_logPrefix][state] $oldState -> $newState statusCode=$statusCode msg=$msg establishElapsed=${elapsedMs}ms",
    );
    if (newState != PipeState.attempting && _establishStopwatch.isRunning) {
      _establishStopwatch.stop();
    }
    _pipeStateListener?.call(newState);
  }

  bool get isEstablished => currentState() == PipeState.established;

  void establish() {
    final stopwatch = Stopwatch()..start();
    _establishStopwatch
      ..reset()
      ..start();
    Logging.i(
      _tag,
      "[$_logPrefix][establish.begin] currentState=${currentState()} establishedCalled=$_establishedCalled caller=${rapidStackTrace()}",
    );
    _nativePipe.establish();
    _establishedCalled = true;
    stopwatch.stop();
    Logging.i(
      _tag,
      "[$_logPrefix][establish.end] dispatchElapsed=${stopwatch.elapsedMilliseconds}ms currentState=${currentState()}",
    );
  }

  @Deprecated(
    "Use 'currentState()' instead, \"_state\" would be removed in the future",
  )
  PipeState get state => _state;

  PipeState currentState() {
    final nativeState = _nativePipe.currentStatus();
    return nativeState < 0
        ? PipeState.undefined
        : PipeState.values[nativeState];
  }

  String? get setupMetricsSnapshot => _nativePipe.setupMetricsSnapshot;

  void lan() => _nativePipe.enableLanMode();

  void setTransportMode(int mode) => _nativePipe.setTransportMode(mode);

  void abolish() {
    final stopwatch = Stopwatch()..start();
    Logging.i(
      _tag,
      "[$_logPrefix][abolish.begin] currentState=${currentState()} caller=${rapidStackTrace()}",
    );
    _nativePipe.abolish();
    _establishedCalled = false;
    stopwatch.stop();
    Logging.i(
      _tag,
      "[$_logPrefix][abolish.end] execution=${stopwatch.elapsedMilliseconds}ms currentState=${currentState()}",
    );
  }

  void destroy() {
    final stopwatch = Stopwatch()..start();
    Logging.i(
      _tag,
      "[$_logPrefix][destroy.begin] currentState=${currentState()} establishedCalled=$_establishedCalled caller=${rapidStackTrace()}",
    );
    if (_establishedCalled) {
      Logging.i(
        _tag,
        "[$_logPrefix][destroy] pipe is established, should abolish it first",
      );
      if (kDebugMode) {
        throw FlutterError(
          'Pipe.destroy() called - but you MUST call abolish() first!',
        );
      }
    }
    _pipeStateListener = null;
    _nativePipe.destroy();
    stopwatch.stop();
    Logging.i(
      _tag,
      "[$_logPrefix][destroy.end] execution=${stopwatch.elapsedMilliseconds}ms",
    );
  }

  VoidCallback listen(PipeStateListener listener) {
    _pipeStateListener = listener;
    return () {
      if (identical(_pipeStateListener, listener)) {
        _pipeStateListener = null;
        Logging.i(_tag, "[listen] cancelled, deviceId=$_deviceId");
      }
    };
  }

  Future<Resp<Uint8List?>> instruct(
    int id,
    Uint8List? data, {
    int timeoutSecond = 5,
  }) {
    Completer<Resp<Uint8List?>> completer = Completer<Resp<Uint8List?>>();
    void proxyListener(int state, Uint8List? buffer) => completer.complete(
      state == 0 ? Resp.success(buffer) : Resp.error(state, ""),
    );
    _nativePipe.instruct(id, data, proxyListener, timeoutSecond);
    return completer.future;
  }

  static Pipe create(String deviceId) =>
      Pipe._(deviceId, RapidNativePipe(deviceId)..create());

  static Pipe createIndependent(String deviceId) => Pipe._(
        deviceId,
        RapidNativePipe(deviceId, useCache: false)..create(),
      );

  static Future<void> prepareToken(String deviceId) async =>
      await compute(_prepareTokenInIsolate, deviceId);
  static void _prepareTokenInIsolate(String deviceId) =>
      RapidNativePipe.prepareToken(deviceId);

  static void debuggingTGRTC(bool enable) =>
      RapidNativePipe.enableTgrtcDebugging(enable);
}
