// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class CoreApiMemoryBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) _lookup;

  CoreApiMemoryBinding(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  CoreApiMemoryBinding.fromLookup(ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup) : _lookup = lookup;

  ffi.Pointer<Utf8> RAPID_Core_Memory_Toolbox_AllocateCopy(
    ffi.Pointer<Utf8> str,
  ) {
    return _RAPID_Core_Memory_Toolbox_AllocateCopy(
      str,
    );
  }

  late final _RAPID_Core_Memory_Toolbox_AllocateCopyPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>)>>('RAPID_Core_Memory_Toolbox_AllocateCopy');
  late final _RAPID_Core_Memory_Toolbox_AllocateCopy =
      _RAPID_Core_Memory_Toolbox_AllocateCopyPtr.asFunction<ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>)>();

  void RAPID_Core_Memory_Toolbox_FreeCharPtr(
    ffi.Pointer<Utf8> ptr,
  ) {
    return _RAPID_Core_Memory_Toolbox_FreeCharPtr(
      ptr,
    );
  }

  late final _RAPID_Core_Memory_Toolbox_FreeCharPtrPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<Utf8>)>>('RAPID_Core_Memory_Toolbox_FreeCharPtr');
  late final _RAPID_Core_Memory_Toolbox_FreeCharPtr = _RAPID_Core_Memory_Toolbox_FreeCharPtrPtr.asFunction<void Function(ffi.Pointer<Utf8>)>();
}
