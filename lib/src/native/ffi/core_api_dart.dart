// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class CoreApiDartBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) _lookup;

  CoreApiDartBinding(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  CoreApiDartBinding.fromLookup(ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup) : _lookup = lookup;

  int RAPID_Core_Dart_API_InitializeDL(
    ffi.Pointer<ffi.Void> data,
  ) {
    return _RAPID_Core_Dart_API_InitializeDL(
      data,
    );
  }

  late final _RAPID_Core_Dart_API_InitializeDLPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(ffi.Pointer<ffi.Void>)>>('RAPID_Core_Dart_API_InitializeDL');
  late final _RAPID_Core_Dart_API_InitializeDL = _RAPID_Core_Dart_API_InitializeDLPtr.asFunction<int Function(ffi.Pointer<ffi.Void>)>();
}
