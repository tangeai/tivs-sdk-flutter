part of 'library.dart';

typedef InstructStandardResponseListener = void Function(String response);

class RapidNativeInstructStandard {
  static const String _tag = "_RapidNativeInstructStandard_";
  final RapidNativePipe _nativePipe;

  late final ReceivePort _receivePort;
  late final SendPort _sendPort;

  RapidNativeInstructStandard(RapidNativePipe pipe) : _nativePipe = pipe;
  Pointer<Void>? _nativePtr;
  InstructStandardResponseListener? _responseListener;

  void create() {
    _receivePort = ReceivePort();
    _sendPort = _receivePort.sendPort;

    _nativePtr = coreApiInstructBinding.RAPID_Core_InstructStandard_Create(_nativePipe._pipePtr!, nullptr, nullptr);
    coreApiInstructBinding.RAPID_Core_InstructStandard_SetResponseSendPort(_nativePtr!, _sendPort.nativePort);

    _receivePort.asBroadcastStream().listen((dynamic message) {
      if (message is Uint8List) {
        String messageString = utf8.decode(message);
        _onInstructResponse(messageString);
      }
    });
  }

  void request(String name, String params, InstructStandardResponseListener? responseListener) {
    _responseListener = responseListener;
    if (_nativePtr != null && _nativePtr != nullptr) {
      Pointer<Utf8> nameC = name.toNativeUtf8();
      Pointer<Utf8> paramsC = params.toNativeUtf8();
      coreApiInstructBinding.RAPID_Core_InstructStandard_Request(_nativePtr!, nameC, paramsC);
      calloc.free(nameC);
      calloc.free(paramsC);
    } else {
      Logging.i(_tag, "request no valid instruct to request");
    }
  }

  void destroy() {
    if (_nativePtr != null && _nativePtr != nullptr) {
      coreApiInstructBinding.RAPID_Core_InstructStandard_Release(_nativePtr!);
      _nativePtr = null;
    } else {
      Logging.i(_tag, "destroy no valid instruct to destroy");
    }

    _receivePort.close();
    _responseListener = null;
  }

  void _onInstructResponse(String data) {
    Logging.i(_tag, "onInstructResponse data = $data");
    _responseListener?.call(data);
  }
}
