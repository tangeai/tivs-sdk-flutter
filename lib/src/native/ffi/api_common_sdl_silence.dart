// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class ApiCommonSdl_silenceBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) _lookup;

  ApiCommonSdl_silenceBinding(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  ApiCommonSdl_silenceBinding.fromLookup(ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup) : _lookup = lookup;

  ffi.Pointer<RAPID_SDL_Vout> RAPID_SDL_Vout_Silence_Create() {
    return _RAPID_SDL_Vout_Silence_Create();
  }

  late final _RAPID_SDL_Vout_Silence_CreatePtr = _lookup<ffi.NativeFunction<ffi.Pointer<RAPID_SDL_Vout> Function()>>('RAPID_SDL_Vout_Silence_Create');
  late final _RAPID_SDL_Vout_Silence_Create = _RAPID_SDL_Vout_Silence_CreatePtr.asFunction<ffi.Pointer<RAPID_SDL_Vout> Function()>();

  ffi.Pointer<RAPID_SDL_Aout> RAPID_SDL_Aout_Silence_Create() {
    return _RAPID_SDL_Aout_Silence_Create();
  }

  late final _RAPID_SDL_Aout_Silence_CreatePtr = _lookup<ffi.NativeFunction<ffi.Pointer<RAPID_SDL_Aout> Function()>>('RAPID_SDL_Aout_Silence_Create');
  late final _RAPID_SDL_Aout_Silence_Create = _RAPID_SDL_Aout_Silence_CreatePtr.asFunction<ffi.Pointer<RAPID_SDL_Aout> Function()>();

  ffi.Pointer<RAPID_SDL_Aout> RAPID_SDL_Aout_Silence_Create_WithInterval(
    int interval_ms,
  ) {
    return _RAPID_SDL_Aout_Silence_Create_WithInterval(
      interval_ms,
    );
  }

  late final _RAPID_SDL_Aout_Silence_Create_WithIntervalPtr = _lookup<ffi.NativeFunction<ffi.Pointer<RAPID_SDL_Aout> Function(ffi.Int)>>('RAPID_SDL_Aout_Silence_Create_WithInterval');
  late final _RAPID_SDL_Aout_Silence_Create_WithInterval = _RAPID_SDL_Aout_Silence_Create_WithIntervalPtr.asFunction<ffi.Pointer<RAPID_SDL_Aout> Function(int)>();
}

class RAPID_SDL_VoutOverlay extends ffi.Opaque {}

class RAPID_SDL_Aout extends ffi.Opaque {}

class RAPID_SDL_Vout extends ffi.Opaque {}
