// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class CoreApiProfileBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) _lookup;

  CoreApiProfileBinding(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  CoreApiProfileBinding.fromLookup(ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup) : _lookup = lookup;

  ffi.Pointer<Utf8> RAPID_Core_BindingProfile_Create(
    ffi.Pointer<Utf8> wifi,
    ffi.Pointer<Utf8> pwd,
    ffi.Pointer<Utf8> bindToken,
  ) {
    return _RAPID_Core_BindingProfile_Create(
      wifi,
      pwd,
      bindToken,
    );
  }

  late final _RAPID_Core_BindingProfile_CreatePtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>)>>(
          'RAPID_Core_BindingProfile_Create');
  late final _RAPID_Core_BindingProfile_Create =
      _RAPID_Core_BindingProfile_CreatePtr.asFunction<ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>)>();

  ffi.Pointer<RAPID_Core_BindingProfile_ByteArray> RAPID_Core_BindingProfileWithHeader(
    ffi.Pointer<Utf8> wifi,
    ffi.Pointer<Utf8> pwd,
    ffi.Pointer<Utf8> bindToken,
  ) {
    return _RAPID_Core_BindingProfileWithHeader(
      wifi,
      pwd,
      bindToken,
    );
  }

  late final _RAPID_Core_BindingProfileWithHeaderPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<RAPID_Core_BindingProfile_ByteArray> Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>)>>(
          'RAPID_Core_BindingProfileWithHeader');
  late final _RAPID_Core_BindingProfileWithHeader = _RAPID_Core_BindingProfileWithHeaderPtr.asFunction<
      ffi.Pointer<RAPID_Core_BindingProfile_ByteArray> Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>)>();

  void RAPID_Core_BindingProfile_Release(
    ffi.Pointer<Utf8> profile,
  ) {
    return _RAPID_Core_BindingProfile_Release(
      profile,
    );
  }

  late final _RAPID_Core_BindingProfile_ReleasePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<Utf8>)>>('RAPID_Core_BindingProfile_Release');
  late final _RAPID_Core_BindingProfile_Release = _RAPID_Core_BindingProfile_ReleasePtr.asFunction<void Function(ffi.Pointer<Utf8>)>();

  void RAPID_Core_BindingProfile_ByteArray_Release(
    ffi.Pointer<RAPID_Core_BindingProfile_ByteArray> byte_array,
  ) {
    return _RAPID_Core_BindingProfile_ByteArray_Release(
      byte_array,
    );
  }

  late final _RAPID_Core_BindingProfile_ByteArray_ReleasePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<RAPID_Core_BindingProfile_ByteArray>)>>('RAPID_Core_BindingProfile_ByteArray_Release');
  late final _RAPID_Core_BindingProfile_ByteArray_Release =
      _RAPID_Core_BindingProfile_ByteArray_ReleasePtr.asFunction<void Function(ffi.Pointer<RAPID_Core_BindingProfile_ByteArray>)>();
}

class RAPID_Core_BindingProfile_ByteArray extends ffi.Struct {
  external ffi.Pointer<Utf8> data;

  @ffi.Int()
  external int length;
}
