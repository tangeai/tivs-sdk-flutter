// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class CoreApiLogBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) _lookup;

  CoreApiLogBinding(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  CoreApiLogBinding.fromLookup(ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup) : _lookup = lookup;

  void RAPID_Core_LeveledLoggingPrint(
    int level,
    ffi.Pointer<Utf8> tag,
    ffi.Pointer<Utf8> fmt,
  ) {
    return _RAPID_Core_LeveledLoggingPrint(
      level,
      tag,
      fmt,
    );
  }

  late final _RAPID_Core_LeveledLoggingPrintPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>)>>('RAPID_Core_LeveledLoggingPrint');
  late final _RAPID_Core_LeveledLoggingPrint =
      _RAPID_Core_LeveledLoggingPrintPtr.asFunction<void Function(int, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>)>();

  ffi.Pointer<Utf8> RAPID_Core_UploadLogging() {
    return _RAPID_Core_UploadLogging();
  }

  late final _RAPID_Core_UploadLoggingPtr = _lookup<ffi.NativeFunction<ffi.Pointer<Utf8> Function()>>('RAPID_Core_UploadLogging');
  late final _RAPID_Core_UploadLogging = _RAPID_Core_UploadLoggingPtr.asFunction<ffi.Pointer<Utf8> Function()>();

  void RAPID_Core_SetConsoleLoggingFunc(
    RAPID_Core_ConsoleLoggingFunc func,
  ) {
    return _RAPID_Core_SetConsoleLoggingFunc(
      func,
    );
  }

  late final _RAPID_Core_SetConsoleLoggingFuncPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_ConsoleLoggingFunc)>>('RAPID_Core_SetConsoleLoggingFunc');
  late final _RAPID_Core_SetConsoleLoggingFunc = _RAPID_Core_SetConsoleLoggingFuncPtr.asFunction<void Function(RAPID_Core_ConsoleLoggingFunc)>();
}

typedef RAPID_Core_ConsoleLoggingFunc = ffi.Pointer<ffi.NativeFunction<RAPID_Core_ConsoleLoggingFuncFunction>>;
typedef RAPID_Core_ConsoleLoggingFuncFunction = ffi.Void Function(ffi.Int level, ffi.Pointer<Utf8> tag, ffi.Pointer<Utf8> fmt, va_list args);
typedef DartRAPID_Core_ConsoleLoggingFuncFunction = void Function(int level, ffi.Pointer<Utf8> tag, ffi.Pointer<Utf8> fmt, va_list args);
typedef va_list = __builtin_va_list;
typedef __builtin_va_list = ffi.Pointer<Utf8>;
