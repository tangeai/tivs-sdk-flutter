// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class CoreApiObsBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) _lookup;

  CoreApiObsBinding(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  ffi.Pointer<Utf8> RAPID_Obs_PullEvents(
    ffi.Pointer<Utf8> device_id,
    int since_seq,
  ) {
    return _RAPID_Obs_PullEvents(
      device_id,
      since_seq,
    );
  }

  late final _RAPID_Obs_PullEventsPtr = _lookup<
          ffi.NativeFunction<ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, ffi.Int64)>>(
      'RAPID_Obs_PullEvents');
  late final _RAPID_Obs_PullEvents =
      _RAPID_Obs_PullEventsPtr.asFunction<ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, int)>();

  void RAPID_Obs_FreeString(
    ffi.Pointer<Utf8> str,
  ) {
    return _RAPID_Obs_FreeString(
      str,
    );
  }

  late final _RAPID_Obs_FreeStringPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<Utf8>)>>('RAPID_Obs_FreeString');
  late final _RAPID_Obs_FreeString =
      _RAPID_Obs_FreeStringPtr.asFunction<void Function(ffi.Pointer<Utf8>)>();
}
