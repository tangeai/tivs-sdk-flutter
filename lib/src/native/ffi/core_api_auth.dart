// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class CoreApiAuthBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) _lookup;

  CoreApiAuthBinding(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  CoreApiAuthBinding.fromLookup(ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup) : _lookup = lookup;

  ffi.Pointer<RAPID_Core_AuthResp> RAPID_Core_Authenticate(
    ffi.Pointer<Utf8> access_token,
  ) {
    return _RAPID_Core_Authenticate(
      access_token,
    );
  }

  late final _RAPID_Core_AuthenticatePtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<RAPID_Core_AuthResp> Function(ffi.Pointer<Utf8>)>>('RAPID_Core_Authenticate');
  late final _RAPID_Core_Authenticate = _RAPID_Core_AuthenticatePtr.asFunction<ffi.Pointer<RAPID_Core_AuthResp> Function(ffi.Pointer<Utf8>)>();

  void RAPID_Core_AuthResp_Free(
    ffi.Pointer<RAPID_Core_AuthResp> resp,
  ) {
    return _RAPID_Core_AuthResp_Free(
      resp,
    );
  }

  late final _RAPID_Core_AuthResp_FreePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<RAPID_Core_AuthResp>)>>('RAPID_Core_AuthResp_Free');
  late final _RAPID_Core_AuthResp_Free = _RAPID_Core_AuthResp_FreePtr.asFunction<void Function(ffi.Pointer<RAPID_Core_AuthResp>)>();
}

class RAPID_Core_AuthResp extends ffi.Struct {
  @ffi.Int()
  external int user_id;

  @ffi.Int()
  external int issue_at;

  @ffi.Int()
  external int expires_in;

  @ffi.Int()
  external int success;

  external ffi.Pointer<Utf8> message;

  @ffi.Int()
  external int code;
}
