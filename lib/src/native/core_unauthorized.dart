part of 'library.dart';

class RapidNativeUnauthorizedChannel {
  static const String _tag = "NativeUnauthorizedChannel";

  static RapidNativeUnauthorizedChannel? _instance;
  static RapidNativeUnauthorizedChannel get instance => _instance ??= RapidNativeUnauthorizedChannel._();

  Function()? _callback;

  late final ReceivePort _receivePort;
  late final SendPort _sendPort;

  RapidNativeUnauthorizedChannel._() {
    _receivePort = ReceivePort();
    _sendPort = _receivePort.sendPort;

    _receivePort.asBroadcastStream().listen((dynamic message) {
      if (message is int && message == 401) {
        _onUnauthorized();
      }
    });
  }

  void setCallback(Function() callback) {
    _callback = callback;
    coreApiUnauthorizedBinding.RAPID_Core_Unauthorized_SetSendPort(_sendPort.nativePort);
  }

  void _onUnauthorized() {
    Logging.i(_tag, "[_onUnauthorized] HTTP 401 Unauthorized detected");
    _callback?.call();
  }

  void cleanup() {
    _receivePort.close();
    _callback = null;
  }
}
