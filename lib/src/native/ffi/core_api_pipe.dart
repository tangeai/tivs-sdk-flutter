// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class CoreApiPipeBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  CoreApiPipeBinding(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  CoreApiPipeBinding.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  RAPID_Core_PipeProxy RAPID_Core_PipeProxy_Create(
    ffi.Pointer<Utf8> devide_id,
  ) {
    return _RAPID_Core_PipeProxy_Create(
      devide_id,
    );
  }

  late final _RAPID_Core_PipeProxy_CreatePtr = _lookup<
          ffi.NativeFunction<RAPID_Core_PipeProxy Function(ffi.Pointer<Utf8>)>>(
      'RAPID_Core_PipeProxy_Create');
  late final _RAPID_Core_PipeProxy_Create = _RAPID_Core_PipeProxy_CreatePtr
      .asFunction<RAPID_Core_PipeProxy Function(ffi.Pointer<Utf8>)>();

  RAPID_Core_PipeProxy RAPID_Core_PipeProxy_CreateIndependent(
    ffi.Pointer<Utf8> device_id,
  ) {
    return _RAPID_Core_PipeProxy_CreateIndependent(
      device_id,
    );
  }

  late final _RAPID_Core_PipeProxy_CreateIndependentPtr = _lookup<
          ffi.NativeFunction<RAPID_Core_PipeProxy Function(ffi.Pointer<Utf8>)>>(
      'RAPID_Core_PipeProxy_CreateIndependent');
  late final _RAPID_Core_PipeProxy_CreateIndependent =
      _RAPID_Core_PipeProxy_CreateIndependentPtr.asFunction<
          RAPID_Core_PipeProxy Function(ffi.Pointer<Utf8>)>();

  void RAPID_Core_PipeProxy_Destroy(
    RAPID_Core_PipeProxy proxy,
  ) {
    return _RAPID_Core_PipeProxy_Destroy(
      proxy,
    );
  }

  late final _RAPID_Core_PipeProxy_DestroyPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_PipeProxy)>>(
          'RAPID_Core_PipeProxy_Destroy');
  late final _RAPID_Core_PipeProxy_Destroy = _RAPID_Core_PipeProxy_DestroyPtr
      .asFunction<void Function(RAPID_Core_PipeProxy)>();

  int RAPID_Core_PipeProxy_DestroyRecordQuery(RAPID_Core_PipeProxy proxy) =>
      _destroyRecordQuery(proxy);

  late final _destroyRecordQuery =
      _lookup<ffi.NativeFunction<ffi.Int Function(RAPID_Core_PipeProxy)>>(
              'RAPID_Core_PipeProxy_DestroyRecordQuery')
          .asFunction<int Function(RAPID_Core_PipeProxy)>();

  int RAPID_Core_PipeProxy_CopyConnectionConfig(
          RAPID_Core_PipeProxy destination, RAPID_Core_PipeProxy source) =>
      _copyConnectionConfig(destination, source);

  late final _copyConnectionConfig = _lookup<
              ffi.NativeFunction<
                  ffi.Int Function(
                      RAPID_Core_PipeProxy, RAPID_Core_PipeProxy)>>(
          'RAPID_Core_PipeProxy_CopyConnectionConfig')
      .asFunction<int Function(RAPID_Core_PipeProxy, RAPID_Core_PipeProxy)>();

  void RAPID_Core_PipeProxy_Establish(
    RAPID_Core_PipeProxy proxy,
  ) {
    return _RAPID_Core_PipeProxy_Establish(
      proxy,
    );
  }

  late final _RAPID_Core_PipeProxy_EstablishPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_PipeProxy)>>(
          'RAPID_Core_PipeProxy_Establish');
  late final _RAPID_Core_PipeProxy_Establish =
      _RAPID_Core_PipeProxy_EstablishPtr.asFunction<
          void Function(RAPID_Core_PipeProxy)>();

  void RAPID_Core_PipeProxy_Abolish(
    RAPID_Core_PipeProxy proxy,
  ) {
    return _RAPID_Core_PipeProxy_Abolish(
      proxy,
    );
  }

  late final _RAPID_Core_PipeProxy_AbolishPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_PipeProxy)>>(
          'RAPID_Core_PipeProxy_Abolish');
  late final _RAPID_Core_PipeProxy_Abolish = _RAPID_Core_PipeProxy_AbolishPtr
      .asFunction<void Function(RAPID_Core_PipeProxy)>();

  int RAPID_Core_PipeProxy_Status(
    RAPID_Core_PipeProxy proxy,
  ) {
    return _RAPID_Core_PipeProxy_Status(
      proxy,
    );
  }

  late final _RAPID_Core_PipeProxy_StatusPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(RAPID_Core_PipeProxy)>>(
          'RAPID_Core_PipeProxy_Status');
  late final _RAPID_Core_PipeProxy_Status = _RAPID_Core_PipeProxy_StatusPtr
      .asFunction<int Function(RAPID_Core_PipeProxy)>();

  void RAPID_Core_PipeProxy_EnableLanMode(
    RAPID_Core_PipeProxy proxy,
    int lan_mode,
  ) {
    return _RAPID_Core_PipeProxy_EnableLanMode(
      proxy,
      lan_mode,
    );
  }

  late final _RAPID_Core_PipeProxy_EnableLanModePtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_Core_PipeProxy, ffi.Int)>>(
      'RAPID_Core_PipeProxy_EnableLanMode');
  late final _RAPID_Core_PipeProxy_EnableLanMode =
      _RAPID_Core_PipeProxy_EnableLanModePtr.asFunction<
          void Function(RAPID_Core_PipeProxy, int)>();

  void RAPID_Core_PipeProxy_SetTransportMode(
    RAPID_Core_PipeProxy proxy,
    int mode,
  ) {
    return _RAPID_Core_PipeProxy_SetTransportMode(
      proxy,
      mode,
    );
  }

  late final _RAPID_Core_PipeProxy_SetTransportModePtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_Core_PipeProxy, ffi.Int)>>(
      'RAPID_Core_PipeProxy_SetTransportMode');
  late final _RAPID_Core_PipeProxy_SetTransportMode =
      _RAPID_Core_PipeProxy_SetTransportModePtr.asFunction<
          void Function(RAPID_Core_PipeProxy, int)>();

  void RAPID_Core_PipeProxy_SetStatusFunc(
    RAPID_Core_PipeProxy proxy,
    RAPID_Core_PipeStateFunc func,
    ffi.Pointer<ffi.Void> user_context,
  ) {
    return _RAPID_Core_PipeProxy_SetStatusFunc(
      proxy,
      func,
      user_context,
    );
  }

  late final _RAPID_Core_PipeProxy_SetStatusFuncPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_Core_PipeProxy, RAPID_Core_PipeStateFunc,
              ffi.Pointer<ffi.Void>)>>('RAPID_Core_PipeProxy_SetStatusFunc');
  late final _RAPID_Core_PipeProxy_SetStatusFunc =
      _RAPID_Core_PipeProxy_SetStatusFuncPtr.asFunction<
          void Function(RAPID_Core_PipeProxy, RAPID_Core_PipeStateFunc,
              ffi.Pointer<ffi.Void>)>();

  void RAPID_Core_PipeProxy_SetStatusSendPort(
    RAPID_Core_PipeProxy proxy,
    int port,
  ) {
    return _RAPID_Core_PipeProxy_SetStatusSendPort(
      proxy,
      port,
    );
  }

  late final _RAPID_Core_PipeProxy_SetStatusSendPortPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_Core_PipeProxy,
              ffi.LongLong)>>('RAPID_Core_PipeProxy_SetStatusSendPort');
  late final _RAPID_Core_PipeProxy_SetStatusSendPort =
      _RAPID_Core_PipeProxy_SetStatusSendPortPtr.asFunction<
          void Function(RAPID_Core_PipeProxy, int)>();

  void RAPID_Core_PipeProxy_InstructRequest(
    RAPID_Core_PipeProxy proxy,
    int id,
    ffi.Pointer<Utf8> buffer,
    int buffer_size,
    RAPID_Core_InstructResponseFunc func,
    int timeout_s,
    ffi.Pointer<ffi.Void> user_context,
  ) {
    return _RAPID_Core_PipeProxy_InstructRequest(
      proxy,
      id,
      buffer,
      buffer_size,
      func,
      timeout_s,
      user_context,
    );
  }

  late final _RAPID_Core_PipeProxy_InstructRequestPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              RAPID_Core_PipeProxy,
              ffi.UnsignedInt,
              ffi.Pointer<Utf8>,
              ffi.UnsignedInt,
              RAPID_Core_InstructResponseFunc,
              ffi.UnsignedInt,
              ffi.Pointer<ffi.Void>)>>('RAPID_Core_PipeProxy_InstructRequest');
  late final _RAPID_Core_PipeProxy_InstructRequest =
      _RAPID_Core_PipeProxy_InstructRequestPtr.asFunction<
          void Function(RAPID_Core_PipeProxy, int, ffi.Pointer<Utf8>, int,
              RAPID_Core_InstructResponseFunc, int, ffi.Pointer<ffi.Void>)>();

  void RAPID_Core_PipeProxy_InstructRequest_ResponseBySendPort(
    RAPID_Core_PipeProxy proxy,
    int id,
    ffi.Pointer<Utf8> buffer,
    int buffer_size,
    int send_port,
    int timeout_s,
  ) {
    return _RAPID_Core_PipeProxy_InstructRequest_ResponseBySendPort(
      proxy,
      id,
      buffer,
      buffer_size,
      send_port,
      timeout_s,
    );
  }

  late final _RAPID_Core_PipeProxy_InstructRequest_ResponseBySendPortPtr =
      _lookup<
              ffi.NativeFunction<
                  ffi.Void Function(
                      RAPID_Core_PipeProxy,
                      ffi.UnsignedInt,
                      ffi.Pointer<Utf8>,
                      ffi.UnsignedInt,
                      ffi.LongLong,
                      ffi.UnsignedInt)>>(
          'RAPID_Core_PipeProxy_InstructRequest_ResponseBySendPort');
  late final _RAPID_Core_PipeProxy_InstructRequest_ResponseBySendPort =
      _RAPID_Core_PipeProxy_InstructRequest_ResponseBySendPortPtr.asFunction<
          void Function(
              RAPID_Core_PipeProxy, int, ffi.Pointer<Utf8>, int, int, int)>();

  void RAPID_Core_PipeToken_Prepare(
    ffi.Pointer<Utf8> device_id,
  ) {
    return _RAPID_Core_PipeToken_Prepare(
      device_id,
    );
  }

  late final _RAPID_Core_PipeToken_PreparePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<Utf8>)>>(
          'RAPID_Core_PipeToken_Prepare');
  late final _RAPID_Core_PipeToken_Prepare = _RAPID_Core_PipeToken_PreparePtr
      .asFunction<void Function(ffi.Pointer<Utf8>)>();

  ffi.Pointer<Utf8> RAPID_Core_PipeProxy_GetSetupMetrics(
    RAPID_Core_PipeProxy proxy,
  ) {
    return _RAPID_Core_PipeProxy_GetSetupMetrics(
      proxy,
    );
  }

  late final _RAPID_Core_PipeProxy_GetSetupMetricsPtr = _lookup<
          ffi.NativeFunction<ffi.Pointer<Utf8> Function(RAPID_Core_PipeProxy)>>(
      'RAPID_Core_PipeProxy_GetSetupMetrics');
  late final _RAPID_Core_PipeProxy_GetSetupMetrics =
      _RAPID_Core_PipeProxy_GetSetupMetricsPtr.asFunction<
          ffi.Pointer<Utf8> Function(RAPID_Core_PipeProxy)>();

  void RAPID_Core_PipeProxy_FreeSetupMetrics(
    ffi.Pointer<Utf8> json,
  ) {
    return _RAPID_Core_PipeProxy_FreeSetupMetrics(
      json,
    );
  }

  late final _RAPID_Core_PipeProxy_FreeSetupMetricsPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<Utf8>)>>(
          'RAPID_Core_PipeProxy_FreeSetupMetrics');
  late final _RAPID_Core_PipeProxy_FreeSetupMetrics =
      _RAPID_Core_PipeProxy_FreeSetupMetricsPtr.asFunction<
          void Function(ffi.Pointer<Utf8>)>();

  void RAPID_Core_Pipe_TGRTC_EnableLog(
    int enable,
  ) {
    return _RAPID_Core_Pipe_TGRTC_EnableLog(
      enable,
    );
  }

  late final _RAPID_Core_Pipe_TGRTC_EnableLogPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int)>>(
          'RAPID_Core_Pipe_TGRTC_EnableLog');
  late final _RAPID_Core_Pipe_TGRTC_EnableLog =
      _RAPID_Core_Pipe_TGRTC_EnableLogPtr.asFunction<void Function(int)>();

  void RAPID_Core_Pipe_TGRTC_EnableDebugging(
    int enable,
  ) {
    return _RAPID_Core_Pipe_TGRTC_EnableDebugging(
      enable,
    );
  }

  late final _RAPID_Core_Pipe_TGRTC_EnableDebuggingPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int)>>(
          'RAPID_Core_Pipe_TGRTC_EnableDebugging');
  late final _RAPID_Core_Pipe_TGRTC_EnableDebugging =
      _RAPID_Core_Pipe_TGRTC_EnableDebuggingPtr.asFunction<
          void Function(int)>();
}

