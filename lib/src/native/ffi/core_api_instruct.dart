// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class CoreApiInstructBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) _lookup;

  CoreApiInstructBinding(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  CoreApiInstructBinding.fromLookup(ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup) : _lookup = lookup;

  RAPID_Core_InstructStandard RAPID_Core_InstructStandard_Create(
    ffi.Pointer<ffi.Void> pipe_proxy,
    RAPID_Core_InstructStandard_ResponseFunc func,
    ffi.Pointer<ffi.Void> user_data,
  ) {
    return _RAPID_Core_InstructStandard_Create(
      pipe_proxy,
      func,
      user_data,
    );
  }

  late final _RAPID_Core_InstructStandard_CreatePtr = _lookup<
      ffi.NativeFunction<
          RAPID_Core_InstructStandard Function(
              ffi.Pointer<ffi.Void>, RAPID_Core_InstructStandard_ResponseFunc, ffi.Pointer<ffi.Void>)>>('RAPID_Core_InstructStandard_Create');
  late final _RAPID_Core_InstructStandard_Create = _RAPID_Core_InstructStandard_CreatePtr.asFunction<
      RAPID_Core_InstructStandard Function(ffi.Pointer<ffi.Void>, RAPID_Core_InstructStandard_ResponseFunc, ffi.Pointer<ffi.Void>)>();

  void RAPID_Core_InstructStandard_Request(
    RAPID_Core_InstructStandard instruct,
    ffi.Pointer<Utf8> name,
    ffi.Pointer<Utf8> params,
  ) {
    return _RAPID_Core_InstructStandard_Request(
      instruct,
      name,
      params,
    );
  }

  late final _RAPID_Core_InstructStandard_RequestPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_InstructStandard, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>)>>(
          'RAPID_Core_InstructStandard_Request');
  late final _RAPID_Core_InstructStandard_Request =
      _RAPID_Core_InstructStandard_RequestPtr.asFunction<void Function(RAPID_Core_InstructStandard, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>)>();

  void RAPID_Core_InstructStandard_Release(
    RAPID_Core_InstructStandard instruct,
  ) {
    return _RAPID_Core_InstructStandard_Release(
      instruct,
    );
  }

  late final _RAPID_Core_InstructStandard_ReleasePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_InstructStandard)>>('RAPID_Core_InstructStandard_Release');
  late final _RAPID_Core_InstructStandard_Release = _RAPID_Core_InstructStandard_ReleasePtr.asFunction<void Function(RAPID_Core_InstructStandard)>();

  void RAPID_Core_InstructStandard_SetResponseSendPort(
    RAPID_Core_InstructStandard instruct,
    int port,
  ) {
    return _RAPID_Core_InstructStandard_SetResponseSendPort(
      instruct,
      port,
    );
  }

  late final _RAPID_Core_InstructStandard_SetResponseSendPortPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_InstructStandard, ffi.LongLong)>>('RAPID_Core_InstructStandard_SetResponseSendPort');
  late final _RAPID_Core_InstructStandard_SetResponseSendPort =
      _RAPID_Core_InstructStandard_SetResponseSendPortPtr.asFunction<void Function(RAPID_Core_InstructStandard, int)>();
}

abstract class RAPID_Core_InstructState {
  static const int RAPID_Core_InstructState_RESPONSE_SUCCESS = 0;
  static const int RAPID_Core_InstructState_TRANSPORT_UNAVAILABLE = 1;
  static const int RAPID_Core_InstructState_RESPONSE_TIMEOUT = 2;
  static const int RAPID_Core_InstructState_DUPLICATE_INSTRUCT = 3;
  static const int RAPID_Core_InstructState_FAILED_INSTRUCT = 4;
  static const int RAPID_Core_InstructState_UNKNOWN = 5;
  static const int RAPID_Core_InstructState_DEVICE_IN_PROGRESS = 6;
  static const int RAPID_Core_InstructState_DEVICE_ERROR_HEADER = 7;
  static const int RAPID_Core_InstructState_DEVICE_UNSUPPORT_CMD = 8;
  static const int RAPID_Core_InstructState_DEVICE_INVALID_PARAM = 9;
  static const int RAPID_Core_InstructState_DEVICE_LACK_OF_RESOURCE = 10;
  static const int RAPID_Core_InstructState_DEVICE_ERROR_INTERNAL = 11;
  static const int RAPID_Core_InstructState_DEVICE_NOT_ALLOWED = 12;
}

typedef RAPID_Core_InstructStandard = ffi.Pointer<ffi.Void>;
typedef RAPID_Core_InstructStandard_ResponseFunc = ffi.Pointer<ffi.NativeFunction<RAPID_Core_InstructStandard_ResponseFuncFunction>>;
typedef RAPID_Core_InstructStandard_ResponseFuncFunction = ffi.Void Function(
    ffi.Pointer<Utf8> json_str, ffi.Int json_length, ffi.Pointer<ffi.Void> user_data);
typedef DartRAPID_Core_InstructStandard_ResponseFuncFunction = void Function(
    ffi.Pointer<Utf8> json_str, int json_length, ffi.Pointer<ffi.Void> user_data);
