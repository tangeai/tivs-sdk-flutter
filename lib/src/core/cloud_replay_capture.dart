part of 'library.dart';

enum CloudReplayCaptureState { idle, started, completed, error }

typedef CloudReplayCaptureStateListener = void Function(
    CloudReplayCaptureState state, int errorCode);

typedef CloudReplayCaptureProgressListener = void Function(double progress);

class CloudReplayCapture {
  final String _deviceId;
  CloudReplayCaptureState _currentState = CloudReplayCaptureState.idle;

  static const _errorCodeExportToGallery = 10;
  static const _errorCodeWriteStreamTrailer = 20;

  CloudReplayCaptureStateListener? _stateListener;
  CloudReplayCaptureProgressListener? _progressListener;

  late Pointer<Void> providerPtr;
  _MediaCapture? _mediaCapture;

  int _startTimestampInSecond = 0;
  int _endTimestampInSecond = 0;
  String _recordingCachePath = "";

  bool _started = false;
  bool _autoExport = true;

  String? _galleryName;

  CloudReplayCapture._(
      this._deviceId, CloudReplayStream _cloudReplayStream, int _cameraIndex) {
    providerPtr = _cloudReplayStream.provider(cameraIndex: _cameraIndex)!;
    _cloudReplayStream._enableDownloadControl(true);
  }

  set onState(CloudReplayCaptureStateListener listener) =>
      _stateListener = listener;

  set onProgress(CloudReplayCaptureProgressListener listener) =>
      _progressListener = listener;

  CloudReplayCaptureState get currentState => _currentState;

  String? get recordedFilePath =>
      _recordingCachePath.isEmpty ? null : _recordingCachePath;

  Future<bool> start(int startTimestampInSecond, int endTimestampInSecond,
      {bool autoExport = true, String? galleryName}) async {
    if (_started) return false;
    _started = true;

    final cachedPath = await _PlatformChannel.requireWriteableCachePath();
    if (cachedPath.isEmpty) return false;

    if (!cachedPath.endsWith(".mp4")) {
      _recordingCachePath = "$cachedPath.mp4";
    } else {
      _recordingCachePath = cachedPath;
    }

    _autoExport = autoExport;
    _galleryName = galleryName;
    _startTimestampInSecond = startTimestampInSecond;
    _endTimestampInSecond = endTimestampInSecond;

    _mediaCapture = _MediaCapture.create();
    _mediaCapture!.onCaptureState = (state) {
      if (state == MediaCaptureState.completed) {
        _autoComplete().catchError((_) {});
      } else if (state == MediaCaptureState.error) {
        _emit(CloudReplayCaptureState.error,
            errorCode: _errorCodeWriteStreamTrailer);
      } else if (state == MediaCaptureState.started) {
        _emit(CloudReplayCaptureState.started);
      }
    };
    _mediaCapture!.onUts = (uts) => _emitProgress(uts ~/ 1000);
    _mediaCapture!.prepare(providerPtr);
    _mediaCapture!.setTimeline(
        startTimestampInSecond * 1000, endTimestampInSecond * 1000);
    _mediaCapture!.start(_recordingCachePath);

    return true;
  }

  void stop() {
    if (!_started) return;
    _started = false;

    _mediaCapture?.stop();
    _mediaCapture?.destroy();
    _mediaCapture = null;

    _currentState = CloudReplayCaptureState.idle;
  }

  Future<void> _autoComplete() async {
    if (_autoExport) {
      if (await _PlatformChannel.exportCapturedVideo(_recordingCachePath,
          galleryName: _galleryName)) {
        _progressListener?.call(1.0);
        _emit(CloudReplayCaptureState.completed);
      } else {
        _emit(CloudReplayCaptureState.error,
            errorCode: _errorCodeExportToGallery);
      }
    } else {
      _progressListener?.call(1.0);
      _emit(CloudReplayCaptureState.completed);
    }

    stop();
  }

  static CloudReplayCapture create(
          String deviceId, CloudReplayStream cloudReplayStream,
          {int cameraIndex = 0}) =>
      CloudReplayCapture._(deviceId, cloudReplayStream, cameraIndex);

  void _emit(CloudReplayCaptureState state, {int errorCode = 0}) {
    if (_currentState == state) return;
    _currentState = state;
    _stateListener?.call(_currentState, errorCode);
  }

  void _emitProgress(int uts) {
    if (_startTimestampInSecond == 0 || _endTimestampInSecond == 0) return;
    final total = _endTimestampInSecond - _startTimestampInSecond;
    if (total <= 0) return;

    final current = uts - _startTimestampInSecond;
    if (current < 0) return;

    final progress = (current / total).clamp(0.0, 1.0);
    final emitValue = progress >= 1.0 ? 0.99 : progress;
    _progressListener?.call(emitValue);
  }
}
