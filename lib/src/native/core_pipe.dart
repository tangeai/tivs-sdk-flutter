part of 'library.dart';

typedef InstructResponseListener = void Function(int state, Uint8List? buffer);

class RapidNativePipe {
  static const String _tag = "NativePipe";

  final String _deviceId;
  final bool _useCache;

  Pointer<Void>? _pipePtr;
  Function(int, String)? _statusCallback;
  RapidExternalDataListener? _externalDataListener;
  // ignore: non_constant_identifier_names
  Future<void>? _record_query_cleanup;

  late final ReceivePort _receivePortOfState;
  late final SendPort _sendPortOfState;
  late final ReceivePort _receivePortOfExternalData;
  late final SendPort _sendPortOfExternalData;

  RapidNativePipe(this._deviceId, {bool useCache = true})
      : _useCache = useCache {
    _receivePortOfState = ReceivePort();
    _sendPortOfState = _receivePortOfState.sendPort;
    _receivePortOfExternalData = ReceivePort();
    _sendPortOfExternalData = _receivePortOfExternalData.sendPort;

    _receivePortOfState.asBroadcastStream().listen((dynamic message) {
      if (message is int) {
        _onStatus(message);
      }
    });

    _receivePortOfExternalData.asBroadcastStream().listen((dynamic message) {
      if (message is! List<dynamic> || message.length != 4) return;
      final type = message[0] as int? ?? 0;
      final data1 = message[1] as int? ?? 0;
      final data2 = message[2] as int? ?? 0;
      final buffer = message[3] as Uint8List?;
      _externalDataListener?.call(type, data1, data2, buffer);
    });
  }

  static void enableTgrtcDebugging(bool enable) {
    coreApiPipeBinding.RAPID_Core_Pipe_TGRTC_EnableDebugging(enable ? 1 : 0);
  }

  static void prepareToken(String deviceId) {
    Pointer<Utf8> deviceIdC = deviceId.toNativeUtf8();
    coreApiPipeBinding.RAPID_Core_PipeToken_Prepare(deviceIdC);
    calloc.free(deviceIdC);
  }

  bool create() {
    Pointer<Utf8> deviceIdC = _deviceId.toNativeUtf8();
    _pipePtr = _useCache
        ? coreApiPipeBinding.RAPID_Core_PipeProxy_Create(deviceIdC)
        : coreApiPipeBinding.RAPID_Core_PipeProxy_CreateIndependent(deviceIdC);
    calloc.free(deviceIdC);

    if (_pipePtr == nullptr) {
      Logging.i(_tag, "create failed to create pipe");
      _pipePtr = null;
      return false;
    }

    coreApiPipeBinding.RAPID_Core_PipeProxy_SetStatusSendPort(
        _pipePtr!, _sendPortOfState.nativePort);
    _syncExternalDataSendPort();
    return true;
  }

  void enableLanMode() {
    if (_pipePtr != null && _pipePtr != nullptr) {
      coreApiPipeBinding.RAPID_Core_PipeProxy_EnableLanMode(_pipePtr!, 1);
    }
  }

  void setTransportMode(int mode) {
    if (_pipePtr != null && _pipePtr != nullptr) {
      coreApiPipeBinding.RAPID_Core_PipeProxy_SetTransportMode(_pipePtr!, mode);
    }
  }

  // ignore: non_constant_identifier_names
  void copy_connection_config_from(RapidNativePipe source) {
    final targetPointer = _pipePtr;
    final sourcePointer = source._pipePtr;
    if (_record_query_cleanup != null ||
        source._record_query_cleanup != null ||
        targetPointer == null ||
        sourcePointer == null ||
        coreApiPipeBinding.RAPID_Core_PipeProxy_CopyConnectionConfig(
                targetPointer, sourcePointer) !=
            1) {
      throw StateError('Record query connection configuration unavailable');
    }
  }

  void destroy() {
    if (_record_query_cleanup != null) {
      throw StateError('Record query cleanup already owns this Pipe');
    }
    if (_pipePtr != null && _pipePtr != nullptr) {
      coreApiExternalBinding.RAPID_Core_Instruct_SetUserExternalDataSendPort(
          _pipePtr!, 0);
      coreApiPipeBinding.RAPID_Core_PipeProxy_Destroy(_pipePtr!);
      _pipePtr = null;
    }
    _receivePortOfState.close();
    _receivePortOfExternalData.close();
  }

