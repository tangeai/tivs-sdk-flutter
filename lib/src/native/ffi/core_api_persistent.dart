// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class CoreApiPersistentBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) _lookup;

  CoreApiPersistentBinding(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  CoreApiPersistentBinding.fromLookup(ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup) : _lookup = lookup;

  void RAPID_Core_PersistentChannel_SetStateCallback(
    RAPID_Core_PersistentChannelStateFunc callback,
    ffi.Pointer<ffi.Void> user_context,
  ) {
    return _RAPID_Core_PersistentChannel_SetStateCallback(
      callback,
      user_context,
    );
  }

  late final _RAPID_Core_PersistentChannel_SetStateCallbackPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_PersistentChannelStateFunc, ffi.Pointer<ffi.Void>)>>(
          'RAPID_Core_PersistentChannel_SetStateCallback');
  late final _RAPID_Core_PersistentChannel_SetStateCallback =
      _RAPID_Core_PersistentChannel_SetStateCallbackPtr.asFunction<void Function(RAPID_Core_PersistentChannelStateFunc, ffi.Pointer<ffi.Void>)>();

  void RAPID_Core_PersistentChannel_SetStateSendPort(
    int port,
  ) {
    return _RAPID_Core_PersistentChannel_SetStateSendPort(
      port,
    );
  }

  late final _RAPID_Core_PersistentChannel_SetStateSendPortPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.LongLong)>>('RAPID_Core_PersistentChannel_SetStateSendPort');
  late final _RAPID_Core_PersistentChannel_SetStateSendPort = _RAPID_Core_PersistentChannel_SetStateSendPortPtr.asFunction<void Function(int)>();

  void RAPID_Core_PersistentChannel_SetMessageCallback(
    RAPID_Core_PersistentChannelMessageFunc callback,
    ffi.Pointer<ffi.Void> user_context,
  ) {
    return _RAPID_Core_PersistentChannel_SetMessageCallback(
      callback,
      user_context,
    );
  }

  late final _RAPID_Core_PersistentChannel_SetMessageCallbackPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_PersistentChannelMessageFunc, ffi.Pointer<ffi.Void>)>>(
          'RAPID_Core_PersistentChannel_SetMessageCallback');
  late final _RAPID_Core_PersistentChannel_SetMessageCallback =
      _RAPID_Core_PersistentChannel_SetMessageCallbackPtr.asFunction<void Function(RAPID_Core_PersistentChannelMessageFunc, ffi.Pointer<ffi.Void>)>();

  void RAPID_Core_PersistentChannel_SetMessageSendPort(
    int port,
  ) {
    return _RAPID_Core_PersistentChannel_SetMessageSendPort(
      port,
    );
  }

  late final _RAPID_Core_PersistentChannel_SetMessageSendPortPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.LongLong)>>('RAPID_Core_PersistentChannel_SetMessageSendPort');
  late final _RAPID_Core_PersistentChannel_SetMessageSendPort = _RAPID_Core_PersistentChannel_SetMessageSendPortPtr.asFunction<void Function(int)>();

  void RAPID_Core_PersistentChannel_Connect() {
    return _RAPID_Core_PersistentChannel_Connect();
  }

  late final _RAPID_Core_PersistentChannel_ConnectPtr = _lookup<ffi.NativeFunction<ffi.Void Function()>>('RAPID_Core_PersistentChannel_Connect');
  late final _RAPID_Core_PersistentChannel_Connect = _RAPID_Core_PersistentChannel_ConnectPtr.asFunction<void Function()>();

  void RAPID_Core_PersistentChannel_Disconnect() {
    return _RAPID_Core_PersistentChannel_Disconnect();
  }

  late final _RAPID_Core_PersistentChannel_DisconnectPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function()>>('RAPID_Core_PersistentChannel_Disconnect');
  late final _RAPID_Core_PersistentChannel_Disconnect = _RAPID_Core_PersistentChannel_DisconnectPtr.asFunction<void Function()>();

  int RAPID_Core_PersistentChannel_CurrentState() {
    return _RAPID_Core_PersistentChannel_CurrentState();
  }

  late final _RAPID_Core_PersistentChannel_CurrentStatePtr =
      _lookup<ffi.NativeFunction<ffi.Int Function()>>('RAPID_Core_PersistentChannel_CurrentState');
  late final _RAPID_Core_PersistentChannel_CurrentState = _RAPID_Core_PersistentChannel_CurrentStatePtr.asFunction<int Function()>();
}

abstract class RAPID_Core_PersistentChannelState {
  static const int RAPID_CORE_PERSISTENT_CHANNEL_STATE_DISCONNECTED = 0;
  static const int RAPID_CORE_PERSISTENT_CHANNEL_STATE_CONNECTING = 1;
  static const int RAPID_CORE_PERSISTENT_CHANNEL_STATE_CONNECTED = 2;
}

typedef RAPID_Core_PersistentChannelStateFunc = ffi.Pointer<ffi.NativeFunction<RAPID_Core_PersistentChannelStateFuncFunction>>;
typedef RAPID_Core_PersistentChannelStateFuncFunction = ffi.Void Function(
    ffi.Int state, ffi.Pointer<Utf8> reason, ffi.Pointer<ffi.Void> user_context);
typedef DartRAPID_Core_PersistentChannelStateFuncFunction = void Function(int state, ffi.Pointer<Utf8> reason, ffi.Pointer<ffi.Void> user_context);
typedef RAPID_Core_PersistentChannelMessageFunc = ffi.Pointer<ffi.NativeFunction<RAPID_Core_PersistentChannelMessageFuncFunction>>;
typedef RAPID_Core_PersistentChannelMessageFuncFunction = ffi.Void Function(
    ffi.Pointer<Utf8> name, ffi.Pointer<Utf8> detail, ffi.Pointer<ffi.Void> user_context);
typedef DartRAPID_Core_PersistentChannelMessageFuncFunction = void Function(
    ffi.Pointer<Utf8> name, ffi.Pointer<Utf8> detail, ffi.Pointer<ffi.Void> user_context);
