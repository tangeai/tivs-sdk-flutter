// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class CoreApiHttpBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  CoreApiHttpBinding(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  CoreApiHttpBinding.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  ffi.Pointer<RAPID_Core_HttpResp> RAPID_Core_HttpRequest(
    ffi.Pointer<Utf8> path,
    int method,
    ffi.Pointer<Utf8> request_content,
  ) {
    return _RAPID_Core_HttpRequest(
      path,
      method,
      request_content,
    );
  }

  late final _RAPID_Core_HttpRequestPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<RAPID_Core_HttpResp> Function(ffi.Pointer<Utf8>, ffi.Int,
              ffi.Pointer<Utf8>)>>('RAPID_Core_HttpRequest');
  late final _RAPID_Core_HttpRequest = _RAPID_Core_HttpRequestPtr.asFunction<
      ffi.Pointer<RAPID_Core_HttpResp> Function(
          ffi.Pointer<Utf8>, int, ffi.Pointer<Utf8>)>();

  ffi.Pointer<RAPID_Core_HttpResp> RAPID_Core_HttpRequestWithHeaders(
    ffi.Pointer<Utf8> path,
    int method,
    ffi.Pointer<Utf8> request_content,
    ffi.Pointer<Utf8> request_headers,
  ) {
    return _RAPID_Core_HttpRequestWithHeaders(
        path, method, request_content, request_headers);
  }

  late final _RAPID_Core_HttpRequestWithHeadersPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<RAPID_Core_HttpResp> Function(
              ffi.Pointer<Utf8>,
              ffi.Int,
              ffi.Pointer<Utf8>,
              ffi.Pointer<Utf8>)>>('RAPID_Core_HttpRequestWithHeaders');
  late final _RAPID_Core_HttpRequestWithHeaders =
      _RAPID_Core_HttpRequestWithHeadersPtr.asFunction<
          ffi.Pointer<RAPID_Core_HttpResp> Function(
              ffi.Pointer<Utf8>, int, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>)>();

  void RAPID_Core_HttpResp_Free(
    ffi.Pointer<RAPID_Core_HttpResp> resp,
  ) {
    return _RAPID_Core_HttpResp_Free(
      resp,
    );
  }

  late final _RAPID_Core_HttpResp_FreePtr = _lookup<
          ffi
          .NativeFunction<ffi.Void Function(ffi.Pointer<RAPID_Core_HttpResp>)>>(
      'RAPID_Core_HttpResp_Free');
  late final _RAPID_Core_HttpResp_Free = _RAPID_Core_HttpResp_FreePtr
      .asFunction<void Function(ffi.Pointer<RAPID_Core_HttpResp>)>();

  void RAPID_Core_Http_LoggingEnable(
    int enable,
  ) {
    return _RAPID_Core_Http_LoggingEnable(
      enable,
    );
  }

  late final _RAPID_Core_Http_LoggingEnablePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int)>>(
          'RAPID_Core_Http_LoggingEnable');
  late final _RAPID_Core_Http_LoggingEnable =
      _RAPID_Core_Http_LoggingEnablePtr.asFunction<void Function(int)>();
}

abstract class RAPID_Core_HttpMethod {
  static const int RAPID_Core_HttpMethod_GET = 0;
  static const int RAPID_Core_HttpMethod_POST = 1;
  static const int RAPID_Core_HttpMethod_DELETE = 2;
  static const int RAPID_Core_HttpMethod_PATCH = 3;
}

class RAPID_Core_HttpResp extends ffi.Struct {
  external ffi.Pointer<Utf8> data;

  @ffi.Int()
  external int success;

  external ffi.Pointer<Utf8> message;

  @ffi.Int()
  external int code;
}