abstract class RAPID_Core_PipeState {
  static const int RAPID_CORE_PIPE_STATE_UNDEFINED = 0;
  static const int RAPID_CORE_PIPE_STATE_ATTEMPTING = 1;
  static const int RAPID_CORE_PIPE_STATE_ESTABLISHED = 2;
  static const int RAPID_CORE_PIPE_STATE_ABOLISHED = 3;
  static const int RAPID_CORE_PIPE_STATE_FAILED = 4;
  static const int RAPID_CORE_PIPE_STATE_SHUTDOWN_BY_REMOTE = 5;
  static const int RAPID_CORE_PIPE_STATE_TOKEN_NOT_AVAILABLE = 6;
  static const int RAPID_CORE_PIPE_STATE_INTERNET_NOT_AVAILABLE = 7;
  static const int RAPID_CORE_PIPE_STATE_AUTH_FAILED = 8;
}

typedef RAPID_Core_PipeProxy = ffi.Pointer<ffi.Void>;
typedef RAPID_Core_PipeStateFunc
    = ffi.Pointer<ffi.NativeFunction<RAPID_Core_PipeStateFuncFunction>>;
typedef RAPID_Core_PipeStateFuncFunction = ffi.Void Function(
    ffi.Int status, ffi.Pointer<ffi.Void> user_context);
typedef DartRAPID_Core_PipeStateFuncFunction = void Function(
    int status, ffi.Pointer<ffi.Void> user_context);
typedef RAPID_Core_InstructResponseFunc
    = ffi.Pointer<ffi.NativeFunction<RAPID_Core_InstructResponseFuncFunction>>;
typedef RAPID_Core_InstructResponseFuncFunction = ffi.Void Function(
    ffi.Int state,
    ffi.Pointer<Utf8> buffer,
    ffi.Int buffer_size,
    ffi.Pointer<ffi.Void> user_context);
typedef DartRAPID_Core_InstructResponseFuncFunction = void Function(
    int state,
    ffi.Pointer<Utf8> buffer,
    int buffer_size,
    ffi.Pointer<ffi.Void> user_context);
