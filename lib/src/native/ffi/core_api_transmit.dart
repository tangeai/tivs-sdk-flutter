// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class CoreApiTransmitBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) _lookup;

  CoreApiTransmitBinding(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  CoreApiTransmitBinding.fromLookup(ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup) : _lookup = lookup;

  RAPID_Core_ProfileTransmitter RAPID_Core_ProfileTransmitter_Create() {
    return _RAPID_Core_ProfileTransmitter_Create();
  }

  late final _RAPID_Core_ProfileTransmitter_CreatePtr =
      _lookup<ffi.NativeFunction<RAPID_Core_ProfileTransmitter Function()>>('RAPID_Core_ProfileTransmitter_Create');
  late final _RAPID_Core_ProfileTransmitter_Create = _RAPID_Core_ProfileTransmitter_CreatePtr.asFunction<RAPID_Core_ProfileTransmitter Function()>();

  void RAPID_Core_ProfileTransmitter_Prepare(
    RAPID_Core_ProfileTransmitter transmitter,
    ffi.Pointer<Utf8> ssid,
    ffi.Pointer<Utf8> password,
    ffi.Pointer<Utf8> bind_token,
  ) {
    return _RAPID_Core_ProfileTransmitter_Prepare(
      transmitter,
      ssid,
      password,
      bind_token,
    );
  }

  late final _RAPID_Core_ProfileTransmitter_PreparePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_ProfileTransmitter, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>)>>(
          'RAPID_Core_ProfileTransmitter_Prepare');
  late final _RAPID_Core_ProfileTransmitter_Prepare = _RAPID_Core_ProfileTransmitter_PreparePtr.asFunction<
      void Function(RAPID_Core_ProfileTransmitter, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>)>();

  void RAPID_Core_ProfileTransmitter_SetStateFunc(
    RAPID_Core_ProfileTransmitter transmitter,
    RAPID_Core_ProfileTransmitter_StateFunc callback,
    ffi.Pointer<ffi.Void> user_data,
  ) {
    return _RAPID_Core_ProfileTransmitter_SetStateFunc(
      transmitter,
      callback,
      user_data,
    );
  }

  late final _RAPID_Core_ProfileTransmitter_SetStateFuncPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_ProfileTransmitter, RAPID_Core_ProfileTransmitter_StateFunc, ffi.Pointer<ffi.Void>)>>(
          'RAPID_Core_ProfileTransmitter_SetStateFunc');
  late final _RAPID_Core_ProfileTransmitter_SetStateFunc = _RAPID_Core_ProfileTransmitter_SetStateFuncPtr.asFunction<
      void Function(RAPID_Core_ProfileTransmitter, RAPID_Core_ProfileTransmitter_StateFunc, ffi.Pointer<ffi.Void>)>();

  void RAPID_Core_ProfileTransmitter_SetResponseSendPort(
    RAPID_Core_ProfileTransmitter transmitter,
    int send_port,
  ) {
    return _RAPID_Core_ProfileTransmitter_SetResponseSendPort(
      transmitter,
      send_port,
    );
  }

  late final _RAPID_Core_ProfileTransmitter_SetResponseSendPortPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_ProfileTransmitter, ffi.LongLong)>>(
          'RAPID_Core_ProfileTransmitter_SetResponseSendPort');
  late final _RAPID_Core_ProfileTransmitter_SetResponseSendPort =
      _RAPID_Core_ProfileTransmitter_SetResponseSendPortPtr.asFunction<void Function(RAPID_Core_ProfileTransmitter, int)>();

  int RAPID_Core_ProfileTransmitter_GetCurrentState(
    RAPID_Core_ProfileTransmitter transmitter,
  ) {
    return _RAPID_Core_ProfileTransmitter_GetCurrentState(
      transmitter,
    );
  }

  late final _RAPID_Core_ProfileTransmitter_GetCurrentStatePtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(RAPID_Core_ProfileTransmitter)>>('RAPID_Core_ProfileTransmitter_GetCurrentState');
  late final _RAPID_Core_ProfileTransmitter_GetCurrentState =
      _RAPID_Core_ProfileTransmitter_GetCurrentStatePtr.asFunction<int Function(RAPID_Core_ProfileTransmitter)>();

  void RAPID_Core_ProfileTransmitter_Start(
    RAPID_Core_ProfileTransmitter transmitter,
  ) {
    return _RAPID_Core_ProfileTransmitter_Start(
      transmitter,
    );
  }

  late final _RAPID_Core_ProfileTransmitter_StartPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_ProfileTransmitter)>>('RAPID_Core_ProfileTransmitter_Start');
  late final _RAPID_Core_ProfileTransmitter_Start =
      _RAPID_Core_ProfileTransmitter_StartPtr.asFunction<void Function(RAPID_Core_ProfileTransmitter)>();

  void RAPID_Core_ProfileTransmitter_Stop(
    RAPID_Core_ProfileTransmitter transmitter,
  ) {
    return _RAPID_Core_ProfileTransmitter_Stop(
      transmitter,
    );
  }

  late final _RAPID_Core_ProfileTransmitter_StopPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_ProfileTransmitter)>>('RAPID_Core_ProfileTransmitter_Stop');
  late final _RAPID_Core_ProfileTransmitter_Stop = _RAPID_Core_ProfileTransmitter_StopPtr.asFunction<void Function(RAPID_Core_ProfileTransmitter)>();

  void RAPID_Core_ProfileTransmitter_Free(
    RAPID_Core_ProfileTransmitter transmitter,
  ) {
    return _RAPID_Core_ProfileTransmitter_Free(
      transmitter,
    );
  }

  late final _RAPID_Core_ProfileTransmitter_FreePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_ProfileTransmitter)>>('RAPID_Core_ProfileTransmitter_Free');
  late final _RAPID_Core_ProfileTransmitter_Free = _RAPID_Core_ProfileTransmitter_FreePtr.asFunction<void Function(RAPID_Core_ProfileTransmitter)>();
}

typedef RAPID_Core_ProfileTransmitter = ffi.Pointer<ffi.Void>;
typedef RAPID_Core_ProfileTransmitter_StateFunc = ffi.Pointer<ffi.NativeFunction<RAPID_Core_ProfileTransmitter_StateFuncFunction>>;
typedef RAPID_Core_ProfileTransmitter_StateFuncFunction = ffi.Void Function(ffi.Int state, ffi.Pointer<ffi.Void> user_data);
typedef DartRAPID_Core_ProfileTransmitter_StateFuncFunction = void Function(int state, ffi.Pointer<ffi.Void> user_data);
