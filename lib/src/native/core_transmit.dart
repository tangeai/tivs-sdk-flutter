part of 'library.dart';

typedef ProfileTransmitterFunc = void Function(int state);

class RapidNativeProfileTransmitter {
  late final ReceivePort _receivePortOfState;
  late final SendPort _sendPortOfState;

  Pointer<Void>? _nativePtr;

  ProfileTransmitterFunc? _listener;

  void create() {
    _receivePortOfState = ReceivePort();
    _sendPortOfState = _receivePortOfState.sendPort;
    _receivePortOfState.asBroadcastStream().listen((dynamic message) {
      if (message is int) {
        _onState(message);
      }
    });

    _nativePtr = coreApiTransmitBinding.RAPID_Core_ProfileTransmitter_Create();
    coreApiTransmitBinding.RAPID_Core_ProfileTransmitter_SetResponseSendPort(_nativePtr!, _sendPortOfState.nativePort);
  }

  void prepare(String ssid, String password, String token) {
    if (_nativePtr == null || _nativePtr == nullptr) {
      return;
    }

    Pointer<Utf8> ssidC = ssid.toNativeUtf8();
    Pointer<Utf8> passwordC = password.toNativeUtf8();
    Pointer<Utf8> tokenC = token.toNativeUtf8();
    coreApiTransmitBinding.RAPID_Core_ProfileTransmitter_Prepare(_nativePtr!, ssidC, passwordC, tokenC);
    calloc.free(ssidC);
    calloc.free(passwordC);
    calloc.free(tokenC);
  }

  void start() {
    if (_nativePtr == null || _nativePtr == nullptr) {
      return;
    }

    coreApiTransmitBinding.RAPID_Core_ProfileTransmitter_Start(_nativePtr!);
  }

  void stop() {
    if (_nativePtr == null || _nativePtr == nullptr) {
      return;
    }

    coreApiTransmitBinding.RAPID_Core_ProfileTransmitter_Stop(_nativePtr!);
  }

  void destroy() {
    if (_nativePtr == null || _nativePtr == nullptr) {
      return;
    }

    coreApiTransmitBinding.RAPID_Core_ProfileTransmitter_Free(_nativePtr!);

    _receivePortOfState.close();
    _nativePtr = null;
    _listener = null;
  }

  void _onState(int state) {
    _listener?.call(state);
  }

  set listener(ProfileTransmitterFunc func) {
    _listener = func;
  }
}
