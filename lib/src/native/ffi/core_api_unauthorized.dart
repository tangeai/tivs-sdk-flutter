// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class CoreApiUnauthorizedBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) _lookup;

  CoreApiUnauthorizedBinding(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  CoreApiUnauthorizedBinding.fromLookup(ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup) : _lookup = lookup;

  void RAPID_Core_Unauthorized_SetFunc(
    RAPID_Core_UnauthorizedFunc callback,
    ffi.Pointer<ffi.Void> user_context,
  ) {
    return _RAPID_Core_Unauthorized_SetFunc(
      callback,
      user_context,
    );
  }

  late final _RAPID_Core_Unauthorized_SetFuncPtr = _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_UnauthorizedFunc, ffi.Pointer<ffi.Void>)>>('RAPID_Core_Unauthorized_SetFunc');
  late final _RAPID_Core_Unauthorized_SetFunc = _RAPID_Core_Unauthorized_SetFuncPtr.asFunction<void Function(RAPID_Core_UnauthorizedFunc, ffi.Pointer<ffi.Void>)>();

  void RAPID_Core_Unauthorized_SetSendPort(
    int port,
  ) {
    return _RAPID_Core_Unauthorized_SetSendPort(
      port,
    );
  }

  late final _RAPID_Core_Unauthorized_SetSendPortPtr = _lookup<ffi.NativeFunction<ffi.Void Function(ffi.LongLong)>>('RAPID_Core_Unauthorized_SetSendPort');
  late final _RAPID_Core_Unauthorized_SetSendPort = _RAPID_Core_Unauthorized_SetSendPortPtr.asFunction<void Function(int)>();
}

typedef RAPID_Core_UnauthorizedFunc = ffi.Pointer<ffi.NativeFunction<RAPID_Core_UnauthorizedFuncFunction>>;
typedef RAPID_Core_UnauthorizedFuncFunction = ffi.Void Function(ffi.Pointer<ffi.Void> user_context);
typedef DartRAPID_Core_UnauthorizedFuncFunction = void Function(ffi.Pointer<ffi.Void> user_context);
