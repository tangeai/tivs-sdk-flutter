part of 'library.dart';

class RapidNativeCapture {
  static const String _tag = "NativeCapture";
  Pointer<Void>? _ptr;

  Function(int)? _captureStateListener;

  late final ReceivePort _receivePortCaptureState;
  late final SendPort _sendPortCaptureState;

  bool create() {
    _receivePortCaptureState = ReceivePort();
    _sendPortCaptureState = _receivePortCaptureState.sendPort;

    _ptr = mediaApiCaptureBinding.RAPID_MediaCapture_Create();

    if (_ptr != nullptr) {
      mediaApiCaptureBinding.RAPID_MediaCapture_SetStateSendPort(
          _ptr!, _sendPortCaptureState.nativePort);
      _receivePortCaptureState.asBroadcastStream().listen((dynamic message) {
        if (message is int) {
          _captureStateListener?.call(message);
        }
      });

      return true;
    }

    return false;
  }

  set onCaptureState(Function(int) listener) =>
      _captureStateListener = listener;

  void prepare(Pointer<Void> providerPtr) {
    if (_ptr != null && _ptr != nullptr) {
      Pointer<Void> ffiPointer = providerPtr.cast<Void>();
      mediaApiCaptureBinding.RAPID_MediaCapture_Prepare(_ptr!, ffiPointer);
    }
  }

  void setTimeline(int startUtcMs, int endUtcMs) {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiCaptureBinding.RAPID_MediaCapture_SetTimeline(
          _ptr!, startUtcMs, endUtcMs);
    }
  }

  void start(String path) {
    if (_ptr != null && _ptr != nullptr) {
      Pointer<Utf8> pathC = path.toNativeUtf8();
      mediaApiCaptureBinding.RAPID_MediaCapture_Start(_ptr!, pathC);
      calloc.free(pathC);
    }
  }

  void stop() {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiCaptureBinding.RAPID_MediaCapture_Stop(_ptr!);
    }
  }

  int get state => _ptr != null && _ptr != nullptr
      ? mediaApiCaptureBinding.RAPID_MediaCapture_CurrentState(_ptr!)
      : -1;

  int get uts => _ptr != null && _ptr != nullptr
      ? mediaApiCaptureBinding.RAPID_MediaCapture_GetUts(_ptr!)
      : 0;

  void destroy() {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiCaptureBinding.RAPID_MediaCapture_Destroy(_ptr!);
      _ptr = null;
      _receivePortCaptureState.close();
    }
  }

  int get ptr => _ptr != null ? _ptr!.address : 0;
}
