// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class CoreApiDebugBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) _lookup;

  CoreApiDebugBinding(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  CoreApiDebugBinding.fromLookup(ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup) : _lookup = lookup;

  ffi.Pointer<Utf8> RAPID_Core_DebuggingCode_Create() {
    return _RAPID_Core_DebuggingCode_Create();
  }

  late final _RAPID_Core_DebuggingCode_CreatePtr = _lookup<ffi.NativeFunction<ffi.Pointer<Utf8> Function()>>('RAPID_Core_DebuggingCode_Create');
  late final _RAPID_Core_DebuggingCode_Create = _RAPID_Core_DebuggingCode_CreatePtr.asFunction<ffi.Pointer<Utf8> Function()>();

  void RAPID_Core_DebuggingCode_Free(
    ffi.Pointer<Utf8> code,
  ) {
    return _RAPID_Core_DebuggingCode_Free(
      code,
    );
  }

  late final _RAPID_Core_DebuggingCode_FreePtr = _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<Utf8>)>>('RAPID_Core_DebuggingCode_Free');
  late final _RAPID_Core_DebuggingCode_Free = _RAPID_Core_DebuggingCode_FreePtr.asFunction<void Function(ffi.Pointer<Utf8>)>();

  ffi.Pointer<RAPID_Core_AuthResp> RAPID_Core_DebuggingCode_Apply(
    ffi.Pointer<Utf8> code,
  ) {
    return _RAPID_Core_DebuggingCode_Apply(
      code,
    );
  }

  late final _RAPID_Core_DebuggingCode_ApplyPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<RAPID_Core_AuthResp> Function(ffi.Pointer<Utf8>)>>('RAPID_Core_DebuggingCode_Apply');
  late final _RAPID_Core_DebuggingCode_Apply =
      _RAPID_Core_DebuggingCode_ApplyPtr.asFunction<ffi.Pointer<RAPID_Core_AuthResp> Function(ffi.Pointer<Utf8>)>();
}
