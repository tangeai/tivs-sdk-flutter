// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class CoreApiExternalBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  CoreApiExternalBinding(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  CoreApiExternalBinding.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  void RAPID_Core_Instruct_SetUserExternalDataSendPort(
    ffi.Pointer<ffi.Void> proxy,
    int port,
  ) {
    return _RAPID_Core_Instruct_SetUserExternalDataSendPort(
      proxy,
      port,
    );
  }

  late final _RAPID_Core_Instruct_SetUserExternalDataSendPortPtr = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.LongLong)>>(
      'RAPID_Core_Instruct_SetUserExternalDataSendPort');
  late final _RAPID_Core_Instruct_SetUserExternalDataSendPort =
      _RAPID_Core_Instruct_SetUserExternalDataSendPortPtr.asFunction<
          void Function(ffi.Pointer<ffi.Void>, int)>();

  void RAPID_Core_LiveStream_SetUserExternalDataSendPort(
    ffi.Pointer<ffi.Void> live_stream,
    int port,
  ) {
    return _RAPID_Core_LiveStream_SetUserExternalDataSendPort(
      live_stream,
      port,
    );
  }

  late final _RAPID_Core_LiveStream_SetUserExternalDataSendPortPtr = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.LongLong)>>(
      'RAPID_Core_LiveStream_SetUserExternalDataSendPort');
  late final _RAPID_Core_LiveStream_SetUserExternalDataSendPort =
      _RAPID_Core_LiveStream_SetUserExternalDataSendPortPtr.asFunction<
          void Function(ffi.Pointer<ffi.Void>, int)>();
}
