part of 'library.dart';

typedef MediaCaptureStateListener = Function(MediaCaptureState state);
typedef MediaCaptureUtsListener = Function(int millisecond);

enum MediaCaptureState { unknown, started, completed, error, stopped }

class _MediaCapture {
  final RapidNativeCapture _nativeCapture;
  MediaCaptureStateListener? _stateListener;
  MediaCaptureUtsListener? _utsListener;
  Timer? _utsTimer;

  _MediaCapture._(this._nativeCapture) {
    _nativeCapture.onCaptureState = (state) {
      _stateListener?.call(state >= 0 && state < MediaCaptureState.values.length
          ? MediaCaptureState.values[state]
          : MediaCaptureState.unknown);
    };
  }

  set onCaptureState(MediaCaptureStateListener listener) =>
      _stateListener = listener;

  set onUts(MediaCaptureUtsListener listener) => _utsListener = listener;

  void _launchUtsTimer() {
    _utsTimer?.cancel();
    _utsTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      final ts = _nativeCapture.uts;
      if (ts > 0) _utsListener?.call(ts);
    });
  }

  void prepare(Pointer<Void> providerPtr) =>
      _nativeCapture.prepare(providerPtr);

  void setTimeline(int startUtcMs, int endUtcMs) =>
      _nativeCapture.setTimeline(startUtcMs, endUtcMs);

  void start(String path) {
    _nativeCapture.start(path);
    if (_utsListener != null) _launchUtsTimer();
  }

  void stop() {
    _nativeCapture.stop();
    _utsTimer?.cancel();
  }

  void destroy() => _nativeCapture.destroy();

  static _MediaCapture create() {
    final nativeCapture = RapidNativeCapture();
    nativeCapture.create();
    return _MediaCapture._(nativeCapture);
  }
}