  // ignore: non_constant_identifier_names
  Future<void> destroy_record_query() {
    if (_useCache) throw StateError('Shared Pipe cannot use query cleanup');
    if (_record_query_cleanup != null) return _record_query_cleanup!;
    final pointer = _pipePtr;
    _statusCallback = null;
    _externalDataListener = null;
    _receivePortOfState.close();
    _receivePortOfExternalData.close();
    if (pointer == null || pointer == nullptr) return Future.value();
    coreApiPipeBinding.RAPID_Core_PipeProxy_SetStatusSendPort(pointer, 0);
    coreApiExternalBinding.RAPID_Core_Instruct_SetUserExternalDataSendPort(
        pointer, 0);
    return _record_query_cleanup =
        _release_record_query_pipe(pointer.address, () => _pipePtr = null);
  }

  void establish() {
    if (_pipePtr != null && _pipePtr != nullptr) {
      coreApiPipeBinding.RAPID_Core_PipeProxy_Establish(_pipePtr!);
    }
  }

  void abolish() {
    if (_pipePtr != null && _pipePtr != nullptr) {
      coreApiPipeBinding.RAPID_Core_PipeProxy_Abolish(_pipePtr!);
    }
  }

  void instruct(int id, Uint8List? data, InstructResponseListener listener,
      int timeoutSecond) {
    if (_pipePtr == null || _pipePtr == nullptr) {
      return;
    }

    final ReceivePort receivePortOfInstruct = ReceivePort();
    final SendPort sendPortOfInstruct = receivePortOfInstruct.sendPort;
    receivePortOfInstruct.asBroadcastStream().listen((dynamic message) {
      if (message is List<dynamic> && message.length == 2) {
        final state = message[0] as int;
        final buffer = message[1] as Uint8List?;
        listener(state, buffer);
        receivePortOfInstruct.close();
      }
    });

    Pointer<Utf8> utf8Pointer;
    final size = data?.length ?? 0;

    if (data == null || data.isEmpty) {
      utf8Pointer = nullptr.cast<Utf8>();
    } else {
      utf8Pointer = calloc.allocate<Uint8>(data.length).cast<Utf8>();
      utf8Pointer.cast<Uint8>().asTypedList(data.length).setAll(0, data);
    }

    try {
      coreApiPipeBinding
          .RAPID_Core_PipeProxy_InstructRequest_ResponseBySendPort(
        _pipePtr!,
        id,
        utf8Pointer,
        size,
        sendPortOfInstruct.nativePort,
        timeoutSecond,
      );
    } catch (e) {
      Logging.i(_tag, "instruct error: $e");
    } finally {
      if (utf8Pointer != nullptr) {
        calloc.free(utf8Pointer);
      }
    }
  }

  void setStatusCallback(Function(int, String) statusCallback) {
    _statusCallback = statusCallback;
  }

  void setExternalDataListener(RapidExternalDataListener? listener) {
    _externalDataListener = listener;
    _syncExternalDataSendPort();
  }

  int currentStatus() {
    if (_pipePtr == null || _pipePtr == nullptr) return -1;
    return coreApiPipeBinding.RAPID_Core_PipeProxy_Status(_pipePtr!);
  }

  String? get setupMetricsSnapshot {
    if (_pipePtr == null || _pipePtr == nullptr) {
      return null;
    }

    final jsonPtr =
        coreApiPipeBinding.RAPID_Core_PipeProxy_GetSetupMetrics(_pipePtr!);
    if (jsonPtr == nullptr || jsonPtr.address == 0) {
      return null;
    }

    try {
      return jsonPtr.toDartString();
    } finally {
      coreApiPipeBinding.RAPID_Core_PipeProxy_FreeSetupMetrics(jsonPtr);
    }
  }

  void _syncExternalDataSendPort() {
    if (_pipePtr == null || _pipePtr == nullptr) {
      return;
    }
    final port =
        _externalDataListener == null ? 0 : _sendPortOfExternalData.nativePort;
    coreApiExternalBinding.RAPID_Core_Instruct_SetUserExternalDataSendPort(
        _pipePtr!, port);
  }

  void _onStatus(int status) {
    _statusCallback?.call(status, "");
  }
}
