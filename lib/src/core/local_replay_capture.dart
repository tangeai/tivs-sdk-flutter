part of 'library.dart';

enum LocalReplayCaptureState { idle, started, completed, error }

typedef LocalReplayCaptureStateListener = void Function(
    LocalReplayCaptureState state, int errorCode);

typedef LocalReplayCaptureProgressListener = void Function(double progress);

class LocalReplayCapture {
  static const String _tag = "LocalReplayCapture";

  LocalReplayCaptureState _currentState = LocalReplayCaptureState.idle;

  static const _errorCodeExportToGallery = 10;
  static const _errorCodeWriteStreamTrailer = 20;

  LocalReplayCaptureStateListener? _stateListener;
  LocalReplayCaptureProgressListener? _progressListener;

  final Pointer<Void> _providerPtr;
  _MediaCapture? _mediaCapture;

  int _startTimestampInSecond = 0;
  int _endTimestampInSecond = 0;
  String _recordingCachePath = "";

  bool _started = false;
  int _startGeneration = 0;
  bool _autoExport = true;

  String? _galleryName;

  LocalReplayCapture._(this._providerPtr);

  set onState(LocalReplayCaptureStateListener listener) =>
      _stateListener = listener;

  set onProgress(LocalReplayCaptureProgressListener listener) =>
      _progressListener = listener;

  LocalReplayCaptureState get currentState => _currentState;

  String? get recordedFilePath =>
      _recordingCachePath.isEmpty ? null : _recordingCachePath;

  Future<bool> start(int startTimestampInSecond, int endTimestampInSecond,
      {bool autoExport = true, String? galleryName}) async {
    if (_started) {
      Logging.i(_tag, "[start] already started");
      return false;
    }

    _started = true;
    final startGeneration = ++_startGeneration;

    final cachedPath = await _PlatformChannel.requireWriteableCachePath();
    if (!_started || startGeneration != _startGeneration) return false;
    if (cachedPath.isEmpty) {
      Logging.i(_tag, "[start] empty cache path");
      _started = false;
      return false;
    }

    if (!cachedPath.endsWith(".mp4")) {
      _recordingCachePath = "$cachedPath.mp4";
    } else {
      _recordingCachePath = cachedPath;
    }

    _autoExport = autoExport;
    _galleryName = galleryName;
    _startTimestampInSecond = startTimestampInSecond;
    _endTimestampInSecond = endTimestampInSecond;

    Logging.i(
      _tag,
      "[start] start=${_startTimestampInSecond}s end=${_endTimestampInSecond}s path=$_recordingCachePath autoExport=$_autoExport",
    );

    _mediaCapture = _MediaCapture.create();
    _mediaCapture!.onCaptureState = (state) {
      if (state == MediaCaptureState.completed) {
        _autoComplete().catchError((_) {});
      } else if (state == MediaCaptureState.error) {
        _emit(LocalReplayCaptureState.error,
            errorCode: _errorCodeWriteStreamTrailer);
      } else if (state == MediaCaptureState.started) {
        _emit(LocalReplayCaptureState.started);
      }
    };
    _mediaCapture!.onUts = (uts) => _emitProgress(uts ~/ 1000);
    _mediaCapture!.prepare(_providerPtr);
    _mediaCapture!.setTimeline(
        startTimestampInSecond * 1000, endTimestampInSecond * 1000);
    _mediaCapture!.start(_recordingCachePath);

    return true;
  }

  void stop() {
    _startGeneration++;
    if (!_started) {
      Logging.i(_tag, "[stop] not started");
      return;
    }

    Logging.i(_tag, "[stop]");
    _started = false;

    _mediaCapture?.stop();
    _mediaCapture?.destroy();
    _mediaCapture = null;

    _currentState = LocalReplayCaptureState.idle;
  }

  Future<void> _autoComplete() async {
    if (_autoExport) {
      Logging.i(_tag, "[export] start path=$_recordingCachePath");
      if (await _PlatformChannel.exportCapturedVideo(_recordingCachePath,
          galleryName: _galleryName)) {
        Logging.i(_tag, "[export] completed path=$_recordingCachePath");
        _progressListener?.call(1.0);
        _emit(LocalReplayCaptureState.completed);
      } else {
        Logging.i(_tag, "[export] failed path=$_recordingCachePath");
        _emit(LocalReplayCaptureState.error,
            errorCode: _errorCodeExportToGallery);
      }
    } else {
      _progressListener?.call(1.0);
      _emit(LocalReplayCaptureState.completed);
    }

    stop();
  }

  static LocalReplayCapture create(LocalReplayStream localReplayStream,
      {int cameraIndex = 0}) {
    final providerPtr = localReplayStream.provider(cameraIndex: cameraIndex);
    if (providerPtr == null) {
      throw FlutterError("LocalReplayStream.provider() returned null");
    }
    return LocalReplayCapture._(providerPtr);
  }

  void _emit(LocalReplayCaptureState state, {int errorCode = 0}) {
    if (_currentState == state) return;
    _currentState = state;
    _stateListener?.call(_currentState, errorCode);
  }

  void _emitProgress(int utsInSecond) {
    if (_startTimestampInSecond == 0 || _endTimestampInSecond == 0) return;
    final total = _endTimestampInSecond - _startTimestampInSecond;
    if (total <= 0) return;

    final current = utsInSecond - _startTimestampInSecond;
    if (current < 0) return;

    final progress = (current / total).clamp(0.0, 1.0);
    final emitValue = progress >= 1.0 ? 0.99 : progress;
    _progressListener?.call(emitValue);
  }
}
